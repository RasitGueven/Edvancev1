-- ============================================================================
-- E3: Hinweise als KI-Entwurf für die Session-Aufgaben aus dem Szenario Batu (Migration 20261013175427).
--
-- Zusagen:
--   1) Jede Session-Aufgabe der acht Skills, die in dieser DB steht, hat Hinweise auf Stufe 1, 2 und 3 mit Text,
--      alle im Status entwurf; keiner ist geprüft. (In der CI stehen nur die 24 Aufgaben gleichung_quadr_*; die
--      25 Fundament-Aufgaben gibt es nur in Prod. Den Abgleich mit allen 49 macht tools/hinweise-e3-wegwerf-db.sh.)
--   2) Die Migration überschreibt keinen vorhandenen Hinweis und ändert beim zweiten Lauf nichts.
--   3) hinweis_abrufen liefert die Hinweise im Testlauf (T3), in einer echten Session nicht (nur geprüfte).
--   4) Kennzeichen: tasks.vorbefuellt.hints der Aufgaben gleichung_quadr_* steht auf „neu“ (Entscheidung Rasit 12.10.).
--   5) LSA ohne Hinweise (Migration 20261013173601): lsa_hint liefert nie einen Hinweis, auch keinen geprüften und
--      auch nicht für ein Testkonto; die Fehlercodes der Prüfungen davor bleiben.
-- Eigene Fixtures (session_a2_fixture), alles in einer Transaktion, am Ende rollback.
-- Lauf: npx supabase test db  (lokal: bash tools/hinweise-e3-wegwerf-db.sh <db> --tests)
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(22);

\ir session_a2_fixture.sql

create or replace function pg_temp.fehler(p_sql text) returns text language plpgsql as $f$
declare v_state text;
begin
  execute p_sql;
  return 'kein Fehler';
exception when others then
  get stacked diagnostics v_state = returned_sqlstate;
  return v_state;
end $f$;

create temp table e3_aufgaben as
  select t.id, t.skill_key from tasks t
   where t.skill_key in ('gleichung_quadr_faktor', 'gleichung_quadr_wurzel', 'gleichung_quadr_formel',
                         'gleichung_quadr_anzahl', 'gleichung_einschrittig', 'gleichung_zweischrittig',
                         'term_ausklammern', 'vorzeichen_add_sub')
     -- Reihe 1 A1 (20261027130250): der Bestand ist seitdem nur LSA; die Hinweise bleiben dieselben.
     and t.einsatz && array['lsa', 'session']
     and t.bauform_id is null;  -- Reihe 1: nur der Bestand, keine Bauform-Instanzen
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

-- ── 4) Kennzeichen für Lena ─────────────────────────────────────────────────
select is((select count(*)::int from tasks t join e3_aufgaben a on a.id = t.id
            where a.skill_key like 'gleichung_quadr\_%'
              and t.vorbefuellt -> 'hints' is distinct from
                  '{"art":"neu","grund":"E3: drei Hinweisstufen für die Session. In der LSA gibt es keine Hinweise (lsa_hint gesperrt)."}'::jsonb),
          0, '4 vorbefuellt.hints der Aufgaben gleichung_quadr_* steht auf neu');
select is((select count(*)::int from tasks t join e3_aufgaben a on a.id = t.id
            where a.skill_key like 'gleichung_quadr\_%' and t.vorbefuellt_am is null),
          0, '4 vorbefuellt_am ist gesetzt');

-- ── 5) LSA ohne Hinweise ────────────────────────────────────────────────────
-- Stufe 1 von f3 als geprüft (wie nach Lenas Freigabe); je eine LSA für das Testkonto und das echte Kind.
select set_config('edvance.hinweis_status', 'setzen', true);
update task_solutions set hints = jsonb_set(hints, '{0,status}', '"geprueft"') where task_id = :'f3';
select set_config('edvance.hinweis_status', '', true);
insert into lsa_sessions (student_id, subject, grade, item_ids) values (:'k_test', 'Mathematik', 9, array[:'f3'::uuid])
returning id as l_test \gset
insert into lsa_sessions (student_id, subject, grade, item_ids) values (:'k_echt', 'Mathematik', 9, array[:'f3'::uuid])
returning id as l_echt \gset
select is((select hints -> 0 ->> 'status' from task_solutions where task_id = :'f3'), 'geprueft',
          '5 Vorbedingung: Stufe 1 von quadrgl-faktor-03 ist geprüft');
select pg_temp.act_as(:'admin');
select is(public.lsa_hint(:'l_echt', :'f3', 1), '{"level":1,"text":null,"available":false}'::jsonb,
          '5 lsa_hint echtes Kind: auch der geprüfte Hinweis kommt nicht');
select is(public.lsa_hint(:'l_test', :'f3', 1), '{"level":1,"text":null,"available":false}'::jsonb,
          '5 lsa_hint Testkonto: kein Hinweis (auch nicht im Testmodus)');
select is(public.lsa_hint(:'l_test', :'f3', 2), '{"level":2,"text":null,"available":false}'::jsonb,
          '5 lsa_hint Testkonto: Stufe 2 ebenso');
select is(pg_temp.fehler(format('select lsa_hint(%L, %L, 1)', :'l_echt', :'f1')), 'P0001',
          '5 lsa_hint: fremdes Item weiter P0001');
select is(pg_temp.fehler(format('select lsa_hint(%L, %L, 1)', gen_random_uuid(), :'f3')), 'P0002',
          '5 lsa_hint: unbekannte Session weiter P0002');
select set_config('request.jwt.claims', '', true);

select * from finish();
rollback;
