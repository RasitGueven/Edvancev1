-- ============================================================================
-- Lena-Board LSA/Session (Migration 20261016140100): pruef_board().anlaesse und .hat_hinweise,
-- pruef_board_soll(p_anlass). Zuordnung nur über den Knoten, auch für später angelegte Aufgaben.
-- Eigene Fixtures (Quelle 'lsa_session_test', Knoten geo_kreis_umfang mit eigenen Anlässen), am Ende rollback.
--
-- Lauf: npx supabase test db
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(18);

-- --- Fixtures --------------------------------------------------------------
\set lena_uid  '2c200000-0000-4000-8000-00000000000b'
\set coach_uid '2c200000-0000-4000-8000-00000000000c'

insert into auth.users (id, email, instance_id, aud, role) values
  (:'lena_uid',  'ls-lena@test.local',  '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated'),
  (:'coach_uid', 'ls-coach@test.local', '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated');
insert into profiles (id, email, role, full_name, darf_pruefen) values
  (:'lena_uid',  'ls-lena@test.local',  'coach', 'LS Lena',  true),
  (:'coach_uid', 'ls-coach@test.local', 'coach', 'LS Coach', false);
update pruef_einstellungen set nur_pilot = true;
-- P4 (20261025210952) gibt geo_kreis_umfang ein batu_lsa-Soll; der Test braucht den Knoten ohne Soll.
delete from pruef_soll where skill_key = 'geo_kreis_umfang';

create function pg_temp.aufgabe(p_ref text, p_hints jsonb)
returns uuid language plpgsql as $$
declare v uuid;
begin
  insert into tasks (content_type, input_type, title, question, afb, cluster_id, curriculum_grade,
                     skill_key, sondierrang, source, source_ref, status, pruef_pilot)
  values ('exercise', 'NUMERIC', 'AFB II · ' || p_ref, 'Ein Kreis hat den Radius 3,6 m. Wie groß ist sein Umfang?',
          'II', (select id from skill_clusters order by id limit 1), 9, 'geo_kreis_umfang', 3,
          'lsa_session_test', p_ref, 'review', true)
  returning id into v;
  insert into task_solutions (task_id, correct_answers, acceptance, solution, hints)
  values (v, '["22,62", "22.62"]', '{"canonical": "22,62", "equivalents": ["22.62"]}', 'U = 2 · π · 3,6 m ≈ 22,62 m',
          coalesce(p_hints, '[]'));
  return v;
end $$;

create function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;
create function pg_temp.fehler(p_sql text) returns text language plpgsql as $$
declare s text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics s = returned_sqlstate;
  return s;
end $$;

select pg_temp.aufgabe('ls-mit', '[{"level": 1, "text": "Formel für den Umfang?"}]') as mit \gset
select pg_temp.aufgabe('ls-leer', '[]') as leer \gset

-- ============================================================================
-- 1 · Signatur und Rechte
-- ============================================================================
select is((select pg_get_function_result('public.pruef_board()'::regprocedure)),
  'TABLE(task_id uuid, stufe text, thema_key text, thema_label text, thema_sort integer, skill_key text, '
  'skill_label text, kurztitel text, reihenfolge bigint, lena_status text, geaendert boolean, '
  'letzte_dauer_sek integer, anlaesse text[], hat_hinweise boolean)',
  '1: pruef_board liefert die alten Spalten plus anlaesse, hat_hinweise');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
            where n.nspname = 'public' and p.proname = 'pruef_board_soll'), 1, '1: genau eine pruef_board_soll');
select ok(pg_get_function_identity_arguments('public.pruef_board_soll(text)'::regprocedure) = 'p_anlass text',
  '1: pruef_board_soll(p_anlass text)');
select ok(has_function_privilege('authenticated', 'public.pruef_board()', 'execute')
          and not has_function_privilege('anon', 'public.pruef_board()', 'execute'),
  '1: pruef_board: authenticated ja, anon nein');
