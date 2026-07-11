-- ============================================================================
-- Migration 006 – Serlo komplett entfernen
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund:
--   Serlo war die erste Aufgabenquelle in der Pre-Launch-Phase. Wir steigen
--   auf eine eigene Aufgabenpipeline um (Lambacher Schweizer 8. Klasse NRW
--   als Erstquelle). Damit fliegt Serlo komplett raus:
--     - alle Serlo-getaggten Aufgaben loeschen (cascadiert task_coach_metadata
--       und behavior_snapshots mit, ist abgestimmt: Snapshots sind Testdaten)
--     - alle serlo_*-Spalten auf tasks / skill_clusters / subjects droppen
--
-- ⚠️  Cascade-Verhalten:
--   - tasks.serlo_uuid IS NOT NULL    → tasks geloescht
--   - task_coach_metadata.task_id     → cascade delete
--   - behavior_snapshots.task_id      → cascade delete (Snapshots sind
--     normalerweise append-only, hier explizit abgesegnet als Testdaten-Reset)
--
-- ⚠️  Reihenfolge:
--   Erst Daten loeschen, dann Spalten droppen.
-- ============================================================================

begin;

-- 1. Alle Serlo-Aufgaben loeschen (cascadiert Coach-Metadata + Snapshots)
delete from tasks
where serlo_uuid is not null;

-- 2. Spalten auf tasks droppen
alter table tasks drop column if exists serlo_uuid;
alter table tasks drop column if exists serlo_url;
alter table tasks drop column if exists serlo_video_url;
alter table tasks drop column if exists serlo_content_raw;

-- 3. Spalte auf skill_clusters droppen
alter table skill_clusters drop column if exists serlo_taxonomy_id;

-- 4. Spalte auf subjects droppen
alter table subjects drop column if exists serlo_id;

commit;
