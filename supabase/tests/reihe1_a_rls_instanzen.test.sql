-- ============================================================================
-- Reihe 1 · A: Kinder lesen Bauform-Instanzen nicht direkt (Migration 20261028141848_reihe1_a_rls_instanzen).
--   Als Kind (role authenticated, profiles.role student): keine Instanz-Zeile, kein params, kein pruefmaschine;
--   LSA- und andere ready-Aufgaben ohne Bauform weiter lesbar; die home-Instanz kommt ueber aufgabe_ziehen und
--   aufgabe_payload ohne params. Coach liest Instanzen weiter. Eltern wie Kind. Am Ende rollback.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(13);

\ir session_a2_fixture.sql

\set eltern '2c700000-0000-4000-8000-0000000000e1'
insert into auth.users (id, email, instance_id, aud, role)
values (:'eltern', 'rls-eltern@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name) values (:'eltern', 'rls-eltern@test.local', 'parent', 'RLS Eltern');

-- Bauform freigegeben, Instanzen ready (wie nach Sammelfreigabe); dazu ready-Aufgaben ohne Bauform.
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values ('zz_rls', 'ZZ RLS', 9, 1);
insert into bauformen (schluessel, skill_key, format, rollen, steckbrief, status, pruefprotokoll, blindloeser)
values ('ZZ-9', 'zz_rls', 'zahl', '{uebung,home}', '{"text": "Wie viel ist {a} + {b}?"}', 'freigegeben',
        '{"gruen": 2, "rot": 0, "lauf_am": "2026-10-28"}', '{"bestanden": true}')
returning id as bf, version as bf_v \gset
insert into tasks (content_type, input_type, status, is_active, question, question_payload, skill_key, est_duration_sec,
                   source, source_ref, einsatz, bauform_id, bauform_version, stufe, rolle, params, pruefmaschine)
values ('exercise', 'NUMERIC', 'ready', true, 'ZZ RLS: Wie viel ist 3 + 4?', '{"kind":"short_input","prompt":"Wie viel ist 3 + 4?"}',
        'zz_rls', 60, 'reihe1_rls_test', 'h1', '{session}', :'bf', :'bf_v', 1, 'home', '{"a":3,"b":4}', '{"1":{"ok":true}}'),
       ('exercise', 'NUMERIC', 'ready', true, 'ZZ RLS: Wie viel ist 5 + 4?', '{"kind":"short_input","prompt":"Wie viel ist 5 + 4?"}',
        'zz_rls', 60, 'reihe1_rls_test', 'u1', '{session}', :'bf', :'bf_v', 1, 'uebung', '{"a":5,"b":4}', '{"1":{"ok":true}}');
select id as h1 from tasks where source = 'reihe1_rls_test' and source_ref = 'h1' \gset
insert into task_solutions (task_id, correct_answers, solution, acceptance)
select id, '["7"]'::jsonb, '3 + 4 = 7', '{"canonical":"7"}'::jsonb from tasks where source = 'reihe1_rls_test' and source_ref = 'h1'
union all
select id, '["9"]'::jsonb, '5 + 4 = 9', '{"canonical":"9"}'::jsonb from tasks where source = 'reihe1_rls_test' and source_ref = 'u1';
insert into tasks (content_type, input_type, status, is_active, question, skill_key, est_duration_sec, source, source_ref, einsatz)
values ('exercise', 'NUMERIC', 'ready', true, 'ZZ RLS LSA: 2 + 2?', 'zz_rls', 60, 'reihe1_rls_test', 'lsa1', '{lsa}');

select pg_temp.kind('ZZ RLS Kind') as kind \gset
update students set profile_id = :'schueler' where id = :'kind';

-- ── Kind ────────────────────────────────────────────────────────────────────
select pg_temp.act_as(:'schueler');
set local role authenticated;
select is((select count(*)::int from tasks where bauform_id is not null), 0, 'Kind liest keine Instanz-Zeile');
select is((select count(*)::int from tasks where source = 'reihe1_rls_test' and params is not null), 0, 'Kind liest kein params');
select is((select count(*)::int from tasks where source = 'reihe1_rls_test' and pruefmaschine is not null), 0,
          'Kind liest kein pruefmaschine');
select is((select count(*)::int from tasks where source = 'reihe1_rls_test' and source_ref = 'lsa1'), 1,
          'Kind liest weiter ready-Aufgaben ohne Bauform (LSA)');
select is(aufgabe_ziehen(:'kind', 'zz_rls', 'home'), :'h1'::uuid, 'Kind zieht seine home-Instanz ueber aufgabe_ziehen');
select ok(not (aufgabe_payload(:'h1') ?| array['params', 'pruefmaschine']), 'aufgabe_payload liefert die Instanz ohne params');
select is(aufgabe_payload(:'h1') ->> 'prompt', 'ZZ RLS: Wie viel ist 3 + 4?', 'aufgabe_payload liefert die Kindersicht');
reset role;

-- ── Tablet (Geraetekonto, profiles.role student), Entwurf, Policy-Text ─────
select pg_temp.act_as(pg_temp.tablet(1));
set local role authenticated;
select is((select count(*)::int from tasks where bauform_id is not null), 0, 'Tablet-Konto liest keine Instanz-Zeile direkt');
reset role;
update tasks set status = 'draft' where source = 'reihe1_rls_test' and source_ref = 'lsa1';
select pg_temp.act_as(:'schueler');
set local role authenticated;
select is((select count(*)::int from tasks where source = 'reihe1_rls_test'), 0, 'Kind liest weiter keinen Entwurf');
reset role;
select ok((select qual ~ 'bauform_id IS NULL' from pg_policies where tablename = 'tasks' and policyname = 'read_tasks_by_role'),
          'Policy verlangt bauform_id is null');

-- ── Eltern, Coach ───────────────────────────────────────────────────────────
select pg_temp.act_as(:'eltern');
set local role authenticated;
select is((select count(*)::int from tasks where bauform_id is not null), 0, 'Eltern lesen keine Instanz-Zeile');
reset role;
select pg_temp.act_as(:'coach_a');
set local role authenticated;
select is((select count(*)::int from tasks where source = 'reihe1_rls_test' and bauform_id is not null), 2,
          'Coach liest Instanzen weiter');
select is((select params from tasks where id = :'h1'), '{"a":3,"b":4}'::jsonb, 'Coach liest params weiter');
reset role;

select * from finish();
rollback;
