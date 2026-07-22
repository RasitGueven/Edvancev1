-- ============================================================================
-- Edvance – Konsolidiertes Datenbankschema (SINGLE SOURCE OF TRUTH)
-- ============================================================================
--
-- Stand / konsolidiert am: 2026-06-22
-- Abgebildeter Endzustand: Basis-Schema (profiles/students/...) + Content-Schema
--   (subjects/skill_clusters/microskills/tasks/task_coach_metadata) +
--   migrations/001_*.sql … 041_*.sql in numerischer Reihenfolge angewendet.
--
-- Diese Datei ist ab sofort die EINZIGE Wahrheit über den DB-Strukturstand.
-- Sie wurde aus den Migrationen 001-041 abgeleitet (inkl. späterer Drops/Alters,
-- z. B. 006 Serlo-Removal, 028/029 Screening-Lockerungen, 036 drop streak_days,
-- 037 XP-Fix, 038-040 Zwei-Achsen-Kompetenz-Matrix, 041 Modellieren-Aufloesung).
-- schema_content.sql ist DEPRECATED (siehe Kopf jener Datei).
--
-- Abweichungen zwischen den alten Quellen (alte schema.sql, schema_content.sql,
-- alte docs/SCHEMA.md) und den Migrationen sind in docs/DRIFT_REPORT.md
-- tabellarisch dokumentiert.
--
-- ✅ D-01 BEHOBEN (Migration 037): Die Trigger-Funktion public.apply_xp_event()
--   (urspr. Migration 019) referenzierte student_progress.streak_days, das
--   Migration 036 gedroppt hat → jeder INSERT in xp_events (und damit
--   complete_task) schlug fehl. Migration 037 schreibt die Funktion ohne jede
--   streak_days-/Datums-Streak-Logik neu; dieser Freeze bildet den reparierten
--   Endzustand ab. Siehe docs/DRIFT_REPORT.md (D-01).
--
-- Konventionen:
--   - Timestamps: timestamptz, UTC gespeichert, Anzeige Europe/Berlin (Frontend).
--   - RLS: jede Tabelle hat RLS aktiviert; Policies stehen direkt bei der Tabelle.
--   - Security-Definer-Helper get_my_role()/get_my_student_id()/
--     is_parent_of_student() werden zuerst angelegt (Policies hängen daran).
--   - Append-only-Tabellen haben bewusst KEINE update/delete-Policy.
--
-- Ausführungsreihenfolge in dieser Datei: Enums → Helper-Funktionen → Tabellen
-- (in Abhängigkeitsreihenfolge, RLS inline) → übrige Funktionen/Trigger →
-- Storage-RLS → Seed-/Katalogdaten.
-- ============================================================================


-- check_function_bodies wie bei pg_dump deaktivieren: erlaubt Vorwärts-
-- referenzen in Funktionskörpern (z. B. get_my_role() vor profiles) beim
-- Greenfield-Load. Ändert NICHT die Laufzeit-Semantik. (D-01 ist seit
-- Migration 037 behoben; apply_xp_event referenziert streak_days nicht mehr.)
set check_function_bodies = off;


-- ============================================================================
-- 1. ENUMS  (Migration 034)
-- ============================================================================

do $$
begin
  if not exists (select 1 from pg_type where typname = 'badge_rarity') then
    create type public.badge_rarity as enum ('bronze','silver','gold','platinum');
  end if;
  if not exists (select 1 from pg_type where typname = 'badge_form') then
    create type public.badge_form as enum ('round','shield');
  end if;
end$$;


-- ============================================================================
-- 2. SECURITY-DEFINER-HELPER  (nicht-rekursiv, von RLS-Policies genutzt)
--    get_my_role: schema.sql · get_my_student_id/is_parent_of_student: Migr. 011
-- ============================================================================

create or replace function public.get_my_role()
returns text
language sql
security definer
stable
set search_path = public
as $$
  select role from profiles where id = auth.uid() limit 1;
$$;

create or replace function public.get_my_student_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select id from students where profile_id = auth.uid() limit 1;
$$;

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


-- ============================================================================
-- 3. AUTH & PERSONEN  (schema.sql)
-- ============================================================================

-- profiles: erweitert Supabase Auth (auth.users). Rollen-Hierarchie:
-- admin > coach > parent > student.
create table profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  role text not null check (role in ('student','parent','coach','admin')),
  full_name text,
  created_at timestamptz default now()
);

alter table profiles enable row level security;

create policy "users_see_own_profile" on profiles
  for select using (auth.uid() = id);

create policy "coaches_admins_see_all_profiles" on profiles
  for select using (public.get_my_role() in ('coach','admin'));

-- Policy "parents_see_own_children" referenziert parent_student und wird daher
-- erst NACH dessen CREATE TABLE angelegt (siehe unten).

-- students: Schülerdetails (1:1 zu einem Profil mit role='student').
create table students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references profiles(id) on delete cascade,
  class_level integer check (class_level between 5 and 13),
  school_name text,
  school_type text check (
    school_type in ('Gymnasium','Gesamtschule','Realschule','Hauptschule')
  )
);

alter table students enable row level security;

-- RLS-Policies seit Migration 011 (vorher RLS aktiv, aber policy-los = deny).
create policy "students_select_own" on students
  for select using (profile_id = auth.uid());
create policy "students_parents_read" on students
  for select using (public.is_parent_of_student(id));
create policy "students_coach_admin_all" on students
  for all
  using (public.get_my_role() in ('coach', 'admin'))
  with check (public.get_my_role() in ('coach', 'admin'));

-- parent_student: Eltern-Kind-Verknüpfung.
-- ⚠️  student_id referenziert profiles(id) – NICHT students(id).
create table parent_student (
  parent_id uuid references profiles(id) on delete cascade,
  student_id uuid references profiles(id) on delete cascade,
  primary key (parent_id, student_id)
);

alter table parent_student enable row level security;

create policy "parent_student_parent_read" on parent_student
  for select using (parent_id = auth.uid());
create policy "parent_student_student_read" on parent_student
  for select using (student_id = auth.uid());
create policy "parent_student_coach_admin_all" on parent_student
  for all
  using (public.get_my_role() in ('coach', 'admin'))
  with check (public.get_my_role() in ('coach', 'admin'));

-- profiles-Policy, die parent_student braucht (Eltern sehen ihre Kinder).
create policy "parents_see_own_children" on profiles
  for select using (
    exists (
      select 1 from parent_student ps
      where ps.parent_id = auth.uid() and ps.student_id = id
    )
  );


-- ============================================================================
-- 4. INHALTE / AUFGABEN  (schema_content.sql + Migr. 001,002,004,005,006,007,008,009)
-- ============================================================================

-- subjects: Fach. Effektiver Stand OHNE name-CHECK-Constraint:
-- schema.sql legte name mit CHECK (Mathematik|Deutsch|Englisch) an, das
-- Content-Schema droppt ihn explizit (subjects_name_check). Siehe DRIFT D-09.
-- serlo_id wurde von Migration 006 gedroppt (falls vorhanden).
create table subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null
);

alter table subjects enable row level security;

create policy "authenticated_read_subjects"
  on subjects for select using (auth.role() = 'authenticated');

-- student_subjects: Schüler-Fach-Verknüpfung (m:n). Basis-Tabelle (schema.sql),
-- RLS-Policies seit Migration 011. Steht hier nach subjects wegen FK-Reihenfolge.
create table student_subjects (
  student_id uuid references students(id) on delete cascade,
  subject_id uuid references subjects(id) on delete cascade,
  primary key (student_id, subject_id)
);

alter table student_subjects enable row level security;

create policy "student_subjects_select_own" on student_subjects
  for select using (student_id = public.get_my_student_id());
create policy "student_subjects_parents_read" on student_subjects
  for select using (public.is_parent_of_student(student_id));
create policy "student_subjects_coach_admin_all" on student_subjects
  for all
  using (public.get_my_role() in ('coach', 'admin'))
  with check (public.get_my_role() in ('coach', 'admin'));

-- skill_clusters: Themencluster pro Fach. Für Mathematik = 5 KMK-Kompetenz-
-- bereiche (Seed via Migration 001, siehe Abschnitt 9).
-- serlo_taxonomy_id wurde von Migration 006 gedroppt (falls vorhanden).
-- is_deprecated (Migration 041): markiert achsen-vermischte Cluster (z. B.
-- "Sachrechnen & Modellieren"), die nicht geloescht, aber stillgelegt werden.
create table skill_clusters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references subjects(id) on delete cascade,
  name text not null,
  class_level_min integer not null check (class_level_min between 5 and 13),
  class_level_max integer not null check (class_level_max between 5 and 13),
  sort_order integer default 0,
  is_deprecated boolean not null default false
);

alter table skill_clusters enable row level security;

create policy "authenticated_read_clusters"
  on skill_clusters for select using (auth.role() = 'authenticated');

-- process_competencies (Migration 038): Achse B der Zwei-Achsen-Matrix.
-- Die 6 KMK-Prozesskompetenzen als eigene Achse (parallel zu skill_clusters =
-- Achse A / Inhaltsfeld). Referenzdaten; Seed in Abschnitt 14.
create table process_competencies (
  id          uuid primary key default gen_random_uuid(),
  code        text not null unique,        -- Ope|Mod|Pro|Arg|Kom|Wkz
  name        text not null,               -- interner Klartext
  sort_order  integer not null
);

alter table process_competencies enable row level security;

create policy "authenticated_read_process_competencies"
  on process_competencies for select using (auth.role() = 'authenticated');
create policy "process_competencies_admin_write"
  on process_competencies for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- microskills: atomare Lernziele innerhalb eines Clusters.
-- cognitive_type/estimated_minutes/curriculum_ref aus Migration 005.
create table microskills (
  id uuid primary key default gen_random_uuid(),
  cluster_id uuid references skill_clusters(id) on delete cascade,
  code text not null unique,
  name text not null,
  description text,
  class_level integer not null check (class_level between 5 and 13),
  prerequisite_ids uuid[] default '{}',
  sort_order integer default 0,
  cognitive_type text check (cognitive_type in ('FACT','TRANSFER','ANALYSIS')),
  estimated_minutes integer,
  curriculum_ref text
);

alter table microskills enable row level security;

create policy "authenticated_read_microskills"
  on microskills for select using (auth.role() = 'authenticated');

-- tasks: Lern-/Aufgabeninhalte. Endzustand nach Serlo-Removal (006):
-- KEINE serlo_*-Spalten mehr. Diagnostic-Felder aus 005, source/source_ref
-- aus 007 (+ UNIQUE aus 008), assets aus 009.
create table tasks (
  id uuid primary key default gen_random_uuid(),
  microskill_id uuid references microskills(id) on delete set null,
  cluster_id uuid references skill_clusters(id) on delete set null,
  content_type text not null check (
    content_type in ('exercise','exercise_group','article','video','course')
  ),
  title text,
  question text,
  -- `solution` GEDROPPT in 20260714120000 (T1b). Die Loesung lebt ausschliesslich
  -- in task_solutions (Server-Only-Zone, kein Grant fuer anon/authenticated).
  -- Auf `tasks` darf JEDER eingeloggte Nutzer lesen — eine Loesungsspalte hier
  -- war fuer jede:n Schueler:in per select=* abrufbar. Ebenso verboten: Loesungs-
  -- felder in question_payload, siehe CHECK tasks_question_payload_no_solution.
  hint text,
  common_errors text,
  coach_note text,
  difficulty integer check (difficulty between 1 and 5),
  estimated_minutes integer default 3,
  class_level integer check (class_level between 5 and 13),
  is_active boolean default true,
  created_at timestamptz default now(),
  -- Migration 005 (Diagnostic-Felder)
  cognitive_type text check (cognitive_type in ('FACT','TRANSFER','ANALYSIS')),
  -- input_type-CHECK in 042 auf den kanonischen Enum vereinheitlicht
  -- (FREE_INPUT/STEPS→FREE_TEXT, DRAW→COORDINATE):
  input_type text check (input_type in (
    'MC','NUMERIC','SHORT_TEXT','TRUE_FALSE','FREE_TEXT','MATCHING','CLOZE','COORDINATE'
  )),
  is_diagnostic boolean default false,
  curriculum_ref text,
  question_payload jsonb,
  typical_errors text[],
  -- Migration 007 (Quelle + Idempotenz-Referenz)
  source text not null default 'unbekannt',
  source_ref text,
  -- Migration 009 (Bilder/Abbildungen)
  assets jsonb not null default '[]'::jsonb,
  -- Migration 039 (Achse B): Prozesskompetenz-Tag (nullable; Backfill = Content)
  competency_id uuid references process_competencies(id) on delete set null,
  -- Migration 008: echter UNIQUE CONSTRAINT (ersetzt partiellen Index aus 007)
  constraint tasks_source_ref_unique unique (source, source_ref)
);

create index if not exists tasks_diagnostic_idx
  on tasks (is_diagnostic) where is_diagnostic = true;
create index if not exists tasks_microskill_diagnostic_idx
  on tasks (microskill_id, is_diagnostic, difficulty)
  where is_diagnostic = true;
