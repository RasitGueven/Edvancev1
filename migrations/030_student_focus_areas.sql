-- ============================================================================
-- Migration 030 – Student Focus Areas
--
-- Erlaubt Coach/Admin, pro Schüler:in Schwerpunkte aus der letzten Klassen-
-- arbeit (oder eigener Einschätzung) zu hinterlegen. Diese fließen als
-- `weightedTopics` in den adaptiven Screening-Lauf — die Engine fragt die
-- gewichteten Cluster zuerst und tiefer (mehr Items) ab.
--
-- Append-friendly: mehrere aktive Focus-Areas pro Cluster sind erlaubt
-- (z. B. nach jeder Klassenarbeit ein neuer Eintrag). Coach setzt `active`
-- auf false, wenn der Schwerpunkt nicht mehr relevant ist.
-- ============================================================================

create table student_focus_areas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  cluster_id uuid not null references skill_clusters (id) on delete cascade,
  coach_id uuid references profiles (id) on delete set null,
  -- Quelle/Anlass: 'klassenarbeit' | 'beobachtung' | 'erstgespraech' | 'sonstiges'
  source text default 'klassenarbeit',
  note text,
  active boolean not null default true
);

create index student_focus_areas_student_idx
  on student_focus_areas (student_id) where active = true;
create index student_focus_areas_cluster_idx
  on student_focus_areas (cluster_id) where active = true;

alter table student_focus_areas enable row level security;

-- Coach + Admin lesen/schreiben alle. Eltern lesen die eigenen Kinder.
-- Schüler:in sieht nichts (CLAUDE §6 — neutraler Screening-Prozess).
create policy "student_focus_areas_coach_all" on student_focus_areas
  for all using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

create policy "student_focus_areas_parent_read" on student_focus_areas
  for select using (
    public.get_my_role() = 'parent'
    and exists (
      select 1 from students s
      where s.id = student_focus_areas.student_id
        and public.is_parent_of_student(s.id)
    )
  );
