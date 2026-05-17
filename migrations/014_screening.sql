-- ============================================================================
-- Migration 014 – screening_tests + screening_ratings
--                  + behavior_snapshots.screening_test_id
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- screening_tests: mutables Aggregat pro (Schueler, Fach). generated_test +
--   result_summary als jsonb (Reproduzierbarkeit, YAGNI statt Normalisierung).
-- screening_ratings: APPEND-ONLY (kein update/delete) – Coach-Bewertung als
--   separater Insert, damit behavior_snapshots append-only bleibt.
-- behavior_snapshots: nur additive nullable FK -> RLS-Semantik unveraendert.
-- ============================================================================

create table screening_tests (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  subject text not null,
  status text not null default 'in_progress' check (
    status in ('in_progress','completed','aborted')
  ),
  coach_id uuid references profiles (id) on delete set null,
  coach_note text,
  generated_test jsonb,
  generated_test_version smallint not null default 1,
  result_summary jsonb,
  estimated_total_minutes integer,
  started_at timestamptz,
  completed_at timestamptz
);

create index screening_tests_student_idx on screening_tests (student_id);
create index screening_tests_status_idx on screening_tests (status);

-- Verhindert doppelte aktive Tests pro (Schueler, Fach)
create unique index screening_tests_active_unique
  on screening_tests (student_id, subject)
  where status = 'in_progress';

alter table screening_tests enable row level security;

create policy "screening_tests_select_own" on screening_tests
  for select using (student_id = public.get_my_student_id());

create policy "screening_tests_parent_read" on screening_tests
  for select using (public.is_parent_of_student(student_id));

create policy "screening_tests_coach_admin_all" on screening_tests
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- ── screening_ratings (append-only) ─────────────────────────────────────────

create table screening_ratings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  behavior_snapshot_id uuid not null
    references behavior_snapshots (id) on delete cascade,
  screening_test_id uuid not null
    references screening_tests (id) on delete cascade,
  rating smallint not null check (rating in (1,2,3,4)),
  coach_id uuid references profiles (id) on delete set null
);

create index screening_ratings_snapshot_idx
  on screening_ratings (behavior_snapshot_id);
create index screening_ratings_test_idx
  on screening_ratings (screening_test_id);

alter table screening_ratings enable row level security;

-- append-only: KEIN update-, KEIN delete-Policy
create policy "screening_ratings_coach_insert" on screening_ratings
  for insert with check (public.get_my_role() in ('coach','admin'));

create policy "screening_ratings_coach_admin_read" on screening_ratings
  for select using (public.get_my_role() in ('coach','admin'));

create policy "screening_ratings_student_read" on screening_ratings
  for select using (
    screening_test_id in (
      select id from screening_tests
      where student_id = public.get_my_student_id()
    )
  );

create policy "screening_ratings_parent_read" on screening_ratings
  for select using (
    screening_test_id in (
      select id from screening_tests
      where public.is_parent_of_student(student_id)
    )
  );

-- ── behavior_snapshots: Verknuepfung zum Screening-Lauf ──────────────────────

alter table behavior_snapshots
  add column screening_test_id uuid
    references screening_tests (id) on delete cascade;

create index behavior_snapshots_screening_idx
  on behavior_snapshots (screening_test_id);
