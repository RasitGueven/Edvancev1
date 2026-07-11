-- ============================================================================
-- Migration 004 – serlo_content_raw Spalte fuer ExerciseGroup + Course
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund:
--   exercise_group (Mini-Tests) und course (Kurse) bestehen aus mehreren
--   Sub-Items. Eine eigene relationale Modellierung waere overkill fuer
--   die Pre-Launch-Phase – wir speichern die Sub-Struktur als JSON.
--
--   Diese Migration legt die Spalte an. Import-Script und TaskPlayer-
--   Rendering folgen separat (TODO: ExerciseGroup/Course GraphQL fragments
--   in import-serlo.ts, Subtask-Iteration in TaskPlayer).
-- ============================================================================

alter table tasks add column if not exists serlo_content_raw jsonb;
