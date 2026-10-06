-- R1-Durchlauf: eine Session von session_starten bis session_abschliessen.
--
-- Nur fuer eine Wegwerf-DB (alle Migrationen + supabase/seed.sql), nie gegen
-- Produktion. Laeuft in begin … rollback und legt alle Daten selbst an (ZZ_).
--
--   psql -X -v ON_ERROR_STOP=1 -f docs/session/r1-durchlauf.sql
--
-- Ablauf wie im Coach-Live-Dummy: Vorher → Check-in → Warm-up → Kernarbeit →
-- Check-out → Danach. Drei Kinder, Coach Sara, Tablets 1 bis 3.
\pset footer off
begin;

\set admin  'ffffffff-0001-4000-8000-000000000001'
\set sara   'ffffffff-0001-4000-8000-000000000002'
insert into auth.users (id, email) values (:'admin', 'zz-dl-admin@test.local'), (:'sara', 'zz-dl-sara@test.local');
insert into auth.users (id, email)
select ('ffffffff-0002-4000-8000-00000000000' || i)::uuid, 'zz-dl-tablet' || i || '@test.local' from generate_series(1, 3) i;
insert into profiles (id, email, role, full_name) values
  (:'admin', 'zz-dl-admin@test.local', 'admin', 'ZZ Admin'), (:'sara', 'zz-dl-sara@test.local', 'coach', 'ZZ Sara');
insert into profiles (id, email, role, full_name)
select ('ffffffff-0002-4000-8000-00000000000' || i)::uuid, 'zz-dl-tablet' || i || '@test.local', 'student', 'ZZ Tablet ' || i
  from generate_series(1, 3) i;
insert into platz_devices (profile_id, label, tablet_nr)
select ('ffffffff-0002-4000-8000-00000000000' || i)::uuid, 'ZZ Tablet ' || i, i from generate_series(1, 3) i;

