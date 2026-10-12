-- Slots SL1, Teil 6c: die vier SQL-Stellen suchen den nächsten Termin über naechster_termin.
--
-- Bauauftrag Slots (Fassung 1), Entscheidung 14. In quest_erzeugen, session_kind_kontext, coach_raum_live
-- und session_abschluss_kind ändert sich nur die Suche nach dem nächsten Termin; alles andere bleibt.
-- Ausgangspunkt ist der Stand in Produktion (pg_get_functiondef, 10.10.2026); coach_raum_live trägt dort
-- schon die F1-Erweiterung (20261011140000, PR #234). Signatur, SECURITY, search_path und Rechte bleiben
-- (create or replace mit gleicher Signatur). Der Diff je Funktion steht im PR.

begin;

CREATE OR REPLACE FUNCTION public.quest_erzeugen(p_session_id uuid, p_student_id uuid, p_skill_keys text[], p_ka_thema_key text DEFAULT NULL::text, p_ka_datum date DEFAULT NULL::date)
 RETURNS TABLE(quest_id uuid, art text, faellig_ab date, aufgaben integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_session   public.coaching_sessions%rowtype;
  v_tag       date;
  v_naechste  date;
  v_anzahl    integer := public.quest_einstellung_zahl('quests_pro_woche', 2, p_session_id)::integer;
  v_abstand   integer := public.quest_einstellung_zahl('quest_a_abstand_tage', 2, p_session_id)::integer;
  v_a_tag     date;
  v_b_tag     date;
  v_ka        boolean;
  v_ka_skills text[];
  v_plan      record;
  v_id        uuid;
  v_n         integer;
begin
  select * into v_session from public.coaching_sessions where id = p_session_id;
  if not found then
    -- Nur Admin und System erfahren, dass es die Session nicht gibt (kein Existenz-Orakel).
    if coalesce(public.ist_systemaufruf() or coalesce(public.get_my_role(), '') = 'admin', false) then
      raise exception 'quest_erzeugen: Session unbekannt' using errcode = '22023';
    end if;
    raise exception 'quest_erzeugen: kein Zugriff' using errcode = '42501';
  end if;

  -- coalesce: ohne Profil liefert get_my_role() null, und "not null" liesse durch.
  if not coalesce(public.ist_systemaufruf()
                  or coalesce(public.get_my_role(), '') = 'admin'
                  or (coalesce(public.get_my_role(), '') = 'coach' and v_session.coach_id = auth.uid()
                      and public.hat_zugang(p_student_id)), false) then
    raise exception 'quest_erzeugen: nur Coach der Session (bei laufendem Vertrag), Admin oder Systemaufruf' using errcode = '42501';
  end if;

  -- FernUSG: solange die Clinic prueft, bleibt home_quests_aktiv aus. Dann legt nur ein
  -- Systemaufruf (Test, Durchlauf) Quests an, nie ein Coach aus dem Check-out.
  if not public.home_quests_aktiv(p_session_id) and not public.ist_systemaufruf() then
    raise exception 'quest_erzeugen: Home Quests sind ausgeschaltet (home_quests_aktiv)' using errcode = '55000';
  end if;

  if not exists (select 1 from public.session_students ss
                  where ss.session_id = p_session_id and ss.student_id = p_student_id
                    and ss.attendance not in ('cancelled', 'cancelled_by_us', 'unexcused')) then
    raise exception 'quest_erzeugen: Kind ist in dieser Session nicht gebucht' using errcode = '22023';
  end if;

  if coalesce(cardinality(p_skill_keys), 0) = 0 and p_ka_thema_key is null then
    raise exception 'quest_erzeugen: skill_keys oder ka_thema_key ist Pflicht' using errcode = '22023';
  end if;

  -- Parallele Aufrufe fuer dasselbe Kind und dieselbe Session nacheinander.
  perform pg_advisory_xact_lock(hashtextextended(p_session_id::text || p_student_id::text, 0));

  -- Schon erzeugt: bestehende Quests unveraendert zurueckgeben (wiederholbar).
  if exists (select 1 from public.quests q where q.session_id = p_session_id and q.student_id = p_student_id) then
    return query
      select q.id, q.art, q.faellig_ab, (select count(*)::integer from public.quest_aufgaben qa where qa.quest_id = q.id)
        from public.quests q
       where q.session_id = p_session_id and q.student_id = p_student_id
       order by q.faellig_ab, q.art;
    return;
  end if;

  v_tag := (v_session.scheduled_at at time zone 'Europe/Berlin')::date;

  -- SL1 (Entscheidung 14): naechster Termin auch vor dem Festschreiben (Slot-Termin ohne Session).
  v_naechste := public.slots_berlin_tag(public.naechster_termin(p_student_id, v_session.scheduled_at));

  -- Ohne naechste Buchung gilt der Wochenrhythmus (offener Punkt).
  v_b_tag := coalesce(v_naechste, v_tag + 7) - 1;
  v_a_tag := greatest(v_tag + 1, least(v_tag + v_abstand, v_b_tag));

  v_ka := p_ka_thema_key is not null
          and (p_ka_datum is null or (p_ka_datum > v_tag and (v_naechste is null or p_ka_datum <= v_naechste)));
  if v_ka then
    select coalesce(array_agg(distinct k), '{}') into v_ka_skills
      from (select st.skill_key as k from public.skill_thema st where st.thema_key = p_ka_thema_key
            union
            select te.skill_key from public.thema_einstieg te where te.thema_key = p_ka_thema_key) s;
    v_b_tag := greatest(v_tag + 1, least(coalesce(p_ka_datum - 1, v_b_tag), v_b_tag));
  end if;

  -- Neue Quests loesen die offenen aus frueheren Sessions ab.
  update public.quests q
     set status = 'verfallen'
   where q.student_id = p_student_id and q.status = 'offen' and q.session_id <> p_session_id;

  for v_plan in
    select x.art, x.tag, x.skills, x.mischen
      from (values
              (1, 'A',  v_a_tag, p_skill_keys, true),
              (2, case when v_ka then 'KA' else 'B' end, v_b_tag,
                  case when v_ka then v_ka_skills else p_skill_keys end, not v_ka)
           ) as x(nr, art, tag, skills, mischen)
     where x.nr <= v_anzahl
       and coalesce(cardinality(x.skills), 0) > 0
       -- B nur, wenn sie nach A liegt; das KA-Paket immer.
       and (x.nr = 1 or x.art = 'KA' or x.tag > v_a_tag)
     order by x.nr
  loop
    insert into public.quests (student_id, session_id, art, ka_thema_key, faellig_ab)
    values (p_student_id, p_session_id, v_plan.art,
            case when v_plan.art = 'KA' then p_ka_thema_key end, v_plan.tag)
    returning id into v_id;

    v_n := public.quest_aufgaben_waehlen(v_id, p_student_id, v_plan.skills, v_plan.mischen);
    if v_n = 0 then
      -- Ohne passende Aufgabe keine leere Quest.
      delete from public.quests where id = v_id;
      raise notice 'quest_erzeugen: keine freigegebene Aufgabe fuer Quest %', v_plan.art;
      continue;
    end if;

    quest_id := v_id; art := v_plan.art; faellig_ab := v_plan.tag; aufgaben := v_n;
    return next;
  end loop;
end;
$function$;

CREATE OR REPLACE FUNCTION public.session_kind_kontext(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t      public.session_tablets := public.session_tablet_platz(p_session_id, 'session_kind_kontext');
  s      public.coaching_sessions;
  v_tag  date;
  v_ab   int;
  v_th   text := public.session_schulthema(t.student_id);
begin
  select * into s from public.coaching_sessions where id = p_session_id;
  v_tag := (s.scheduled_at at time zone 'Europe/Berlin')::date;
  v_ab := public.quest_einstellung_zahl('quest_a_abstand_tage', 2, p_session_id)::int;
  return jsonb_build_object(
    'vorname', (select coalesce(l.first_name, split_part(l.full_name, ' ', 1)) from public.leads l
                 where l.id = public.session_lead_von_kind(t.student_id)),
    'coach_vorname', (select split_part(p.full_name, ' ', 1) from public.profiles p where p.id = s.coach_id),
    'schulthema', case when v_th is null then null else jsonb_build_object(
        'thema_key', v_th, 'label', (select th.label from public.themen th where th.thema_key = v_th)) end,
    -- Entscheidung 21: Quest A zwei bis drei Tage nach der Session, Quest B am Tag vor der naechsten.
    'quest_termine', case when not coalesce(public.home_quests_aktiv(p_session_id), false) then null
      else jsonb_build_object(
        'quest_a', jsonb_build_array(v_tag + v_ab, v_tag + v_ab + 1),
        -- SL1 (Entscheidung 14): naechster Termin auch vor dem Festschreiben.
        'quest_b', public.slots_berlin_tag(public.naechster_termin(t.student_id, s.scheduled_at)) - 1) end);
end;
$function$;

CREATE OR REPLACE FUNCTION public.coach_raum_live(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  s        public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'coach_raum_live');
  v_sig    jsonb;
  v_kinder jsonb;
  v_quests boolean := coalesce(public.home_quests_aktiv(p_session_id), false);
begin
  select coalesce(jsonb_agg(to_jsonb(x) order by x.rang, x.seit), '[]') into v_sig
    from public.session_signale_intern(p_session_id) x;

  select coalesce(jsonb_agg(k.j || jsonb_build_object(
           'status', coalesce((select case x.art when 'kandidat' then 'kandidat' when 'entscheidung' then 'entscheidung'
                                 when 'haengt' then 'haengt' else 'hinweis' end
                                 from jsonb_to_recordset(v_sig) as x(student_id uuid, art text, rang int, seit timestamptz)
                                where x.student_id = k.student_id order by x.rang, x.seit limit 1), 'laeuft'),
           'signale', coalesce((select jsonb_agg(z) from jsonb_array_elements(v_sig) z
                                 where (z ->> 'student_id')::uuid = k.student_id), '[]'),
           -- C2: Check-out je Kind. quest_von: 'kind' (Tablet) oder 'coach' (Coach oder Admin hat nachgetragen).
           'abschluss', (select jsonb_build_object(
                'satz_text', a.satz_text, 'satz_gesagt', a.satz_gesagt, 'notiz', a.notiz,
                'flag_eltern', a.flag_eltern, 'flag_pfad', a.flag_pfad, 'exit_ergebnis', a.exit_ergebnis,
                'quest_termin', a.quest_termin,
                'quest_von', case when a.quest_termin is null then null
                                  when exists (select 1 from public.profiles p where p.id = a.quest_termin_von
                                                and p.role in ('coach', 'admin')) then 'coach'
                                  else 'kind' end)
              from public.session_kind_abschluss a
             where a.session_id = p_session_id and a.student_id = k.student_id),
           -- C2: Quest B wie session_kind_kontext (Tag vor der naechsten gebuchten Session), nur mit Home Quests.
           'quest_b', case when v_quests then (
                -- SL1 (Entscheidung 14): naechster Termin auch vor dem Festschreiben.
                select public.slots_berlin_tag(public.naechster_termin(k.student_id, s.scheduled_at)) - 1) end,
           'eingriffe', coalesce((select jsonb_agg(jsonb_build_object('stufe', (e.payload ->> 'stufe')::int, 'zeit', e.zeit)
                                          order by e.zeit)
                                    from public.session_ereignisse e
                                   where e.session_id = p_session_id and e.student_id = k.student_id
                                     and e.typ = 'eingriff'), '[]'),
           'pfad_entscheidung', (select jsonb_build_object('entscheidung', e.payload ->> 'entscheidung', 'zeit', e.zeit)
                                   from public.session_ereignisse e
                                  where e.session_id = p_session_id and e.student_id = k.student_id
                                    and e.typ = 'entscheidung_pfad'
                                  order by e.zeit desc limit 1),
           'mastery_heute', coalesce((select jsonb_agg(jsonb_build_object(
                                'skill_key', p.skill_key, 'label', public.session_label(p.skill_key),
                                'stand_coach', p.neu ->> 'stand_coach', 'grund', p.grund, 'am', p.am,
                                'von', (select pr.full_name from public.profiles pr where pr.id = p.von)) order by p.am)
                                       from public.lernpfad_protokoll p
                                      where p.session_id = p_session_id and p.student_id = k.student_id
                                        and p.aktion = 'mastery'), '[]'),
           -- F1 (A4): seit wann das Kind in seiner Phase ist (juengster Phasenwechsel) und ob das Warm-up
           -- entfallen ist: kein Warm-up-Schritt, aber schon Kernarbeit/Check-out. kein_stoff = Kernarbeit begann,
           -- solange die Uhr noch Check-in oder Warm-up zeigte (session_plan_warmup fand keinen Skill mit
           -- Aufgabe); zeit = Kernarbeit erst nach dem Warm-up laut Uhr (spaet angekommen). Fehlt ein Zeitpunkt: null.
           -- Ein Phasenwechsel durch den Coach (phase_setzen) zaehlt wie einer vom Tablet (offene-punkte-f1).
           'phase_seit', (select max(e.zeit) from public.session_ereignisse e
                           where e.session_id = p_session_id and e.student_id = k.student_id
                             and e.typ = 'phase_wechsel'),
           'warmup_entfallen', case
              when k.j ->> 'phase' in ('kern', 'checkout')
               and not exists (select 1 from public.session_schritte x
                                where x.session_id = p_session_id and x.student_id = k.student_id
                                  and x.phase = 'warmup')
              then (select case when x.kern_ab < x.warmup_ende then 'kein_stoff'
                                when x.kern_ab >= x.warmup_ende then 'zeit' end
                      from (select (select min(e.zeit) from public.session_ereignisse e
                                     where e.session_id = p_session_id and e.student_id = k.student_id
                                       and e.typ = 'phase_wechsel' and e.payload ->> 'phase' = 'kern') as kern_ab,
                                   s.gestartet_am + (public.session_wert_zahl(p_session_id, 'phase_checkin_min')
                                                     + public.session_wert_zahl(p_session_id, 'phase_warmup_min'))
                                                    * interval '1 minute' as warmup_ende) x) end)
           order by (k.j ->> 'tablet_nr')::int nulls last, k.j ->> 'name'), '[]')
    into v_kinder
    from (select ss.student_id, public.session_kind_live(p_session_id, ss.student_id) as j
            from public.session_students ss where ss.session_id = p_session_id) k;

  return jsonb_build_object(
    'session', jsonb_build_object(
      'id', s.id, 'status', s.status, 'scheduled_at', s.scheduled_at, 'gestartet_am', s.gestartet_am,
      'beendet_am', s.beendet_am, 'room', s.room, 'testlauf', s.testlauf,
      'coach_name', (select p.full_name from public.profiles p where p.id = s.coach_id),
      'einstellungen', coalesce(s.einstellungen,
                        (select jsonb_object_agg(e.schluessel, e.wert) from public.session_einstellungen e)),
      'mastery_bestaetigt', (select count(*) from public.lernpfad_protokoll p
                              where p.session_id = s.id and p.aktion = 'mastery'
                                and p.neu ->> 'stand_coach' = 'gemeistert')),
    'stand', clock_timestamp(),
    'kinder', v_kinder,
    'signale', v_sig);
end;
$function$;

CREATE OR REPLACE FUNCTION public.session_abschluss_kind(p_session_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  t public.session_tablets := public.session_tablet_platz(p_session_id, 'session_abschluss_kind');
begin
  return jsonb_build_object(
    'geuebt', coalesce((select jsonb_agg(public.session_label(g.skill_key) order by g.erst)
                          from (select x.skill_key, min(x.id) as erst from public.session_schritte x
                                 where x.session_id = p_session_id and x.student_id = t.student_id and x.phase = 'kern'
                                   and x.art = 'aufgabe' and not x.eingemischt and x.skill_key is not null
                                 group by x.skill_key order by min(x.id) limit 3) g), '[]'::jsonb),
    'xp', coalesce((select sum(e.xp) from public.xp_events e
                     where e.student_id = t.student_id and e.buchungs_schluessel = 'session:' || p_session_id), 0),
    -- SL1 (Entscheidung 14): naechster Termin auch vor dem Festschreiben.
    'naechste_session', public.naechster_termin(
                          t.student_id, (select scheduled_at from public.coaching_sessions where id = p_session_id)));
end;
$function$;

commit;
