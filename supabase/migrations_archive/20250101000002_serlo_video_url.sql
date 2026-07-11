-- ============================================================================
-- Migration 002 – Eigene Spalte fuer Serlo-Video-URLs
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund:
--   Im ersten Wurf hat import-serlo.ts die Video-URL ins question-Feld
--   geschrieben (semantisch verwirrend). Diese Migration:
--     1. fuegt eine eigene Spalte serlo_video_url hinzu
--     2. backfillt bestehende Video-Tasks: question → serlo_video_url
--   Anschliessend kann import-serlo.ts dauerhaft die richtige Spalte fuellen.
-- ============================================================================

alter table tasks add column if not exists serlo_video_url text;

-- Backfill: bisherige Video-URLs aus question-Feld in serlo_video_url uebernehmen.
update tasks
set serlo_video_url = question,
    question = null
where content_type = 'video'
  and serlo_video_url is null
  and question is not null;
