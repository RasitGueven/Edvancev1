-- ============================================================================
-- E2b: Erklärsequenzen Lineare Funktionen (Pilot, Entwurf) — Daten-Migrationen
--   20261010132749_erklaer_k8_linfkt_checks.sql und 20261010132750_erklaer_k8_linfkt.sql.
--
-- Zusagen (Nummern wie im Auftrag):
--   1) Die Migrationen laufen zweimal ohne Fehler und ohne doppelte Zeilen.
--   2) Kernideen und Schritte stehen auf entwurf (Quelle ki), Check-Aufgaben auf draft mit einsatz {check}.
--   3) Im Testlauf startet erklaer_start die Sequenz; ein falscher Check mit Fehlbild x führt zur
--      Variante mit x; außerhalb des Testlaufs liefert erklaer_start nichts (nichts freigegeben).
--   4) Kein Check taucht in der Auswahl für Session, LSA oder Quests auf.
-- Zusage 5 (Nachrechnung, Blind-Löser) prüfen tools/erklaer-rechnen.mjs und verify-tasks.mjs.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(45);

\ir session_a2_fixture.sql

create temp view e2b_stand as
select (select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt') as tasks,
       (select count(*) from task_solutions s join tasks t on t.id = s.task_id
         where t.source = 'edvance_erklaer_k8_linfkt') as loesungen,
       (select count(*) from task_figures f join tasks t on t.id = f.task_id
         where t.source = 'edvance_erklaer_k8_linfkt') as figuren,
       (select count(*) from erklaer_kernidee where skill_key like 'fkt_linear_%') as kernideen,
       (select count(*) from erklaer_schritt s join erklaer_kernidee k on k.id = s.kernidee_id
         where k.skill_key like 'fkt_linear_%') as schritte,
       (select count(*) from erklaer_check c join erklaer_kernidee k on k.id = c.kernidee_id
         where k.skill_key like 'fkt_linear_%') as checks;

-- ── 1) zweimal einspielen ──────────────────────────────────────────────────
select row_to_json(e)::text as vorher from e2b_stand e \gset
select ok((:'vorher'::jsonb ->> 'kernideen')::int > 0 and (:'vorher'::jsonb ->> 'tasks')::int > 0,
          '1 die Migrationen sind eingespielt (Kernideen und Check-Aufgaben vorhanden)');
\ir ../migrations/20261010132749_erklaer_k8_linfkt_checks.sql
\ir ../migrations/20261010132750_erklaer_k8_linfkt.sql
\ir ../migrations/20261010132749_erklaer_k8_linfkt_checks.sql
\ir ../migrations/20261010132750_erklaer_k8_linfkt.sql
select is((select row_to_json(e)::text from e2b_stand e), :'vorher', '1 zweimal erneut eingespielt: dieselben Zeilenzahlen');
select is((select count(*) from (select skill_key, nr from erklaer_kernidee group by 1, 2 having count(*) > 1) d), 0::bigint,
          '1 keine doppelte Kernidee je Skill und Nummer');
select is((select count(*) from (select source_ref from tasks where source = 'edvance_erklaer_k8_linfkt'
                                  group by 1 having count(*) > 1) d), 0::bigint, '1 keine doppelte Check-Aufgabe');
select is((:'vorher'::jsonb ->> 'loesungen')::int, (:'vorher'::jsonb ->> 'tasks')::int, '1 jede Check-Aufgabe hat genau eine Lösung');

-- ── 2) alles Entwurf ───────────────────────────────────────────────────────
select is((select count(*) from erklaer_kernidee where skill_key like 'fkt_linear_%'
            and (status <> 'entwurf' or quelle <> 'ki')), 0::bigint, '2 Kernideen: entwurf, Quelle ki');
select is((select count(*) from erklaer_schritt s join erklaer_kernidee k on k.id = s.kernidee_id
            where k.skill_key like 'fkt_linear_%' and s.status <> 'entwurf'), 0::bigint, '2 Schritte: entwurf');
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt'
            and (status <> 'draft' or einsatz <> '{check}'::text[])), 0::bigint, '2 Check-Aufgaben: draft, einsatz {check}');
