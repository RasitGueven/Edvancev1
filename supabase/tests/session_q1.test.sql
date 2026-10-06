-- ============================================================================
-- Q1 Home Quests — Endpunkte (Bauauftrag Session-Rahmen P1, Entscheidungen 4, 21, 22).
--
-- Zusagen (Nummern wie im Bauauftrag):
--   1) quest_erzeugen legt A und B mit den richtigen Tagen an; mit Klassenarbeit vor
--      der naechsten Session ein KA-Paket statt B, mit Klassenarbeit danach B.
--   2) Aufgaben nur aus dem Quest-Pool (Einsatz quest, weder lsa noch session), freigegeben,
--      aktiv, mit Loesungsweg; Summe <= quest_minuten.
--   3) quest_inhalt fuer ein fremdes Kind (und einen Coach) -> 42501.
--   4) quest_erledigt bucht XP genau einmal; der zweite Aufruf bucht nichts.
--   5) Zeilenzahlen in lsa_*, session_antworten, lernpfad, student_task_progress,
--      behavior_snapshots und Report-Tabellen sind vor und nach quest_erledigt gleich.
--   6) quest_erinnerungen_faellig liefert nur offene Quests mit Termin im Fenster.
--   7) eltern_quest_wochenstand fuer Schuelerkonto oder Coach -> 42501.
-- Dazu: Rechte von quest_erzeugen und quest_termin_setzen, Wochenserie, Push-Token,
-- XP ueber xp_buchen_intern (Schluessel quest:<id>), Testlaeufe (X0) ohne Erinnerung und Wochenstand.
--
-- Fixture-Hinweis: session_students prueft per Trigger einen laufenden Vertrag (ZG001).
-- Die Fixtures schalten ihn transaktionslokal ab; alles wird zurueckgerollt.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(54);

