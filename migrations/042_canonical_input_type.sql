-- ============================================================================
-- Migration 042 – Kanonischer input_type-Enum (Antwort-Vertrag, Foundation)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Ziel: tasks.input_type und screening_items.input_type auf EINEN kanonischen
-- Enum (genau 8 Werte) vereinheitlichen, auf den QS-Tool, DB, Renderer-Registry
-- und Evaluator (src/lib/answer/evaluators.ts) gemeinsam zugreifen.
--
--   MC | NUMERIC | SHORT_TEXT | TRUE_FALSE | FREE_TEXT | MATCHING | CLOZE | COORDINATE
--
-- NICHT-DESTRUKTIV: nur Remap bestehender Werte + CHECK-Constraints. Keine
-- Spalte neu, keine Daten geloescht. Bestehende JSONB-Spalten (question_payload,
-- payload, canonical) bleiben unveraendert.
--
-- Remap:
--   tasks:           FREE_INPUT→FREE_TEXT, STEPS→FREE_TEXT, DRAW→COORDINATE
--                    (MC, MATCHING, NUMERIC unveraendert)
--   screening_items: STEPS_FINAL→FREE_TEXT, OPEN→FREE_TEXT
--                    (MC, NUMERIC, MATCHING unveraendert)
--
-- ⚠️  STEPS / STEPS_FINAL / DRAW sind grobe Remaps — siehe
--     docs/INPUT_TYPE_CANON.md ("spaeter verfeinern").
-- ============================================================================

-- ── 0. Bestand ZAEHLEN (vor dem Remap) — Ergebnis in INPUT_TYPE_CANON.md ──────
--    Diese SELECTs nur zur Doku ausfuehren; sie veraendern nichts.
select 'tasks.input_type' as col, coalesce(input_type, '∅NULL') as value, count(*)
  from tasks group by input_type
union all
select 'screening_items.input_type', input_type, count(*)
  from screening_items group by input_type
union all
select 'screening_items.check_type', check_type, count(*)
  from screening_items group by check_type
order by col, value;

-- ── 1. tasks.input_type ──────────────────────────────────────────────────────
alter table tasks drop constraint if exists tasks_input_type_check;

update tasks
   set input_type = case input_type
     when 'FREE_INPUT' then 'FREE_TEXT'
     when 'STEPS'      then 'FREE_TEXT'
     when 'DRAW'       then 'COORDINATE'
     else input_type
   end
 where input_type in ('FREE_INPUT', 'STEPS', 'DRAW');

alter table tasks
  add constraint tasks_input_type_check check (
    input_type in (
      'MC', 'NUMERIC', 'SHORT_TEXT', 'TRUE_FALSE',
      'FREE_TEXT', 'MATCHING', 'CLOZE', 'COORDINATE'
    )
  );

-- ── 2. screening_items.input_type ────────────────────────────────────────────
-- Die Cross-Constraint OPEN<=>manual (028) faellt: OPEN (manual/coach) und
-- STEPS_FINAL (normalized/auto) kollabieren beide nach FREE_TEXT, d.h. FREE_TEXT
-- spannt jetzt Auto- UND Coach-Bewertung. Die Auto/Coach-Unterscheidung lebt
-- ab hier ausschliesslich in check_type (der Screening-Grader grade.ts schaltet
-- ohnehin auf check_type, nicht auf input_type). check_type-Vokabular bleibt
-- unveraendert (mc_index|numeric|matching_set|normalized|manual).
alter table screening_items drop constraint if exists screening_items_open_iff_manual;
alter table screening_items drop constraint if exists screening_items_input_type_check;

update screening_items
   set input_type = case input_type
     when 'STEPS_FINAL' then 'FREE_TEXT'
     when 'OPEN'        then 'FREE_TEXT'
     else input_type
   end
 where input_type in ('STEPS_FINAL', 'OPEN');

alter table screening_items
  add constraint screening_items_input_type_check check (
    input_type in (
      'MC', 'NUMERIC', 'SHORT_TEXT', 'TRUE_FALSE',
      'FREE_TEXT', 'MATCHING', 'CLOZE', 'COORDINATE'
    )
  );

-- ── 3. Kontrolle (nach dem Remap) ────────────────────────────────────────────
select 'tasks.input_type' as col, coalesce(input_type, '∅NULL') as value, count(*)
  from tasks group by input_type
union all
select 'screening_items.input_type', input_type, count(*)
  from screening_items group by input_type
order by col, value;
