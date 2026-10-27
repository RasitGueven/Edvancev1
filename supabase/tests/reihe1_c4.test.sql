-- Reihe 1 · C4: session_gp_ergebnis (Coach-Sicht). Rechte und Ergebnis je Skill.
begin;
create extension if not exists pgtap with schema extensions;
select plan(4);
\ir session_a2_fixture.sql
select pg_temp.kind_mit('ZZ C4 Ida', 'zz_a2_terme', '{}') as k \gset
select pg_temp.neue_session(array[:'k']::uuid[], 20) as s \gset
select pg_temp.act_as(:'coach_a');
select is(session_gp_ergebnis(:'s', :'k'), '[]'::jsonb, '1 ohne Generalprobe leer');
reset role;
insert into session_schritte (session_id, student_id, art, phase, skill_key, task_id, grund, grund_code, rolle)
select :'s', :'k', 'generalprobe', 'kern', 'zz_a2_s1', id, 'Test', 'generalprobe', 'generalprobe'
  from tasks where source_ref = 'a2-zz_a2_s1-1';
insert into session_ausgegeben (session_id, student_id, task_id, phase) select :'s', :'k', id, 'kern' from tasks where source_ref = 'a2-zz_a2_s1-1';
select pg_temp.act_as(:'coach_a');
select is(session_gp_ergebnis(:'s', :'k') -> 0 ->> 'offen', 'true', '2 unbeantwortet: läuft');
select pg_temp.act_as(pg_temp.tablet(1));
select antwort_abgeben(:'s', (select id from tasks where source_ref = 'a2-zz_a2_s1-1'), null, '"7"');
select pg_temp.act_as(:'coach_a');
select is(session_gp_ergebnis(:'s', :'k') -> 0 ->> 'sicher', 'true', '3 beim ersten Versuch richtig: sicher');
select pg_temp.act_as(:'coach_b');
select throws_ok(format('select session_gp_ergebnis(%L, %L)', :'s', :'k'), '42501', null, '4 fremder Coach: kein Zugriff');
select * from finish();
rollback;