\set admin_uid  'dddddddd-0071-4000-8000-000000000001'
\set coach_uid  'dddddddd-0071-4000-8000-000000000002'
\set coach2_uid 'dddddddd-0071-4000-8000-000000000003'
\set kind1_uid  'dddddddd-0071-4000-8000-000000000004'
\set kind2_uid  'dddddddd-0071-4000-8000-000000000005'
\set kind3_uid  'dddddddd-0071-4000-8000-000000000006'
\set kind4_uid  'dddddddd-0071-4000-8000-000000000007'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'q1-' || n || '@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'
  from (values (:'admin_uid'::uuid, 'admin'), (:'coach_uid'::uuid, 'coach'), (:'coach2_uid'::uuid, 'coach2'),
               (:'kind1_uid'::uuid, 'kind1'), (:'kind2_uid'::uuid, 'kind2'), (:'kind3_uid'::uuid, 'kind3'), (:'kind4_uid'::uuid, 'kind4')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin_uid',  'q1-admin@test.local',  'admin',   'Q1 Admin'),
  (:'coach_uid',  'q1-coach@test.local',  'coach',   'Q1 Coach'),
  (:'coach2_uid', 'q1-coach2@test.local', 'coach',   'Q1 Coach Zwei'),
  (:'kind1_uid',  'q1-kind1@test.local',  'student', 'Q1 Kind Eins'),
  (:'kind2_uid',  'q1-kind2@test.local',  'student', 'Q1 Kind Zwei'),
  (:'kind3_uid',  'q1-kind3@test.local',  'student', 'Q1 Kind Drei'),
  (:'kind4_uid',  'q1-kind4@test.local',  'student', 'Q1 Testkind');
insert into students (profile_id, class_level, ist_test) values
  (:'kind1_uid', 8, false), (:'kind2_uid', 8, false), (:'kind3_uid', 9, false), (:'kind4_uid', 8, true);
select (select id from students where profile_id = :'kind1_uid') as k1,
       (select id from students where profile_id = :'kind2_uid') as k2,
       (select id from students where profile_id = :'kind3_uid') as k3,
       (select id from students where profile_id = :'kind4_uid') as k4 \gset

-- Kind 1 hat einen laufenden Vertrag (hat_zugang), Kind 2 und 3 nicht.
insert into leads (full_name, status) values ('Q1 Lead Kind Eins', 'vertrag');
insert into vertraege (
  lead_id, status, vertrag_status, abgeschlossen_at, abgeschlossen_am, abschluss_weg, unterschrieben_am,
  student_id, tier_id, laufzeit_monate, preis_cents, einheiten, vertragsbeginn, vertrag_ende, widerruf_bis,
  eltern_vorname, eltern_nachname, eltern_email, kind_vorname, kind_nachname, klasse, fach)
select l.id, 'abgeschlossen', 'aktiv', now(), date '2026-07-20', 'vor_ort', date '2026-07-20',
       :'k1', (select id from tiers order by name limit 1), 12, 38990, 38, date '2026-08-01', current_date + 200, date '2026-08-15',
       'Q1', 'Eltern', 'q1-eltern@edvance.invalid', 'Q1', 'Kind', 8, 'Mathematik'
  from leads l where l.full_name = 'Q1 Lead Kind Eins';

-- Skills, Thema der Klassenarbeit, Aufgaben (Budget: 10 Minuten = 600 s).
insert into skills (skill_key, label, fundament_tiefe, klasse_herkunft) values
  ('zz_q1_neu', 'Q1 Neu', 1, 8), ('zz_q1_alt', 'Q1 Alt', 1, 7), ('zz_q1_ka', 'Q1 KA', 1, 9);
insert into themen (thema_key, fach, klasse, stufe, label, sort) values ('zz_q1_thema', 'mathematik', 9, 'erste', 'Q1 Thema', 9101);
insert into skill_thema (skill_key, thema_key) values ('zz_q1_ka', 'zz_q1_thema');

insert into tasks (content_type, input_type, status, is_active, question, skill_key, est_duration_sec, source, source_ref, einsatz)
select 'exercise', 'SHORT_TEXT', x.status, x.aktiv, 'Q1 Frage ' || x.ref, x.skill, x.dauer, 'test', x.ref,
       case x.ref when 'q1-neu-lsa' then '{lsa,session}'::text[] when 'q1-neu-gemischt' then '{quest,session}'::text[]
                  else '{quest}'::text[] end
  from (values
    ('q1-neu-1', 'zz_q1_neu', 180, 'ready', true), ('q1-neu-2', 'zz_q1_neu', 180, 'ready', true),
    ('q1-neu-3', 'zz_q1_neu', 180, 'ready', true), ('q1-neu-4', 'zz_q1_neu', 180, 'ready', true),
    ('q1-neu-ohne-loesung', 'zz_q1_neu', 60, 'ready', true),
    ('q1-neu-draft',        'zz_q1_neu', 60, 'draft', true),
    ('q1-neu-inaktiv',      'zz_q1_neu', 60, 'ready', false),
    ('q1-neu-ohne-dauer',   'zz_q1_neu', null, 'ready', true),
    ('q1-neu-lsa',          'zz_q1_neu', 60, 'ready', true),
    ('q1-neu-gemischt',     'zz_q1_neu', 60, 'ready', true),
    ('q1-alt-1', 'zz_q1_alt', 120, 'ready', true), ('q1-alt-2', 'zz_q1_alt', 120, 'ready', true),
    ('q1-ka-1', 'zz_q1_ka', 200, 'ready', true), ('q1-ka-2', 'zz_q1_ka', 200, 'ready', true),
    ('q1-ka-3', 'zz_q1_ka', 200, 'ready', true), ('q1-ka-4', 'zz_q1_ka', 200, 'ready', true)
  ) as x(ref, skill, dauer, status, aktiv);
insert into task_solutions (task_id, correct_answers, solution)
select t.id, '["1"]'::jsonb, case when t.source_ref = 'q1-neu-ohne-loesung' then '  ' else 'Loesungsweg ' || t.source_ref end
  from tasks t where t.source_ref like 'q1-%';

-- Sessions (Europe/Berlin): S0 25.08., S1 01.09., S2 08.09. fuer Kind 1;
-- S3 15.09., S4 22.09., S5 29.09. fuer Kind 3.
insert into coaching_sessions (coach_id, room, scheduled_at, status)
select :'coach_uid', 'Q1-' || n, (d || ' 16:00')::timestamp at time zone 'Europe/Berlin', 'done'
  from (values ('S0', '2026-08-25'), ('S1', '2026-09-01'), ('S2', '2026-09-08'),
               ('S3', '2026-09-15'), ('S4', '2026-09-22'), ('S5', '2026-09-29')) v(n, d);
select (select id from coaching_sessions where room = 'Q1-S0') as s0, (select id from coaching_sessions where room = 'Q1-S1') as s1,
       (select id from coaching_sessions where room = 'Q1-S3') as s3, (select id from coaching_sessions where room = 'Q1-S4') as s4 \gset

alter table session_students disable trigger session_students_zugang_trg;
insert into session_students (session_id, student_id, attendance)
select cs.id, k.sid, 'present'
  from coaching_sessions cs
  join (values (:'k1'::uuid, array['Q1-S0','Q1-S1','Q1-S2']), (:'k3'::uuid, array['Q1-S3','Q1-S4','Q1-S5'])) k(sid, raeume)
    on cs.room = any (k.raeume);
insert into session_students (session_id, student_id, attendance) values (:'s1', :'k2', 'present');

-- Eine aeltere Quest von Kind 1 aus S0 mit einer Aufgabe zu zz_q1_alt ("Aelteres").
insert into quests (student_id, session_id, art, faellig_ab) values (:'k1', :'s0', 'A', '2026-08-27');
insert into quest_aufgaben (quest_id, task_id, reihenfolge)
select q.id, t.id, 1 from quests q, tasks t where q.session_id = :'s0' and t.source_ref = 'q1-alt-1';

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create or replace function pg_temp.als_system() returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', '{"role":"service_role"}', true);
end $$;

-- --- Rechte von quest_erzeugen --------------------------------------------
set local role authenticated;
select pg_temp.act_as(:'coach2_uid');
select throws_ok(format($f$select * from quest_erzeugen(%L, %L, array['zz_q1_neu'])$f$, :'s1', :'k1'),
  '42501', null, 'quest_erzeugen: fremder Coach -> 42501');
select pg_temp.act_as(:'kind1_uid');
select throws_ok(format($f$select * from quest_erzeugen(%L, %L, array['zz_q1_neu'])$f$, :'s1', :'k1'),
  '42501', null, 'quest_erzeugen: Schuelerkonto -> 42501');
select pg_temp.act_as(:'coach_uid');
select throws_ok(format($f$select * from quest_erzeugen(%L, %L, array['zz_q1_neu'])$f$, :'s3', :'k3'),
  '42501', null, 'quest_erzeugen: Coach der Session, Kind ohne laufenden Vertrag -> 42501');
select throws_ok(format($f$select * from quest_erzeugen(%L, %L, array['zz_q1_neu'])$f$, gen_random_uuid(), :'k1'),
  '42501', null, 'quest_erzeugen: unbekannte Session -> 42501 fuer den Coach (kein Existenz-Orakel)');
select throws_ok(format($f$select * from quest_erzeugen(%L, %L, array['zz_q1_neu'])$f$, :'s1', :'k1'),
  '55000', null, 'quest_erzeugen: Coach der Session, aber home_quests_aktiv = aus -> 55000');
select pg_temp.act_as(:'admin_uid');
select throws_ok(format($f$select * from quest_erzeugen(%L, %L, array['zz_q1_neu'])$f$, :'s1', :'k1'),
  '55000', null, 'quest_erzeugen: auch Admin bei home_quests_aktiv = aus -> 55000');

-- --- 1) A, B, KA ------------------------------------------------------------
select pg_temp.als_system();
create temp table erg_k1 as select * from quest_erzeugen(:'s1', :'k1', array['zz_q1_neu']);
create temp table erg_k2 as select * from quest_erzeugen(:'s1', :'k2', array['zz_q1_neu']);
create temp table erg_k3a as select * from quest_erzeugen(:'s3', :'k3', array['zz_q1_neu'], 'zz_q1_thema', date '2026-09-17');
create temp table erg_k3b as select * from quest_erzeugen(:'s4', :'k3', array['zz_q1_neu'], 'zz_q1_thema', date '2026-10-30');
reset role;  -- Pruefungen lesen die Tabellen direkt, ohne RLS

