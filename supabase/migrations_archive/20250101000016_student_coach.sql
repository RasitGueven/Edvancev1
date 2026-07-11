-- ============================================================================
-- Migration 016 – student_coach (Schueler<->Coach-Zuordnung)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Zuweisung ist Admin-Aufgabe (PROCESSES: Planung & Zuweisung). Coach liest
-- eigene Zuordnungen; Schueler/Eltern lesen die eigene.
-- ============================================================================

create table student_coach (
  student_id uuid not null references students (id) on delete cascade,
  coach_id uuid not null references profiles (id) on delete cascade,
  assigned_at timestamptz default now(),
  active boolean not null default true,
  primary key (student_id, coach_id)
);

create index student_coach_coach_idx on student_coach (coach_id);

alter table student_coach enable row level security;

create policy "student_coach_select_own" on student_coach
  for select using (student_id = public.get_my_student_id());

create policy "student_coach_parent_read" on student_coach
  for select using (public.is_parent_of_student(student_id));

create policy "student_coach_coach_read" on student_coach
  for select using (coach_id = auth.uid());

create policy "student_coach_admin_all" on student_coach
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