select is((select count(*) from erklaer_check c join erklaer_kernidee k on k.id = c.kernidee_id
             join tasks t on t.id = c.task_id
            where k.skill_key like 'fkt_linear_%' and t.source is distinct from 'edvance_erklaer_k8_linfkt'), 0::bigint,
          '2 jeder Check ist eine neue Aufgabe dieser Charge (keine umgewidmete)');
select is((select count(*) from tasks where source = 'edvance_k8_linfkt' and einsatz <> '{lsa,session}'::text[]), 0::bigint,
          '2 die Aufgaben der Charge k8-linfkt behalten ihren Einsatz');
select is((select count(*) from erklaer_schritt s join erklaer_kernidee k on k.id = s.kernidee_id
            where k.skill_key like 'fkt_linear_%' and cardinality(s.formeln) > 0), 0::bigint,
          '2 formeln leer bis tools/formeln-svg.mjs');

-- Wie in Prod nach dem Einspielen: Cluster gesetzt (CI seedet skill_clusters erst nach den
-- Migrationen) und die Check-Figur hochgeladen (upload_figures.py setzt svg_hash).
update tasks set cluster_id = coalesce((select id from skill_clusters where id = 'edbb548a-54d9-4a8f-8be4-3052f9025524'),
                                       (select id from skill_clusters where name = 'ZZ A2 Cluster'))
 where source = 'edvance_erklaer_k8_linfkt';
update task_figures f set svg_hash = 'e2b-test' from tasks t where t.id = f.task_id and t.source = 'edvance_erklaer_k8_linfkt';
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt' and pruef_ausschluss(id) is not null), 0::bigint,
          '2 Check-Aufgaben bestehen die Prüfung wie im Lena-Board (pruef_ausschluss leer)');

-- ── 3) Testlauf: Start, Fehlbild -> Variante, außerhalb nichts ─────────────
select (select id from tasks where source_ref = 'erklaer-steigung-k1-c1') as c1,
       (select id from tasks where source_ref = 'erklaer-steigung-k2-c1') as c2,
       (select id from tasks where source_ref = 'erklaer-steigung-k3-c1') as c3,
       (select id from tasks where source_ref = 'erklaer-steigung-k1-c2') as c1b,
       (select id from tasks where source_ref = 'erklaer-steigung-k2-c2') as c2b,
       (select id from tasks where source_ref = 'erklaer-steigung-k3-c2') as c3b \gset
create or replace function pg_temp.ab(p_s uuid, p_k uuid, p_c uuid, p_text text) returns jsonb language plpgsql as $$
begin
  perform pg_temp.act_as(pg_temp.tablet(1));
  return public.erklaer_check_abgeben(p_s, p_k, p_c, jsonb_build_object('text', p_text));
end $$;
create or replace function pg_temp.kurz(x jsonb) returns text language sql as $$
  select concat_ws(' ', x ->> 'aktion', 'K' || (x -> 'kernidee' ->> 'nr'), x ->> 'variante', x ->> 'uebergang')
$$;
select is((select count(*) from erklaer_check c join erklaer_kernidee k on k.id = c.kernidee_id
            where k.skill_key = 'fkt_linear_steigung' group by c.kernidee_id order by 1 limit 1), 2::bigint,
          '3 jede Kernidee hat zwei Checks (Runde 1 und Runde 2)');