create index if not exists tasks_source_idx on tasks (source);
create index if not exists tasks_has_assets_idx
  on tasks ((jsonb_array_length(assets) > 0))
  where jsonb_array_length(assets) > 0;
create index if not exists tasks_competency_idx on tasks (competency_id);

alter table tasks enable row level security;

-- B01 (20260714140000): Rolle statt "eingeloggt". auth.role() sagt nur, DASS
-- jemand eingeloggt ist — nicht WER. Seit C08 liegen 285 draft-Items in der
-- Tabelle; die alte Policy gab sie jedem Schuelergeraet.
create policy "read_tasks_by_role"
  on tasks for select using (
    public.get_my_role() in ('coach', 'admin')
    or (public.get_my_role() is not null and status = 'ready')
  );
create policy "admin_write_tasks"
  on tasks for all using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- task_coach_metadata: optionale Coach-Hinweise pro Aufgabe.
-- ⚠️  Nur Read-Policy (coach/admin); kein Write-Policy → mit aktiver RLS
-- ist kein Client-Write möglich. Siehe DRIFT D-10.
create table task_coach_metadata (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references tasks(id) on delete cascade,
  typical_errors text,
  observation_hints text,
  intervention_triggers text,
  updated_at timestamptz default now()
);

alter table task_coach_metadata enable row level security;

create policy "coaches_read_task_metadata"
  on task_coach_metadata for select using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('coach','admin')
    )
  );


-- ============================================================================
-- 5. BEHAVIOR-TRACKING  (Migration 003; FK screening_test_id via Migration 014)
-- ============================================================================

-- behavior_snapshots: APPEND-ONLY Roh-Verhaltensdaten pro Submit.
-- Spalten 1:1 zu src/types/diagnosis.ts (BehaviorSnapshot, Capture-Seite).
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
  -- screening_test_id wird nach screening_tests per ALTER ergänzt (Migration 014).
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


-- ============================================================================
-- 6. ERSTGESPRÄCH (LEAD-FUNNEL)  (Migrationen 012, 013)
-- ============================================================================

-- leads: Erstkontakt VOR Account (Stufe A). Interne PII, nur Coach/Admin.
create table leads (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  full_name text not null,
  contact_email text,
  contact_phone text,
  class_level integer check (class_level between 5 and 13),
  school_type text check (
    school_type in ('Gymnasium','Gesamtschule','Realschule','Hauptschule')
  ),
  school_name text,
  subjects text[] default '{}',
  goal text check (goal in ('IMPROVE_GRADES','CLOSE_GAPS','EXAM_PREP','GENERAL')),
  known_weak_topics text[] default '{}',
  source text,
  status text not null default 'new' check (
    status in ('new','contacted','onboarding_scheduled','converted','rejected')
  ),
  owner_id uuid references profiles (id) on delete set null,
  notes text,
  converted_student_id uuid references students (id) on delete set null,
  contacted_at timestamptz,
  onboarding_scheduled_at timestamptz
);

create index leads_status_idx on leads (status);
create index leads_owner_idx on leads (owner_id);

alter table leads enable row level security;

create policy "leads_coach_admin_all" on leads
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- intake_sessions: strukturiertes Erstgespräch-Protokoll am Schüler (Stufe B).
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


-- ============================================================================
-- 7. SCREENING  (Migrationen 014, 022, 023, 028, 029)
-- ============================================================================

-- screening_tests: mutables Aggregat pro (Schüler, Fach); max. 1 aktiver Lauf.
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
-- Migration 023: Schüler-Self-Service-Write (stiller, adaptiver /screening-Lauf).
create policy "screening_tests_student_insert" on screening_tests
  for insert
  with check (student_id = public.get_my_student_id());
create policy "screening_tests_student_update" on screening_tests
  for update
  using (student_id = public.get_my_student_id())
  with check (student_id = public.get_my_student_id());

-- behavior_snapshots: additiver FK auf den Screening-Lauf (Migration 014).
alter table behavior_snapshots
  add column screening_test_id uuid
    references screening_tests (id) on delete cascade;
create index behavior_snapshots_screening_idx
  on behavior_snapshots (screening_test_id);

-- screening_ratings: APPEND-ONLY Coach-Bewertung pro behavior_snapshot/Lauf.
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

-- Append-only: KEIN update-, KEIN delete-Policy.
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

-- screening_items: eigene Itembank. Endzustand nach 028 (afb/phase, OPEN/manual)
-- und 029 (VERA-8-Lockerung: viele Spalten nullable, VERA-Felder + iqb_titel).
create table screening_items (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  -- 022 NOT NULL → 029 nullable (VERA-Items haben keinen Cluster):
  cluster_id uuid references skill_clusters (id) on delete cascade,
  class_level integer not null check (class_level between 5 and 13),
  topic text,
  skill_code text,
  skill_label text,
  level smallint check (level in (1, 2, 3)),
  curriculum_seq integer,
  -- input_type-CHECK in 042 auf den kanonischen Enum vereinheitlicht
  -- (STEPS_FINAL/OPEN→FREE_TEXT). check_type bleibt der Grading-Diskriminator.
  input_type text not null check (
    input_type in (
      'MC','NUMERIC','SHORT_TEXT','TRUE_FALSE','FREE_TEXT','MATCHING','CLOZE','COORDINATE'
    )
  ),
  prompt text,
  payload jsonb,
  canonical jsonb,
  check_type text not null check (
    check_type in ('mc_index','numeric','matching_set','normalized','manual')
  ),
  tolerance numeric,
  typical_errors text[] default '{}',
  explanation text,
  source text not null default 'edvance_original',
  active boolean not null default false,
  -- Migration 028 (AFB + Phase). Cross-Constraint OPEN<=>manual in 042
  -- entfernt: FREE_TEXT spannt nach der Kanonisierung Auto (normalized) UND
  -- Coach (manual); die Unterscheidung lebt allein in check_type.
  afb text check (afb in ('I','II','III')),
  phase text check (phase in ('sprint','tiefe')),
  -- Migration 029 (VERA-8-Felder; iqb_titel UNIQUE für Seed-Idempotenz):
  iqb_titel text,
  kompetenzfelder text[],
  aufgabe_typ text,
  teilaufgaben jsonb,
  kontext text,
  loesung_pro_ta jsonb,
  akzeptierte_antworten jsonb,
  kodierung text,
  kommentar_highlights jsonb,
  urls jsonb,
  datei_ext text,
  quelle text,
  fix_anker boolean default false,
  meta jsonb,
  -- Migration 039 (Achse B): competency_id ist die strukturierte Wahrheit der
  -- Prozesskompetenz. kompetenzfelder (text[], oben) bleibt als Legacy/VERA-8-
  -- Historie erhalten und wird NICHT entfernt.
  competency_id uuid references process_competencies(id) on delete set null,
  -- Migration 043 (Microskill-Lokalisierung): feinste Inhalts-Granularitaet
  -- (unterhalb cluster_id); Basis fuer Root-Gap-Walk via microskills.prerequisite_ids.
  microskill_id uuid references microskills(id) on delete set null,
  constraint screening_items_iqb_titel_uniq unique (iqb_titel)
);

create index screening_items_cluster_idx on screening_items (cluster_id);
create index screening_items_active_idx on screening_items (active);
create index screening_items_cluster_level_idx
  on screening_items (cluster_id, level) where active = true;
create index screening_items_skill_idx on screening_items (skill_code);
create index screening_items_v2_pool_idx
  on screening_items (cluster_id, phase, afb)
  where active = true and afb is not null and phase is not null;
create index if not exists screening_items_quelle_idx
  on screening_items (quelle);
create index if not exists screening_items_competency_idx
  on screening_items (competency_id);
create index if not exists screening_items_microskill_idx
  on screening_items (microskill_id);

alter table screening_items enable row level security;

create policy "screening_items_read_active" on screening_items
  for select using (auth.role() = 'authenticated' and active = true);
create policy "screening_items_admin_all" on screening_items
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
create policy "screening_items_coach_read" on screening_items
  for select using (public.get_my_role() in ('coach','admin'));

-- screening_item_results: APPEND-ONLY Ergebnis pro Item/Lauf.
-- correct in 028 nullable (offene Items haben zur Insert-Zeit kein Auto-Grade).
-- ⚠️  cluster_id bleibt NOT NULL, obwohl screening_items.cluster_id nullable
--     wurde (029) → VERA-Items ohne Cluster siehe DRIFT D-11.
create table screening_item_results (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  screening_test_id uuid not null
    references screening_tests (id) on delete cascade,
  screening_item_id uuid not null
    references screening_items (id) on delete cascade,
  cluster_id uuid not null references skill_clusters (id) on delete cascade,
  level smallint not null check (level in (1, 2, 3)),
  correct boolean,
  answer jsonb,
  duration_ms integer
);

create index screening_item_results_test_idx
  on screening_item_results (screening_test_id);

alter table screening_item_results enable row level security;

-- Append-only: KEIN update-, KEIN delete-Policy.
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

-- screening_item_ratings: APPEND-ONLY manuelle Coach-Bewertung offener Items
-- (Migration 028). Schüler/Eltern lesen NICHT direkt (CLAUDE §6).
create table screening_item_ratings (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  screening_item_result_id uuid not null
    references screening_item_results (id) on delete cascade,
  coach_id uuid references profiles (id) on delete set null,
  reached_afb text check (reached_afb in ('I','II','III')),
  note text
);

create index screening_item_ratings_result_idx
  on screening_item_ratings (screening_item_result_id);
create index screening_item_ratings_coach_idx
  on screening_item_ratings (coach_id);

alter table screening_item_ratings enable row level security;

-- Append-only: KEIN update-/delete-Policy.
create policy "screening_item_ratings_coach_insert" on screening_item_ratings
  for insert with check (public.get_my_role() in ('coach','admin'));
create policy "screening_item_ratings_coach_read" on screening_item_ratings
  for select using (public.get_my_role() in ('coach','admin'));


-- ============================================================================
-- 8. TARIF / ZUORDNUNG / FOKUS  (Migrationen 015, 016, 030)
-- ============================================================================

-- tiers: Tarif-Katalog (Seed Basic/Standard/Premium in Abschnitt 9).
create table tiers (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  price_cents integer not null,
  features jsonb not null default '[]'::jsonb,
  sort_order integer not null default 0,
  active boolean not null default true
);

alter table tiers enable row level security;

create policy "tiers_authenticated_read" on tiers
  for select using (auth.role() = 'authenticated');
create policy "tiers_admin_write" on tiers
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- student_subscriptions: gewählter Tarif pro Schüler.
create table student_subscriptions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  tier_id uuid not null references tiers (id),
  status text not null default 'active' check (
    status in ('active','paused','cancelled')
  ),
  started_at timestamptz default now(),
  ended_at timestamptz
);

create index student_subscriptions_student_idx
  on student_subscriptions (student_id);

alter table student_subscriptions enable row level security;

create policy "student_subscriptions_select_own" on student_subscriptions
  for select using (student_id = public.get_my_student_id());
create policy "student_subscriptions_parent_read" on student_subscriptions
  for select using (public.is_parent_of_student(student_id));
create policy "student_subscriptions_coach_admin_all" on student_subscriptions
  for all
  using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

-- student_coach: Schüler<->Coach-Zuordnung (Zuweisung = Admin-Aufgabe).
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

-- student_focus_areas: Coach/Admin setzt Schwerpunkte (gewichtet die Engine).
create table student_focus_areas (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  cluster_id uuid not null references skill_clusters (id) on delete cascade,
  coach_id uuid references profiles (id) on delete set null,
  source text default 'klassenarbeit',
  note text,
  active boolean not null default true
);

create index student_focus_areas_student_idx
  on student_focus_areas (student_id) where active = true;
create index student_focus_areas_cluster_idx
  on student_focus_areas (cluster_id) where active = true;

alter table student_focus_areas enable row level security;

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


-- ============================================================================
-- 9. SESSION-BETRIEB  (Migrationen 017, 024, 025)
-- ============================================================================

-- coaching_sessions: geplante/laufende Präsenz-Sessions eines Coaches.
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

-- session_students: Anwesenheit pro Schüler in einer Session.
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
-- Migration 024: Eltern lesen Sessions des eigenen Kindes (RLS-Lücke aus 017).
create policy "coaching_sessions_parent_read" on coaching_sessions
  for select using (
    id in (
      select ss.session_id
      from session_students ss
      where public.is_parent_of_student(ss.student_id)
    )
  );

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

-- interventions: Eingriff-Tracking (eine veränderbare Zeile pro Vorgang;
-- Dauer = resolved_at - started_at, nie gespeichert). Schüler: kein Zugriff.
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
create policy "interventions_parent_read" on interventions
  for select using (public.is_parent_of_student(student_id));


-- ============================================================================
-- 10. FORTSCHRITT & GAMIFICATION  (Migr. 018, 019, 026, 032, 034, 035, 036)
-- ============================================================================

-- student_task_progress: Aufgaben-Abschluss (ersetzt localStorage).
create table student_task_progress (
  student_id uuid not null references students (id) on delete cascade,
  task_id uuid not null references tasks (id) on delete cascade,
  completed_at timestamptz default now(),
  primary key (student_id, task_id)
);

