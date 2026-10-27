-- ============================================================================
-- Reihe 1 · D1c Home-Sitzungen begrenzen (Bauauftrag D, Zweitprüfung D1 Befunde 3 und 4).
--
--   1) get_my_student_id(): Passwort-Session und aktives Gerät → das Kind; abgemeldetes Gerät → null
--   2) lsa_may_act_for(): das Kind ohne Gerätezeile ja, über eine Gerätesitzung nein; Admin und Coach unverändert
--   3) screening_tests: das Kind schreibt nur ohne Gerätesitzung; ein abgemeldetes Gerät liest keine eigenen xp_events
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

\set admin 'dddddddd-d1c0-4000-8000-000000000001'
\set coach 'dddddddd-d1c0-4000-8000-000000000003'
\set pw    'aaaaaaaa-d1c0-4000-8000-000000000009'
\set k1    'dddddddd-d1c0-4000-8000-000000000002'
\set aktiv 'aaaaaaaa-d1c0-4000-8000-000000000001'
\set weg   'aaaaaaaa-d1c0-4000-8000-000000000002'

insert into auth.users (id, email, instance_id, aud, role)
select u, 'd1c-' || n || '@test.local', '00000000-0000-0000-0000-000000000000'::uuid, 'authenticated', 'authenticated'
  from (values (:'admin'::uuid, 'admin'), (:'k1', 'k1'), (:'coach', 'coach')) v(u, n);
insert into profiles (id, email, role, full_name) values
  (:'admin', 'd1c-admin@test.local', 'admin', 'ZZ Admin'),
  (:'k1', 'd1c-k1@test.local', 'student', 'Batu Test'),
  (:'coach', 'd1c-coach@test.local', 'coach', 'ZZ Coach');
insert into students (class_level, profile_id) values (9, :'k1');
select id as s1 from students where profile_id = :'k1' \gset
insert into kind_geraete (student_id, name, plattform, installation_hash, auth_session_id) values
  (:'s1', 'iPhone', 'ios', repeat('a', 64), :'aktiv');
insert into kind_geraete (student_id, name, plattform, installation_hash, auth_session_id, abgemeldet_am, abmelde_grund) values
  (:'s1', 'Altes Handy', 'android', repeat('b', 64), :'weg', now(), 'admin');

create or replace function pg_temp.als(uid uuid, sess uuid default null) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
                     json_build_object('sub', uid, 'role', 'authenticated', 'session_id', sess)::text, true);
  perform set_config('request.jwt.claim.sub', uid::text, true);
  perform set_config('request.jwt.claim.role', 'authenticated', true);
end $$;

-- ── 1) get_my_student_id ────────────────────────────────────────────────────
select pg_temp.als(:'k1');
select is(get_my_student_id(), :'s1'::uuid, '1 Passwort-Session: das Kind');
select pg_temp.als(:'k1', :'aktiv');
select is(get_my_student_id(), :'s1'::uuid, '1 aktives Gerät: das Kind');
select pg_temp.als(:'k1', :'weg');
select is(get_my_student_id(), null::uuid, '1 abgemeldetes Gerät: null, sofort, ohne auf den Ablauf des Tokens zu warten');
select is(geraet_status(), 'abgemeldet', '1 geraet_status meldet trotzdem „abgemeldet“');

select pg_temp.als(:'k1', :'pw');
select is(get_my_student_id(), :'s1'::uuid, '1 Session mit session_id, aber ohne Gerätezeile: das Kind');
select pg_temp.als(:'coach');
select is(get_my_student_id(), null::uuid, '1 Coach: null wie bisher');

-- ── 2) lsa_may_act_for ──────────────────────────────────────────────────────
select pg_temp.als(:'k1', :'aktiv');
select ok(not lsa_may_act_for(:'s1'), '2 über die Gerätesitzung zuhause nicht');
select pg_temp.als(:'k1', :'pw');
select ok(lsa_may_act_for(:'s1'), '2 Session ohne Gerätezeile: wie bisher (offener Punkt Passwortwechsel, bericht.md)');
select pg_temp.als(:'admin');
select ok(lsa_may_act_for(:'s1'), '2 Admin unverändert');
select pg_temp.als(:'coach');
select is(lsa_may_act_for(:'s1'), akte_aktiv(:'s1'), '2 Coach unverändert (über akte_aktiv)');

-- ── 3) Tabellen ─────────────────────────────────────────────────────────────
insert into xp_events (student_id, xp, reason) values (:'s1', 10, 'ZZ Test');
select pg_temp.als(:'k1', :'aktiv');
set local role authenticated;
select is((select count(*)::int from xp_events where student_id = :'s1'), 1, '3 aktives Gerät liest eigene xp_events');
select throws_ok(format($$insert into screening_tests (student_id, subject) values (%L, 'Mathematik')$$, :'s1'), '42501', null,
                 '3 Gerätesitzung schreibt keinen Screening-Test');
reset role;
select pg_temp.als(:'k1', :'weg');
set local role authenticated;
select is((select count(*)::int from xp_events where student_id = :'s1'), 0, '3 abgemeldetes Gerät liest keine xp_events mehr');
reset role;
select pg_temp.als(:'k1', :'pw');
set local role authenticated;
select lives_ok(format($$insert into screening_tests (student_id, subject) values (%L, 'Mathematik')$$, :'s1'), '3 ohne Gerätesitzung wie bisher');
reset role;

select * from finish();
rollback;
