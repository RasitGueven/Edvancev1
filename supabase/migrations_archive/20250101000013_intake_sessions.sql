-- ============================================================================
-- Migration 013 – intake_sessions (Erstgespraech Stufe B: strukturiertes
--                  Protokoll am bereits angelegten Schueler)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Mutabel (Status draft -> final). Coach/Admin Vollzugriff; Eltern lesen
-- das Protokoll des eigenen Kindes (via Security-Definer is_parent_of_student).
-- ============================================================================

create table intake_sessions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  lead_id uuid references leads (id) on delete set null,
  coach_id uuid references profiles (id) on delete set null,
  conducted_at timestamptz,
  goals text,
  motivation text,
  learning_history text,
  parent_expectations text,
  known_weak_topics text[] default '{}',
  agreed_next_steps text,
  notes text,
  status text not null default 'draft' check (status in ('draft','final'))
);

create index intake_sessions_student_idx on intake_sessions (student_id);

alter table intake_sessions enable row level security;

create policy "intake_sessions_coach_admin_all" on intake_sessions
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

create policy "intake_sessions_parent_read" on intake_sessions
  for select using (public.is_parent_of_student(student_id));
