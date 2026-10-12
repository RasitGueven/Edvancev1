-- T2 (Session-Rahmen): drei Haertungen aus X0c (offene-punkte-x0c, Weitere offene Punkte 2 und 5).
--
-- 1. erklaer_status_setzen: p_status (und p_objekt) NULL wirft 22023 in der
--    Eingangspruefung, also vor dem Admin-Tor fuer das Freigeben. Bisher fiel NULL
--    durch beide "not in" und scheiterte erst am not null der Statusspalte (23502).
-- 2. lsa_uebernahme: p_student_id NULL wirft 22023 direkt nach dem Rollen-Tor.
--    Bisher fiel NULL durch "v_session.student_id <> p_student_id".
-- 3. authoring_review_meta(): kein EXECUTE mehr ohne Anmeldung. anon hatte das Recht
--    nur ueber PUBLIC (ACL "=X/postgres"). Einziger Aufrufer ist listReviewMeta in
--    src/lib/supabase/taskAuthoring.ts aus der Item-Pflege (/admin/items, nur Admin).
--    authenticated behaelt das Recht; service_role bekommt es ausdruecklich, damit
--    nur anon etwas verliert.
--
-- Funktionen 1 und 2 aus Prod (pg_get_functiondef); Signatur, SECURITY DEFINER,
-- search_path und Grants unveraendert, create or replace behaelt die ACL.

create or replace function public.erklaer_status_setzen(p_objekt text, p_id uuid, p_status text, p_pruef_version bigint)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_kernidee public.erklaer_kernidee;
  v_schritt  public.erklaer_schritt;
  v_alt      text;
  v_fehlt    jsonb;
  v_version  bigint;
  v_admin    boolean := coalesce(public.get_my_role(), '') = 'admin' or public.ist_systemaufruf();
begin
  perform public.erklaer_darf_schreiben('erklaer_status_setzen');
  -- T2: NULL fiel bisher durch beide not in (offene-punkte-x0c, Weiteres 5) und erst an not null.
  if p_status is null or p_objekt is null
     or p_status not in ('entwurf', 'geprueft', 'freigegeben') or p_objekt not in ('kernidee', 'schritt') then
    raise exception 'erklaer_status_setzen: ungueltiger Status oder Objekt' using errcode = '22023';
  end if;

  if p_objekt = 'schritt' then
    -- Sperrreihenfolge: erst die Kernidee, dann der Schritt.
    select * into v_kernidee from public.erklaer_kernidee
     where id = (select s.kernidee_id from public.erklaer_schritt s where s.id = p_id) for update;
    select * into v_schritt from public.erklaer_schritt where id = p_id for update;
    if v_schritt.id is null then
      raise exception 'erklaer_status_setzen: Schritt nicht gefunden' using errcode = 'P0002';
    end if;
    v_alt := v_schritt.status;
  else
    select * into v_kernidee from public.erklaer_kernidee where id = p_id for update;
    if v_kernidee.id is null then
      raise exception 'erklaer_status_setzen: Kernidee nicht gefunden' using errcode = 'P0002';
    end if;
    v_alt := v_kernidee.status;
  end if;

  if v_kernidee.pruef_version is distinct from p_pruef_version then
    perform public.pruef_fehler('veraltet', 'erklaer_status_setzen: inzwischen geaendert, neu laden');
  end if;
  -- Freigeben und eine Freigabe zuruecknehmen: nur Admin (L6, Entscheidung 18).
  if (p_status = 'freigegeben' or (v_alt = 'freigegeben' and p_status <> 'freigegeben')) and not v_admin then
    raise exception 'erklaer_status_setzen: freigeben nur Admin' using errcode = '42501';
  end if;
  if p_status = 'freigegeben' then
    if v_alt <> 'geprueft' then
      perform public.pruef_fehler('erst_pruefen', 'erklaer_status_setzen: erst pruefen, dann freigeben');
    end if;
    if p_objekt = 'schritt'
       and cardinality(v_schritt.formeln) <> public.erklaer_formel_anzahl(v_schritt.inhalt) then
      perform public.pruef_fehler('formeln_fehlen', 'erklaer_status_setzen: Formeln noch nicht als SVG erzeugt');
    end if;
    if p_objekt = 'kernidee' then
      -- Anders als erklaer_freigeben hebt dieser Weg keine Schritte mit an: gepruefte Schritte muessen
      -- vorher einzeln freigegeben sein, sonst stuende eine freigegebene Kernidee ohne Inhalt da.
      v_fehlt := public.erklaer_freigabe_fehlt(p_id)
        || coalesce((select jsonb_agg(jsonb_build_object('was', 'schritt_nicht_freigegeben',
                                                         'variante', s.variante, 'art', s.art)
                                      order by s.variante, s.art)
                       from public.erklaer_schritt s where s.kernidee_id = p_id and s.status = 'geprueft'), '[]');
      if jsonb_array_length(v_fehlt) > 0 then
        raise exception 'erklaer_status_setzen: Freigabe unvollstaendig: %', v_fehlt::text
          using errcode = 'ED422', hint = 'freigabe_unvollstaendig', detail = v_fehlt::text;
      end if;
    end if;
  end if;

  if p_objekt = 'schritt' then
    update public.erklaer_schritt set status = p_status, geaendert_am = now() where id = p_id;
  else
    update public.erklaer_kernidee set status = p_status where id = p_id;
  end if;
  v_version := public.erklaer_version_hoch(v_kernidee.id);
  if v_alt is distinct from p_status then
    perform public.erklaer_protokollieren(v_kernidee.id, 'status', jsonb_build_array(
      public.erklaer_aenderung(p_objekt, v_schritt.variante, v_schritt.art, 'status', to_jsonb(v_alt), to_jsonb(p_status))));
  end if;
  return v_version;
end;
$function$;

create or replace function public.lsa_uebernahme(p_session_id uuid, p_student_id uuid, p_jetzt timestamp with time zone DEFAULT now())
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
  if coalesce(public.get_my_role(), '') not in ('coach','admin') then
    raise exception 'lsa_uebernahme: nur Coach/Admin' using errcode = '42501';
  end if;
  -- T2: ohne Schueler lief NULL am Vergleich unten vorbei (offene-punkte-x0c, Weiteres 5).
  if p_student_id is null then
    raise exception 'lsa_uebernahme: Schueler fehlt' using errcode = '22023';
  end if;

  select * into v_session from lsa_sessions where id = p_session_id;
  if not found then
    raise exception 'lsa_uebernahme: Session nicht gefunden' using errcode = 'P0002';
  end if;
  -- X0: ein Testlauf geht nie in den Lernpfad.
  if v_session.testlauf then
    raise exception 'lsa_uebernahme: Testlauf wird nicht uebernommen' using errcode = '22023';
  end if;
  -- X0 (Entscheidung 26): Coach nur fuer Kinder mit aktiver Akte.
  if coalesce(public.get_my_role(), '') = 'coach' and not public.akte_aktiv(v_session.student_id) then
    raise exception 'lsa_uebernahme: keine aktive Akte' using errcode = '42501';
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

revoke execute on function public.authoring_review_meta() from public, anon;
grant execute on function public.authoring_review_meta() to authenticated, service_role;
