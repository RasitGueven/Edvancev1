-- ============================================================================
-- Migration 005 – Diagnostic-Felder fuer tasks + microskills
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Hintergrund: Diagnosetest-Generator (PRD v1.1) braucht zusaetzliche
-- strukturierte Felder pro Task (Schwierigkeitsdimension, Input-Typ,
-- Diagnostik-Marker, Curriculum-Referenz) und pro Microskill
-- (cognitive_type, geschaetzte Bearbeitungszeit, Curriculum-Referenz).
-- ============================================================================

-- ── Microskills ─────────────────────────────────────────────────────────────

alter table microskills add column if not exists cognitive_type text
  check (cognitive_type in ('FACT', 'TRANSFER', 'ANALYSIS'));

alter table microskills add column if not exists estimated_minutes integer;

alter table microskills add column if not exists curriculum_ref text;

-- ── Tasks ───────────────────────────────────────────────────────────────────

alter table tasks add column if not exists cognitive_type text
  check (cognitive_type in ('FACT', 'TRANSFER', 'ANALYSIS'));

alter table tasks add column if not exists input_type text
  check (input_type in ('MC', 'FREE_INPUT', 'STEPS', 'MATCHING', 'DRAW'));

alter table tasks add column if not exists is_diagnostic boolean default false;

alter table tasks add column if not exists curriculum_ref text;

alter table tasks add column if not exists question_payload jsonb;

alter table tasks add column if not exists typical_errors text[];

-- ── Indexes fuer Diagnostic-Pickup ──────────────────────────────────────────

create index if not exists tasks_diagnostic_idx
  on tasks (is_diagnostic) where is_diagnostic = true;

create index if not exists tasks_microskill_diagnostic_idx
  on tasks (microskill_id, is_diagnostic, difficulty)
  where is_diagnostic = true;

-- Hinweis: 'competency_level' ist im PRD ein 1|2|3 Wert. Wir nutzen
-- die existierende 'difficulty' Spalte (1-5) und mappen 1-2 → level 1,
-- 3 → level 2, 4-5 → level 3 in src/lib/diagnostic/generator.ts.
-- Falls strenge 1|2|3 gewuenscht: separate Spalte 'competency_level'
-- in einer Folge-Migration.