create function pg_temp.als(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.tablet(i int) returns uuid language sql as $$ select ('ffffffff-0002-4000-8000-00000000000' || i)::uuid $$;
create function pg_temp.kind(p_name text) returns uuid language plpgsql as $$
declare v_lead uuid; v_st uuid;
begin
  insert into leads (full_name, first_name, status, class_level) values (p_name, split_part(p_name, ' ', 1), 'vertrag', 8)
  returning id into v_lead;
  insert into students (class_level) values (8) returning id into v_st;
  update leads set converted_student_id = v_st where id = v_lead;
  insert into vertraege (lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg,
                         student_id, vertragsbeginn, vertrag_ende, widerruf_bis)
  values (v_lead, 'abgeschlossen', 'aktiv', now(), date_trunc('month', current_date)::date - 31, 'vor_ort', v_st,
          date_trunc('month', current_date - 31)::date,
          (date_trunc('month', current_date) + interval '7 month' - interval '1 day')::date, current_date - 16);
  return v_st;
end $$;

select pg_temp.kind('Mila ZZ') as mila, pg_temp.kind('Emir ZZ') as emir, pg_temp.kind('Lea ZZ') as lea \gset
insert into themen (thema_key, fach, klasse, stufe, label, sort) values
  ('zz_dl_terme', 'mathematik', 8, 'erste', 'ZZ Terme', 9201), ('zz_dl_steigung', 'mathematik', 8, 'erste', 'ZZ Steigung', 9202);
insert into lead_themen (lead_id, fach, thema_key, status, quelle)
select id, 'mathematik', 'zz_dl_terme', 'aktuell', 'gespraech' from leads where converted_student_id = :'emir';
insert into fehlbild_labels (slug, klartext, freigegeben_am) values ('zz_dl_minus', 'Minus nur beim ersten Summanden', now());
insert into tasks (content_type, input_type, status, question, question_payload, afb, competency_content,
                   est_duration_sec, class_level, source, source_ref)
values ('exercise', 'SHORT_TEXT', 'ready', 'Löse die Klammer auf: −(3a − 2b)',
        '{"input_type":"SHORT_TEXT","kind":"short_input","prompt":"Löse die Klammer auf: −(3a − 2b)"}', 'I',
        'Terme und Gleichungen', 60, 8, 'test', 'zz-dl') returning id as aufgabe \gset
select set_config('edvance.hinweis_status', 'setzen', true);  -- gepruefter Hinweis (E1)
insert into task_solutions (task_id, correct_answers, solution, hints, acceptance)
values (:'aufgabe', '["-3a+2b"]', 'Minus vor der Klammer ändert jedes Vorzeichen: −3a + 2b',
        '[{"level":1,"text":"Womit multiplizierst du jeden Summanden?","status":"geprueft"}]',
        '{"canonical":"-3a+2b","known_errors":{"-3a-2b":"zz_dl_minus"}}');
select set_config('edvance.hinweis_status', '', true);
insert into coaching_sessions (coach_id, room, scheduled_at) values (:'sara', 'Raum 1', now()) returning id as s \gset
insert into session_students (session_id, student_id) select :'s', k from unnest(array[:'mila', :'emir', :'lea']::uuid[]) k;

\echo '== Vorher: Session starten (Snapshot der Stellschrauben)'
select from pg_temp.als(:'sara');
select (session_starten(:'s')) ->> 'signal_fehlversuche' as snapshot_signal_fehlversuche;
select status, gestartet_am is not null as gestartet from coaching_sessions where id = :'s';

\echo '== Check-in: Tablets zuweisen, Kinder fuellen aus, Coach entscheidet'
select tablet_zuweisen(:'s', :'mila', 1) is not null as mila_tablet_1,
       tablet_zuweisen(:'s', :'emir', 2) is not null as emir_tablet_2,
       tablet_zuweisen(:'s', :'lea', 3) is not null as lea_tablet_3;
select from pg_temp.als(pg_temp.tablet(1));
select tablet_stand() ->> 'vorname' as tablet1_vorname, tablet_stand() ->> 'phase' as phase;
select checkin_kind_speichern(:'s', 'gut', null, null, 'neu', 'Steigung');
select from pg_temp.als(pg_temp.tablet(2));
select checkin_kind_speichern(:'s', 'geht_so', current_date + 21, 'zz_dl_terme', 'noch_dran');
select from pg_temp.als(pg_temp.tablet(3));
select checkin_kind_speichern(:'s', 'angespannt', current_date + 2, 'zz_dl_terme', 'noch_dran');
select from pg_temp.als(:'sara');
select checkin_coach_setzen(:'s', :'mila', 'schulthema', 'zz_dl_steigung') as mila_neues_schulthema;
select public.session_kind_name(student_id) as kind, fall_vorschlag, fall_coach, ziel_thema_key, stimmung
  from session_checkin where session_id = :'s' order by 1;

\echo '== Warm-up/Kernarbeit: Aufgabe, Antworten, Hinweis, Signale'
select aufgabe_ausgeben(:'s', :'emir', :'aufgabe') is not null as emir_aufgabe;
select phase_setzen(:'s', :'emir', 'kern');
select from pg_temp.als(pg_temp.tablet(2));
select antwort_abgeben(:'s', :'aufgabe', null, '"-3a-2b"', 31000) as versuch_1;
select hinweis_abrufen(:'s', :'aufgabe', 1) as hinweis;
select antwort_abgeben(:'s', :'aufgabe', null, '"-3a-2b"', 25000) as versuch_2;
select from pg_temp.als(:'sara');
select public.session_kind_name(student_id) as kind, art, rang, grund from raum_signale(:'s');
select (coach_raum_live(:'s')) -> 'kinder' -> 1 ->> 'status' as emir_status_live;
select eingriff_notieren(:'s', :'emir', 3, 'zz_dl_minus');
select signal_erledigen(:'s', :'emir', 'haengt');
select signal_erledigen(:'s', :'lea', 'hinweis');
select from pg_temp.als(pg_temp.tablet(2));
select antwort_abgeben(:'s', :'aufgabe', null, '"-3a+2b"', 18000) as versuch_3;
select from pg_temp.als(:'sara');
select d -> 'aufgabe_detail' ->> 'musterloesung' as musterloesung_nur_coach,
       jsonb_array_length(d -> 'versuche') as versuche, jsonb_array_length(d -> 'eingriffe') as eingriffe
  from coach_kind_detail(:'s', :'emir') d;
select count(*) as offene_signale from raum_signale(:'s');

\echo '== Check-out: Satz, Notiz, Flags, Quest-Termin'
select abschluss_setzen(:'s', :'emir', 'Beim Minus vor der Klammer hast du heute den Dreh gefunden.', true,
                        'Vorzeichen sitzt nach Mikro-Erklärung.', false, true);
select abschluss_setzen(:'s', :'lea', 'Die Klammern sitzen.', true, 'Vor der Arbeit angespannt.', true, false);
select from pg_temp.als(pg_temp.tablet(2));
select quest_termin_setzen(:'s', null, now() + interval '1 day');

\echo '== Danach: Abschluss'
select from pg_temp.als(:'sara');
select session_abschliessen(:'s') as abschluss;
select public.session_kind_name(ss.student_id) as kind, ss.attendance, a.exit_ergebnis, a.zusammenfassung ->> 'aufgaben' as aufgaben,
       jsonb_array_length(a.zusammenfassung -> 'eingriffe_ab_3') as eingriffe_ab_3, a.in_akte_am is not null as in_akte
  from session_students ss join session_kind_abschluss a using (session_id, student_id)
 where ss.session_id = :'s' order by 1;
select public.session_kind_name(student_id) as kind, kategorie, text from schueler_notizen
 where student_id in (:'mila', :'emir', :'lea') order by 1, 2;
select status, beendet_am is not null as beendet, einstellungen ->> 'ka_tage' as snapshot_ka_tage
  from coaching_sessions where id = :'s';
select from pg_temp.als(:'admin');
select public.session_kind_name(student_id) as kind, flag from session_flags_offen() order by 1;

rollback;