create index student_task_progress_student_idx
  on student_task_progress (student_id);

alter table student_task_progress enable row level security;

create policy "student_task_progress_own_rw" on student_task_progress
  for all
  using (student_id = public.get_my_student_id())
  with check (student_id = public.get_my_student_id());
create policy "student_task_progress_parent_read" on student_task_progress
  for select using (public.is_parent_of_student(student_id));
create policy "student_task_progress_coach_admin_read" on student_task_progress
  for select using (public.get_my_role() in ('coach','admin'));

-- student_progress: abgeleiteter Totals-Spiegel (nur via Trigger geschrieben).
-- Endzustand: streak_days von Migration 036 GEDROPPT; Zwei-Streak-Modell aus
-- Migration 032 ist aktiv (presence_* / home_*).
create table student_progress (
  student_id uuid primary key references students (id) on delete cascade,
  xp_total integer not null default 0,
  level integer not null default 1,
  last_activity timestamptz,
  -- Migration 032 (Zwei-Streak-Modell):
  presence_streak_weeks integer not null default 0,
  presence_streak_last_week_start timestamptz,
  presence_streak_multiplier numeric(3,2) not null default 1.00,
  home_streak_sessions integer not null default 0,
  home_streak_last_completed_at timestamptz
);

alter table student_progress enable row level security;

create policy "student_progress_select_own" on student_progress
  for select using (student_id = public.get_my_student_id());
create policy "student_progress_parent_read" on student_progress
  for select using (public.is_parent_of_student(student_id));
create policy "student_progress_coach_admin_read" on student_progress
  for select using (public.get_my_role() in ('coach','admin'));

-- xp_events: APPEND-ONLY XP-Vergabe; speist student_progress via Trigger.
create table xp_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  student_id uuid not null references students (id) on delete cascade,
  task_id uuid references tasks (id) on delete set null,
  xp integer not null,
  reason text
);

create index xp_events_student_idx on xp_events (student_id);

alter table xp_events enable row level security;

-- Append-only: KEIN update-, KEIN delete-Policy.
create policy "xp_events_insert_own" on xp_events
  for insert with check (student_id = public.get_my_student_id());
create policy "xp_events_select_own" on xp_events
  for select using (student_id = public.get_my_student_id());
create policy "xp_events_parent_read" on xp_events
  for select using (public.is_parent_of_student(student_id));
create policy "xp_events_coach_admin_read" on xp_events
  for select using (public.get_my_role() in ('coach','admin'));

-- xp_rules: admin-konfigurierbare XP-Gewichtung pro content_type (Seed unten).
create table xp_rules (
  content_type text primary key,
  base_xp integer not null default 0,
  difficulty_multiplier integer not null default 0,
  updated_at timestamptz not null default now()
);

alter table xp_rules enable row level security;

create policy "xp_rules_admin_all" on xp_rules
  for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');
create policy "xp_rules_staff_read" on xp_rules
  for select using (public.get_my_role() in ('coach', 'admin'));

-- badge_catalog: Badge-Definitionen (Seed = 10 regulär + 3 Platin, unten).
create table if not exists public.badge_catalog (
  id          text primary key,
  label       text not null,
  description text,
  rarity      public.badge_rarity not null,
  form        public.badge_form   not null default 'round',
  klasse      int,
  trigger     text,
  created_at  timestamptz not null default now()
);

alter table public.badge_catalog enable row level security;

create policy "badge_catalog_read_all"
  on public.badge_catalog for select using (true);
create policy "badge_catalog_admin_write"
  on public.badge_catalog for all
  using (public.get_my_role() = 'admin')
  with check (public.get_my_role() = 'admin');

-- student_badges: verliehene Badges pro Schüler.
create table if not exists public.student_badges (
  student_id   uuid not null references public.students(id) on delete cascade,
  badge_id     text not null references public.badge_catalog(id),
  awarded_at   timestamptz not null default now(),
  primary key (student_id, badge_id)
);

alter table public.student_badges enable row level security;

create policy "student_badges_self_read"
  on public.student_badges for select
  using (
    student_id in (select id from public.students where profile_id = auth.uid())
    or public.get_my_role() in ('coach','admin')
    or exists (
      select 1 from public.parent_student ps
      where ps.student_id = public.student_badges.student_id
        and ps.parent_id  = auth.uid()
    )
  );
create policy "student_badges_admin_write"
  on public.student_badges for all
  using (public.get_my_role() in ('admin','coach'))
  with check (public.get_my_role() in ('admin','coach'));

-- streak_repair_inventory: Inventory für Streak-Repair-Token.
create table if not exists public.streak_repair_inventory (
  student_id   uuid primary key references public.students(id) on delete cascade,
  tokens       int not null default 0,
  earned_total int not null default 0,
  used_total   int not null default 0,
  updated_at   timestamptz not null default now()
);

alter table public.streak_repair_inventory enable row level security;

create policy "streak_repair_self_read"
  on public.streak_repair_inventory for select
  using (
    student_id in (select id from public.students where profile_id = auth.uid())
    or public.get_my_role() in ('coach','admin')
  );
create policy "streak_repair_admin_write"
  on public.streak_repair_inventory for all
  using (public.get_my_role() in ('admin'))
  with check (public.get_my_role() in ('admin'));


-- ============================================================================
-- 11. ELTERNREPORT  (Migrationen 020, 027)
-- ============================================================================

-- parent_reports: kuratierter Report (draft -> published). Eltern/Schüler
-- sehen NUR 'published' des eigenen Kindes/von sich.
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

-- parent_report_generations: APPEND-ONLY Log jeder erfolgreichen KI-Generierung
-- (Kosten-Guardrail). Insert NUR via Service-Role aus der Edge Function
-- (umgeht RLS); daher KEIN insert/update/delete-Policy. coach_id ohne FK.
create table parent_report_generations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  coach_id uuid,
  student_id uuid not null references students (id) on delete cascade,
  model text
);

create index parent_report_gen_coach_idx
  on parent_report_generations (coach_id, created_at);
create index parent_report_gen_student_idx
  on parent_report_generations (student_id, created_at);
create index parent_report_gen_created_idx
  on parent_report_generations (created_at);

alter table parent_report_generations enable row level security;

create policy "prg_coach_admin_read" on parent_report_generations
  for select using (public.get_my_role() in ('coach', 'admin'));


-- ============================================================================
-- 12. FUNKTIONEN & TRIGGER (tabellenabhängig)
-- ============================================================================

-- apply_xp_event (Migration 019, repariert in Migration 037 = D-01-Fix):
-- leitet student_progress aus xp_events ab. OHNE streak_days-Bezug (von 036
-- gedroppt). Das Zwei-Streak-Modell (presence/home, 032) wird hier bewusst
-- NICHT gepflegt – separater Folge-Task. SECURITY DEFINER, append-only-Quelle.
create or replace function public.apply_xp_event()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  perform 1 from student_progress where student_id = new.student_id;

  if not found then
    insert into student_progress
      (student_id, xp_total, level, last_activity)
    values
      (new.student_id, new.xp, 1 + (new.xp / 500), now());
    return new;
  end if;

  update student_progress
     set xp_total = xp_total + new.xp,
         level = 1 + ((xp_total + new.xp) / 500),
         last_activity = now()
   where student_id = new.student_id;

  return new;
end;
$$;

create trigger xp_events_apply
  after insert on xp_events
  for each row execute function public.apply_xp_event();

-- complete_task (Migration 026): atomare, idempotente Abschluss-RPC.
-- Cheat-sicher: Server leitet XP aus xp_rules + tasks ab. Idempotent: XP nur
-- bei NEUER Progress-Zeile. (Löst über xp_events den Trigger oben aus.)
create or replace function public.complete_task(p_task_id uuid)
returns table (newly_completed boolean, awarded_xp integer)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student uuid;
  v_ins integer;
  v_xp integer;
begin
  v_student := public.get_my_student_id();
  if v_student is null then
    return;
  end if;

  insert into student_task_progress (student_id, task_id)
  values (v_student, p_task_id)
  on conflict (student_id, task_id) do nothing;
  get diagnostics v_ins = row_count;

  if v_ins = 0 then
    return query select false, 0;
    return;
  end if;

  select r.base_xp + r.difficulty_multiplier * coalesce(t.difficulty, 0)
    into v_xp
    from tasks t
    join xp_rules r on r.content_type = t.content_type
   where t.id = p_task_id;

  v_xp := coalesce(v_xp, 0);

  if v_xp > 0 then
    insert into xp_events (student_id, task_id, xp, reason)
    values (v_student, p_task_id, v_xp, 'Aufgabe abgeschlossen');
  end if;

  return query select true, v_xp;
end;
$$;

grant execute on function public.complete_task(uuid) to authenticated;

-- app_provision_student (Migration 021): atomare Lead->Student-Conversion.
-- Nur via Edge Function provision_student (service_role) aufrufbar.
create or replace function public.app_provision_student(
  p_student_uid uuid,
  p_student_email text,
  p_parent_uid uuid,
  p_parent_email text,
  p_full_name text,
  p_class_level integer,
  p_school_type text,
  p_school_name text,
  p_subjects text[],
  p_coach_id uuid,
  p_tier_id uuid,
  p_lead_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_student_id uuid;
  v_subj text;
  v_subject_id uuid;
begin
  insert into profiles (id, email, role, full_name)
  values (p_student_uid, p_student_email, 'student', p_full_name)
  on conflict (id) do update
    set email = excluded.email,
        role = 'student',
        full_name = excluded.full_name;

  if p_parent_uid is not null then
    insert into profiles (id, email, role, full_name)
    values (p_parent_uid, p_parent_email, 'parent', null)
    on conflict (id) do update
      set email = excluded.email,
          role = 'parent';
  end if;

  insert into students (profile_id, class_level, school_name, school_type)
  values (p_student_uid, p_class_level, p_school_name, p_school_type)
  returning id into v_student_id;

  if p_parent_uid is not null then
    insert into parent_student (parent_id, student_id)
    values (p_parent_uid, p_student_uid);
  end if;

  if p_subjects is not null then
    foreach v_subj in array p_subjects loop
      select id into v_subject_id from subjects where name = v_subj;
      if v_subject_id is null then
        raise exception 'Fach unbekannt: %', v_subj;
      end if;
      insert into student_subjects (student_id, subject_id)
      values (v_student_id, v_subject_id);
    end loop;
  end if;

  if p_coach_id is not null then
    insert into student_coach (student_id, coach_id)
    values (v_student_id, p_coach_id);
  end if;

  if p_tier_id is not null then
    insert into student_subscriptions (student_id, tier_id)
    values (v_student_id, p_tier_id);
  end if;

  if p_lead_id is not null then
    update leads
       set status = 'converted',
           converted_student_id = v_student_id
     where id = p_lead_id;
  end if;

  return v_student_id;
end;
$$;

revoke all on function public.app_provision_student(
  uuid,text,uuid,text,text,integer,text,text,text[],uuid,uuid,uuid
) from public, anon, authenticated;
grant execute on function public.app_provision_student(
  uuid,text,uuid,text,text,integer,text,text,text[],uuid,uuid,uuid
) to service_role;

-- calc_presence_multiplier (Migration 032): Präsenz-Streak -> XP-Multiplikator.
create or replace function public.calc_presence_multiplier(weeks int)
returns numeric(3,2)
language sql
immutable
as $$
  select case
    when weeks >= 8 then 1.30
    when weeks >= 5 then 1.20
    when weeks >= 3 then 1.10
    else 1.00
  end::numeric(3,2)
$$;

-- mastery_stage (Migration 033): Score (0..100) -> 5-Stufen-Label.
-- Mastery bleibt in der DB als Level 1..10; diese Funktion mappt aufs Frontend.
create or replace function public.mastery_stage(score numeric)
returns text
language sql
immutable
as $$
  select case
    when score >= 85 then 'mastered'
    when score >= 75 then 'proficient'
    when score >= 60 then 'progressing'
    when score >= 40 then 'developing'
    else 'introduced'
  end
$$;

create or replace function public.mastery_stage_from_level(lvl int)
returns text
language sql
immutable
as $$
  select public.mastery_stage(lvl * 10.0)
$$;


-- ============================================================================
-- 12b. KOMPETENZ-MATRIX (Migrationen 038-040)
--      student_competency_mastery steht hier (nicht in Abschnitt 10), weil die
--      generated column stage die oben definierte Funktion mastery_stage(score)
--      benoetigt. Zwei-Achsen-Matrix: (Schüler × Mikroskill × Prozesskompetenz).
-- ============================================================================

-- FernUSG-GATE: "mastered" darf strukturell NUR von Coach/Admin gesetzt werden.
-- Erzwingt das Gate-Trigger-seitig (auch fuer service-role), setzt mastered_by/
-- _at beim Gewaehren und updated_at bei jedem Schreibvorgang.
create or replace function public.enforce_mastery_gate()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_was_mastered boolean := false;
begin
  new.updated_at := now();

  if tg_op = 'UPDATE' then
    v_was_mastered := coalesce(old.mastered, false);
  end if;

  if new.mastered and not v_was_mastered then
    if public.get_my_role() not in ('coach','admin') then
      raise exception 'Mastered darf nur durch Coach gesetzt werden (FernUSG)';
    end if;
    new.mastered_by := auth.uid();
    new.mastered_at := now();
  end if;

  return new;
end;
$$;

-- student_competency_mastery: Mastery-Zustand pro (Schüler × Mikroskill ×
-- Prozesskompetenz). score wird serverseitig/coach gepflegt; stage ist
-- abgeleitet (mastery_stage). mastered nur via Gate-Trigger (FernUSG).
create table student_competency_mastery (
  student_id    uuid not null references students(id) on delete cascade,
  microskill_id uuid not null references microskills(id) on delete cascade,
  competency_id uuid not null references process_competencies(id) on delete cascade,
  score         numeric(5,2) not null default 0 check (score between 0 and 100),
  mastered      boolean not null default false,
  mastered_by   uuid references profiles(id),
  mastered_at   timestamptz,
  updated_at    timestamptz not null default now(),
  stage         text generated always as (public.mastery_stage(score)) stored,
  primary key (student_id, microskill_id, competency_id)
);

create index student_competency_mastery_student_idx
  on student_competency_mastery (student_id);

alter table student_competency_mastery enable row level security;

-- Lesen: exakt analog student_task_progress.
create policy "scm_student_read" on student_competency_mastery
  for select using (student_id = public.get_my_student_id());
create policy "scm_parent_read" on student_competency_mastery
  for select using (public.is_parent_of_student(student_id));
create policy "scm_coach_admin_read" on student_competency_mastery
  for select using (public.get_my_role() in ('coach','admin'));

-- Schreiben (score): nur coach/admin. Kein student/parent-Schreibpfad.
create policy "scm_coach_admin_insert" on student_competency_mastery
  for insert with check (public.get_my_role() in ('coach','admin'));
create policy "scm_coach_admin_update" on student_competency_mastery
  for update using (public.get_my_role() in ('coach','admin'))
  with check (public.get_my_role() in ('coach','admin'));

create trigger trg_enforce_mastery_gate
  before insert or update on student_competency_mastery
  for each row execute function public.enforce_mastery_gate();


-- ============================================================================
-- 13. STORAGE-RLS  (Migrationen 010, 031)
-- ============================================================================
-- Voraussetzung: Buckets sind in Supabase Studio angelegt:
--   - 'task-assets'       (public)  – Bilder/Abbildungen für tasks.assets
--   - 'screening-uploads' (privat)  – Foto-Uploads (Handschrift/PII), Signed URL

-- task-assets: Admins schreiben; Lesen ist public (Bucket-Setting).
create policy "admin_insert_task_assets"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'task-assets'
  and public.get_my_role() = 'admin'
);
create policy "admin_update_task_assets"
on storage.objects for update to authenticated
using (
  bucket_id = 'task-assets'
  and public.get_my_role() = 'admin'
);
create policy "admin_delete_task_assets"
on storage.objects for delete to authenticated
using (
  bucket_id = 'task-assets'
  and public.get_my_role() = 'admin'
);