-- Kind 1: K1 Kehrwert -> B mit neuem Check; K2 Seiten verwechselt -> B; K3 b_ignoriert -> C, dann Signal.
select pg_temp.kind('ZZ E2b Eins', true) as k1 \gset
select pg_temp.neue_session(array[:'k1']::uuid[], 20, true) as s1 \gset
select pg_temp.act_as(pg_temp.tablet(1));
select erklaer_start(:'s1', :'k1', 'fkt_linear_steigung') as st \gset
select is(pg_temp.kurz(:'st'), 'start K1 A', '3 Testlauf: erklaer_start beginnt mit Kernidee 1, Variante A');
select is((:'st'::jsonb -> 'check' ->> 'task_id')::uuid, :'c1'::uuid, '3 der offene Check ist der erste Check der Kernidee 1');
select is(jsonb_array_length(:'st'::jsonb -> 'schritte'), 2, '3 Variante A: Erklärung und Beispiel');
select ok(:'st'::jsonb -> 'schritte' -> 0 -> 'bild' ->> 'url' ~ 'erklaer/bilder/[0-9a-f]{64}\.svg$', '3 Bild-URL nach der Pfadregel aus E1');
select is((:'st'::jsonb -> 'kernidee' ->> 'von')::int, 3, '3 Steigung hat 3 Kernideen');
select pg_temp.ab(:'s1', :'k1', :'c1', '1/4') as r2 \gset
select is(pg_temp.kurz(:'r2'), 'variante K1 B', '3 K1 falsch mit steigung_kehrwert -> Variante B');
select is((:'r2'::jsonb -> 'check' ->> 'task_id')::uuid, :'c1b'::uuid, '3 Runde 2 bekommt einen neuen Check (Entscheidung 18)');
select is((select fehlbild_slug from erklaer_fortschritt where session_id = :'s1' and ergebnis = 'falsch' order by id desc limit 1),
          'steigung_kehrwert', '3 Fehlbild steigung_kehrwert im Fortschritt');
select is(pg_temp.kurz(pg_temp.ab(:'s1', :'k1', :'c1b', '1,5')), 'weiter K2 A', '3 K1 Runde 2 richtig -> Kernidee 2');
select is(pg_temp.kurz(pg_temp.ab(:'s1', :'k1', :'c2', '-1,5')), 'variante K2 B', '3 K2 falsch mit seiten_verwechselt -> Variante B');
select is(pg_temp.kurz(pg_temp.ab(:'s1', :'k1', :'c2b', '-3')), 'weiter K3 A', '3 K2 Runde 2 richtig -> Kernidee 3');
select is(pg_temp.kurz(pg_temp.ab(:'s1', :'k1', :'c3', '15')), 'variante K3 C', '3 K3 falsch mit b_ignoriert -> Variante C');
select is(pg_temp.kurz(pg_temp.ab(:'s1', :'k1', :'c3b', '6')), 'signal', '3 K3 zweimal falsch -> Signal an den Coach');
select ok(not exists (select 1 from erklaer_fortschritt f join tasks t on t.id = f.check_task_id
                       where f.session_id = :'s1' and t.source <> 'edvance_erklaer_k8_linfkt'), '3 nur Checks dieser Charge');

-- Kind 2: K2 Kehrwert -> C, K3 nur_einmal_addiert -> B, K3 Runde 2 richtig -> Üben.
select pg_temp.kind('ZZ E2b Zwei', true) as k2 \gset
select pg_temp.neue_session(array[:'k2']::uuid[], 20, true) as s2 \gset
select pg_temp.act_as(pg_temp.tablet(1));
select ok(erklaer_start(:'s2', :'k2', 'fkt_linear_steigung') ->> 'aktion' = 'start', '3 Kind 2: Start');
select is(pg_temp.kurz(pg_temp.ab(:'s2', :'k2', :'c1', '4')), 'weiter K2 A', '3 Kind 2: K1 richtig');
select is(pg_temp.kurz(pg_temp.ab(:'s2', :'k2', :'c2', '2/3')), 'variante K2 C', '3 K2 falsch mit steigung_kehrwert -> Variante C');
select is(pg_temp.kurz(pg_temp.ab(:'s2', :'k2', :'c2b', '-3')), 'weiter K3 A', '3 Kind 2: K2 Runde 2 richtig');
select is(pg_temp.kurz(pg_temp.ab(:'s2', :'k2', :'c3', '4')), 'variante K3 B', '3 K3 falsch mit nur_einmal_addiert -> Variante B');
select is(pg_temp.kurz(pg_temp.ab(:'s2', :'k2', :'c3b', '14')), 'weiter ueben', '3 K3 Runde 2 richtig -> Übergang ins Üben');

