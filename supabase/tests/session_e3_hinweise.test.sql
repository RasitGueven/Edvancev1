-- ============================================================================
-- E3: Hinweise als KI-Entwurf für die Session-Aufgaben aus dem Szenario Batu (Migration 20261013175427).
--
-- Zusagen:
--   1) Jede Session-Aufgabe der acht Skills, die in dieser DB steht, hat Hinweise auf Stufe 1, 2 und 3 mit Text,
--      alle im Status entwurf; keiner ist geprüft. (In der CI stehen nur die 24 Aufgaben gleichung_quadr_*; die
--      25 Fundament-Aufgaben gibt es nur in Prod. Den Abgleich mit allen 49 macht tools/hinweise-e3-wegwerf-db.sh.)
--   2) Die Migration überschreibt keinen vorhandenen Hinweis und ändert beim zweiten Lauf nichts.
--   3) hinweis_abrufen liefert die Hinweise im Testlauf (T3), in einer echten Session nicht (nur geprüfte).
-- Eigene Fixtures (session_a2_fixture), alles in einer Transaktion, am Ende rollback.
-- Lauf: npx supabase test db  (lokal: bash tools/hinweise-e3-wegwerf-db.sh <db> --tests)
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(14);

\ir session_a2_fixture.sql

create temp table e3_aufgaben as
  select t.id, t.skill_key from tasks t
   where t.skill_key in ('gleichung_quadr_faktor', 'gleichung_quadr_wurzel', 'gleichung_quadr_formel',
                         'gleichung_quadr_anzahl', 'gleichung_einschrittig', 'gleichung_zweischrittig',
                         'term_ausklammern', 'vorzeichen_add_sub')
     and 'session' = any (t.einsatz);
select (select id from tasks where source_ref = 'quadrgl-faktor-03') as f3,
       (select id from tasks where source_ref = 'quadrgl-faktor-01') as f1 \gset

-- ── 1) Hinweise stehen als Entwurf ──────────────────────────────────────────
select cmp_ok((select count(*)::int from e3_aufgaben where skill_key like 'gleichung_quadr%'), '>=', 24,
              '1 Vorbedingung: die Session-Aufgaben gleichung_quadr_* stehen in der DB');
select is((select count(*)::int from e3_aufgaben a join task_solutions s on s.task_id = a.id
            where (select array_agg((h ->> 'level')::int order by (h ->> 'level')::int)
                     from jsonb_array_elements(s.hints) h) is distinct from array[1, 2, 3]),
          0, '1 jede Aufgabe hat genau Stufe 1, 2 und 3');
select is((select count(*)::int from e3_aufgaben a join task_solutions s on s.task_id = a.id,
                  jsonb_array_elements(s.hints) h
            where h ->> 'status' is distinct from 'entwurf' or nullif(btrim(h ->> 'text'), '') is null),
          0, '1 jeder Hinweis hat Text und steht auf entwurf (keiner geprüft)');
select is((select s.hints -> 0 ->> 'text' from task_solutions s where s.task_id = :'f3'),
          'Gesucht sind alle x, für die beide Seiten gleich sind. Teile nicht durch x, sonst geht eine Lösung verloren; bring lieber alles auf eine Seite.',
          '1 Stufe 1 von quadrgl-faktor-03 wie in der Quelle');
select is((select count(*)::int from e3_aufgaben a join task_solutions s on s.task_id = a.id,
                  jsonb_array_elements(s.hints) h where h ->> 'text' ~ '_'),
          0, '1 kein Fehlbild-Slug im Text');

-- ── 2) Kein Überschreiben, zweiter Lauf ohne Wirkung ────────────────────────
update task_solutions set hints = '[{"level":1,"text":"ZZ-E3-VORHANDEN"}]' where task_id = :'f1';
create temp table e3_vorher as select task_id, to_jsonb(s) as zeile from task_solutions s;
\ir ../migrations/20261013175427_hinweise_e3_batu.sql
select is((select hints from task_solutions where task_id = :'f1'),
          '[{"level":1,"text":"ZZ-E3-VORHANDEN","status":"entwurf"}]'::jsonb,
          '2 vorhandener Hinweis bleibt (Migration setzt nur bei hints = [])');
select is((select count(*)::int from task_solutions s join e3_vorher v using (task_id) where to_jsonb(s) <> v.zeile),
          0, '2 zweiter Lauf ändert keine Zeile in task_solutions');

-- ── 3) hinweis_abrufen: Testlauf ja, echte Session nein ─────────────────────
-- Die Wegwerf-DB kennt den Cluster aus Prod nicht; in Prod besteht f3 die Prüfung (pruef_ausschluss leer, dbread 12.10.).
update tasks set cluster_id = (select id from skill_clusters order by id limit 1) where id = :'f3' and cluster_id is null;
select is(public.pruef_ausschluss(:'f3'), null, '3 Vorbedingung: quadrgl-faktor-03 besteht die Prüfung');

select pg_temp.kind_mit('ZZ Test E3', null, '{}', '{}', true) as k_test,
       pg_temp.kind_mit('ZZ Echt E3', null, '{}') as k_echt \gset
select pg_temp.neue_session(array[:'k_test']::uuid[], 20, true) as s_tl \gset
insert into session_ausgegeben (session_id, student_id, task_id) values (:'s_tl', :'k_test', :'f3');

select pg_temp.act_as(pg_temp.tablet(1));
select is(public.hinweis_abrufen(:'s_tl', :'f3', 1) ->> 'text',
          (select hints -> 0 ->> 'text' from task_solutions where task_id = :'f3'), '3 Testlauf: Stufe 1 kommt');
select is(public.hinweis_abrufen(:'s_tl', :'f3', 2) ->> 'text',
          (select hints -> 1 ->> 'text' from task_solutions where task_id = :'f3'), '3 Testlauf: Stufe 2 kommt');
select is(public.hinweis_abrufen(:'s_tl', :'f3', 3) ->> 'text',
          (select hints -> 2 ->> 'text' from task_solutions where task_id = :'f3'), '3 Testlauf: Stufe 3 kommt');
select set_config('request.jwt.claims', '', true);

select pg_temp.neue_session(array[:'k_echt']::uuid[], 20) as s_echt \gset
insert into session_ausgegeben (session_id, student_id, task_id) values (:'s_echt', :'k_echt', :'f3');
select pg_temp.act_as(pg_temp.tablet(1));
select is(public.hinweis_abrufen(:'s_echt', :'f3', 1) - 'weitere', '{"stufe":1,"text":null,"verfuegbar":false}'::jsonb,
          '3 echte Session: Entwurf Stufe 1 nicht verfügbar');
select is(public.hinweis_abrufen(:'s_echt', :'f3', 2) - 'weitere', '{"stufe":2,"text":null,"verfuegbar":false}'::jsonb,
          '3 echte Session: Entwurf Stufe 2 nicht verfügbar');
select is(public.hinweis_abrufen(:'s_echt', :'f3', 3) - 'weitere', '{"stufe":3,"text":null,"verfuegbar":false}'::jsonb,
          '3 echte Session: Entwurf Stufe 3 nicht verfügbar');
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
