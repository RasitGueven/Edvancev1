# Edvance – Datenbankschema

## Tabellen

### Auth & Personen
profiles            → id, email, role, full_name, created_at
students            → id, profile_id, class_level, school_name, school_type
parent_student      → parent_id, student_id

### Inhalte / Aufgaben
subjects            → id, name
skill_clusters      → id, subject_id, name, class_level_min, class_level_max, sort_order
                      (= 5 KMK-Kompetenzbereiche pro Fach, klassenstufenuebergreifend)
microskills         → id, cluster_id, code, name, description, class_level, prerequisite_ids[], sort_order, cognitive_type, estimated_minutes, curriculum_ref
tasks               → id, microskill_id, cluster_id, content_type, title, question, solution, hint, common_errors, coach_note, difficulty, estimated_minutes, class_level, is_active, created_at, cognitive_type, input_type, is_diagnostic, curriculum_ref, question_payload, typical_errors[]
task_coach_metadata → id, task_id, typical_errors, observation_hints, intervention_triggers, updated_at

#### KMK-Kompetenzbereiche Mathematik (Kl. 8-10)
1. Zahl & Rechnen
2. Algebra & Funktionen
3. Geometrie & Messen
4. Daten & Zufall
5. Sachrechnen & Modellieren

Aufgaben werden einem Cluster und (optional) Mikroskill zugeordnet.
Nicht zuordbare Tasks landen mit `cluster_id = NULL` und werden manuell
sortiert.

### Schueler-Fach Verknuepfung
student_subjects    → student_id, subject_id

### Erstgespraech & Screening (Migrationen 012-014)
leads               → id, created_at, full_name, contact_email, contact_phone, class_level, school_type, school_name, subjects[], goal, known_weak_topics[], source, status, owner_id, notes, converted_student_id, contacted_at, onboarding_scheduled_at
                      (Stufe A: Lead/Erstkontakt vor Account – nur Coach/Admin, PII)
intake_sessions     → id, created_at, student_id, lead_id, coach_id, conducted_at, goals, motivation, learning_history, parent_expectations, known_weak_topics[], agreed_next_steps, notes, status
                      (Stufe B: strukturiertes Erstgespraech-Protokoll am Schueler)
screening_tests     → id, created_at, student_id, subject, status, coach_id, coach_note, generated_test(jsonb), generated_test_version, result_summary(jsonb), estimated_total_minutes, started_at, completed_at
                      (mutables Aggregat pro (Schueler,Fach); 1 aktiver Test je Paar)
screening_ratings   → id, created_at, behavior_snapshot_id, screening_test_id, rating(1-4), coach_id
                      (APPEND-ONLY – Coach-Bewertung separat, haelt behavior_snapshots append-only)
behavior_snapshots  → + screening_test_id (additive nullable FK, Migration 014)

### Tarif / Zuordnung / Fortschritt (Migrationen 015,016,018)
tiers                  → id, name, price_cents, features(jsonb), sort_order, active (Katalog, seed Basic/Standard/Premium)
student_subscriptions  → id, created_at, student_id, tier_id, status, started_at, ended_at
student_coach          → student_id, coach_id, assigned_at, active (PK student_id+coach_id)
student_task_progress  → student_id, task_id, completed_at (PK student_id+task_id; ersetzt localStorage)

### Session-Betrieb / Gamification / Report (Migrationen 017,019,020)
coaching_sessions      → id, created_at, coach_id, room, scheduled_at, status (ersetzt MOCK_SESSIONS)
session_students       → session_id, student_id, attendance (PK session_id+student_id)
student_progress       → student_id(PK), xp_total, streak_days, level, last_activity (nur via Trigger)
xp_events              → id, created_at, student_id, task_id, xp, reason (APPEND-ONLY; speist student_progress)
parent_reports         → id, created_at, student_id, period_start, period_end, summary(jsonb), coach_note, status, published_at

## Beziehungen

- `subjects 1—n skill_clusters` (Fach → Themencluster)
- `skill_clusters 1—n microskills` (Cluster → Mikroskills)
- `microskills 1—n tasks` (Mikroskill → Aufgaben; tasks koennen auch nur am Cluster haengen)
- `tasks 1—1 task_coach_metadata` (optionale Coach-Hinweise)
- `microskills.prerequisite_ids` zeigt auf andere `microskills.id` (Vorbedingung)

## Content-Typen (`tasks.content_type`)