-- screening-uploads: privat. Pfad-Konvention {student_id}/{timestamp}-{rand}.{ext}.
create policy "screening_uploads_insert_own_student"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'screening-uploads'
  and (storage.foldername(name))[1] = public.get_my_student_id()::text
);
create policy "screening_uploads_select_own_student"
on storage.objects for select to authenticated
using (
  bucket_id = 'screening-uploads'
  and (storage.foldername(name))[1] = public.get_my_student_id()::text
);
create policy "screening_uploads_delete_own_student"
on storage.objects for delete to authenticated
using (
  bucket_id = 'screening-uploads'
  and (storage.foldername(name))[1] = public.get_my_student_id()::text
);
create policy "screening_uploads_select_parent"
on storage.objects for select to authenticated
using (
  bucket_id = 'screening-uploads'
  and public.get_my_role() = 'parent'
  and public.is_parent_of_student(((storage.foldername(name))[1])::uuid)
);
create policy "screening_uploads_select_coach_admin"
on storage.objects for select to authenticated
using (
  bucket_id = 'screening-uploads'
  and public.get_my_role() in ('coach','admin')
);
create policy "screening_uploads_delete_admin"
on storage.objects for delete to authenticated
using (
  bucket_id = 'screening-uploads'
  and public.get_my_role() = 'admin'
);


-- ============================================================================
-- 14. SEED- / KATALOGDATEN
--     Idempotent gehaltene Stammdaten aus schema.sql + Migrationen 001/015/026/034.
-- ============================================================================

-- subjects (schema.sql)
insert into subjects (name)
  select v from (values ('Mathematik'),('Deutsch'),('Englisch')) as s(v)
  where not exists (select 1 from subjects where subjects.name = s.v);

-- skill_clusters: 5 KMK-Kompetenzbereiche Mathematik Kl. 8-10 (Migration 001).
insert into skill_clusters (subject_id, name, class_level_min, class_level_max, sort_order)
select s.id, c.name, 8, 10, c.sort_order
from subjects s
cross join (values
  ('Zahl & Rechnen', 1),
  ('Algebra & Funktionen', 2),
  ('Geometrie & Messen', 3),
  ('Daten & Zufall', 4),
  ('Sachrechnen & Modellieren', 5)
) as c(name, sort_order)
where s.name = 'Mathematik'
  and not exists (
    select 1 from skill_clusters sc
    where sc.subject_id = s.id and sc.name = c.name
  );

-- process_competencies: 6 KMK-Prozesskompetenzen / Achse B (Migration 038).
insert into process_competencies (code, name, sort_order)
values
  ('Ope', 'Operieren',        1),
  ('Mod', 'Modellieren',      2),
  ('Pro', 'Problemlösen',     3),
  ('Arg', 'Argumentieren',    4),
  ('Kom', 'Kommunizieren',    5),
  ('Wkz', 'Werkzeuge nutzen', 6)
on conflict (code) do nothing;

-- tiers (Migration 015)
insert into tiers (name, price_cents, features, sort_order)
select v.name, v.price_cents, v.features::jsonb, v.sort_order
from (values
  ('Basic', 8900,
   '["2 Sessions/Woche","Basis-Lernpfad","Monatlicher Eltern-Report"]', 1),
  ('Standard', 12900,
   '["3 Sessions/Woche","KI-Lernpfad","2x Eltern-Report/Monat","Coach-Chat"]', 2),
  ('Premium', 16900,
   '["Unbegrenzte Sessions","Voller KI-Lernpfad","Woechentlicher Report","Prioritaets-Coach","Fachwechsel flexibel"]', 3)
) as v(name, price_cents, features, sort_order)
where not exists (select 1 from tiers where tiers.name = v.name);

-- xp_rules (Migration 026)
insert into xp_rules (content_type, base_xp, difficulty_multiplier) values
  ('exercise', 20, 5),
  ('video', 10, 0),
  ('article', 10, 0),
  ('exercise_group', 0, 0),
  ('course', 0, 0)
on conflict (content_type) do nothing;

-- badge_catalog: 10 reguläre Badges (Migration 034)
insert into public.badge_catalog (id, label, description, rarity, form, trigger) values
  ('first_step',        'Erster Schritt',         'Erste Session abgeschlossen',                   'bronze', 'round', 'first_session_done'),
  ('warmed_up',         'Aufgewärmt',             'Erste 3 Sessions abgeschlossen',                'bronze', 'round', 'three_sessions_done'),
  ('persistent_3',      'Dranbleiber',            '3-Wochen-Präsenz-Streak',                       'silver', 'round', 'presence_streak_3'),
  ('machine_7',         'Maschine',               '7-Wochen-Präsenz-Streak',                       'gold',   'round', 'presence_streak_7'),
  ('hw_hero',           'Hausaufgaben-Held',      '5 Hausaufgaben hochgeladen',                    'silver', 'round', 'hw_uploaded_5'),
  ('exam_warrior',      'Klassenarbeit-Krieger',  'Case A vollständig durchlaufen',                'gold',   'round', 'case_a_complete'),
  ('thinker',           'Durchdenker',            'Erste Reflection als valide bestätigt',         'silver', 'round', 'first_reflection_valid'),
  ('tenacious',         'Hartnäckig',             'Nach 3 Fehlversuchen korrekt gelöst',           'bronze', 'round', 'comeback_correct'),
  ('level_5_reached',   'Level 5 erreicht',       'XP-Level 5 erreicht',                           'silver', 'round', 'xp_level_5'),
  ('master_of_topic',   'Meister des Themas',     'Mastery-Level 7+ in einem Mikro-Skill',         'gold',   'round', 'mastered_microskill')
on conflict (id) do nothing;

-- badge_catalog: Platin (Shield) für Klassen-Abschlüsse 8/9/10 (Migration 034)
insert into public.badge_catalog (id, label, description, rarity, form, klasse, trigger) values
  ('class_8_complete',  'Klasse 8 gemeistert',    'Alle Mikro-Skills Klasse 8 auf Mastered',       'platinum', 'shield', 8,  'class_complete'),
  ('class_9_complete',  'Klasse 9 gemeistert',    'Alle Mikro-Skills Klasse 9 auf Mastered',       'platinum', 'shield', 9,  'class_complete'),
  ('class_10_complete', 'Klasse 10 gemeistert',   'Alle Mikro-Skills Klasse 10 auf Mastered',      'platinum', 'shield', 10, 'class_complete')
on conflict (id) do nothing;

-- ============================================================================
-- 15. P01 – DATENVERTRAG + LSA
--     (supabase/migrations/20260712100000_p01_datenvertrag.sql)
--     Vertragsdokumentation: docs/api/DATENVERTRAG.md
-- ============================================================================
--
-- tasks (additiv, Lenas Metadaten — alles davon ist HARMLOS und darf ans Kind):
--   status             text not null default 'draft' check (draft|review|ready)
--                      → Redaktions-Freigabe. Nur 'ready' kommt in den LSA-Pool.
--                        is_active bleibt unveraendert (Sichtbarkeit im Lernpfad).
--   competency_content text     – Inhaltsfeld (Lena)
--   competency_process text     – Prozesskompetenz als Klartext (strukturiert: competency_id)
--   afb                text check ('I','II','III')
--   est_duration_sec   int check (10..3600)
--   unit               text     – Einheit fuer short_input; rein deklarativ, KEINE Umrechnung
--   dialog_enabled     bool not null default false – Feld fuer den spaeteren Fehler-Dialog
--   Index: tasks_lsa_pool_idx (status, input_type, afb) where status='ready'
--   Backfill: status='ready' fuer alle is_active-Zeilen.
--
-- task_solutions (1:1-Extension zu tasks) – DIE SERVER-ONLY-ZONE:
--   task_id pk → tasks(id) on delete cascade
--   correct_answers jsonb not null default '[]'  – alle akzeptierten Varianten,
--                                                  explizit gepflegt (keine Einheiten-Magie)
--   solution        text                         – der didaktische LOESUNGSWEG
--                                                  (Handarbeit). NICHT der Beleg.
--   beleg           jsonb (B01)                  – die Quellenbelege der Extraktion,
--                                                  pro Feld: [{feld, gate, quelle, zitat}]
--   hints           jsonb not null default '[]'  – [{level, text}]
--   coach_hints     jsonb not null default '[]'  – max 3 (CHECK)
--   typical_errors  jsonb not null default '[]'  – [{error, socratic_question}]
--   updated_at      timestamptz not null default now()
--
--   ⚠️  SICHERHEITSZUSAGE: `revoke all on task_solutions from anon, authenticated`.
--       RLS ist an, es gibt KEINE Policy fuer die API-Rollen. Der Inhalt ist
--       ausschliesslich ueber die SECURITY-DEFINER-RPCs erreichbar.
--       Der REVOKE ist notwendig, weil die default privileges aus
--       20260711120000_api_role_grants.sql jeder neuen Tabelle sonst
--       automatisch DML an authenticated geben.
--       Bewiesen in supabase/tests/inv2_lsa_datenvertrag.test.sql.
--
-- lsa_sessions:
--   id, student_id → students, subject, grade (5..13),
--   status (in_progress|completed|aborted), item_ids uuid[], started_at,
--   completed_at, result_summary jsonb
--   unique (student_id, subject) where status='in_progress'
--   RLS: coach/admin all, parent read. KEIN Schueler-SELECT — result_summary
--        enthaelt die Trefferquoten, und das Kind bekommt in der LSA kein
--        Feedback (CLAUDE §6). Der Schueler sieht seine Session nur durch die RPCs.
--
-- lsa_responses (APPEND-ONLY, analog behavior_snapshots):
--   id, session_id → lsa_sessions, task_id → tasks, response jsonb,
--   correct boolean, duration_ms int
--   unique (session_id, task_id)   – ein Item, eine Antwort
--   RLS: coach/admin + parent read. Kein Schueler-SELECT (die Zeile traegt `correct`).
--        Kein update-, kein delete-Policy.
--
-- Funktionen:
--   lsa_normalize_answer(text) → text          [immutable]
--       trim → Whitespace kollabieren → ERSTES Komma zu Punkt → lowercase.
--       War der Spiegel von normText() aus src/lib/answer/evaluators.ts —
--       die Datei ist mit der Vite-Session weg (T1b). Die Normalisierung lebt
--       jetzt NUR noch hier: eine Konvention, ein Ort.
--   lsa_is_correct(input_type, correct_answers, response) → bool   [immutable]
--       Bekommt die Loesung als Parameter, liest sie nie selbst → leakt nichts.
--   lsa_public_assets(jsonb) → jsonb           [immutable]
--   lsa_question_payload(uuid) → jsonb         [stable, SECURITY DEFINER]
--       DER Vertrag (§1). Baut aus einer WHITELIST: kind/prompt/assets/options/unit.
--       Kopiert nie ein bestehendes jsonb durch — eine Loesung kann strukturell
--       nicht mitrutschen, auch nicht aus tasks.question_payload (das bei
--       Bestandszeilen die Loesung enthaelt).
--       kind: input_type MC → 'mc', SHORT_TEXT/NUMERIC → 'short_input'.
--   lsa_may_act_for(uuid) → bool               [stable, SECURITY DEFINER]
--   lsa_start(student_id, grade, subject) → jsonb          [SECURITY DEFINER]
--       Pool: status='ready' + task_solutions mit >=1 Antwort + input_type in
--       (MC, SHORT_TEXT, NUMERIC) + Fach + class_level <= grade.
--       Round-Robin ueber (AFB × Kompetenzfeld), Zielumfang ~20 min ueber
--       est_duration_sec. → {session_id, total_items, item}
--   lsa_submit(session_id, task_id, response, duration_ms) → jsonb [SEC. DEFINER]
--       Bewertet serverseitig, gibt {ok, next} zurueck — KEIN Richtig/Falsch.
--   lsa_hint(session_id, task_id, level) → jsonb           [SECURITY DEFINER]
--       Hinweise einzeln auf Anfrage (§1), nie vorab im Payload.
--   lsa_finish(session_id) → jsonb                         [SECURITY DEFINER]
--       Auswertung + VORSCHLAG (proposal.is_proposal=true, applied=false).
--       Schreibt KEINEN Lernpfad, KEIN student_focus_areas, KEIN mastered.
--   lsa_confirm_focus(session_id, cluster_ids) → jsonb     [SECURITY DEFINER]
--       FernUSG-Gate: nur coach/admin. Erst hier wird aus dem Vorschlag ein
--       Lernpfad — geschrieben in die BESTEHENDE Tabelle student_focus_areas
--       (source='lsa'). screening_tests wird bewusst NICHT wiederverwendet:
--       generate_parent_report liest dessen result_summary-Format.
--   task_solution_upsert(...) → jsonb                      [SECURITY DEFINER]
--       Lenas Schreibpfad in die Server-Only-Zone. Nur Admin.
--
-- Execute-Grants: Postgres gibt neuen Funktionen automatisch EXECUTE an PUBLIC
--   (= auch anon). Die Migration nimmt das weg und grantet gezielt an
--   authenticated/service_role; die internen Helfer nur an service_role.

