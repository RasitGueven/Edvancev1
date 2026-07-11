-- ============================================================================
-- Migration 025 – interventions (Eingriff-Tracking)
--
-- ⚠️  Auth/RLS-AENDERUNG – per CLAUDE.md §4/§7 mit Rasit explizit
-- abgestimmt (Bindung Session+Schueler, Lesen Coach+Admin+Eltern).
-- Vor Ausfuehrung im Supabase SQL Editor.
--
-- Coach markiert pro Schueler in einer Session einen Eingriff
-- ("Eingegriffen") und loest ihn spaeter ("Geloest"). EINE veraenderbare
-- Zeile pro Vorgang: started_at gesetzt beim Anlegen, resolved_at beim
-- Loesen. Dauer wird NIE gespeichert (immer resolved_at - started_at).
-- Kein Append-Only (anders als behavior_snapshots) – derselbe Vorgang
-- wird fortgeschrieben.
--
-- Sichtbarkeit: Coach (eigene Sessions) r/w, Admin r/w, Eltern read
-- (eigenes Kind). Schueler: keine Policy => kein Zugriff (CLAUDE.md §6).
-- ============================================================================

create table interventions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  session_id uuid not null references coaching_sessions (id) on delete cascade,
  student_id uuid not null references students (id) on delete cascade,
  coach_id uuid not null references profiles (id) on delete cascade,
  started_at timestamptz not null default now(),
  resolved_at timestamptz,
  note text
);

create index interventions_session_idx on interventions (session_id);
create index interventions_student_idx on interventions (student_id);

alter table interventions enable row level security;

-- Coach: nur Eingriffe in eigenen Sessions (lesen + schreiben).
create policy "interventions_coach_rw" on interventions
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

create policy "interventions_admin_all" on interventions
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- Eltern: nur lesen, nur eigenes Kind.
create policy "interventions_parent_read" on interventions
  for select using (public.is_parent_of_student(student_id));
