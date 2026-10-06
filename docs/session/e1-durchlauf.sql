-- E1-Abnahme: Beispiel-Sequenz „Steigung aus dem Graphen“ in einer Wegwerf-DB.
-- Drei Kernideen, je Variante A und B (Fixture supabase/tests/session_e1_fixture.sql),
-- ein falscher und ein richtiger Check. Nur Wegwerf-DB, alles wird zurueckgerollt.
--
--   psql -X -v ON_ERROR_STOP=1 -d <wegwerf-db> -f docs/session/e1-durchlauf.sql

\pset pager off
begin;
\ir ../../supabase/tests/session_e1_fixture.sql

select set_config('request.jwt.claims',
                  json_build_object('sub', :'kind_uid', 'role', 'authenticated')::text, true) is not null as als_kind;

\echo '--- 1. Jonas startet die Erklaersequenz'
select jsonb_pretty(public.erklaer_start(:'session_id', :'kind_id', 'fkt_linear_steigung')
                    - 'check' || jsonb_build_object('check_task', 'e1-check-1')) as antwort;

\echo '--- 2. Check zu Kernidee 1, falsch (7 statt 2)'
select jsonb_pretty(x - 'schritte' - 'check'
                    || jsonb_build_object('schritte', jsonb_array_length(x -> 'schritte'))) as antwort
  from (select public.erklaer_check_abgeben(:'session_id', :'kind_id', :'check1', '{"text":"7"}') x) a;

\echo '--- 3. Check zu Kernidee 1 in Runde 2, richtig'
select jsonb_pretty(x - 'schritte' - 'check'
                    || jsonb_build_object('schritte', jsonb_array_length(x -> 'schritte'),
                                          'check_task', (select source_ref from tasks where id = (x -> 'check' ->> 'task_id')::uuid))) as antwort
  from (select public.erklaer_check_abgeben(:'session_id', :'kind_id', :'check1', '{"text":"2"}') x) a;

\echo '--- 4. Verlauf in erklaer_fortschritt (append-only); der Coach der Session sieht ihn per RLS'
select set_config('request.jwt.claims',
                  json_build_object('sub', :'coach_uid', 'role', 'authenticated')::text, true) is not null as als_coach;
set local role authenticated;
select count(*) as zeilen_fuer_coach from erklaer_fortschritt;
reset role;
select f.id, k.nr as kernidee, f.runde, f.variante, t.source_ref as check_task, f.ergebnis,
       coalesce(f.fehlbild_slug, '-') as fehlbild
  from erklaer_fortschritt f
  join erklaer_kernidee k on k.id = f.kernidee_id
  left join tasks t on t.id = f.check_task_id
 order by f.id;

\echo '--- 5. Zuhause nachlesen (nur Variante A, ohne Checks)'
select set_config('request.jwt.claims',
                  json_build_object('sub', :'kind_uid', 'role', 'authenticated')::text, true) is not null as als_kind;
select k ->> 'nr' as nr, k ->> 'titel' as titel, jsonb_array_length(k -> 'schritte') as schritte
  from jsonb_array_elements(public.erklaer_nachlesen(:'kind_id', 'fkt_linear_steigung') -> 'kernideen') k;

rollback;