-- ============================================================================
-- 16. P02 – MULTI-PART-AUFGABENTYP
--     (supabase/migrations/20260713100000_p02_multipart.sql)
--     Vertragsdokumentation: docs/api/DATENVERTRAG.md §6
-- ============================================================================
--
-- Eine Aufgabe, mehrere Teilaufgaben. Jede Teilaufgabe hat einen eigenen
-- Antworttyp, eine eigene Kompetenz und ein eigenes AFB. Ausgewertet wird PRO
-- TEILAUFGABE — ein Item mit drei Teilaufgaben liefert drei Kompetenz-Datenpunkte.
-- Ein Item-Gesamtergebnis gibt es bewusst NICHT (eine "2 von 3"-Quote waere
-- diagnostisch wertlos).
--
-- tasks:
--   input_type            + 'MULTI_PART' (tasks_input_type_check neu gesetzt;
--                           Bestand aus 042: MC, NUMERIC, SHORT_TEXT, TRUE_FALSE,
--                           FREE_TEXT, MATCHING, CLOZE, COORDINATE)
--   parts   jsonb not null default '[]'
--           [{nr, kind(short_input|mc), prompt, unit?, options?,
--             competency_content?, competency_process?, afb?}]
--           → WARUM eine eigene Spalte: die Teilaufgabe traegt ihre EIGENE
--             Kompetenz. tasks.competency_content/_process/afb sind skalar (einmal
--             pro Item) und koennen das nicht halten. Ohne diese Spalte waere die
--             Kompetenz je Teilaufgabe — der Kern der Diagnostik — verloren.
--           → Die Loesung liegt NICHT hier, sondern in task_solutions.
--   Index: tasks_parts_idx (gin) where input_type='MULTI_PART'
--
--   CHECK tasks_multipart_check — der Import-Filter als DB-Zusage:
--     MULTI_PART ⇒ lsa_parts_valid(parts)               (>=2 Teilaufgaben, nr
--                                                        eindeutig, kind nur
--                                                        short_input|mc, prompt
--                                                        nicht leer, MC mit >=2
--                                                        Optionen, KEIN Loesungsfeld)
--                  UND question <> ''                    (Stamm ist Pflicht: ein
--                                                        Multi-Part ohne abtrennbaren
--                                                        Stamm ist keines → Import
--                                                        verweigern)
--                  UND est_duration_sec is not null      (Zeitbudget: vier
--                                                        Teilaufgaben kosten vier
--                                                        Aufgaben Zeit — lsa_start
--                                                        darf das nicht schaetzen)
--     sonst        ⇒ parts = '[]'
--
-- task_solutions:
--   correct_answers  jsonb — jetzt Array ODER Objekt (CHECK: lsa_answers_valid):
--     flach:      ["0,3 m","30 cm"]
--     multi-part: {"1":["20"],"2":["b"],"3":["16"]}   ← Schluessel = Teilaufgaben-nr
--   Beide Formen koexistieren. Die 14 flachen Bestandsitems brechen nicht.
--
-- lsa_responses:
--   part_nr int (null bei flachen Items, >=1 bei Teilaufgaben)
--   unique (session_id, task_id) ENTFERNT — sie haette die zweite Teilaufgabe
--     desselben Items abgewiesen. Ersetzt durch den Unique-INDEX
--     lsa_responses_once_per_part (session_id, task_id, coalesce(part_nr, 0)).
--   Eine Zeile PRO TEILAUFGABE. Bestandszeilen: part_nr = null.
--   duration_ms ist bei Multi-Part die Dauer des GESAMTEN Items (der Client misst
--     nicht pro Teilaufgabe) und steht deshalb auf jeder Teilaufgaben-Zeile gleich.
--
-- Funktionen (neu):
--   lsa_parts_valid(jsonb) → bool     [immutable]  – Strukturvertrag, steht im CHECK
--   lsa_answers_valid(jsonb) → bool   [immutable]  – Array|Objekt, steht im CHECK
--   lsa_public_parts(jsonb) → jsonb   [immutable]  – Whitelist je Teilaufgabe:
--       nr/kind/prompt/unit/options(id,label). Kein competency_*, kein afb, keine
--       Loesung — es wird gebaut, nicht durchgereicht.
--   lsa_part_answer(kind, jsonb) → jsonb [immutable] – uebersetzt die skalare
--       Teilantwort ("20") in die StudentAnswer-Form ({text}/{selected}), damit
--       lsa_is_correct die EINZIGE Bewertungskonvention bleibt.
--   lsa_has_answers(input_type, parts, correct_answers) → bool [immutable]
--       Pool-Eignung. Bei MULTI_PART braucht JEDE Teilaufgabe eine Loesung.
--
-- Funktionen (geaendert):
--   lsa_question_payload(uuid)  – neuer Zweig MULTI_PART:
--       { kind:'multi_part', task_id, stem, assets, parts:[…] }
--       Die Whitelist gilt REKURSIV (pgTAP inv3 prueft den gesamten Payload-Text).
--   lsa_start(...)              – MULTI_PART im Pool; gezogen wird gegen das
--       Zeitbudget (Summe est_duration_sec, ~1200 s), nicht gegen eine Item-Anzahl.
--       Der coalesce-Fallback (estimated_minutes*60, 180) greift nur noch fuer
--       FLACHE Bestandsitems — MULTI_PART hat est_duration_sec per CHECK.
--   lsa_submit(...)             – Multi-Part: p_response = {"1":"20","2":"b"}.
--       Unterschieden wird am input_type der TASK, nicht an der Form des Payloads.
--       Schreibt eine lsa_responses-Zeile je Teilaufgabe. Die Antwort bleibt
--       {ok, next} — kein correct, kein Score, kein Zaehler, auf keiner Ebene.
--   lsa_finish(...)             – result_summary aggregiert ueber TEILAUFGABEN nach
--       Kompetenz (aus tasks.parts, Fallback auf die Item-Kompetenz bei flachen
--       Items). Neu: 'answered_parts' (Datenpunkte) neben 'answered' (Items).
--       Kein Item-Score, keine Item-Quote.
--
-- Beweis: supabase/tests/inv3_lsa_multipart.test.sql (pgTAP, 23 Assertions).
--   inv2 bleibt unveraendert gruen — die flachen Items laufen weiter.

-- ============================================================================
-- 17. B01 – QUELLENBELEG + ROLLENBASIERTE RLS AUF `tasks`
--     (supabase/migrations/20260714140000_b01_beleg_und_rls.sql)
-- ============================================================================
--
-- task_solutions:
--   beleg jsonb (nullable, CHECK: array)
--     [{feld:"part1.correct_answers", gate:"G2", quelle:"Auswertung (RICHTIG-Zelle)",
--       zitat:"16"}, …] – die Struktur des _grounding aus der Extraktion
--       (src/types/authoring.ts: GroundingBeleg).
--     WARUM: C08 hat den Quellenbeleg mangels Zuhause nach `solution` geschrieben —
--       in das Feld, das den didaktischen Loesungsweg traegt. Wer im Autoren-Tool
--       einen Loesungsweg schreibt, haette den Beleg ueberschrieben. Zwei Dinge,
--       zwei Spalten.
--     Bestandsdaten: die 229 C08-Belege wurden aus `solution` herausgeloest
--       (Kriterium: der maschinell erzeugte Blockanfang "[<feld …correct_answers>";
--       Roundtrip-Pruefung, Abbruch statt Heuristik). `solution` steht damit leer
--       fuer den echten Loesungsweg.
--
-- task_solution_get(uuid):   liefert `beleg` mit. Haertung unveraendert: coach/admin.
-- task_solution_upsert(...): +p_beleg jsonb, und PATCH-Semantik fuer ALLE Parameter —
--       NULL = "nicht mitgeschickt" = unveraendert. Der Import schreibt den Beleg,
--       ohne den Loesungsweg zu loeschen; der Editor umgekehrt. Explizit geleert
--       wird mit '' (solution), 'null'::jsonb (beleg), '[]' (Arrays).
--       Die alte 6-stellige Signatur ist gedroppt (PostgREST kann zwei
--       Ueberladungen mit Defaults nicht eindeutig aufloesen).
--
-- tasks (RLS):
--   authenticated_read_tasks  → GEDROPPT (qual: auth.role() = 'authenticated' —
--                               "eingeloggt" ist keine Rolle).
--   read_tasks_by_role        → coach/admin lesen alles (Item-Pflege), jede andere
--                               Rolle nur status='ready'. anon: get_my_role() ist
--                               NULL → keine Zeile.
--   admin_write_tasks         → unveraendert.
--   Die LSA-RPCs sind SECURITY DEFINER und von der Policy nicht betroffen.
--
-- Beweis: supabase/tests/inv7_draft_nicht_fuer_schueler.test.sql (pgTAP, 12
--   Assertions: Schueler sieht nur ready, Coach sieht drafts, Beleg ueber keinen
--   Weg erreichbar, lsa_start liefert weiterhin Items). inv6 bleibt gruen.

