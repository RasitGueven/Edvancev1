-- ============================================================================
-- LSA-A1: Themenfeld im Aufgaben-Payload. Migration 20261023074802_lsa_themenfeld.
-- Bauauftrag docs/lsa/Bauauftrag-LSA-A1.md.
--   T1 lsa_themenfeld gleich feldVon (themenfelder.ts): alle Paare aus fixtures/themenfeld.sql,
--      erzeugt von tools/themenfeld-fixture.ts
--   T2 lsa_question_payload liefert 'themenfeld' fuer mc, short_input und multi_part
--   T3 Rechte: lsa_themenfeld ist Helfer (nicht anon/authenticated), immutable;
--      lsa_question_payload unveraendert nicht fuer anon/authenticated
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(12);

\ir fixtures/themenfeld.sql
\ir lsa_l1_fixture.sql

-- T1 Gleichlauf mit feldVon ---------------------------------------------------
select cmp_ok((select count(*) from themenfeld_soll), '>=', 130::bigint, 'T1 Fixture traegt den Skill-Bestand');
select is_empty(
  $$ select skill_key, feld, public.lsa_themenfeld(skill_key)
       from themenfeld_soll
      where public.lsa_themenfeld(skill_key) is distinct from feld $$,
  'T1 lsa_themenfeld = feldVon fuer jeden skill_key der Fixture');
select is(public.lsa_themenfeld(null), 'weitere', 'T1 ohne skill_key → weitere');

-- T2 Payload ------------------------------------------------------------------
insert into skills (skill_key, label, klasse_herkunft, fundament_tiefe) values
  ('bruch_add', 'ZZ A1 Brueche', 6, 1),
  ('stoch_laplace', 'ZZ A1 Zufall', 7, 1),
  ('fkt_linear_graph', 'ZZ A1 Funktionen', 8, 1)
on conflict (skill_key) do nothing;

select pg_temp.l1_aufgabe('a1-num', 'NUMERIC', '["12"]') as t_num \gset
select pg_temp.l1_aufgabe('a1-mc', 'MC', '["b"]') as t_mc \gset
select pg_temp.l1_aufgabe('a1-mp', 'MULTI_PART', '{"1":["7"],"2":["8"]}',
  '[{"nr":1,"kind":"short_input","prompt":"Teil a"},{"nr":2,"kind":"short_input","prompt":"Teil b"}]') as t_mp \gset
select pg_temp.l1_aufgabe('a1-weitere', 'NUMERIC', '["3"]') as t_weitere \gset
update tasks set skill_key = 'bruch_add' where id = :'t_num';
update tasks set skill_key = 'stoch_laplace' where id = :'t_mc';
update tasks set skill_key = 'fkt_linear_graph' where id = :'t_mp';

select is(public.lsa_question_payload(:'t_num') ->> 'kind' || '/' || (public.lsa_question_payload(:'t_num') ->> 'themenfeld'),
          'short_input/brueche', 'T2 short_input traegt themenfeld');
select is(public.lsa_question_payload(:'t_mc') ->> 'kind' || '/' || (public.lsa_question_payload(:'t_mc') ->> 'themenfeld'),
          'mc/zufall', 'T2 mc traegt themenfeld');
select is(public.lsa_question_payload(:'t_mp') ->> 'kind' || '/' || (public.lsa_question_payload(:'t_mp') ->> 'themenfeld'),
          'multi_part/funktionen', 'T2 multi_part traegt themenfeld');
select is(public.lsa_question_payload(:'t_weitere') ->> 'themenfeld', 'weitere',
          'T2 unbekannter Skill → weitere, nie der rohe Schluessel');
select ok(not (public.lsa_question_payload(:'t_mp') -> 'parts' -> 0 ? 'themenfeld'),
          'T2 das Feld steht an der Aufgabe, nicht an den Teilen');

-- T3 Rechte -------------------------------------------------------------------
select is(has_function_privilege('anon', 'public.lsa_themenfeld(text)', 'execute'), false,
          'T3 lsa_themenfeld nicht fuer anon');
select is(has_function_privilege('authenticated', 'public.lsa_themenfeld(text)', 'execute'), false,
          'T3 lsa_themenfeld nicht fuer authenticated');
select is((select provolatile from pg_proc where oid = 'public.lsa_themenfeld(text)'::regprocedure), 'i'::"char",
          'T3 lsa_themenfeld ist immutable');
select is(has_function_privilege('anon', 'public.lsa_question_payload(uuid)', 'execute')
          or has_function_privilege('authenticated', 'public.lsa_question_payload(uuid)', 'execute'), false,
          'T3 lsa_question_payload behaelt seine Rechte (nicht anon, nicht authenticated)');

select * from finish();
rollback;
