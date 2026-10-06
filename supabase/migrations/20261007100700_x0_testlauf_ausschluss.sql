-- X0.3 Testlaeufe ausschliessen (Entscheidung 27, Auftrag Punkt 10).
--
-- Jede Funktion ist der geltende Stand (pg_get_functiondef aus allen
-- Migrationen) mit genau der markierten Ergaenzung:
--   akte_basis              letzte Session ohne Test-Sessions (Akte, Board, Heute)
--   einheiten_stand_intern  verbrauchte Einheiten ohne Test-Sessions
--   akte_sessions           Sessions-Kachel der Akte ohne Test-Sessions
--   eltern_report_eintragen kein Report aus einem LSA-Testlauf
--   lsa_uebernahme          kein Lernpfad aus einem Testlauf
--   lsa_confirm_focus       kein Lernpfad aus einem Testlauf
-- vertrag_abschliessen (Report 1) folgt in 20261007100800.
-- Lead-Trichter: Testlaeufe gibt es nur mit Test-Leads (lead_lsa_freigeben),
-- und Test-Leads zaehlen in keinem Lead-Zaehler der Oberflaeche.

CREATE OR REPLACE FUNCTION public.akte_basis()
 RETURNS TABLE(student_id uuid, name text, klasse integer, schule_id uuid, schule text, akte_seit date, zustand text, ruhend_seit date, letzte_session timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with ich as (
    select public.get_my_role() as rolle
  ),
  vertrag as (
    select v.student_id,
           min(v.abgeschlossen_am) as akte_seit,
           bool_or(v.wirksamer_status in ('aktiv', 'im_widerruf')) as aktiv,
           -- Ende des letzten Vertrags, der gelaufen ist: gekuendigt_zum vor
           -- vertrag_ende; ein widerrufener Vertrag ist nie gelaufen und zaehlt
           -- nur, wenn es keinen anderen gibt (dann ab dem Widerruf).
           coalesce(max(coalesce(v.gekuendigt_zum, v.vertrag_ende)) filter (where v.widerrufen_am is null),
                    max(v.widerrufen_am)) as letztes_ende,
           (array_agg(nullif(btrim(concat_ws(' ', v.kind_vorname, v.kind_nachname)), '')
                      order by v.vertragsbeginn desc nulls last))[1] as kindname
      from public.vertraege_aktuell v
     where v.student_id is not null
     group by v.student_id
  ),
  anwesend as (
    select ss.student_id, max(cs.scheduled_at) as letzte_session
      from public.session_students ss
      join public.coaching_sessions cs on cs.id = ss.session_id
     where ss.attendance = 'present'
       and not cs.testlauf
     group by ss.student_id
  )
  select s.id,
         coalesce(nullif(btrim(p.full_name), ''), vt.kindname),
         s.class_level,
         s.schule_id,
         coalesce(sch.name, s.school_name),
         vt.akte_seit,
         case when vt.aktiv then 'aktiv' else 'ruhend' end,
         case when vt.aktiv then null else vt.letztes_ende end,
         a.letzte_session
    from vertrag vt
    join public.students s   on s.id = vt.student_id
    left join public.profiles p   on p.id = s.profile_id
    left join public.schulen  sch on sch.id = s.schule_id
    left join anwesend a on a.student_id = s.id
    cross join ich
   where ich.rolle = 'admin'
      or (ich.rolle = 'coach' and vt.aktiv);
$function$;

CREATE OR REPLACE FUNCTION public.einheiten_stand_intern(p_student_id uuid, p_heute date)
 RETURNS TABLE(art text, einheiten integer, beginn date, stichtag date, verbraucht integer, offen integer, soll numeric, rueckstand numeric, ampel text, wochen_rest numeric, noetig_pro_woche numeric, gleichmaessig_pro_woche numeric)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
  with vertrag as (
    select v.einheiten, v.vertragsbeginn, v.vertrag_ende
      from public.vertraege_aktuell v
     where v.student_id = p_student_id
       and v.wirksamer_status in ('aktiv', 'im_widerruf')
       and v.einheiten is not null
       and v.vertragsbeginn is not null
       and v.vertrag_ende is not null
       and v.vertrag_ende >= p_heute
     order by (v.vertragsbeginn <= p_heute) desc,
              case when v.vertragsbeginn <= p_heute then v.vertragsbeginn end desc nulls last,
              v.vertragsbeginn asc
     limit 1
  ),
  zaehlung as (
    select count(*)::integer as verbraucht
      from vertrag vt
      join public.session_students ss on ss.student_id = p_student_id
      join public.coaching_sessions cs on cs.id = ss.session_id
     where public.einheit_verbraucht(ss.attendance)
       and not cs.testlauf
       and (cs.scheduled_at at time zone 'Europe/Berlin')::date
           between vt.vertragsbeginn and vt.vertrag_ende
  )
  select coalesce(r.art, 'keiner'),
         vt.einheiten,
         vt.vertragsbeginn,
         vt.vertrag_ende,
         case when r.art = 'laufend' then z.verbraucht end,
         r.offen,
         r.soll,
         r.rueckstand,
         r.ampel,
         r.wochen_rest,
         r.noetig_pro_woche,
         r.gleichmaessig_pro_woche
    from (select 1) eins
    left join vertrag vt on true
    left join zaehlung z on true
    left join lateral public.einheiten_rechnung(
      vt.einheiten, vt.vertragsbeginn, vt.vertrag_ende, z.verbraucht, p_heute
    ) r on true;
$function$;

CREATE OR REPLACE FUNCTION public.akte_sessions(p_student_id uuid)
 RETURNS TABLE(session_id uuid, scheduled_at timestamp with time zone, coach_id uuid, coach_name text, attendance text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_rolle text := public.get_my_role();
  v_seit  date;
begin
  if v_rolle = 'admin' then
    null;
  elsif v_rolle = 'coach' and public.akte_aktiv(p_student_id) then
    null;
  else
    raise exception 'akte_sessions: keine Berechtigung fuer diese Akte' using errcode = '42501';
  end if;

  select min(v.abgeschlossen_am) into v_seit
    from public.vertraege v
   where v.student_id = p_student_id and v.status = 'abgeschlossen';

  return query
    select cs.id, cs.scheduled_at, cs.coach_id, p.full_name, ss.attendance
      from public.session_students ss
      join public.coaching_sessions cs on cs.id = ss.session_id
      left join public.profiles p on p.id = cs.coach_id
     where ss.student_id = p_student_id
       and not cs.testlauf
       and v_seit is not null
       and (cs.scheduled_at at time zone 'Europe/Berlin')::date >= v_seit
     order by cs.scheduled_at desc;
end;
$function$;

CREATE OR REPLACE FUNCTION public.eltern_report_eintragen(p_student_id uuid, p_art text, p_berichtsmonat date DEFAULT NULL::date, p_kernaussagen jsonb DEFAULT NULL::jsonb, p_freigegeben_von uuid DEFAULT NULL::uuid, p_freigegeben_am timestamp with time zone DEFAULT NULL::timestamp with time zone, p_versendet_am timestamp with time zone DEFAULT NULL::timestamp with time zone, p_versendet_an text DEFAULT NULL::text, p_pdf_pfad text DEFAULT NULL::text, p_parent_report_id uuid DEFAULT NULL::uuid, p_lsa_session_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_nr integer;
  v_id uuid;
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'eltern_report_eintragen: nur Admin' using errcode = '42501';
  end if;

  perform 1 from public.students where id = p_student_id for update;
  if not found then
    raise exception 'eltern_report_eintragen: Kind nicht gefunden' using errcode = 'P0002';
  end if;

  if p_lsa_session_id is not null and not exists (
    select 1 from public.lsa_sessions where id = p_lsa_session_id and student_id = p_student_id
  ) then
    raise exception 'eltern_report_eintragen: die LSA gehoert nicht zu diesem Kind' using errcode = '22023';
  end if;
  -- X0: aus einem Testlauf entsteht nie ein Eltern-Report.
  if p_lsa_session_id is not null and exists (
    select 1 from public.lsa_sessions where id = p_lsa_session_id and testlauf
  ) then
    raise exception 'eltern_report_eintragen: Testlauf ergibt keinen Report' using errcode = '22023';
  end if;

  select coalesce(max(nr), 0) + 1 into v_nr from public.eltern_reports where student_id = p_student_id;

  insert into public.eltern_reports
    (student_id, nr, art, berichtsmonat, kernaussagen, freigegeben_von, freigegeben_am,
     versendet_am, versendet_an, pdf_pfad, parent_report_id, lsa_session_id)
  values
    (p_student_id, v_nr, p_art, p_berichtsmonat, p_kernaussagen, p_freigegeben_von, p_freigegeben_am,
     p_versendet_am, nullif(btrim(coalesce(p_versendet_an, '')), ''), p_pdf_pfad, p_parent_report_id,
     p_lsa_session_id)
  returning id into v_id;

  perform public.audit_log_schreiben('eltern_report_eintragen', 'eltern_report', v_id);

  return jsonb_build_object('id', v_id, 'nr', v_nr);
end;
$function$;

CREATE OR REPLACE FUNCTION public.lsa_uebernahme(p_session_id uuid, p_student_id uuid, p_jetzt timestamp with time zone DEFAULT now())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session lsa_sessions;
  v_lead_id uuid;
  v_n       int;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'lsa_uebernahme: nur Coach/Admin' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'lsa_uebernahme: Session nicht gefunden' using errcode = 'P0002';
  end if;
  -- X0: ein Testlauf geht nie in den Lernpfad.
  if v_session.testlauf then
    raise exception 'lsa_uebernahme: Testlauf wird nicht uebernommen' using errcode = '22023';
  end if;

  -- Frage 1 = JA: die Sitzung haengt am (spaeter echten) Schueler. Der
  -- uebergebene Schueler MUSS dieser sein. Nie "die neueste Sitzung" raten.
  if v_session.student_id <> p_student_id then
    raise exception 'lsa_uebernahme: Sitzung gehoert zu Schueler %, nicht %',
      v_session.student_id, p_student_id using errcode = 'P0001';
  end if;
  -- Konfliktsperre: eine Sitzung gehoert zu genau einem Schueler.
  if v_session.uebernommen_zu_student_id is not null
     and v_session.uebernommen_zu_student_id <> p_student_id then
    raise exception 'lsa_uebernahme: Sitzung bereits an Schueler % uebernommen',
      v_session.uebernommen_zu_student_id using errcode = 'P0001';
  end if;

  -- Fokus-Vorschlaege NUR aus den Luecken. 'traegt' bestaetigt, 'ungeprueft'
  -- gehoert in den Report, nicht in den Pfad. belegt_direkt wandert mit.
  -- ON CONFLICT DO NOTHING: idempotent, und ein bereits bestaetigter/
  -- verworfener Eintrag wird nie ueberschrieben (der Konflikt trifft dieselbe
  -- (student, skill, herkunft) und laesst die Coach-Entscheidung stehen).
  insert into student_focus_areas
    (student_id, cluster_id, skill_key, herkunfts_session_id, zustand,
     belegt_direkt, status, active, source)
  select p_student_id, null, u.skill_key, p_session_id, u.zustand,
         u.belegt_direkt, 'vorgeschlagen', false, 'lsa'
    from lsa_skill_urteil u
   where u.session_id = p_session_id
     and u.zustand in ('traegt_nicht','nicht_angesetzt','traegt_teilweise')
  on conflict (student_id, skill_key, herkunfts_session_id)
    where skill_key is not null
    do nothing;
  get diagnostics v_n = row_count;

  -- Sitzungs-Spur.
  update lsa_sessions
     set uebernommen_zu_student_id = p_student_id,
         uebernommen_am = coalesce(uebernommen_am, p_jetzt)
   where id = p_session_id;

  -- Lead-Spur (Frage 2: am Lead, nicht am Platz). Vor der Konversion ueber
  -- students.lead_id, danach ueber converted_student_id.
  select id into v_lead_id from leads
   where converted_student_id = p_student_id
      or id = (select lead_id from students where id = p_student_id)
   limit 1;
  if v_lead_id is not null then
    update leads set konvertiert_am = coalesce(konvertiert_am, p_jetzt)
     where id = v_lead_id;
  end if;

  return jsonb_build_object('ok', true, 'student_id', p_student_id, 'fokus_erzeugt', v_n);
end;
$function$;

CREATE OR REPLACE FUNCTION public.lsa_confirm_focus(p_session_id uuid, p_cluster_ids uuid[] DEFAULT NULL::uuid[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_session  lsa_sessions;
  v_clusters uuid[];
  v_written  integer := 0;
begin
  if public.get_my_role() not in ('coach','admin') then
    raise exception 'LSA: Lernpfad-Freigabe nur durch Coach (FernUSG)' using errcode = '42501';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'LSA: Session nicht gefunden' using errcode = 'P0002';
  end if;
  -- X0: ein Testlauf geht nie in den Lernpfad.
  if v_session.testlauf then
    raise exception 'LSA: Testlauf wird nicht uebernommen' using errcode = '22023';
  end if;
  if v_session.status <> 'completed' then
    raise exception 'LSA: Session ist noch nicht ausgewertet' using errcode = 'P0001';
  end if;

  v_clusters := coalesce(
    p_cluster_ids,
    (select array_agg((x)::uuid)
       from jsonb_array_elements_text(
              coalesce(v_session.result_summary -> 'proposal' -> 'focus_cluster_ids',
                       '[]'::jsonb)
            ) as t(x))
  );

  if v_clusters is null or array_length(v_clusters, 1) is null then
    return jsonb_build_object('applied', true, 'focus_areas_written', 0);
  end if;

  insert into student_focus_areas (student_id, cluster_id, coach_id, source, note)
  select v_session.student_id, c, auth.uid(), 'lsa',
         'Aus LSA-Vorschlag bestaetigt (' || p_session_id::text || ')'
    from unnest(v_clusters) as c
   where not exists (
           select 1 from student_focus_areas f
            where f.student_id = v_session.student_id
              and f.cluster_id = c
              and f.active
         );
  get diagnostics v_written = row_count;

  update lsa_sessions
     set result_summary = jsonb_set(
           result_summary,
           '{proposal,applied}',
           'true'::jsonb,
           true
         )
   where id = p_session_id;

  return jsonb_build_object('applied', true, 'focus_areas_written', v_written);
end;
$function$;
