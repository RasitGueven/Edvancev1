-- ============================================================================
-- Migration 011 – RLS-Fix students / student_subjects / parent_student
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Hintergrund / kritischer latenter Bug:
--   schema.sql aktiviert RLS auf students, parent_student, student_subjects
--   (Z. 51-54), definiert aber NUR Policies fuer profiles (Z. 57-70).
--   Folge: students/parent_student/student_subjects sind default-deny – KEIN
--   Client kann sie lesen/schreiben. Jede RLS, die ueber students.profile_id
--   joint, liefert leer. Dieser Fix legt die fehlenden Policies an und stellt
--   zwei nicht-rekursive Security-Definer-Helper bereit, die das gesamte
--   Real-Data-Programm (leads, intake_sessions, screening_tests, ...) nutzt.
--
-- Ausfuehrung: Manuell im Supabase SQL Editor.
-- ============================================================================

-- ── Security-Definer-Helper (verhindern Policy-Rekursion) ───────────────────

-- Eigene students.id ohne RLS (Spiegel von public.get_my_role()).
create or replace function public.get_my_student_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from students where profile_id = auth.uid() limit 1;
$$;

-- Ist der eingeloggte User Elternteil dieses Schuelers (students-PK)?
-- parent_student.student_id referenziert profiles(id); students.profile_id
-- ist die Schueler-Profil-ID. Security-Definer umgeht RLS der inneren Joins.
create or replace function public.is_parent_of_student(p_student_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from parent_student ps
    where ps.parent_id = auth.uid()
      and ps.student_id in (
        select profile_id from students where id = p_student_id
      )
  );
$$;

-- ── students ────────────────────────────────────────────────────────────────

create policy "students_select_own" on students
  for select using (profile_id = auth.uid());

create policy "students_parents_read" on students
  for select using (public.is_parent_of_student(id));

create policy "students_coach_admin_all" on students
  for all
  using (public.get_my_role() in ('coach', 'admin'))
  with check (public.get_my_role() in ('coach', 'admin'));

-- ── parent_student ──────────────────────────────────────────────────────────

create policy "parent_student_parent_read" on parent_student
  for select using (parent_id = auth.uid());

create policy "parent_student_student_read" on parent_student
  for select using (student_id = auth.uid());

create policy "parent_student_coach_admin_all" on parent_student
  for all
  using (public.get_my_role() in ('coach', 'admin'))
  with check (public.get_my_role() in ('coach', 'admin'));

-- ── student_subjects ────────────────────────────────────────────────────────

create policy "student_subjects_select_own" on student_subjects
  for select using (student_id = public.get_my_student_id());

create policy "student_subjects_parents_read" on student_subjects
  for select using (public.is_parent_of_student(student_id));

create policy "student_subjects_coach_admin_all" on student_subjects
  for all
  using (public.get_my_role() in ('coach', 'admin'))
  with check (public.get_my_role() in ('coach', 'admin'));
