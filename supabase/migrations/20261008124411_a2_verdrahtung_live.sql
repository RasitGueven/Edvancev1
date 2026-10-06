-- A2.4 Verdrahtung Live-Sicht und Abschluss (Entscheidung A2 N; offene-punkte-r1 13, 15, 16).
--
-- Grundlage: Definitionen in Prod (pg_get_functiondef 06.10., identisch mit der R1-Migration).
--   session_kind_live     fuellt mastery_kandidat (A1, signalisierte und faellige Kandidaten) und
--                         erklaersequenz (E1, Stand aus erklaer_fortschritt); neu: schritt (der
--                         letzte Schritt der Engine mit Grund).
--   coach_raum_live       mastery_bestaetigt zaehlt "gemeistert" aus lernpfad_protokoll dieser Session.
--   session_abschliessen  Testlauf: keine Notizen und Flags in die Akte (Entscheidung 27);
--                         zusammenfassung.mastery_entscheidungen aus lernpfad_protokoll.
--   session_flags_offen   ohne Testlaeufe.

create or replace function public.session_kind_live(p_session_id uuid, p_student_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'student_id', ss.student_id,
    'name', public.session_kind_name(ss.student_id),
    'klasse', s.class_level,
    'anwesenheit', ss.attendance,
    'tablet_nr', st.tablet_nr,
    'tablet_seit', st.zugewiesen_am,
    'phase', public.session_phase(p_session_id, ss.student_id),
    'stimmung', c.stimmung,
    'klassenarbeit_datum', c.klassenarbeit_datum,
    'thema_antwort', c.thema_antwort,
    'thema_stichwort', c.thema_stichwort,
    'schulthema_key', public.session_schulthema(ss.student_id),
    'fall_vorschlag', c.fall_vorschlag,
    'fall_coach', c.fall_coach,
    'fall', coalesce(c.fall_coach, c.fall_vorschlag),
    'ziel_thema_key', c.ziel_thema_key,
    'ziel_thema_label', (select th.label from public.themen th where th.thema_key = c.ziel_thema_key),
    'checkin_fertig', c.kind_am is not null,
    'aufgabe', case when a.id is null then null else jsonb_build_object(
        'task_id', a.task_id, 'seit', a.zeit, 'eingemischt', a.eingemischt, 'phase', a.phase,
        'nr_in_phase', (select count(*) from public.session_ausgegeben x where x.session_id = p_session_id
                         and x.student_id = ss.student_id and x.phase is not distinct from a.phase),
        'skill_key', (select t.skill_key from public.tasks t where t.id = a.task_id),
        'payload', public.lsa_question_payload(a.task_id)) end,
    'ergebnisfolge', coalesce((select jsonb_agg(jsonb_build_object('task_id', r.task_id, 'teil', r.teil,
         'versuch_nr', r.versuch_nr, 'ergebnis', r.ergebnis, 'hinweisstufe_max', r.hinweisstufe_max,
         'phase', r.phase, 'eingemischt', r.eingemischt, 'zeit', r.zeit) order by r.zeit)
       from public.session_antworten r where r.session_id = p_session_id and r.student_id = ss.student_id), '[]'),
    'hinweise_genutzt', (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
       and e.student_id = ss.student_id and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean),
    'letzte_eingabe_am', (select max(r.zeit) from public.session_antworten r
       where r.session_id = p_session_id and r.student_id = ss.student_id),
    'mastery_kandidat', (
       select jsonb_build_object('skill_key', e.payload ->> 'skill_key',
                'label', public.session_label(e.payload ->> 'skill_key'), 'seit', e.zeit,
                'stand_coach', l.stand_coach,
                'pruefung_vorhanden', exists (select 1 from public.skill_pruefung p
                                               where p.skill_key = e.payload ->> 'skill_key' and p.status = 'freigegeben'))
         from public.session_ereignisse e
         left join public.lernpfad l on l.student_id = ss.student_id and l.skill_key = e.payload ->> 'skill_key'
        where e.session_id = p_session_id and e.student_id = ss.student_id and e.typ = 'signal'
          and e.payload ->> 'art' = 'kandidat'
          and public.lernpfad_pruefung_faellig(ss.student_id, e.payload ->> 'skill_key')
        order by e.zeit limit 1),
    'erklaersequenz', (
       select jsonb_build_object('skill_key', ek.skill_key, 'label', public.session_label(ek.skill_key),
                'kernidee_nr', ek.nr, 'kernidee_titel', ek.titel,
                'kernideen', (select count(*) from public.erklaer_kernidee k2
                               where k2.skill_key = ek.skill_key and k2.status = 'freigegeben'),
                'kernideen_fertig', (select count(distinct f2.kernidee_id) from public.erklaer_fortschritt f2
                                      join public.erklaer_kernidee k3 on k3.id = f2.kernidee_id
                                     where f2.session_id = p_session_id and f2.student_id = ss.student_id
                                       and k3.skill_key = ek.skill_key and f2.ergebnis = 'richtig'),
                'runde', ef.runde, 'variante', ef.variante, 'stand', ef.ergebnis, 'zeit', ef.zeit,
                'fehlbild_slug', (select f4.fehlbild_slug from public.erklaer_fortschritt f4
                                   where f4.session_id = p_session_id and f4.student_id = ss.student_id
                                     and f4.kernidee_id = ef.kernidee_id and f4.ergebnis = 'falsch'
                                   order by f4.id desc limit 1))
         from public.erklaer_fortschritt ef
         join public.erklaer_kernidee ek on ek.id = ef.kernidee_id
        where ef.session_id = p_session_id and ef.student_id = ss.student_id
        order by ef.id desc limit 1),
    'schritt', (
       select jsonb_build_object('art', x.art, 'phase', x.phase, 'skill_key', x.skill_key,
                'skill_label', case when x.skill_key is not null then public.session_label(x.skill_key) end,
                'task_id', x.task_id, 'modus', x.modus, 'eingemischt', x.eingemischt,
                'schwierigkeit', x.schwierigkeit, 'grund', x.grund, 'grund_code', x.grund_code, 'zeit', x.zeit)
         from public.session_schritte x
        where x.session_id = p_session_id and x.student_id = ss.student_id
        order by x.id desc limit 1))
  from public.session_students ss
  join public.students s on s.id = ss.student_id
  left join public.session_tablets st on st.session_id = ss.session_id and st.student_id = ss.student_id
                                     and st.geloest_am is null
  left join public.session_checkin c on c.session_id = ss.session_id and c.student_id = ss.student_id
  left join lateral public.session_aktuelle_ausgabe(p_session_id, ss.student_id) a on true
  where ss.session_id = p_session_id and ss.student_id = p_student_id
