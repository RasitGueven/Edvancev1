-- ============================================================================
-- Migration 022 – screening_items + screening_item_results
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explizit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- screening_items: eigene, autogradebare Screening-Item-Bank (getrennt von
--   tasks/Lerninhalten). Pro atomarem Mikroskill je Stufe L1/L2/L3.
--   Nur active=true ist fuer Schueler sichtbar; Admin reviewt/aktiviert.
-- screening_item_results: APPEND-ONLY Auto-Grade-Ergebnis pro Item/Lauf.
-- ============================================================================

create table screening_items (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  cluster_id uuid not null references skill_clusters (id) on delete cascade,
  class_level integer not null check (class_level between 5 and 13),
  topic text not null,
  skill_code text not null,
  skill_label text not null,
  level smallint not null check (level in (1, 2, 3)),
  curriculum_seq integer,
  input_type text not null check (
    input_type in ('MC','NUMERIC','MATCHING','STEPS_FINAL')
  ),
  prompt text not null,
  payload jsonb,
  canonical jsonb not null,
  check_type text not null check (
    check_type in ('mc_index','numeric','matching_set','normalized')
  ),
  tolerance numeric,
  typical_errors text[] default '{}',
  explanation text,
  source text not null default 'edvance_original',
  active boolean not null default false
);

create index screening_items_cluster_idx on screening_items (cluster_id);
create index screening_items_active_idx on screening_items (active);
create index screening_items_cluster_level_idx
  on screening_items (cluster_id, level) where active = true;
create index screening_items_skill_idx on screening_items (skill_code);

alter table screening_items enable row level security;

create policy "screening_items_read_active" on screening_items
  for select using (auth.role() = 'authenticated' and active = true);

create policy "screening_items_admin_all" on screening_items
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

create policy "screening_items_coach_read" on screening_items
  for select using (public.get_my_role() in ('coach','admin'));

-- ── screening_item_results (append-only) ────────────────────────────────────

create table screening_item_results (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  screening_test_id uuid not null
    references screening_tests (id) on delete cascade,
  screening_item_id uuid not null
    references screening_items (id) on delete cascade,
  cluster_id uuid not null references skill_clusters (id) on delete cascade,
  level smallint not null check (level in (1, 2, 3)),
  correct boolean not null,
  answer jsonb,
  duration_ms integer
);

create index screening_item_results_test_idx
  on screening_item_results (screening_test_id);

alter table screening_item_results enable row level security;

-- append-only: KEIN update-, KEIN delete-Policy
create policy "screening_item_results_insert_own" on screening_item_results
  for insert with check (
    screening_test_id in (
      select id from screening_tests
      where student_id = public.get_my_student_id()
    )
  );

create policy "screening_item_results_select_own" on screening_item_results
  for select using (
    screening_test_id in (
      select id from screening_tests
      where student_id = public.get_my_student_id()
    )
  );

create policy "screening_item_results_parent_read" on screening_item_results
  for select using (
    screening_test_id in (
      select id from screening_tests
      where public.is_parent_of_student(student_id)
    )
  );

create policy "screening_item_results_coach_admin_read" on screening_item_results
  for select using (public.get_my_role() in ('coach','admin'));