-- ============================================================================
-- 18. A02 – SCHUELER-VORSCHAU IM AUTOREN-TOOL
--     (supabase/migrations/20260714150000_a02_vorschau.sql)
-- ============================================================================
--
-- task_preview_payload(p_task_id uuid, p_draft jsonb default null) → jsonb
--   [volatile, SECURITY DEFINER, set search_path = public]
--   Rolle: coach/admin (Body-Check, errcode 42501). revoke from public,
--          grant to authenticated, service_role.
--
--   WAS SIE IST: ein Tor vor lsa_question_payload — kein zweiter Builder. Der Body
--     ruft `public.lsa_question_payload(p_task_id)` auf und gibt dessen Ergebnis
--     unveraendert zurueck. Dieselbe Funktion, dieselbe Whitelist, dieselbe
--     Wahrheit; nur ohne LSA-Session, damit die Vorschau ein EINZELNES Item bauen
--     kann. lsa_question_payload selbst bleibt unberuehrt.
--
--   WARUM UEBERHAUPT: die Vorschau im Autoren-Tool hat den Payload bisher im
--     Frontend nachgebaut. Sie zeigte damit, was der Editor denkt — nicht, was das
--     Kind sieht. F01 (die Aufgaben-Tabelle) ist genau daran vorbeigelaufen: der
--     Server lieferte sie, die Vorschau kannte sie nicht.
--
--   p_draft (der ungespeicherte Formularstand): wird in einer PL/pgSQL-
--     Subtransaktion auf die Zeile gespielt, lsa_question_payload baut daraus, und
--     die Subtransaktion wird per `raise ... errcode = 'ED001'` ZURUECKGEROLLT (die
--     PL/pgSQL-Variable ueberlebt den Abbruch, die Zeilenaenderung nicht). Die
--     Alternative waere gewesen, den Entwurf im Frontend zu bauen — also die zweite
--     Wahrheit durch die Hintertuer. Uebernommen werden nur die sechs Spalten, die
--     der Builder ueberhaupt liest: question, input_type, unit, parts, assets,
--     question_payload.
--     Folge mit Ansage: die CHECKs auf `tasks` feuern auf dem Entwurf mit. Ein
--     Entwurf, der nicht speicherbar waere, ist auch nicht vorschaubar (23514).
--
-- Beweis: supabase/tests/inv8_vorschau_ohne_loesung.test.sql (pgTAP, 16 Assertions):
--   Schueler-Kontext → permission denied (Lese- UND Entwurfspfad, damit die
--   Vorschau dem Schueler kein UPDATE schenkt); anon hat nicht mal das Grant;
--   task_preview_payload(id) = lsa_question_payload(id) als Gleichheit (nicht als
--   Feldliste — sonst faellt das naechste Vertragsfeld wieder durch); der Payload
--   traegt REKURSIV kein Loesungsfeld (pg_temp.all_keys steigt in parts und table
--   hinab), obwohl der Sentinel als `accepted` neben der Tabelle im selben
--   question_payload liegt; und die tasks-Zeile ist nach einem Entwurfs-Aufruf
--   unveraendert.

