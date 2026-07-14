-- ============================================================================
-- ⚠️  DEPRECATED — konsolidiert in schema.sql am 2026-06-22
--
-- Diese Datei ist NICHT mehr die Wahrheit über den Content-Schema-Stand.
-- Der vollständige, konsolidierte Endzustand (Basis + Content + Migrationen
-- 001-036) liegt jetzt in schema.sql (Single Source of Truth). Abweichungen
-- zwischen dieser Datei und dem realen Stand sind in docs/DRIFT_REPORT.md
-- dokumentiert (u. a. subjects-CHECK-Constraint, fehlende Felder ab Migr. 010).
-- Datei bleibt nur zur Historie erhalten — NICHT mehr im Supabase SQL Editor
-- ausführen.
-- ============================================================================
--
-- Edvance Content Schema (Aufgaben / Cluster / Microskills)
--
-- Stand: Migration 009 inklusive (Diagnostic-Felder, Serlo-Removal, source/source_ref,
--        source_ref UNIQUE CONSTRAINT [008], Bilder/Abbildungen-Assets [009]).
-- Diese Datei spiegelt den realen DB-Stand. Inkrementelle Aenderungen seit der
-- Erstausfuehrung laufen ueber migrations/00X_*.sql.
--
-- Manueller Schritt: Diese Datei im Supabase SQL Editor ausfuehren (Greenfield).
--
-- ⚠️  KONFLIKT MIT schema.sql:
-- Die Tabelle `subjects` existiert bereits aus schema.sql mit der Form
--   (id uuid, name text CHECK (name in ('Mathematik','Deutsch','Englisch')))
-- und ist mit Werten vorbefuellt. Diese Datei definiert `subjects` neu ohne
-- CHECK-Constraint.
--
-- Wenn schema.sql bereits ausgefuehrt wurde, statt der `create table subjects`
-- Anweisung unten den folgenden additiven Block ausfuehren:
--
--   alter table subjects drop constraint if exists subjects_name_check;
--
-- Danach die `create table subjects (...)` Anweisung unten ueberspringen.
-- ============================================================================

-- Fach (Mathematik, Deutsch, Englisch)
create table subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null
);

-- Themencluster (z.B. "Terme & Gleichungen", "Rationale Zahlen")
create table skill_clusters (
  id uuid primary key default gen_random_uuid(),
  subject_id uuid references subjects(id) on delete cascade,
  name text not null,
  class_level_min integer not null check (class_level_min between 5 and 13),
  class_level_max integer not null check (class_level_max between 5 and 13),
  sort_order integer default 0
);

-- Mikroskills (z.B. "M8.TG.01 - Terme vereinfachen")
create table microskills (
  id uuid primary key default gen_random_uuid(),
  cluster_id uuid references skill_clusters(id) on delete cascade,
  code text not null unique,
  name text not null,
  description text,
  class_level integer not null check (class_level between 5 and 13),
  prerequisite_ids uuid[] default '{}',
  sort_order integer default 0,
  -- aus Migration 005 (Diagnostic-Felder)
  cognitive_type text check (cognitive_type in ('FACT','TRANSFER','ANALYSIS')),
  estimated_minutes integer,
  curriculum_ref text
);

-- Aufgaben (manuell erstellt oder aus externer Quelle importiert)
create table tasks (
  id uuid primary key default gen_random_uuid(),
  microskill_id uuid references microskills(id) on delete set null,
  cluster_id uuid references skill_clusters(id) on delete set null,
  content_type text not null check (
    content_type in ('exercise','exercise_group','article','video','course')
  ),
  title text,
  question text,
  solution text,
  hint text,
  common_errors text,
  coach_note text,
  difficulty integer check (difficulty between 1 and 5),
  estimated_minutes integer default 3,
  class_level integer check (class_level between 5 and 13),
  is_active boolean default true,
  created_at timestamptz default now(),
  -- aus Migration 005 (Diagnostic-Felder)
  cognitive_type text check (cognitive_type in ('FACT','TRANSFER','ANALYSIS')),
  -- input_type-CHECK in 042 auf den kanonischen Enum vereinheitlicht:
  input_type text check (input_type in (
    'MC','NUMERIC','SHORT_TEXT','TRUE_FALSE','FREE_TEXT','MATCHING','CLOZE','COORDINATE'
  )),
  is_diagnostic boolean default false,
  curriculum_ref text,
  question_payload jsonb,
  typical_errors text[],
  -- aus Migration 007 (Quelle + Idempotenz-Referenz)
  source text not null default 'unbekannt',
  source_ref text,
  -- aus Migration 009 (Bilder/Abbildungen)
  assets jsonb not null default '[]'::jsonb
);

-- Coach-Hinweise pro Aufgabe (erweiterbar)
create table task_coach_metadata (
  id uuid primary key default gen_random_uuid(),
  task_id uuid references tasks(id) on delete cascade,
  typical_errors text,
  observation_hints text,
  intervention_triggers text,
  updated_at timestamptz default now()
);

-- Indizes (aus Migrations 005 + 007 + 009)
create index if not exists tasks_diagnostic_idx
  on tasks (is_diagnostic) where is_diagnostic = true;

create index if not exists tasks_microskill_diagnostic_idx
  on tasks (microskill_id, is_diagnostic, difficulty)
  where is_diagnostic = true;

-- Hinweis: ehemals partial unique index (WHERE source_ref IS NOT NULL).
-- Migration 008 hat das durch echten UNIQUE CONSTRAINT ersetzt, weil
-- PostgREST-Upsert ohne WHERE-Praedikat sonst kein ON CONFLICT findet.
alter table tasks
  add constraint tasks_source_ref_unique unique (source, source_ref);

create index if not exists tasks_source_idx on tasks (source);

create index if not exists tasks_has_assets_idx
  on tasks ((jsonb_array_length(assets) > 0))
  where jsonb_array_length(assets) > 0;

-- RLS aktivieren
alter table subjects enable row level security;
alter table skill_clusters enable row level security;
alter table microskills enable row level security;
alter table tasks enable row level security;
alter table task_coach_metadata enable row level security;

-- Policies: Lesen fuer alle eingeloggten User
create policy "authenticated_read_subjects"
  on subjects for select using (auth.role() = 'authenticated');

create policy "authenticated_read_clusters"
  on skill_clusters for select using (auth.role() = 'authenticated');

create policy "authenticated_read_microskills"
  on microskills for select using (auth.role() = 'authenticated');

-- B01 (20260714140000): Schueler/Eltern sehen nur freigegebene Items, coach/admin
-- alles (Item-Pflege). Rolle ueber get_my_role(), nicht ueber auth.role().
create policy "read_tasks_by_role"
  on tasks for select using (
    public.get_my_role() in ('coach', 'admin')
    or (public.get_my_role() is not null and status = 'ready')
  );

create policy "coaches_read_task_metadata"
  on task_coach_metadata for select using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid()
      and p.role in ('coach','admin')
    )
  );

-- Schreiben nur fuer Admins
create policy "admin_write_tasks"
  on tasks for all using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'admin'
    )
  );