select results_eq($$select art, faellig_ab from erg_k1 order by art$$,
  $$values ('A'::text, date '2026-09-03'), ('B'::text, date '2026-09-07')$$,
  '1: A zwei Tage nach der Session, B am Tag vor der naechsten gebuchten Session');
select results_eq($$select art, faellig_ab from erg_k3a order by art$$,
  $$values ('A'::text, date '2026-09-17'), ('KA'::text, date '2026-09-16')$$,
  '1: Klassenarbeit vor der naechsten Session -> KA-Paket statt B, am Tag vor der Arbeit');
select is((select ka_thema_key from quests q join erg_k3a e on e.quest_id = q.id where e.art = 'KA'),
  'zz_q1_thema', '1: KA-Paket traegt das Thema der Klassenarbeit');
select results_eq($$select art, faellig_ab from erg_k3b order by art$$,
  $$values ('A'::text, date '2026-09-24'), ('B'::text, date '2026-09-28')$$,
  '1: Klassenarbeit erst nach der naechsten Session -> normales B');
select is((select count(*)::int from quest_aufgaben qa join erg_k3a e on e.quest_id = qa.quest_id join tasks t on t.id = qa.task_id
            where e.art = 'KA' and t.skill_key <> 'zz_q1_ka'), 0, '1: KA-Paket enthaelt nur Aufgaben zum Thema der Klassenarbeit');
