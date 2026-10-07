-- ============================================================================
-- Session-P1 Paket E1: Erklaersequenz, Hinweis-Status (Bauauftrag Tests 1 bis 9).
--
-- Fixture: session_e1_fixture.sql („Steigung aus dem Graphen“, drei Kernideen,
-- je Variante A und B; Kernidee 2 Variante B fuer steigung_kehrwert).
-- Antworten der Erklaerfunktionen duerfen nie die Loesung (Sentinel LOESUNG-E1),
-- nie einen Entwurf (Sentinel ENTWURF-E1) und nie ein Fehlbild enthalten.
-- ============================================================================
begin;
create extension if not exists pgtap with schema extensions;

select plan(38);

\ir session_e1_fixture.sql

create or replace function pg_temp.act_as(uid uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims', json_build_object('sub', uid, 'role', 'authenticated')::text, true);
end $$;

create temp table e1_antwort (nr serial, fall text, antwort jsonb);
grant all on e1_antwort, e1_antwort_nr_seq to authenticated;

-- --- 1  erklaer_start liefert keinen Entwurf -----------------------------------
select pg_temp.act_as(:'kind_uid');

select throws_ok(
  format($f$select public.erklaer_start(%L, %L, 'fkt_linear_steigung_nur_entwurf')$f$, :'session_id', :'kind_id'),
  'P0002', null,
  '1a erklaer_start: Skill nur mit Entwuerfen liefert nichts (P0002)');

insert into e1_antwort (fall, antwort)
select 'start', public.erklaer_start(:'session_id', :'kind_id', 'fkt_linear_steigung');

select is((select antwort ->> 'aktion' from e1_antwort where fall = 'start'), 'start', '1b erklaer_start: aktion start');
select is((select antwort -> 'kernidee' ->> 'nr' from e1_antwort where fall = 'start'), '1', '1c erste Kernidee');
select is((select antwort ->> 'variante' from e1_antwort where fall = 'start'), 'A', '1d Variante A');
select is((select jsonb_array_length(antwort -> 'schritte') from e1_antwort where fall = 'start'), 2,
          '1e Erklaerschritt und Beispiel');
select is((select antwort -> 'check' ->> 'task_id' from e1_antwort where fall = 'start'), :'check1', '1f Check der Kernidee 1');
select ok((select antwort::text not like '%ENTWURF-E1%' from e1_antwort where fall = 'start'),
          '1g kein Entwurfstext in der Antwort');
select alike((select antwort -> 'schritte' -> 0 -> 'formeln' ->> 0 from e1_antwort where fall = 'start'),
            '%/task-assets/erklaer/formeln/%.svg', '1h Formel nur als SVG-URL');
select is((select antwort ->> 'kernidee' from e1_antwort where fall = 'start'),
          (select antwort ->> 'kernidee' from (select public.erklaer_start(:'session_id', :'kind_id', 'fkt_linear_steigung') antwort) x),
          '1i zweiter Start nimmt dieselbe Stelle wieder auf');

-- --- 4  Falsch ohne passende Variante -> naechste ungezeigte --------------------
insert into e1_antwort (fall, antwort)
select 'k1_falsch', public.erklaer_check_abgeben(:'session_id', :'kind_id', :'check1', '{"text":"7"}');

select is((select antwort ->> 'aktion' from e1_antwort where fall = 'k1_falsch'), 'variante', '4a falsch -> variante');
select is((select antwort ->> 'variante' from e1_antwort where fall = 'k1_falsch'), 'B',
          '4b ohne passendes Fehlbild: naechste ungezeigte Variante (B, nicht der Entwurf C)');
select is((select antwort ->> 'runde' from e1_antwort where fall = 'k1_falsch'), '2', '4c Runde 2');

-- --- 2  Richtiger Check -> weiter ------------------------------------------------
insert into e1_antwort (fall, antwort)
select 'k1_richtig', public.erklaer_check_abgeben(:'session_id', :'kind_id', :'check1', '{"text":"2"}');

select is((select antwort ->> 'aktion' from e1_antwort where fall = 'k1_richtig'), 'weiter', '2a richtig -> weiter');
select is((select antwort -> 'kernidee' ->> 'nr' from e1_antwort where fall = 'k1_richtig'), '2', '2b naechste Kernidee');
select is((select antwort ->> 'variante' from e1_antwort where fall = 'k1_richtig'), 'A', '2c beginnt mit Variante A');

select throws_ok(
  format($f$select public.erklaer_check_abgeben(%L, %L, %L, '{"text":"2"}')$f$, :'session_id', :'kind_id', :'check1'),
  'P0001', null, '2d alter Check ist nicht mehr offen');

-- Check inzwischen nicht mehr freigegeben: weder Wiederaufnahme noch Abgabe liefern ihn aus.
reset role;
update tasks set status = 'review' where id = :'check2';
select pg_temp.act_as(:'kind_uid');
select throws_ok(
  format($f$select public.erklaer_start(%L, %L, 'fkt_linear_steigung')$f$, :'session_id', :'kind_id'),
  'P0002', null, '2e Wiederaufnahme mit nicht mehr freigegebenem Check -> P0002');
select throws_ok(
  format($f$select public.erklaer_check_abgeben(%L, %L, %L, '{"text":"0,5"}')$f$, :'session_id', :'kind_id', :'check2'),
  'P0002', null, '2f Abgabe auf nicht mehr freigegebenen Check -> P0002');
reset role;
update tasks set status = 'ready' where id = :'check2';
select pg_temp.act_as(:'kind_uid');

-- --- 3  Falsch mit Fehlbild x -> Variante mit x in fehlbild_slugs -----------------
insert into e1_antwort (fall, antwort)
select 'k2_kehrwert', public.erklaer_check_abgeben(:'session_id', :'kind_id', :'check2', '{"text":"2"}');

select is((select antwort ->> 'variante' from e1_antwort where fall = 'k2_kehrwert'), 'B',
          '3a Fehlbild steigung_kehrwert -> Variante B');
select ok((select antwort::text not like '%kehrwert%' from e1_antwort where fall = 'k2_kehrwert'),
          '3b Fehlbild steht nicht in der Antwort ans Kind');

-- --- 5  Zweimal falsch in derselben Kernidee -> signal ---------------------------
insert into e1_antwort (fall, antwort)
select 'k2_signal', public.erklaer_check_abgeben(:'session_id', :'kind_id', :'check2', '{"text":"2"}');

select is((select antwort from e1_antwort where fall = 'k2_signal'), '{"aktion":"signal"}'::jsonb,
          '5a zweite falsche Runde -> signal');
reset role;
select is((select array_agg(ergebnis || ':' || coalesce(fehlbild_slug, '-') order by id)
             from erklaer_fortschritt where student_id = :'kind_id'),
          array['gezeigt:-', 'falsch:-', 'gezeigt:-', 'richtig:-', 'gezeigt:-',
                'falsch:steigung_kehrwert', 'gezeigt:-', 'falsch:steigung_kehrwert', 'signal:steigung_kehrwert'],
          '5b Fortschritt append-only mit Fehlbild');
select throws_ok($$delete from erklaer_fortschritt$$, '42501', null, '5c erklaer_fortschritt ist append-only');

-- --- 6  Antworten enthalten nie die Loesung -------------------------------------
select is((select count(*)::int from e1_antwort where antwort::text like '%LOESUNG-E1%'), 0,
          '6a keine Antwort enthaelt den Loesungs-Sentinel');
select is((select count(*)::int from e1_antwort
            where antwort::text ~ '"(correct|correct_answers|solution|acceptance|known_errors|richtig|fehlbild)"'), 0,
          '6b keine Antwort enthaelt Loesungs-, Urteils- oder Fehlbildfelder');

-- --- 7  lsa_hint liefert keinen Hinweis im Status entwurf ------------------------
insert into lsa_sessions (student_id, subject, grade, item_ids)
values (:'kind_id', 'Mathematik', 8, array[:'check1'::uuid]);
select (select id from lsa_sessions where student_id = :'kind_id') as lsa_sid
\gset
select pg_temp.act_as(:'kind_uid');
select is(public.lsa_hint(:'lsa_sid', :'check1', 1) ->> 'available', 'false', '7a Hinweis im Entwurf: nicht verfuegbar');
select is(public.lsa_hint(:'lsa_sid', :'check1', 2) ->> 'text', 'Geh einen Schritt nach rechts.', '7b gepruefter Hinweis kommt');
reset role;
update task_solutions set hints = '[{"level":1,"text":"HINWEIS-ENTWURF-E1"},{"level":2,"text":"Neuer Text"}]'
 where task_id = :'check1';
select is(public.lsa_hint(:'lsa_sid', :'check1', 2) ->> 'available', 'false', '7c geaenderter Text faellt auf entwurf');
select pg_temp.act_as(:'admin_uid');
select public.task_solution_upsert(:'check1',
  p_hints => '[{"level":1,"text":"HINWEIS-ENTWURF-E1","status":"geprueft"}]'::jsonb);
select is((select hints -> 0 ->> 'status' from task_solutions where task_id = :'check1'), 'entwurf',
          '7d Admin-Editor kann den Status nicht am Pruefweg vorbei auf geprueft setzen');
reset role;
insert into task_solutions (task_id, correct_answers, hints)
values (:'check3', '["-2"]', '[{"level":1,"text":"neu","status":"geprueft"}]')
on conflict (task_id) do update set hints = excluded.hints;
select is((select hints -> 0 ->> 'status' from task_solutions where task_id = :'check3'), 'entwurf',
          '7e neuer Hinweis mit mitgeschicktem Status bleibt entwurf');

-- --- 8  erklaer_nachlesen liefert keine Checks ----------------------------------
select pg_temp.act_as(:'kind_uid');
select is((select jsonb_array_length(public.erklaer_nachlesen(:'kind_id', 'fkt_linear_steigung') -> 'kernideen')), 3,
          '8a drei Kernideen zum Nachlesen');
select ok((select public.erklaer_nachlesen(:'kind_id', 'fkt_linear_steigung')::text !~ '"check"|e1-check|LOESUNG-E1|Variante B|ENTWURF-E1'),
          '8b nur Variante A, keine Checks, kein Entwurf');

-- --- 9  Schuelerkonto schreibt weder Kernideen noch Schritte noch Hinweis-Status --
select throws_ok(
  $$select public.erklaer_kernidee_speichern(null, 'fkt_linear_steigung', 4, 'Kind', 'mensch')$$,
  '42501', null, '9a Kind: erklaer_kernidee_speichern -> 42501');
select throws_ok(
  format($f$select public.erklaer_schritt_speichern(%L, 'A', 'erklaerung', 'Kind', null, '{}')$f$,
         (select id from erklaer_kernidee where skill_key = 'fkt_linear_steigung' and nr = 1)),
  '42501', null, '9b Kind: erklaer_schritt_speichern -> 42501');
select throws_ok(
  format($f$select public.hinweis_status_setzen(%L, 1, 'geprueft')$f$, :'check1'),
  '42501', null, '9c Kind: hinweis_status_setzen -> 42501');
set local role authenticated;
select throws_ok($$insert into erklaer_kernidee (skill_key, nr, titel) values ('fkt_linear_steigung', 5, 'x')$$,
  '42501', null, '9d Kind: direkter Insert in erklaer_kernidee -> 42501');
reset role;

-- Session mit Lernverlauf: nicht loeschbar. Kind geloescht: Fortschritt geht per Kaskade mit.
-- Postgres 16 (CI) meldet 23503, ab 18 kommt 23001: deshalb der Constraint-Name statt des Codes.
-- Als Systemaufruf: Seit R1 (20261007110200, coaching_sessions_loeschschutz) loescht eine
-- gestartete Session nur Admin oder System; geprueft wird hier der Fremdschluessel dahinter.
select set_config('request.jwt.claims', json_build_object('role', 'service_role')::text, true);
select throws_matching(format($f$delete from coaching_sessions where id = %L$f$, :'session_id'),
  -- Seit A2 schreibt erklaer_check_abgeben auch session_ereignisse; welcher restrict-Schluessel zuerst greift, ist offen.
  '(erklaer_fortschritt|session_ereignisse)_session_id_fkey', '5d Session mit Lernverlauf ist nicht loeschbar (restrict)');
delete from lsa_sessions where student_id = :'kind_id';
delete from students where id = :'kind_id';
select is((select count(*)::int from erklaer_fortschritt where student_id = :'kind_id'), 0,
          '5e Kind geloescht: Fortschritt per Kaskade entfernt');

select * from finish();
rollback;
