-- ============================================================================
-- Migration 007 – Aufgaben-Quelle (tasks.source + tasks.source_ref)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund:
--   Wir importieren Aufgaben aus mehreren Quellen (Mathebuch Lambacher
--   Schweizer 8 NRW, manuelle Eingaben, ggf. spaeter KI-generiert). Damit
--   wir Quellen unterscheiden und Idempotenz beim Import garantieren
--   koennen, brauchen tasks zwei neue Spalten:
--
--     - source    : kanonischer Quellen-Tag (z.B. 'mathebuch_lambacher_8_nrw')
--     - source_ref: stabiler Referenz-Schluessel innerhalb der Quelle
--                   (z.B. "kap3.s42.nr5") – garantiert eindeutig pro source
--
--   Unique-Index (source, source_ref) macht den Importer idempotent: zweites
--   Mal die gleiche Aufgabe einlesen → UPDATE statt INSERT (ON CONFLICT).
--
-- ⚠️  Voraussetzung:
--   Migration 006 wurde ausgefuehrt (sonst stehen noch serlo-Spalten drin).
-- ============================================================================

begin;

-- 1. source: Pflichtfeld, Default fuer Backfill (Tabelle ist nach 006 leer,
--    aber DEFAULT macht ALTER ADD NOT NULL trotzdem sauber).
alter table tasks
  add column if not exists source text not null default 'unbekannt';

-- 2. source_ref: optional, aber kombiniert mit source eindeutig.
alter table tasks
  add column if not exists source_ref text;

-- 3. Idempotenz-Index: zwei Aufgaben mit gleicher (source, source_ref)
--    sind verboten. Partial – greift nur wenn source_ref gesetzt ist,
--    damit manuell angelegte Aufgaben ohne source_ref erlaubt bleiben.
create unique index if not exists tasks_source_ref_unique
  on tasks (source, source_ref)
  where source_ref is not null;

-- 4. Filter-Index: schnelle Abfragen "alle Aufgaben aus Quelle X".
create index if not exists tasks_source_idx on tasks (source);

commit;