select results_eq(format($f$select status from quests where session_id = %L$f$, :'s0'), $$values ('verfallen'::text)$$,
  '1: die offene Quest der vorigen Session ist verfallen');
select is((select count(*)::int from quest_erzeugen(:'s1', :'k1', array['zz_q1_neu'])), 2, '1: zweiter Aufruf liefert dieselben Quests');
select is((select count(*)::int from quests where session_id = :'s1' and student_id = :'k1'), 2, '1: und legt keine weiteren an');

-- --- 2) Aufgaben -------------------------------------------------------------
reset role;
select is_empty($$
  select t.source_ref from quest_aufgaben qa join tasks t on t.id = qa.task_id
    left join task_solutions s on s.task_id = t.id
   where t.source_ref like 'q1-%'
     and (t.status <> 'ready' or not t.is_active or nullif(btrim(coalesce(s.solution, '')), '') is null)$$,
  '2: nur freigegebene, aktive Aufgaben mit Loesungsweg');
select is_empty($$
  select t.source_ref from quest_aufgaben qa join tasks t on t.id = qa.task_id
   where not ('quest' = any (t.einsatz)) or t.einsatz && array['lsa', 'session']$$,
  '2: nur Quest-Pool: Einsatz quest, weder lsa noch session');
select is_empty($$
  select qa.quest_id from quest_aufgaben qa join tasks t on t.id = qa.task_id
   group by qa.quest_id having sum(t.est_duration_sec) > 600$$, '2: Summe est_duration_sec hoechstens quest_minuten');
select is((select sum(t.est_duration_sec)::int from quest_aufgaben qa join erg_k1 e on e.quest_id = qa.quest_id
             join tasks t on t.id = qa.task_id where e.art = 'A'), 600, '2: Quest A schoepft das Budget aus');