$$;

create or replace function public.coach_raum_live(p_session_id uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  s        public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'coach_raum_live');
  v_sig    jsonb;
  v_kinder jsonb;
begin
  select coalesce(jsonb_agg(to_jsonb(x) order by x.rang, x.seit), '[]') into v_sig
    from public.session_signale_intern(p_session_id) x;

  select coalesce(jsonb_agg(k.j || jsonb_build_object(
           'status', coalesce((select case x.art when 'kandidat' then 'kandidat' when 'entscheidung' then 'entscheidung'
                                 when 'haengt' then 'haengt' else 'hinweis' end
                                 from jsonb_to_recordset(v_sig) as x(student_id uuid, art text, rang int, seit timestamptz)
                                where x.student_id = k.student_id order by x.rang, x.seit limit 1), 'laeuft'),
           'signale', coalesce((select jsonb_agg(z) from jsonb_array_elements(v_sig) z
                                 where (z ->> 'student_id')::uuid = k.student_id), '[]'))
           order by (k.j ->> 'tablet_nr')::int nulls last, k.j ->> 'name'), '[]')
    into v_kinder
    from (select ss.student_id, public.session_kind_live(p_session_id, ss.student_id) as j
            from public.session_students ss where ss.session_id = p_session_id) k;

  return jsonb_build_object(
    'session', jsonb_build_object(
      'id', s.id, 'status', s.status, 'scheduled_at', s.scheduled_at, 'gestartet_am', s.gestartet_am,
      'beendet_am', s.beendet_am, 'room', s.room,
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
$$;

create or replace function public.session_abschliessen(p_session_id uuid)
returns jsonb
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
  s       public.coaching_sessions := public.session_coach_pruefen(p_session_id, 'session_abschliessen');
  k       record;
  v_datum text;
  v_nid   uuid;
  v_n     int := 0;
  v_ohne  jsonb := '[]'::jsonb;
  v_text  text;
begin
  select * into s from public.coaching_sessions where id = p_session_id for update;
  if s.status <> 'active' then
    raise exception 'session_abschliessen: Session laeuft nicht (Status %)', s.status using errcode = 'P0001';
  end if;
  v_datum := to_char(s.scheduled_at at time zone 'Europe/Berlin', 'DD.MM.YYYY');

  -- Anwesenheit final: wer nie ein Tablet bekam und noch geplant ist, war nicht da.
  update public.session_students set attendance = 'unexcused'
   where session_id = p_session_id and attendance = 'planned';
  update public.session_tablets set geloest_am = clock_timestamp(), geloest_von = auth.uid()
   where session_id = p_session_id and geloest_am is null;

  for k in
    select ss.student_id, ss.attendance from public.session_students ss where ss.session_id = p_session_id
  loop
    insert into public.session_kind_abschluss (session_id, student_id, aktualisiert_von)
    values (p_session_id, k.student_id, auth.uid())
    on conflict (session_id, student_id) do nothing;

    -- Consensus-Check Befund 2: Notiz und Flags je Kind in eigenem Block. Hat ein
    -- Kind keine (aktive) Akte mehr, scheitert nicht der ganze Abschluss; das Kind
    -- steht dann in 'nicht_in_akte' und die Werte bleiben in session_kind_abschluss.
    v_nid := null;
    begin
      v_text := (select notiz from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id);
      -- A2: Testlaeufe schreiben nichts in die Akte (Entscheidung 27).
      if v_text is not null and not s.testlauf then
        v_nid := public.notiz_anlegen(k.student_id, 'lernen', v_text);
      end if;
      if not s.testlauf and (select flag_eltern from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id) then
        perform public.notiz_anlegen(k.student_id, 'organisatorisch', 'Session ' || v_datum || ': Elternkontakt nötig');
      end if;
      if not s.testlauf and (select flag_pfad from public.session_kind_abschluss where session_id = p_session_id and student_id = k.student_id) then
        perform public.notiz_anlegen(k.student_id, 'lernen', 'Session ' || v_datum || ': Pfad passt nicht');
      end if;
    exception when insufficient_privilege or no_data_found then
      v_nid := null;
      v_ohne := v_ohne || to_jsonb(k.student_id);
    end;

    update public.session_kind_abschluss a
       set notiz_id = v_nid,
           in_akte_am = case when s.testlauf or v_ohne @> to_jsonb(k.student_id) then null else clock_timestamp() end,
           exit_ergebnis = coalesce(a.exit_ergebnis, (
             select jsonb_build_object('richtig', count(distinct r.task_id) filter (where r.ergebnis = 'richtig'),
                                       'gesamt', count(distinct r.task_id))
               from public.session_antworten r where r.session_id = p_session_id and r.student_id = k.student_id
                and r.phase = 'checkout' having count(*) > 0)),
           zusammenfassung = jsonb_build_object(
             'anwesenheit', (select attendance from public.session_students
                              where session_id = p_session_id and student_id = k.student_id),
             'aufgaben', (select count(distinct r.task_id) from public.session_antworten r
                           where r.session_id = p_session_id and r.student_id = k.student_id),
             'antworten', (select count(*) from public.session_antworten r
                            where r.session_id = p_session_id and r.student_id = k.student_id),
             'richtig', (select count(*) from public.session_antworten r where r.session_id = p_session_id
                          and r.student_id = k.student_id and r.ergebnis = 'richtig'),
             'hinweise', (select count(*) from public.session_ereignisse e where e.session_id = p_session_id
                           and e.student_id = k.student_id and e.typ = 'hinweis' and (e.payload ->> 'geliefert')::boolean),
             'eingriffe_ab_3', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit) order by e.zeit)
                from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = k.student_id
                 and e.typ = 'eingriff' and (e.payload ->> 'stufe')::int >= 3), '[]'),
             'entscheidungen_pfad', coalesce((select jsonb_agg(e.payload || jsonb_build_object('zeit', e.zeit) order by e.zeit)
                from public.session_ereignisse e where e.session_id = p_session_id and e.student_id = k.student_id
                 and e.typ = 'entscheidung_pfad'), '[]'),
             'mastery_entscheidungen', coalesce((select jsonb_agg(jsonb_build_object('skill_key', p.skill_key,
                  'entscheidung', p.neu ->> 'stand_coach', 'grund', p.grund, 'am', p.am) order by p.am)
                from public.lernpfad_protokoll p where p.session_id = p_session_id
                 and p.student_id = k.student_id and p.aktion = 'mastery'), '[]'::jsonb),
             'testlauf', s.testlauf),
           aktualisiert_am = clock_timestamp(), aktualisiert_von = auth.uid()
     where a.session_id = p_session_id and a.student_id = k.student_id;
    v_n := v_n + 1;
  end loop;

  perform public.session_rpc_markieren();
  update public.coaching_sessions set status = 'done', beendet_am = now() where id = p_session_id;
  perform set_config('edvance.session_rpc', '', true);

  return jsonb_build_object(
    'kinder', v_n,
    'nicht_in_akte', v_ohne,
    'anwesend', (select count(*) from public.session_students where session_id = p_session_id and attendance = 'present'),
    'einheit_verbraucht', (select count(*) from public.session_students where session_id = p_session_id
                            and public.einheit_verbraucht(attendance)));
end;
$$;

create or replace function public.session_flags_offen()
returns table (session_id uuid, student_id uuid, name text, flag text, scheduled_at timestamptz, notiz text)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if coalesce(public.get_my_role(), '') <> 'admin' then
    raise exception 'session_flags_offen: nur Admin' using errcode = '42501';
  end if;
  return query
    select a.session_id, a.student_id, public.session_kind_name(a.student_id), f.flag, cs.scheduled_at, a.notiz
      from public.session_kind_abschluss a
      join public.coaching_sessions cs on cs.id = a.session_id
      cross join lateral (values ('eltern', a.flag_eltern and a.flag_eltern_erledigt_am is null),
                                 ('pfad', a.flag_pfad and a.flag_pfad_erledigt_am is null)) as f(flag, offen)
     where a.in_akte_am is not null and f.offen and not cs.testlauf
     order by cs.scheduled_at, a.student_id, f.flag;
end;
$$;