`exercise` | `exercise_group` | `article` | `video` | `course`

## Rollen

student | parent | coach | admin

## RLS-Logik

- Coaches und Admins sehen alles
- Eltern sehen nur ihre Kinder (via parent_student)
- Schüler sehen nur sich selbst
- `subjects`, `skill_clusters`, `microskills`, `tasks`: Lesen fuer alle authentifizierten User
- `task_coach_metadata`: nur fuer Coaches und Admins
- Schreiben auf `tasks`: nur Admins
- `students` / `parent_student` / `student_subjects`: explizite Policies seit
  Migration 011 (vorher RLS aktiv, aber policy-los = default-deny)
- `leads`: nur Coach/Admin (interne PII, kein anon-Zugriff)
- `intake_sessions`: Coach/Admin Vollzugriff; Eltern lesen Protokoll eigenes Kind
- `screening_tests`: Schueler liest eigene; Eltern lesen eigenes Kind; Coach/Admin alles
- `screening_ratings`: append-only; Insert Coach/Admin; Lesen eigener Schueler/Eltern/Coach/Admin
- `behavior_snapshots`: weiterhin append-only (Migration 014 nur additive FK)
- `tiers`: alle authentifizierten lesen; nur Admin schreibt
- `student_subscriptions` / `student_task_progress`: Schueler eigene; Eltern/Coach/Admin lesen
- `student_coach`: Zuweisung nur Admin; Coach liest eigene; Schueler/Eltern eigene
- `coaching_sessions` / `session_students`: Coach r/w eigene; Admin alles; Schueler/Eltern lesen eigene
- `student_progress`: read-only fuer Clients; Schreiben nur via Security-Definer-Trigger apply_xp_event
- `xp_events`: append-only; Schueler insert/select eigene; Eltern/Coach/Admin lesen
- `parent_reports`: Eltern/Schueler lesen nur 'published' eigenes Kind; Coach/Admin r/w

### Security-Definer-Helper (nicht-rekursiv, programmweit)

- `public.get_my_role()` → Rolle des eingeloggten Users
- `public.get_my_student_id()` → eigene `students.id` (Migration 011)
- `public.is_parent_of_student(uuid)` → ist User Elternteil dieses Schuelers (Migration 011)

## Supabase-Regeln

- Jede Tabelle hat RLS aktiviert
- Timestamps als UTC, Anzeige als Europe/Berlin
- BehaviorSnapshots sind append-only

## SQL-Dateien

- `schema.sql`                              – Auth + Schueler-Tabellen (initial)
- `schema_content.sql`                      – Content/Aufgaben-Tabellen (im Supabase SQL Editor manuell)
- `migrations/001_competency_areas.sql`     – Cluster auf 5 KMK-Kompetenzbereiche umstellen
- `migrations/003_behavior_snapshots.sql`   – BehaviorSnapshots (append-only)
- `migrations/011_students_rls_fix.sql`     – RLS-Policies students/parent_student/student_subjects + Security-Definer-Helper
- `migrations/012_leads.sql`                – leads (Erstgespraech Stufe A)
- `migrations/013_intake_sessions.sql`      – intake_sessions (Erstgespraech Stufe B)
- `migrations/014_screening.sql`            – screening_tests + screening_ratings + behavior_snapshots.screening_test_id
- `migrations/015_tiers_subscriptions.sql`  – tiers (Katalog) + student_subscriptions
- `migrations/016_student_coach.sql`        – Schueler<->Coach-Zuordnung
- `migrations/018_student_task_progress.sql`– Aufgaben-Fortschritt (ersetzt localStorage)
- `migrations/017_coaching_sessions.sql`    – coaching_sessions + session_students (ersetzt MOCK_SESSIONS)
- `migrations/019_gamification.sql`         – student_progress + xp_events (+ Trigger apply_xp_event)
- `migrations/020_parent_reports.sql`       – Elternreport (draft/published)
- `migrations/021_provision_student_fn.sql` – atomare Lead->Student-Conversion (nur service_role; via Edge Function provision_student)

## Edge Functions

- `supabase/functions/provision_student` – Lead->Student-Conversion: legt
  auth-User (Schueler + optional Eltern-Invite) an und ruft die atomare
  RPC `app_provision_student` (Migration 021). Deploy via
  `supabase functions deploy provision_student`. Aufruf nur ueber
  `src/lib/supabase/provision.ts` (nie direkt aus Komponenten).