select ok((select count(*) > 0 from quest_aufgaben qa join erg_k1 e on e.quest_id = qa.quest_id
             join tasks t on t.id = qa.task_id where e.art = 'A' and t.skill_key = 'zz_q1_alt'),
  '2: Quest A mischt Aelteres dazu');
select ok((select count(*) > 0 from quest_aufgaben qa join erg_k1 e on e.quest_id = qa.quest_id
             join tasks t on t.id = qa.task_id where e.art = 'A' and t.skill_key = 'zz_q1_neu'),
  '2: Quest A enthaelt das Stundenziel');

select (select quest_id from erg_k1 where art = 'A') as qa1, (select quest_id from erg_k1 where art = 'B') as qb1,
       (select quest_id from erg_k2 where art = 'A') as qa2 \gset

-- --- Termin -----------------------------------------------------------------
set local role authenticated;
select pg_temp.act_as('dddddddd-0071-4000-8000-0000000000ff');
select throws_ok(format($f$select quest_termin_setzen(%L, '2026-09-03 18:00+02')$f$, :'qa1'), '42501', null,
  'Termin: Konto ohne Profil -> 42501 (kein Durchlass ueber null)');
select pg_temp.act_as(:'coach2_uid');
select throws_ok(format($f$select quest_termin_setzen(%L, '2026-09-03 18:00+02')$f$, :'qa1'), '42501', null,
  'Termin: fremder Coach -> 42501');
select pg_temp.act_as(:'kind2_uid');
select throws_ok(format($f$select quest_termin_setzen(%L, '2026-09-03 18:00+02')$f$, :'qa1'), '42501', null,
  'Termin: fremdes Kind -> 42501');
select throws_ok(format($f$select quest_termin_setzen(%L, '2026-09-03 18:00+02')$f$, gen_random_uuid()), '42501', null,
  'Termin: unbekannte Quest -> 42501');
select pg_temp.act_as(:'kind1_uid');
select throws_ok(format($f$select quest_termin_setzen(%L, '2026-09-02 18:00+02')$f$, :'qa1'), '22023', null,
  'Termin: vor faellig_ab -> 22023');
select lives_ok(format($f$select quest_termin_setzen(%L, '2026-09-03 18:00+02')$f$, :'qa1'), 'Termin: das Kind setzt ihn');
select pg_temp.act_as(:'coach_uid');
select lives_ok(format($f$select quest_termin_setzen(%L, '2026-09-07 17:00+02')$f$, :'qb1'), 'Termin: der Coach der Session setzt ihn');
select throws_ok(format($f$select quest_termin_setzen(%L, '2026-09-25 17:00+02')$f$,
  (select quest_id from erg_k3b where art = 'A')), '42501', null, 'Termin: Coach, Kind ohne laufenden Vertrag -> 42501');

-- --- 3) Inhalt ---------------------------------------------------------------
select throws_ok(format($f$select * from quest_inhalt(%L)$f$, :'qa1'), '42501', null, '3: quest_inhalt fuer den Coach -> 42501');
select pg_temp.act_as(:'kind2_uid');
select throws_ok(format($f$select * from quest_inhalt(%L)$f$, :'qa1'), '42501', null, '3: quest_inhalt fuer ein fremdes Kind -> 42501');
select pg_temp.act_as(:'kind1_uid');
select is((select count(*)::int from quest_inhalt(:'qa1') where loesungsweg like 'Loesungsweg q1-%' and aufgabe ? 'prompt'),
  4, '3: das Kind bekommt seine vier Aufgaben mit Loesungsweg');

-- --- 4) + 5) Erledigt --------------------------------------------------------
reset role;
create temp table fern_tabellen as
  select c.oid::regclass as tab from pg_class c join pg_namespace n on n.oid = c.relnamespace
   where n.nspname = 'public' and c.relkind = 'r'
     and (c.relname ~ '^lsa_' or c.relname ~ 'report' or c.relname ~ '^lernpfad'
          or c.relname in ('session_antworten', 'student_task_progress', 'behavior_snapshots'));
