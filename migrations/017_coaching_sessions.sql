-- ============================================================================
-- Migration 017 – coaching_sessions + session_students (Session-Betrieb)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Ersetzt MOCK_SESSIONS (lib/mockData.ts) im CoachDashboard.
-- Coach verwaltet eigene Sessions + Anwesenheit; Schueler/Eltern lesen
-- die Sessions, in denen der Schueler eingetragen ist.
--
-- WICHTIG: Beide Tabellen werden ZUERST angelegt, dann die Policies –
-- coaching_sessions_student_read referenziert session_students und
-- session_students_coach_rw referenziert coaching_sessions.
-- ============================================================================

create table coaching_sessions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  coach_id uuid not null references profiles (id) on delete cascade,
  room text,
  scheduled_at timestamptz not null,
  status text not null default 'upcoming' check (
    status in ('upcoming','active','done')
  )
);

create table session_students (
  session_id uuid not null
    references coaching_sessions (id) on delete cascade,
  student_id uuid not null references students (id) on delete cascade,
  attendance text not null default 'unknown' check (
    attendance in ('present','absent','unknown')
  ),
  primary key (session_id, student_id)
);

create index coaching_sessions_coach_idx on coaching_sessions (coach_id);
create index coaching_sessions_scheduled_idx
  on coaching_sessions (scheduled_at);
create index session_students_student_idx
  on session_students (student_id);

alter table coaching_sessions enable row level security;
alter table session_students enable row level security;

-- ── coaching_sessions Policies ──────────────────────────────────────────────

create policy "coaching_sessions_coach_rw" on coaching_sessions
  for all
  using (coach_id = auth.uid())
  with check (coach_id = auth.uid());

create policy "coaching_sessions_admin_all" on coaching_sessions
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

create policy "coaching_sessions_student_read" on coaching_sessions
  for select using (
    id in (
      select session_id from session_students
      where student_id = public.get_my_student_id()
    )
  );

-- ── session_students Policies ───────────────────────────────────────────────

create policy "session_students_select_own" on session_students
  for select using (student_id = public.get_my_student_id());

create policy "session_students_parent_read" on session_students
  for select using (public.is_parent_of_student(student_id));

create policy "session_students_coach_rw" on session_students
  for all
  using (
    session_id in (
      select id from coaching_sessions where coach_id = auth.uid()
    )
  )
  with check (
    session_id in (
      select id from coaching_sessions where coach_id = auth.uid()
    )
  );

create policy "session_students_admin_all" on session_students
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