select ok(has_function_privilege('authenticated', 'public.pruef_board_soll(text)', 'execute')
          and not has_function_privilege('anon', 'public.pruef_board_soll(text)', 'execute'),
  '1: pruef_board_soll: authenticated ja, anon nein');

set local role authenticated;
select pg_temp.act_as(:'coach_uid');
select is(pg_temp.fehler('select count(*) from public.pruef_board()'), '42501', '1: Coach ohne Pruefrecht → pruef_board 42501');
select is(pg_temp.fehler($$select count(*) from public.pruef_board_soll('x')$$), '42501',
  '1: Coach ohne Pruefrecht → pruef_board_soll(x) 42501');
reset role;

-- ============================================================================
-- 2 · anlaesse: aktive Anlässe des Knotens, sortiert; ohne Soll leer, nie null
-- ============================================================================
create function pg_temp.zeile(p_id uuid) returns table (anlaesse text[], hat_hinweise boolean)
language sql as $$ select b.anlaesse, b.hat_hinweise from public.pruef_board() b where b.task_id = p_id $$;

set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select anlaesse from pg_temp.zeile(:'mit')), '{}'::text[], '2: Knoten ohne Soll → leeres Array');
reset role;

insert into pruef_soll (skill_key, anlass, soll, min_ohne_mc, sort) values
  ('geo_kreis_umfang', 't_session', 7, 0, 902),
  ('geo_kreis_umfang', 't_lsa',     3, 1, 901),
  ('geo_kreis_umfang', 't_aus',     9, 0, 900);
update pruef_soll set aktiv = false where anlass = 't_aus';

set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select anlaesse from pg_temp.zeile(:'mit')), '{t_lsa,t_session}'::text[],
  '2: zwei aktive Anlässe, alphabetisch; inaktiver fehlt');
reset role;

-- Paket 3 legt später Aufgaben an: ohne weiteren Eingriff im richtigen Bereich.
select pg_temp.aufgabe('ls-spaeter', null) as spaeter \gset
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select anlaesse from pg_temp.zeile(:'spaeter')), '{t_lsa,t_session}'::text[],
  '2: später angelegte Aufgabe des Knotens trägt dieselben Anlässe');
reset role;

-- ============================================================================
-- 3 · hat_hinweise
-- ============================================================================
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select hat_hinweise from pg_temp.zeile(:'mit')), true, '3: Hinweis-Array mit Eintrag → true');
select is((select hat_hinweise from pg_temp.zeile(:'leer')), false, '3: leeres Array → false');
reset role;
set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is((select count(*)::int from public.pruef_board() where hat_hinweise is null or anlaesse is null), 0,
  '3: anlaesse und hat_hinweise sind nie null');
reset role;

-- ============================================================================
-- 4 · pruef_board_soll(p_anlass): je Anlass eigene Sollzahl, ohne Argument wie bisher
-- ============================================================================
create function pg_temp.soll(p_anlass text) returns text language sql as $$
  select k.soll || '/' || k.min_ohne_mc || ' ' || array_to_string(k.anlaesse, ',')
    from public.pruef_board_soll(p_anlass) k where k.skill_key = 'geo_kreis_umfang'
$$;

set local role authenticated;
select pg_temp.act_as(:'lena_uid');
select is(pg_temp.soll(null), '7/1 t_lsa,t_session', '4: ohne Anlass → Höchstwerte über beide (wie vor dem Nachtrag)');
select is((select k.soll || '/' || k.min_ohne_mc from public.pruef_board_soll() k where k.skill_key = 'geo_kreis_umfang'),
  '7/1', '4: Aufruf ohne Argument löst weiter auf');
select is(pg_temp.soll('t_lsa'), '3/1 t_lsa', '4: nur t_lsa → 3/1');
select is(pg_temp.soll('t_session'), '7/0 t_session', '4: nur t_session → 7/0');
select is(pg_temp.soll('t_aus'), null, '4: inaktiver Anlass → kein Knoten');
reset role;

select * from finish();
rollback;