create or replace function pg_temp.fern_zeilen() returns text language plpgsql as $$
declare r record; v int; s text := '';
begin
  for r in select tab from fern_tabellen order by tab::text loop
    execute format('select count(*) from %s', r.tab) into v;
    s := s || r.tab::text || '=' || v || ' ';
  end loop;
  return s;
end $$;
grant select on fern_tabellen to authenticated;
create temp table fern_vorher as select pg_temp.fern_zeilen() as z, (select count(*) from xp_events where student_id = :'k1') as xp_n,
  (select coalesce(sum(xp), 0) from xp_events where student_id = :'k1') as xp_sum;

set local role authenticated;
select pg_temp.act_as(:'kind2_uid');
select throws_ok(format($f$select * from quest_erledigt(%L)$f$, :'qa1'), '42501', null, '4: fremdes Kind kann nicht erledigen');
select pg_temp.act_as(:'kind1_uid');
select results_eq(format($f$select status, xp_neu, wochenserie from quest_erledigt(%L)$f$, :'qa1'),
  $$values ('erledigt'::text, 50, 1)$$, '4: erster Aufruf bucht quest_xp, Wochenserie beginnt');
select results_eq(format($f$select status, xp_neu, wochenserie from quest_erledigt(%L)$f$, :'qa1'),
  $$values ('erledigt'::text, 0, 1)$$, '4: zweiter Aufruf bucht nichts');
select throws_ok(format($f$select * from quest_inhalt(%L)$f$, :'qa1'), '55000', null, '3: nach erledigt kein Loesungsweg mehr');
select results_eq(format($f$select status, xp_neu, wochenserie from quest_erledigt(%L)$f$, :'qb1'),
  $$values ('erledigt'::text, 50, 1)$$, '4: zweite Quest derselben Woche zaehlt die Serie nicht doppelt');

reset role;
select is((select count(*) from xp_events where student_id = :'k1') - (select xp_n from fern_vorher), 2::bigint,
  '4: genau zwei XP-Buchungen fuer zwei Quests');
select is((select coalesce(sum(xp), 0) from xp_events where student_id = :'k1') - (select xp_sum from fern_vorher), 100::bigint,
  '4: zusammen 100 XP');
select is((select xp_gebucht from quests where id = :'qa1'), 50, '4: xp_gebucht steht an der Quest');
select results_eq(format($f$select reason, xp from xp_events where buchungs_schluessel = 'quest:' || %L$f$, :'qa1'),
  $$values ('home_quest'::text, 50)$$, '4: gebucht ueber xp_buchen mit Schluessel quest:<id>');
select is(pg_temp.fern_zeilen(), (select z from fern_vorher), '5: lsa_*, Lernpfad, Fortschritt, Snapshots, Reports unveraendert');
select is_empty($$
  select p.proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and (p.proname ~ 'quest' or p.proname = 'push_token_registrieren')
     and p.prosrc ~* '(insert\s+into|update|delete\s+from)\s+(public\.)?(lsa_|session_antworten|lernpfad|student_task_progress|behavior_snapshots|\w*report)'$$,
  '5: keine Quest-Funktion schreibt in FernUSG-Tabellen');

-- Wochenserie pausiert beim Reissen und setzt nie zurueck.
update student_progress set home_streak_sessions = 5, home_streak_last_completed_at = now() - interval '21 days'
 where student_id = :'k2';
insert into student_progress (student_id, home_streak_sessions, home_streak_last_completed_at)
select :'k2', 5, now() - interval '21 days' where not exists (select 1 from student_progress where student_id = :'k2');
set local role authenticated;
select pg_temp.act_as(:'kind2_uid');
select is((select wochenserie from quest_erledigt(:'qa2')), 6, 'Wochenserie: nach drei Wochen Pause 5 -> 6, kein Reset');

