-- ============================================================================
-- Migration 003 – BehaviorSnapshots Persistence (Append-Only)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md mit Rasit explicit abstimmen
-- vor Ausfuehrung im Supabase SQL Editor.
--
-- Hintergrund:
--   TaskPlayer schreibt Schueler-Verhaltensdaten (Bedenkzeit, Revisionen,
--   Hint-Nutzung etc.) bei jedem Submit. Bisher nur console.log – jetzt
--   persistent in Supabase mit Append-Only-Policy.
--
-- Spalten passen 1:1 auf BehaviorSnapshot (src/types/diagnosis.ts).
-- ============================================================================

create table if not exists behavior_snapshots (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles(id) on delete cascade,
  task_id uuid references tasks(id) on delete cascade,
  submitted_at timestamptz default now(),
  answer_text text,
  thinking_time_ms integer,
  task_duration_ms integer,
  revision_count integer,
  rewrite_count integer,
  hint_used boolean,
  hint_request_time_ms integer,
  answer_length integer,
  time_after_completion_ms integer
);

create index if not exists behavior_snapshots_user_task_idx
  on behavior_snapshots (user_id, task_id);

create index if not exists behavior_snapshots_submitted_idx
  on behavior_snapshots (submitted_at desc);

alter table behavior_snapshots enable row level security;

-- Append-only: KEIN UPDATE, KEIN DELETE Policy.

create policy "users_insert_own_snapshots" on behavior_snapshots
  for insert with check (auth.uid() = user_id);

create policy "users_see_own_snapshots" on behavior_snapshots
  for select using (auth.uid() = user_id);

create policy "coaches_admins_see_all_snapshots" on behavior_snapshots
  for select using (public.get_my_role() in ('coach', 'admin'));