-- ============================================================================
-- 19. S7 – LEAD→LSA: PROVISORISCHES SCHUELERKONTO (A1 OPTION 1) + INTAKE-FELDER
--     (supabase/migrations/20260716100000_s7_lead_lsa.sql)
--     Baut auf S5/Ebene A auf: lead_assessments (a3), lead_delete (a2),
--     tasks.is_tutorial (a4) — siehe die jeweiligen Migrationen.
-- ============================================================================
--
-- students (Spalten, additiv — P01-Datenvertrag byte-identisch):
--   is_provisional boolean not null default false
--       Provisorischer Lead-Schueler: profile_id NULL, kein Auth-Konto, kein
--       Abo. Zaehlt NIRGENDS als Schueler — jedes Aggregat filtert
--       is_provisional=false (src/lib: adminStats, listStudents*).
--   lead_id uuid references leads(id) on delete cascade
--       Der Loeschanker: lead_delete kaskadiert
--       leads → students(lead_id) → lsa_sessions → lsa_responses (DSGVO).
--   CHECK students_provisional_lead_ck: is_provisional = (lead_id is not null).
--   UNIQUE students_lead_unique on (lead_id) where lead_id is not null
--       — genau ein provisorischer Schueler pro Lead (Idempotenz-Anker).
--
-- leads (Spalten, Teil B — Fragenkatalog Erstgespraech, KEINE Diagnose-Felder):
--   first_name text                  — Rufname („Hi <Name>" auf dem Tablet)
--   birth_date date, last_grade text
--   grade_trend text                 — CHECK in (besser, stabil, schlechter)
--   struggling_since text            — CHECK in (dieses_halbjahr,
--                                      letztes_schuljahr, laenger)
--   tried_before text[]              — offene Liste, bewusst ohne CHECK
--   next_exam_date date, next_exam_topic text
--   consent_dsgvo_at timestamptz, consent_dsgvo_by uuid → profiles
--       — PFLICHT vor der LSA-Freigabe (lead_lsa_freigeben verweigert sonst).
--   status-CHECK erweitert um 'lsa_freigegeben', 'lsa_fertig'.
--
-- RPCs [alle SECURITY DEFINER, search_path=public, revoke from public,
--       grant to authenticated + service_role, Rollenpruefung im Body]:
--   lead_lsa_freigeben(p_lead_id, p_grade, p_subject) → jsonb   [nur admin]
--       Gates: Lead existiert (P0002), nicht converted (P0001),
--       consent_dsgvo_at gesetzt (P0001). Legt idempotent den provisorischen
--       Schueler an (GUC-Schleuse edvance.allow_provisional, transaktionslokal)
--       und startet die Session ueber das UNVERAENDERTE public.lsa_start —
--       kein Duplikat, kein Overload (A3-Invariante haelt).
--       Setzt leads.status='lsa_freigegeben'.
--       Rueckgabe: session_id, student_id, total_items.
--   lead_convert(p_lead_id) → jsonb                              [nur admin]
--       Datensatz-Flip: students.is_provisional=false + lead_id=null (eine
--       spaetere Lead-Loeschung darf NIE den echten Schueler kaskadieren),
--       leads.status='converted' + converted_student_id. Auth-Konto folgt
--       separat (nicht Teil von S7).
--   lead_delete(p_lead_id)                                       [nur admin]
--       Logik unveraendert (a2); der TODO-Block ist eingeloest: die neue
--       FK-Kaskade raeumt Schueler + LSA-Daten restlos mit ab.
--   lead_assessment_upsert(p_lead_id, p_source, p_note, p_weak_topics)
--       → jsonb                                             [coach + admin]
--       Upsert auf (lead_id, source); source nur parent/child (23514).
--       Reveal-Metadatum — NIE Input fuer lsa_start (A3-Invariante, inv_a3 +
--       s7-Regression).
--
-- Trigger:
--   students_guard_provisional_trg (before insert/update of is_provisional)
--       — provisorische Zeilen entstehen NUR ueber lead_lsa_freigeben.
--   subscriptions_guard_provisional_trg (student_subscriptions)
--       — ein provisorischer Schueler traegt NIE ein Abo (P0001).
--   lsa_session_lead_fertig_trg (lsa_sessions, after update of status)
--       — Session eines provisorischen Schuelers completed → Lead auf
--       'lsa_fertig'. Additiv; lsa_finish selbst bleibt byte-identisch.
--
-- Beweis: supabase/tests/s7_lead_lsa.test.sql (pgTAP, 38 Assertions).

-- ============================================================================
-- 20. S9 – PLATZ-MECHANIK: KIOSK FUER DIE LSA (Option 3, docs/specs/PLATZ-analyse.md)
--     (supabase/migrations/20260716110000_s9_platz_mechanik.sql)
--     Eingrenzung verbindlich: NUR die LSA. Ein Platz erreicht ausschliesslich
--     die ihm aktuell zugewiesene Session — nie Hub, XP, student_progress,
--     fremde oder vergangene Sessions. P01-Datenvertrag byte-identisch
--     (einzige bewusste Ausnahme: das GRANT von lsa_question_payload, s.u.).
-- ============================================================================
--
-- platz_devices (Tabelle):
--   profile_id uuid PK → profiles on delete cascade, label text, created_at
--       Kennzeichnung der Kiosk-Konten. Ein Platz ist ein normaler Auth-User
--       mit role='student' OHNE students-Zeile — strukturell „nichts"
--       (get_my_student_id()=null → alle lsa_* verweigern). KEINE neue Rolle,
--       kein CHECK-Umbau. RLS: admin all; der Platz liest die eigene Zeile.
--
-- platz_assignments (Tabelle):
--   id PK, platz_profile_id → platz_devices, session_id → lsa_sessions,
--   created_by uuid → profiles (Auftrags-Identitaet: der zuweisende Admin),
--   created_at, expires_at (default now()+2h), released_at
--       SESSION-scoped (nicht schueler-scoped): vergangene/parallele Sessions
--       desselben Kindes sind nicht adressierbar. Aktiv = released_at null UND
--       expires_at > now() — in JEDER RPC geprueft (Analyse §3.4).
--       Partial-Unique (platz_profile_id) where released_at is null.
--       RLS: admin all; der Platz liest NUR die eigene aktive Zeile.
--
-- RPCs [alle SECURITY DEFINER, search_path=public, revoke from public,
--       Rollen-/Kontext-Pruefung im Body]:
--   platz_current_assignment() → platz_assignments   [intern, nur service_role]
--       Die EINE aktive, nicht abgelaufene Zuweisung von auth.uid().
--   platz_assign(p_platz_profile_id, p_session_id) → jsonb        [nur admin]
--       Gates: platz_devices-Zeile (P0002), Session in_progress (P0001),
--       keine aktive Zuweisung (P0001). Raeumt abgelaufene Alt-Zeilen
--       (Partial-Unique). Schreibt created_by fest.
--   platz_release(p_assignment_id) → jsonb                        [nur admin]
--       Manuelle Freigabe, idempotent; P0002 bei unbekannter Zuweisung.
--   platz_state() → jsonb                                     [nur Platz-Konto]
--       Kiosk-Poll: {status:'wartet'} | {status:'zugewiesen', first_name
--       (session → students.lead_id → leads.first_name), progress, expires_at}.
--       Traegt NIE session_id/student_id/lead_id/Auswertung.
--   platz_next() → jsonb                                      [nur Platz-Konto]
--       Naechstes offenes Item der ZUGEWIESENEN Session, Payload aus dem
--       UNVERAENDERTEN lsa_question_payload. Kein Parameter von aussen.
--   platz_submit(p_task_id, p_response, p_duration_ms) → jsonb [nur Platz-Konto]
--       Validiert p_task_id = aktuell offenes Item, reicht an das
--       UNVERAENDERTE lsa_submit durch — mit der Auftrags-Identitaet
--       created_by (transaktionslokaler Claims-Tausch, in derselben Funktion
--       geschlossen). Rueckgabe {ok, next} — kein Richtig/Falsch.
--   platz_finish() → jsonb                                    [nur Platz-Konto]
--       Ruft das UNVERAENDERTE lsa_finish und VERWIRFT dessen Auswertung —
--       Rueckgabe exakt {ok:true}.
--
-- Trigger:
--   lsa_session_platz_release_trg (lsa_sessions, after update of status)
--       — completed ODER aborted → alle offenen Zuweisungen der Session
--       released. Additiv; lsa_finish bleibt byte-identisch.
--
-- Grant-Aenderung (§3.6(ii) der Analyse, bewusst gewaehlt):
--   revoke execute on lsa_question_payload from authenticated — der Builder
--   ist nur noch ueber seine Tore erreichbar (lsa_start/lsa_submit intern,
--   task_preview_payload fuer Coach/Admin, platz_next fuer den Platz).
--   Kein Client ruft ihn direkt (verifiziert: kein .rpc(...) in src/**).
--   Die inv2/3/5/6/7/8-Tests pruefen den Inhalts-Vertrag seither im
--   Definer-Kontext; die Nicht-Aufrufbarkeit pinnt s9_platz_mechanik.test.sql.
--
-- Beweis: supabase/tests/s9_platz_mechanik.test.sql (pgTAP, 69 Assertions):
--   (1) Platz ohne Zuweisung: 'wartet', alle lsa_* → 42501, RLS zeigt 0 Zeilen
--   (Anti-Vakuum inklusive); (2) mit Zuweisung: genau die EINE Session, die
--   zweite ist ueber keinen Parameter erreichbar, lsa_* bleiben auch dann zu;
--   (3) nach lsa_finish / expires_at / platz_release / abort faellt alles auf
--   'wartet'/42501 zurueck; plus P01-Regression (keine lsa_*-Funktion kennt
--   'platz', kein Overload, anon ohne jedes Grant).

-- ============================================================================
-- 21. S10 – SLOT-SYSTEM: WOCHENRASTER, FAVORITEN UND FESTE ZUWEISUNG
--     (supabase/migrations/20260719100000_s10_slot_system.sql)
--     Architektur-Branchpoint: alle drei Tabellen haengen an leads(id), NICHT
--     an students(id) — der Slot wird im Erstgespraech vergeben, also VOR
--     Vertragsabschluss. Zu dem Zeitpunkt existiert der Lead, kein Kind. Ein
--     students-FK haette eine provisorische Schueler-Zeile erzwungen
--     (A1-Leitplanke) oder die Vergabe ans Gespraechsende verschoben.
-- ============================================================================
--
-- slots (Tabelle):
--   id PK, created_at, weekday smallint CHECK 0..6 (0=Montag … 6=Sonntag,
--   bewusst NICHT extract(dow)), start_time time, room text (nicht leer),
--   capacity integer default 5 CHECK 1..5, active boolean default true
--       Das Wochenraster (Wochentag × Uhrzeit × Raum). Der capacity-CHECK
--       pinnt die Produktzusage „Kleingruppen max. 5" im Schema.
--       Deaktivieren statt loeschen — bestehende Zuweisungen bleiben lesbar.
--       Partial-Unique (weekday, start_time, room) where active: ein Raum
--       traegt zu einer Zeit eine aktive Gruppe; deaktivierte Alt-Slots
--       blockieren die Koordinate nicht. RLS: coach/admin all, anon nichts.
--
-- slot_wishes (Tabelle):
--   id PK, created_at, lead_id → leads cascade, slot_id → slots cascade,
--   rang smallint CHECK 1..3
--       Bis zu 3 Favoriten je Lead (Erstgespraech, S8). UNVERBINDLICH — ein
--       Wunsch reserviert nichts und zaehlt nie gegen die Kapazitaet.
--       Unique (lead_id, rang) und (lead_id, slot_id). Das Frontend setzt die
--       Liste als Ganzes neu (delete + insert), damit Raenge nie Luecken
--       haben; die Indizes sind die Absicherung darunter.
--       RLS: coach/admin all, anon nichts.
--
-- slot_assignments (Tabelle):
--   id PK, slot_id → slots cascade, lead_id → leads cascade, assigned_at,
--   released_at, created_by uuid → profiles on delete set null
--       Die feste Zuweisung. Aktiv = released_at is null; Loesen setzt
--       released_at statt zu loeschen, damit die Belegungshistorie („welches
--       Kind sass wann in welcher Gruppe") lesbar bleibt. created_by set null:
--       faellt das Konto des Zuweisenden, bleibt die Zuweisung — sie gehoert
--       dem Lead, nicht dem Admin.
--       Partial-Unique (lead_id) where released_at is null — die ZWEITE
--       Verteidigungslinie der Kapazitaets-Garantie, wirksam auch an der RPC
--       vorbei. Partial-Index (slot_id) where released_at is null traegt das
--       Zaehlen der Auslastung. RLS: coach/admin all, anon nichts.
--
-- DIE KAPAZITAETS-GARANTIE (die eigentliche Zusage dieses Abschnitts):
--   Ein naives „erst zaehlen, dann einfuegen" ueberbucht unter Nebenlaeufigkeit
--   — zwei gleichzeitige Zuweisungen lesen beide belegt=4 bei capacity=5 und
--   fuegen beide ein. Deshalb sperrt slot_assign() ZUERST die slots-Zeile
--   (select … for update) und zaehlt erst danach; die zweite Transaktion
--   wartet am Lock und sieht den Stand nach der ersten. Der Lock liegt auf dem
--   SLOT — nur Zuweisungen in denselben Slot serialisieren. Darunter der
--   partielle Unique-Index auf (lead_id). Es gibt genau eine Wahrheit: das
--   Frontend zeigt die Auslastung nur an, es entscheidet sie nicht
--   (src/lib/supabase/slots.ts).
--
-- RPCs [beide SECURITY DEFINER, search_path=public, revoke from public,
--       Rollenpruefung im Body, grant an authenticated + service_role]:
--   slot_assign(p_slot_id, p_lead_id) → jsonb            [coach/admin]
--       Row-Lock auf slots, loest eine bestehende aktive Zuweisung des Leads
--       (vor dem Zaehlen, damit ein Re-Assign in denselben Slot sich nicht
--       selbst als Ueberbuchung sieht), prueft belegt < capacity, fuegt ein.
--       Fehler: P0002 (Lead/Slot unbekannt), P0001 (Slot deaktiviert oder
--       ausgebucht). Rueckgabe {ok, assignment_id, belegt, capacity}.
--   slot_release(p_assignment_id) → jsonb                [coach/admin]
--       Setzt released_at. Idempotent (released=false bei bereits geloester
--       Zeile, Muster wie platz_release); P0002 bei unbekannter Zuweisung.
--
-- OFFENE FRAGE (bewusst nicht hier entschieden, Gruenderrunde):
--   Was passiert mit einer Slot-Zuweisung, wenn der Lead ueber lead_convert()
--   zum Studenten wird — wandert sie mit, oder bleibt sie am Lead und wird
--   ueber leads.converted_student_id aufgeloest? Teil eines groesseren
--   Musters: auch der Kindname faellt heute nach der Konvertierung weg.
--   Die Migration legt sich nicht fest; released_at statt delete haelt den
--   Zustand in jedem Fall nachvollziehbar.

-- ============================================================================
-- ENDE – konsolidiertes Schema (41 Tabellen, 36 Funktionen, 2 Enums, 1 Trigger).
-- 21. R1 – ELTERN-REPORT: COACH-NOTIZEN AN DER LSA-SITZUNG
--     (supabase/migrations/20260719100000_r1_report_notes.sql)
-- ============================================================================
--
-- lsa_report_notes (Tabelle):
--   id uuid PK, session_id uuid NOT NULL UNIQUE → lsa_sessions on delete cascade
--   zielbild text, empfehlung text
--   paket text CHECK in ('basis','standard','premium')
--   updated_at timestamptz not null default now()
--   updated_by uuid → profiles(id) on delete set null
--   INDEX lsa_report_notes_session_idx (session_id)
--   RLS an, revoke all from anon, EINE Policy
--   lsa_report_notes_coach_admin_all (for all, using+with check
--   get_my_role() in ('coach','admin')).
--
-- WAS SIE IST: die einzige schreibbare Flaeche des Eltern-Reports. Der Report
--   (src/pages/admin/ReportPage.tsx) liest Sitzung + Antworten READ-ONLY; nur
--   diese drei Coach-Felder werden gespeichert.
--
-- WARUM eine eigene Tabelle statt Spalten an lsa_sessions: die Notizen sind
--   KEINE Auswertung. Sie erzeugen keinen Score, keine Note, keinen Prozentrang
--   — und sie duerfen die Sitzungsdaten nicht anfassen (§6: Rohdaten
--   append-only). Als eigene Zeile koennen sie ueberschrieben werden, ohne dass
--   je ein Rohdatensatz mutiert.
--
-- 1:1 zur Sitzung ueber UNIQUE(session_id) — der Client schreibt per upsert auf
--   session_id (src/lib/supabase/reportNotes.ts), ein Report pro Sitzung.
--   on delete cascade haengt die Notizen an den bestehenden DSGVO-Loeschanker:
--   leads → students(lead_id) → lsa_sessions → lsa_responses/lsa_report_notes.
--
-- paket als CHECK statt Enum: Paketnamen sind Vertriebs-Sprache und aendern
--   sich schneller als ein Typ, der in Funktionssignaturen einfriert.
--
-- KEIN neues Grant, KEINE Aenderung an task_solutions, lsa_responses,
--   lsa_sessions oder einer bestehenden Funktion. Die Bewertung im Report liest
--   ausschliesslich lsa_responses.correct.
--
-- Vor dieser Migration erkennt reportNotes.ts den Postgres-Fehler 42P01
--   (undefined_table) und kennzeichnet die Felder als „noch nicht speicherbar";
--   der uebrige Report bleibt nutzbar.

-- ============================================================================
-- 22. A09 – LIZENZTEXT AN DER AUFGABE
--     (supabase/migrations/20260720100000_a09_lizenztext.sql)
-- ============================================================================
--
-- tasks.licence_text text NULL
--   Der einblendbare Attributionstext der Aufgabe. Die VERA-8-Abbildungen
--   stehen unter CC BY 4.0 (IQB); CC BY verlangt beim Zeigen eine Namensnennung
--   (Titel, Autor, Quelle, Lizenz — TASL, soweit verfuegbar). Der Lizenzstatus
--   im Quellenbeleg (_grounding.lizenz_status) sagt nur, DASS attribuiert werden
--   muss — dieses Feld haelt, WIE.
--
-- WARUM an der AUFGABE und nicht pro Asset oder pro Teilaufgabe: ein Item traegt
--   in der Praxis eine Abbildung, und selbst bei mehreren stammen sie aus
--   derselben Quelle mit derselben Lizenz. Ein Feld je Bild waere dieselbe Zeile
--   mehrfach — mit dem Risiko, dass sie auseinanderlaeuft.
--
-- WARUM nullable und ohne CHECK: die grosse Mehrheit der Items hat kein Bild und
--   damit nichts zu attribuieren. Die Pflicht ist bedingt („Bild da → Text da")
--   und sitzt im Freigabe-Gate des Autoren-Tools (src/lib/authoring/flags.ts,
--   Flag `licenceMissing`, blockierend) — genau dort, wo schon die Alt-Text-
--   Pflicht sitzt. Ein CHECK ueber tasks.assets waere bei jedem Import und jedem
--   Altbestand-Update im Weg.
--
-- VORBEFUELLUNG: src/lib/authoring/attribution.ts baut aus dem Quellenbeleg den
--   CC-BY-4.0-konformen Standardtext (EINE Stelle, damit die Rechtsberatung die
--   Formel spaeter zentral schaerfen kann). Der Wizard setzt ihn ein, sobald ein
--   Bild zugewiesen ist und das Feld leer war; der Pfleger kann ihn
--   ueberschreiben — eingebettetes Fremdmaterial in einer VERA-Aufgabe braucht
--   eine abweichende Nennung.
--
-- KEIN Schueler-Feld auf diesem Weg: lsa_question_payload baut aus einer
--   Whitelist, lsa_public_assets reicht je Asset nur { url, alt } durch. Der
--   Text wird beim Einblenden bewusst dazugeholt, er kommt nicht versehentlich
--   mit. KEINE Aenderung an einer bestehenden Funktion, Policy oder Grant.

-- ============================================================================
-- 23. A10 – AKZEPTANZ-SET + AFB-III-OPTION-SCORING
--     (supabase/migrations/20260721100000_a10_akzeptanz_und_scoring.sql)
-- ============================================================================
--
-- Zwei Felder, die die auto-gradbare Diagnostik braucht. Beide sind
-- LOESUNGSDATEN und liegen deshalb in der Server-Only-Zone `task_solutions`
-- (P01 §4) — nicht an `tasks`, nicht in `tasks.parts`.
--
-- task_solutions.acceptance jsonb NULL   — DAS AKZEPTANZ-SET
--   Warum eine Antwort zaehlt, maschinenlesbar. Eine Regel:
--     { canonical:"1,5 m", equivalents:["150 cm","1500 mm"],
--       notation:{decimal_comma,unit_optional,ignore_case,ignore_space},
--       tolerance:{mode:'exact'|'absolute'|'decimals', value},
--       unit:"m", unit_graded:false }
--   Flach EINE Regel, bei MULTI_PART {"<nr>": Regel} — dieselbe Doppelform wie
--   correct_answers, kein drittes Format.
--   CHECK task_solutions_acceptance_check → lsa_acceptance_valid.
--
--   WARUM notation als FLAGS, equivalents als LISTE: Notationsvarianten sind
--     eine Regel (jede Zahl mit Komma ist auch mit Punkt richtig) — sie
--     einzeln aufzuzaehlen ist Kombinatorik und laeuft auseinander. Ein
--     EINHEITEN-Wechsel ist dagegen eine fachliche Aussage ("150 cm ist
--     dieselbe Laenge") und gehoert einzeln benannt.
--   WARUM unit_graded: manchmal IST die geforderte Einheit Teil der Kompetenz
--     ("Gib das Ergebnis in Metern an") — dann darf "150 cm" NICHT zaehlen.
--     Das entscheidet die Aufgabe, nicht eine Umrechnung. unit_graded=true
--     schliesst notation.unit_optional=true aus; der Widerspruch ist im CHECK
--     unrepraesentierbar.
--   DEKLARATIV: lsa_is_correct bleibt byte-identisch — bewertet wird weiterhin
--     gegen correct_answers. Der Evaluator-Umbau ist ein eigener Lauf.
--
-- task_solutions.option_scores jsonb NULL — DAS AFB-III-OPTION-SCORING
--   Bewertungsstufe je Antwortoption: { "<option_id>": 'voll'|'teilweise'|'nicht' },
--   bei MULTI_PART {"<nr>": {…}}. CHECK task_solutions_option_scores_check →
--   lsa_option_scores_valid.
--
--   KONSTRUKTIONSREGEL: pro Aufgabe/Teilaufgabe GENAU EINE Option 'voll' und
--     GENAU EINE 'teilweise', alle uebrigen 'nicht'. Die Stufe haengt an der
--     EINZELNEN OPTION, nicht am Urteil — mehrere Optionen duerfen dasselbe
--     Ja/Nein-Urteil tragen (sie unterscheiden sich in der Begruendung), nur
--     eine davon ist 'teilweise'.
--   Der CHECK erzwingt HOECHSTENS eine je Stufe (nie zwei); die
--     Vollstaendigkeit ist eine FREIGABE-Regel, kein Speicher-Verbot — ein halb
--     gepflegter Entwurf muss speicherbar bleiben.
--   AFB I/II bleibt binaer: dort ist die Spalte NULL.
--
-- WARUM in task_solutions und nicht an parts[].options: `tasks` ist fuer jede
--   eingeloggte Rolle lesbar (Policy read_tasks_by_role, Schueler:innen alles
--   mit status='ready') und PostgREST bietet select=* an. Ein Bewertungsfeld an
--   der oeffentlichen Option waere fuer jedes Schuelergeraet abrufbar — genau so
--   ist der Altbestand-Leak entstanden (T1). Die Stufe haengt deshalb ueber die
--   Option-ID an der Option, nicht in ihr; die oeffentliche Option behaelt
--   exakt {id, label}.
-- WARUM JSONB statt eigener Tabelle: eine Zeile je Option waere relational
--   sauberer, braeuchte aber eigene RLS, eigene Grants, eigene RPCs — die
--   Server-Only-Zusage muesste ein zweites Mal bewiesen werden. task_solutions
--   traegt die Loesung schon als JSONB mit derselben Doppelform.
--
-- Funktionen (neu, alle immutable):
--   lsa_acceptance_rule_valid(jsonb)      – Strukturvertrag EINER Regel
--   lsa_acceptance_valid(jsonb)           – Doppelform, steht im CHECK
--   lsa_option_scores_scale_valid(jsonb)  – EINE Skala, hoechstens 1× je Stufe
--   lsa_option_scores_valid(jsonb)        – Doppelform, steht im CHECK
--   lsa_option_scores_complete(afb, options, scale) – die FREIGABE-Regel:
--       bei afb='III' genau eine 'voll', genau eine 'teilweise', jede Option
--       bewertet, keine fremde Option in der Skala. Muster wie lsa_has_answers:
--       bekommt alles als Parameter, liest nie selbst → leakt nichts.
--       NOCH NICHT in task_status_set verdrahtet (der Bestand hat keine Skala).
--
-- Funktionen (geaendert):
--   task_solution_get(uuid)     – liefert acceptance + option_scores mit.
--                                 Haertung unveraendert: nur coach/admin.
--   task_solution_upsert(...)   – +p_acceptance, +p_option_scores (9-stellig;
--       die 7-stellige Signatur wird gedroppt statt ueberladen — PostgREST kann
--       zwei Ueberladungen mit Defaults nicht aufloesen). PATCH-Semantik aus B01
--       unveraendert; geleert wird mit 'null'::jsonb. Beide Felder werden vor
--       dem Schreiben gegen ihren Strukturvertrag geprueft, damit der Editor
--       eine Klartext-Meldung bekommt statt eines CHECK-Fehlers.
--
-- KEIN LEAK: lsa_question_payload/lsa_public_parts bauen aus einer WHITELIST und
--   lesen task_solutions gar nicht. Diese Migration aendert am Payload-Bau KEINE
--   Zeile. Erreichbar sind die Felder nur ueber die beiden SECURITY-DEFINER-RPCs.
--
-- ⚠️  Die Migration muss VOR dem Merge eingespielt werden: task_solution_upsert
--   wird neu erzeugt und die alte Signatur gedroppt. src/types/authoring.ts
--   haelt acceptance/option_scores optional (undefined = Spalte/RPC-Feld fehlt
--   noch), das Autoren-Tool schickt sie heute nicht mit — ein Frontend auf altem
--   Stand bleibt also funktionsfaehig.

-- ============================================================================
-- 24. A11 – ABGESTUFTE BEWERTUNG (voll | teilweise | nicht)
--     (supabase/migrations/20260721110000_a11_abgestufte_bewertung.sql)
--     SETZT A10 VORAUS: ersetzt lsa_acceptance_rule_valid, liest acceptance.
-- ============================================================================
--
-- DAS PROBLEM: lsa_is_correct vergleicht STRINGS. "22/24" ist damit falsch,
--   obwohl die Loesung "11/12" ist — dieselbe Zahl, andere Schreibweise. Das
--   Kind hat richtig gerechnet und nur nicht gekuerzt, und die haeufigste
--   Foerderentscheidung ("Rechenweg sitzt, Darstellung fehlt") ist aus den
--   Daten nicht ablesbar.
--
-- Funktionen (neu, alle immutable, alle NUR service_role):
--   lsa_split_value_unit(text) → text[]
--       [Zahlteil, Einheit]. "1,5 m" → {1.5, m}, "11/12" → {11/12, ''}.
--   lsa_parse_fraction(text) → numeric[]
--       [Zaehler, Nenner]. Ganze Zahl, Dezimal, Bruch, gemischter Bruch, mit
--       Vorzeichen. NULL bei allem anderen (Muell wirft nicht).
--       KUERZT NICHT — die geschriebene Form ist genau das, was
--       require_reduced beurteilt. Wer beim Parsen kuerzt, wirft weg, was er
--       gleich messen will.
--       numeric statt bigint: Ganzzahlarithmetik ohne Ueberlaufgrenze.
--       "0,9166666666" wird zu 9166666666/10000000000 — mit bigint waere das
--       bei genug Nachkommastellen ein Absturz.
--   lsa_is_reduced(text) → boolean
--       Ist die geschriebene Bruchform gekuerzt (ggT = 1)? Ohne '/' immer true.
--       Prueft Kuerzung, NICHT Echtheit: 3/2 ist gekuerzt.
--   lsa_values_equal(a, b, tolerance) → boolean
--       Mathematische Wertgleichheit. exact vergleicht per KREUZPRODUKT
--       (a·d = c·b) und dividiert nie — 1/3 hat keine endliche
--       Dezimaldarstellung, jeder float-Weg waere eine Naeherung, die genau bei
--       den Aufgaben kippt, um die es geht. absolute/decimals nach
--       acceptance.tolerance.
--   lsa_grade(input_type, acceptance, correct_answers, response) → text
--       'voll' | 'teilweise' | 'nicht' — dasselbe Vokabular wie
--       task_solutions.option_scores (A10), auch wenn beide verschieden
--       entscheiden.
--         nicht     – nicht wertgleich, leer oder unlesbar
--         teilweise – wertgleich, aber die geforderte FORM verfehlt
--                     (unit_graded mit falscher/fehlender Einheit;
--                      require_reduced mit ungekuerztem Bruch)
--         voll      – wertgleich und formgerecht
--       p_acceptance ist die Regel EINES Scopes (flache Aufgabe oder EINE
--       Teilaufgabe) — wie p_correct_answers bei lsa_is_correct. Bei MULTI_PART
--       schneidet der Aufrufer zu (acceptance -> nr).
--
-- Funktion (geaendert):
--   lsa_acceptance_rule_valid(jsonb) – erlaubt zusaetzlich `require_reduced`
--       (boolean, oben in der Regel). Additiv und lockernd; keine bestehende
--       Zeile kann dadurch ungueltig werden.
--
-- acceptance.require_reduced (neu, top-level, default fehlt/false):
--   WARUM OBEN statt in `notation`: alle notation-Flags LOCKERN ("diese
--     Schreibweise gilt auch"), eine Kuerzungspflicht VERSCHAERFT. Sie gehoert
--     neben `unit_graded` — die beiden sind die Formanforderungen, notation.*
--     sind die Nachsichten. Praktisch dazu: der A10-CHECK whitelistet die
--     notation-Schluessel, ein `notation.require_reduced` waere von jeder
--     Datenbank mit A10 und ohne A11 abgewiesen worden.
--
-- DIE VIER notation-FLAGS SIND HEUTE DOKUMENTIEREND, NICHT SCHALTEND:
--   decimal_comma / ignore_case / ignore_space beschreiben, was
--   lsa_normalize_answer ohnehin und immer tut. Ein `decimal_comma: false`
--   wuerde eine zweite Normalisierungskonvention verlangen — P01 §3 sagt "eine
--   Konvention, ein Ort". unit_optional ist unter A10 nur mit
--   unit_graded=false erlaubt, und dort ist die Einheit ohnehin kein Kriterium.
--   Wirksam sind genau zwei Flags: unit_graded und require_reduced.
--
-- RUECKWAERTSKOMPATIBILITAET (die eigentliche Zusage):
--   lsa_is_correct bleibt BYTE-IDENTISCH — Signatur, Rumpf, Verhalten. Sein
--   einziger Aufrufer ist lsa_submit (flach + MULTI_PART), und lsa_submit wird
--   NICHT angefasst. lsa_grade tritt DANEBEN, nicht davor: es ist aufrufbar und
--   getestet, aber noch nicht verdrahtet.
--   Ohne acceptance-Regel (NULL, '{}', oder die Teilaufgaben-Abbildung statt
--   einer Regel) faellt lsa_grade auf lsa_is_correct zurueck und kennt nur
--   'voll'/'nicht'. 'teilweise' kann gar nicht entstehen, solange niemand eine
--   Regel gepflegt hat. MC bleibt binaer — die Abstufung dort ist option_scores.
--
-- WARUM NICHT GLEICH VERDRAHTET: lsa_responses.correct ist boolean, und
--   lsa_finish + der Eltern-Report rechnen darauf. Eine Stufe kann dort erst
--   ankommen, wenn die Spalte sie halten kann (eigener Schnitt: `grade` neben
--   `correct`). Ausserdem pinnen inv2/inv3 das heutige Bewertungsverhalten —
--   Datenmodell und gruene Beweise sollten nicht in derselben Migration wandern.
--
-- KEIN LEAK: alle Funktionen bekommen acceptance/correct_answers als PARAMETER
--   und lesen nie selbst aus task_solutions (Muster lsa_is_correct/
--   lsa_has_answers). Gegrantet sind sie nur an service_role. lsa_grade ist
--   AUSWERTUNGS-Logik und laeuft serverseitig; weder acceptance noch eine Stufe
--   gehen je in den Schueler-Payload. Am Payload-Bau aendert die Migration
--   KEINE Zeile.
--
-- Beweis: supabase/tests/a11_abgestufte_bewertung.test.sql (pgTAP, 29
--   Assertions). ⚠️ Laeuft heute weder lokal (kein Docker) noch in
--   .github/workflows/ci.yml — der Test ist geschrieben, aber bis dahin
--   unbewiesen.

-- ============================================================================
-- 25. A12 – `known_errors` IM AKZEPTANZ-SET
--     (supabase/migrations/20260722100000_a12_known_errors.sql)
--     SETZT A10 + A11 VORAUS.
-- ============================================================================
--
-- acceptance.known_errors (optional, Top-Level):
--   Die bekannten FEHLBILDER einer Aufgabe — welcher Wert entsteht, wenn ein
--   Kind einen bestimmten Denkfehler macht.
--     {"17/23":"additiv","3/7":"zaehler_plus_nenner"}   ← Wert → Fehlertyp
--     ["17/23","3/7"]                                    ← nur die Werte
--   Beide Formen gueltig; die innere Struktur wird NICHT erzwungen, weil noch
--   nicht entschieden ist, wie ein Fehlbild benannt wird (freie Labels,
--   Vokabular, oder Verweis auf eine spaetere Fehlbild-Tabelle). Ein CHECK
--   waere hier eine Entscheidung, die niemand getroffen hat.
--
-- WOZU: Der Brueche-Seed (Charge 01) rechnet die Fehlbilder bereits aus und
--   legt sie nur im Bericht ab (data/brueche_fundament_01_report.json) — in der
--   Datenbank landeten sie nirgends. Ohne sie kann der Eltern-/Coach-Report nur
--   „falsch" sagen; mit ihnen, WELCHER Fehler es war. Das ist der Unterschied
--   zwischen einer Note und einer Diagnose.
--
-- BEFUND, DER DIE MIGRATION KLEIN MACHT: lsa_acceptance_rule_valid whitelistet
--   KEINE Top-Level-Schluessel. Es prueft die bekannten Felder einzeln, aber es
--   gibt kein jsonb_object_keys/jsonb_each ueber die Regel selbst — eine
--   Whitelist gilt ausschliesslich INNERHALB von `notation` (und genau daran
--   waere `notation.require_reduced` gescheitert, weshalb A11 das Flag oben
--   ablegte). `known_errors` waere also auch vorher schon durchgegangen, nur
--   ungetypt und undokumentiert.
--   Diese Migration aendert deshalb nicht die Erlaubnis, sondern gibt dem Feld
--   einen TYP (Objekt oder Array) und einen Namen im Vertrag.
--
-- BEWUSST NICHT: unbekannte Top-Level-Schluessel abweisen. Das waere eine
--   Verschaerfung an Bestandsdaten vorbei — welche acceptance-Objekte real in
--   der Tabelle stehen, ist beim Schreiben der Migration nicht einsehbar, und
--   ein CHECK, der an einer Altzeile scheitert, nimmt den ganzen Lauf mit.
--   Folge mit Ansage: ein Tippfehler wie `know_errors` faellt weiterhin nicht
--   auf.
--
-- Funktion (geaendert): lsa_acceptance_rule_valid — EIN neuer Zweig
--   (known_errors is null or jsonb_typeof in ('object','array')).
--
-- KEINE Bewertungsaenderung: lsa_grade liest ausschliesslich benannte
--   Schluessel und ignoriert alles andere; lsa_is_correct liest acceptance
--   ueberhaupt nicht. Beide bleiben byte-identisch. known_errors ist REIN
--   DEKLARATIV.
--
-- KEIN LEAK: known_errors erbt den Schutz von task_solutions
--   (revoke all from anon, authenticated — P01 §2), ohne dass hier etwas getan
--   werden muss. Kein Grant beruehrt, keine Funktion am Payload-Bau.
--
-- Proben in der Migration (Transaktion bricht bei Abweichung ab): acceptance
--   ohne known_errors gueltig · als Objekt gueltig · als Array gueltig · als
--   Zeichenkette abgewiesen · Multi-Part-Doppelform mit known_errors gueltig.

-- ============================================================================
-- ENDE – konsolidiertes Schema (39 Tabellen, 34 Funktionen, 2 Enums, 1 Trigger).
-- ============================================================================
