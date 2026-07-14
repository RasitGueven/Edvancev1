-- ============================================================================
-- Migration 020 – parent_reports (Elternreport)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Coach/Admin erstellen Reports (Status draft -> published). Eltern/Schueler
-- sehen NUR veroeffentlichte Reports des eigenen Kindes/von sich.
-- ============================================================================

create table parent_reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  period_start date not null,
  period_end date not null,
  summary jsonb,
  coach_note text,
  status text not null default 'draft' check (status in ('draft','published')),
  published_at timestamptz
);

create index parent_reports_student_idx on parent_reports (student_id);

alter table parent_reports enable row level security;

create policy "parent_reports_parent_read" on parent_reports
  for select using (
    status = 'published' and public.is_parent_of_student(student_id)
  );

create policy "parent_reports_student_read" on parent_reports
  for select using (
    status = 'published' and student_id = public.get_my_student_id()
  );

create policy "parent_reports_coach_admin_all" on parent_reports
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));
