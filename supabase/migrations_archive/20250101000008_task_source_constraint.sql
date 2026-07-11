-- ============================================================================
-- Migration 008 – source/source_ref UNIQUE CONSTRAINT statt partial Index
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund:
--   Migration 007 hatte (source, source_ref) als PARTIAL UNIQUE INDEX
--   (WHERE source_ref IS NOT NULL) angelegt. Das blockiert PostgREST-Upsert:
--   .upsert(row, { onConflict: 'source,source_ref' }) schickt
--   ON CONFLICT (cols) ohne WHERE-Klausel und Postgres findet keinen
--   passenden Index/Constraint -> "there is no unique or exclusion
--   constraint matching the ON CONFLICT specification".
--
--   Loesung: Partial Index droppen, echten UNIQUE CONSTRAINT anlegen.
--   Funktional aequivalent — NULL != NULL gilt bei Postgres-UNIQUE auch
--   ohne partial-Klausel, mehrere Zeilen mit source_ref = NULL bleiben
--   damit erlaubt.
--
-- ⚠️  Voraussetzung: Migration 007 wurde ausgefuehrt.
-- ============================================================================

begin;

drop index if exists tasks_source_ref_unique;

alter table tasks
  add constraint tasks_source_ref_unique unique (source, source_ref);

commit;
