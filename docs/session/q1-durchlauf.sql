-- Q1 Durchlauf: Session -> quest_erzeugen -> Termin -> Inhalt -> erledigt -> Wochenstand.
--
-- Nur fuer eine Wegwerf-DB aus allen Migrationen (nie Prod, nie edvance_shadow).
-- Alles laeuft in einer Transaktion und wird am Ende zurueckgerollt.
-- Aufruf: psql "<wegwerf-db>" -v ON_ERROR_STOP=1 -f docs/session/q1-durchlauf.sql
--
-- Die Session liegt drei Tage zurueck, die naechste in vier Tagen; so ist Quest A
-- heute schon abrufbar. session_students prueft einen laufenden Vertrag (ZG001); fuer
-- das Testkind ist der Trigger transaktionslokal aus. Testkonten (students.ist_test)
-- kommen mit X0.
\pset pager off
\pset footer off
begin;

\set coach_uid 'dddddddd-0072-4000-8000-000000000001'
\set admin_uid 'dddddddd-0072-4000-8000-000000000002'
\set kind_uid  'dddddddd-0072-4000-8000-000000000003'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'coach_uid', 'q1d-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'admin_uid', 'q1d-admin@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'kind_uid',  'q1d-kind@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values
  (:'coach_uid', 'q1d-coach@test.local', 'coach',   'Durchlauf Coach'),
  (:'admin_uid', 'q1d-admin@test.local', 'admin',   'Durchlauf Admin'),
  (:'kind_uid',  'q1d-kind@test.local',  'student', 'Durchlauf Testkind');
insert into students (profile_id, class_level) values (:'kind_uid', 8);
select id as kind from students where profile_id = :'kind_uid' \gset

insert into skills (skill_key, label, fundament_tiefe, klasse_herkunft) values ('zz_q1d_prozent', 'Grundwert berechnen', 1, 7);
insert into tasks (content_type, input_type, status, question, skill_key, est_duration_sec, source, source_ref)
select 'exercise', 'SHORT_TEXT', 'ready', 'Durchlauf Aufgabe ' || n, 'zz_q1d_prozent', 150, 'test', 'q1d-' || n
  from generate_series(1, 5) n;
insert into task_solutions (task_id, correct_answers, solution)
select id, '["1"]'::jsonb, 'Loesungsweg: G = W / p (' || source_ref || ')' from tasks where source_ref like 'q1d-%';

insert into coaching_sessions (coach_id, room, scheduled_at, status) values
  (:'coach_uid', 'Q1D-heute',    date_trunc('hour', now()) - interval '3 days', 'done'),
  (:'coach_uid', 'Q1D-naechste', date_trunc('hour', now()) + interval '4 days', 'upcoming');
select (select id from coaching_sessions where room = 'Q1D-heute') as sess \gset
alter table session_students disable trigger session_students_zugang_trg;
insert into session_students (session_id, student_id, attendance)
select id, :'kind', case when room = 'Q1D-heute' then 'present' else 'planned' end
  from coaching_sessions where room like 'Q1D-%';

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

\echo '== 0. Stellschrauben (session_einstellungen fehlt bis R1 -> Startwerte)'
select k as schluessel, public.quest_einstellung(k) as wert
  from unnest(array['home_quests_aktiv','quests_pro_woche','quest_minuten','quest_a_abstand_tage','quest_xp','mischanteil']) k;

\echo '== 1. quest_erzeugen als Coach der Session (home_quests_aktiv = aus -> abgelehnt)'
set local role authenticated;
select pg_temp.act_as(:'coach_uid');
savepoint vor_coach;
\set ON_ERROR_STOP 0
select * from quest_erzeugen(:'sess', :'kind', array['zz_q1d_prozent']);
\set ON_ERROR_STOP 1
rollback to savepoint vor_coach;

\echo '== 2. quest_erzeugen als Systemaufruf'
select set_config('request.jwt.claims', '{"role":"service_role"}', true) is not null as system;
select art, faellig_ab, aufgaben from quest_erzeugen(:'sess', :'kind', array['zz_q1d_prozent']) order by faellig_ab;
reset role;
select (select id from quests where session_id = :'sess' and art = 'A') as qa,
       (select id from quests where session_id = :'sess' and art = 'B') as qb \gset

\echo '== 3. Termin: das Kind waehlt im Check-out'
set local role authenticated;
select pg_temp.act_as(:'kind_uid');
select quest_termin_setzen(:'qa', (current_date + 1 + time '17:00') at time zone 'Europe/Berlin') as termin_a;
select quest_termin_setzen(:'qb', (current_date + 3 + time '18:30') at time zone 'Europe/Berlin') as termin_b;

\echo '== 4. Push-Token und faellige Erinnerungen (Admin, naechste 2 Tage)'
select push_token_registrieren('ExponentPushToken[durchlauf]', 'ios', 'iPhone des Testkinds') is not null as token_angelegt;
select pg_temp.act_as(:'admin_uid');
select q.art, f.termin from quest_erinnerungen_faellig(now() + interval '2 days') f join quests q on q.id = f.quest_id;

\echo '== 5. quest_inhalt (Kind): Aufgaben mit Loesungsweg zur Selbstkontrolle'
select pg_temp.act_as(:'kind_uid');
select reihenfolge, aufgabe ->> 'prompt' as aufgabe, loesungsweg, dauer_sec from quest_inhalt(:'qa');

\echo '== 6. quest_erledigt zweimal: XP nur beim ersten Mal'
select * from quest_erledigt(:'qa');
select * from quest_erledigt(:'qa');
select xp_total, home_streak_sessions from student_progress where student_id = :'kind';

\echo '== 7. eltern_quest_wochenstand (Admin) fuer die Woche von Quest A und B'
select pg_temp.act_as(:'admin_uid');
select w.woche_ab, w.erledigt, w.offen, w.eltern_email
  from (select distinct faellig_ab from quests where student_id = :'kind') d,
       lateral eltern_quest_wochenstand(d.faellig_ab) w
 where w.student_id = :'kind'
 group by 1, 2, 3, 4 order by 1;

\echo '== 8. Was gespeichert ist: nur Status und Zeitpunkte'
reset role;
select art, faellig_ab, status, erledigt_am is not null as erledigt_am_gesetzt, xp_gebucht from quests where student_id = :'kind' order by faellig_ab;

rollback;
