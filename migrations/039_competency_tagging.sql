-- ============================================================================
-- Migration 039 – competency_id-Tagging an Inhalten (Achse B)
--
-- Manueller Schritt: Im Supabase SQL Editor ausfuehren.
--
-- Haengt die Prozesskompetenz (Achse B) an Inhalte. Nullable, weil der
-- inhaltliche Backfill Content-Arbeit ist (Lena) und nicht geraten wird.
-- ============================================================================

alter table public.tasks
  add column if not exists competency_id uuid
  references public.process_competencies(id) on delete set null;

alter table public.screening_items
  add column if not exists competency_id uuid
  references public.process_competencies(id) on delete set null;

create index if not exists tasks_competency_idx
  on public.tasks (competency_id);
create index if not exists screening_items_competency_idx
  on public.screening_items (competency_id);

-- Hinweis: screening_items.kompetenzfelder (text[]) bleibt erhalten
-- (Historie / VERA-8). competency_id ist ab hier die strukturierte Wahrheit
-- der Prozesskompetenz-Zuordnung; kompetenzfelder ist nur noch Legacy/Quelle.
comment on column public.screening_items.competency_id is
  'Strukturierte Wahrheit der Prozesskompetenz (Achse B). kompetenzfelder (text[]) bleibt als Legacy/VERA-8-Historie erhalten.';