-- Kind 3: K3 Kehrwert hat dort keine eigene Variante -> nächste ungezeigte (B).
select pg_temp.kind('ZZ E2b Drei', true) as k3 \gset
select pg_temp.neue_session(array[:'k3']::uuid[], 20, true) as s3 \gset
select pg_temp.act_as(pg_temp.tablet(1));
select erklaer_start(:'s3', :'k3', 'fkt_linear_steigung') is not null as gestartet \gset
select pg_temp.ab(:'s3', :'k3', :'c1', '4') is not null as k1_ok \gset
select pg_temp.ab(:'s3', :'k3', :'c2', '1.5') is not null as k2_ok \gset
select is(pg_temp.kurz(pg_temp.ab(:'s3', :'k3', :'c3', '2')), 'variante K3 B', '3 K3 Kehrwert (ohne_variante) -> nächste ungezeigte B');

-- Außerhalb des Testlaufs: nichts freigegeben -> keine Erklärung.
select pg_temp.kind('ZZ E2b Echt', false) as k4 \gset
select pg_temp.neue_session(array[:'k4']::uuid[], 20) as s4 \gset
select pg_temp.act_as(pg_temp.tablet(1));
select throws_ok(format($$select erklaer_start(%L, %L, 'fkt_linear_steigung')$$, :'s4', :'k4'), 'P0002', null,
                 '3 ohne Testlauf: erklaer_start liefert keinen Entwurf');
select is((select count(*) from erklaer_fortschritt where session_id = :'s4'), 0::bigint, '3 ohne Testlauf: kein Fortschritt');
select set_config('request.jwt.claims', '', true) is not null as zurueck \gset

-- ── 4) Checks nie in der Auswahl für Session, LSA oder Quests ──────────────
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt' and lsa_im_pool(id, false)), 0::bigint, '4 LSA-Pool: kein Check');
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt' and lsa_im_pool(id, true)), 0::bigint, '4 LSA-Pool im Testlauf: kein Check');
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt' and session_im_pool(id, false)), 0::bigint, '4 Session-Pool: kein Check');
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt' and session_im_pool(id, true)), 0::bigint, '4 Session-Pool im Testlauf: kein Check');
select is((select count(*) from tasks where source = 'edvance_erklaer_k8_linfkt' and 'quest' = any (einsatz)), 0::bigint,
          '4 Quests: kein Check (quest_aufgaben_waehlen filtert auf Einsatz quest)');
select is((select count(*) from session_schritte x join tasks t on t.id = x.task_id
            where t.source = 'edvance_erklaer_k8_linfkt'), 0::bigint, '4 in keiner Session dieses Tests als Aufgabe ausgegeben');
-- Gegenprobe: Es liegt am Einsatz. Mit Einsatz session wäre derselbe Check im Testlauf im Pool.
update tasks set einsatz = '{lsa,session}' where id = :'c2';
select ok(session_im_pool(:'c2', true) and lsa_im_pool(:'c2', true), '4 Gegenprobe: mit Einsatz lsa,session im Testlauf-Pool');
update tasks set einsatz = '{check}' where id = :'c2';
select ok(not session_im_pool(:'c2', true), '4 Gegenprobe zurückgesetzt');

-- Quest-Auswahl ausdrücklich: Kind mit Quest zum Skill bekommt keinen Check.
select ok(not exists (select 1 from pg_proc where proname = 'quest_aufgaben_waehlen'
                       and pg_get_functiondef(oid) not like '%''quest'' = any (t.einsatz)%'),
          '4 quest_aufgaben_waehlen filtert auf Einsatz quest');

select * from finish();
rollback;
