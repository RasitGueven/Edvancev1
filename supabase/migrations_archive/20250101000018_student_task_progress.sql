-- ============================================================================
-- Migration 018 – student_task_progress (Aufgaben-Fortschritt)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Ersetzt localStorage 'edvance_task_progress_v1' (ClusterView). Schueler
-- liest/schreibt eigenen Fortschritt; Eltern/Coach/Admin lesen.
-- Hinweis: Anwendung NACH Migration 017 (numerisch nicht zusammenhaengend,
-- aber keine Abhaengigkeit auf 017).
-- ============================================================================

create table student_task_progress (
  student_id uuid not null references students (id) on delete cascade,
  task_id uuid not null references tasks (id) on delete cascade,
  completed_at timestamptz default now(),
  primary key (student_id, task_id)
);

create index student_task_progress_student_idx
  on student_task_progress (student_id);

alter table student_task_progress enable row level security;

create policy "student_task_progress_own_rw" on student_task_progress
  for all
  using (student_id = public.get_my_student_id())
  with check (student_id = public.get_my_student_id());

create policy "student_task_progress_parent_read" on student_task_progress
  for select using (public.is_parent_of_student(student_id));

create policy "student_task_progress_coach_admin_read" on student_task_progress
  for select using (public.get_my_role() in ('coach','admin'));