-- --- 6) Erinnerungen ---------------------------------------------------------
select pg_temp.act_as(:'kind1_uid');
select throws_ok($$select * from quest_erinnerungen_faellig(now())$$, '42501', null, '6: Schuelerkonto -> 42501');
select pg_temp.act_as(:'admin_uid');
select results_eq(
  $$select q.art from quest_erinnerungen_faellig('2026-09-05 00:00+02', '2026-09-01 00:00+02') f join quests q on q.id = f.quest_id$$,
  $$select 'X'::text where false$$, '6: erledigte Quest A liefert keine Erinnerung');
reset role;
update quests set termin = '2026-09-18 17:00+02' where session_id = :'s3';
update quests set termin = '2026-09-24 17:00+02' where session_id = :'s4' and art = 'A';
set local role authenticated;
select pg_temp.act_as(:'admin_uid');
select results_eq(
  $$select q.art, f.termin from quest_erinnerungen_faellig('2026-09-25 00:00+02', '2026-09-17 00:00+02') f join quests q on q.id = f.quest_id$$,
  $$values ('A'::text, '2026-09-24 17:00+02'::timestamptz)$$, '6: nur offene Quests mit Termin im Fenster (verfallene nicht)');

-- --- 7) Wochenstand ----------------------------------------------------------
select pg_temp.act_as(:'kind1_uid');
select throws_ok($$select * from eltern_quest_wochenstand('2026-09-01')$$, '42501', null, '7: Schuelerkonto -> 42501');
select pg_temp.act_as(:'coach_uid');
select throws_ok($$select * from eltern_quest_wochenstand('2026-09-01')$$, '42501', null, '7: Coach -> 42501');
select pg_temp.act_as(:'admin_uid');
select results_eq(format($f$select erledigt, offen, eltern_email from eltern_quest_wochenstand('2026-09-03') where student_id = %L$f$, :'k1'),
  $$values (1, 0, 'q1-eltern@edvance.invalid'::text)$$, '7: Admin sieht je Kind erledigt und offen der Woche');

-- --- Testlauf (X0): angelegt, aber ohne Erinnerung und ohne Wochenstand --------
reset role;
select pg_temp.act_as(:'admin_uid');
insert into coaching_sessions (coach_id, room, scheduled_at, status, testlauf)
values (:'coach_uid', 'Q1-TEST', '2026-09-01 16:00+02', 'done', true);
select id as st from coaching_sessions where room = 'Q1-TEST' \gset
insert into session_students (session_id, student_id, attendance) values (:'st', :'k4', 'present');
select pg_temp.als_system();
select is((select count(*)::int from quest_erzeugen(:'st', :'k4', array['zz_q1_neu'])), 2, 'Testlauf: Quests werden angelegt');
update quests set termin = '2026-09-04 17:00+02' where session_id = :'st' and art = 'A';
set local role authenticated;
select pg_temp.act_as(:'admin_uid');
select is((select count(*)::int from quest_erinnerungen_faellig('2026-09-05 00:00+02', '2026-09-01 00:00+02') f
            join quests q on q.id = f.quest_id where q.student_id = :'k4'), 0, 'Testlauf: keine Erinnerung');
select is((select count(*)::int from eltern_quest_wochenstand('2026-09-03') where student_id = :'k4'), 0,
  'Testlauf: kein Eltern-Wochenstand');

-- --- Push-Token ---------------------------------------------------------------
select pg_temp.act_as(:'coach_uid');
select throws_ok($$select push_token_registrieren('tok-q1', 'ios')$$, '42501', null, 'Push: Coach -> 42501');
select pg_temp.act_as(:'kind1_uid');
select lives_ok($$select push_token_registrieren('tok-q1', 'ios', 'iPhone')$$, 'Push: das Kind registriert ein Token');

select * from finish();
rollback;
