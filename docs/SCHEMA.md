# Edvance – Datenbankschema

> **Single Source of Truth:** [`schema.sql`](../schema.sql) (konsolidiert am
> 2026-06-22 aus Basis-Schema + Content-Schema + `migrations/001-036`).
> Dieses Dokument ist 1:1 zu `schema.sql`. Abweichungen der alten Quellen sind
> in [`DRIFT_REPORT.md`](./DRIFT_REPORT.md) dokumentiert.
>
> **Umfang:** 33 Tabellen · 9 Funktionen · 2 Enums · 1 Trigger.
> Jede Tabelle hat RLS aktiviert.

---

## 0. Namens-Klarstellungen (häufige Irrtümer)

Diese Namen tauchen in Köpfen/alten Notizen auf, existieren aber **nicht** als
Tabelle. Real heißt es:

| Vermutet (existiert NICHT) | Realität |
|---|---|
| `aufgaben` | Tabelle heißt **`tasks`** (Lern-/Aufgabeninhalte). |
| `mastery_levels` | **Keine Tabelle.** Mastery ist ein **Level 1..10** (numerisch) + die Funktion **`mastery_stage(score)`** / `mastery_stage_from_level(lvl)`, die auf 5 Frontend-Stufen mappt (`introduced`/`developing`/`progressing`/`proficient`/`mastered`). Microskill-Level wird nicht in einer eigenen Tabelle materialisiert. |
| `home_quests` | **NICHT implementiert.** Es gibt keine Quests-Tabelle. Das nächstliegende reale Konstrukt ist der `home_streak`-Teil in `student_progress` (`home_streak_sessions`, `home_streak_last_completed_at`) sowie `student_task_progress`. |
| `sessions` | Präsenz-Sessions = **`coaching_sessions`** + Teilnahme = **`session_students`**. (Screening-„Läufe" = `screening_tests`, NICHT `sessions`.) |

---

## 1. Enums

- `badge_rarity` = `bronze` \| `silver` \| `gold` \| `platinum` (Migration 034)
- `badge_form` = `round` \| `shield` (Migration 034)

## 2. Security-Definer-Helper (nicht-rekursiv, programmweit)

Werden in fast allen RLS-Policies genutzt (umgehen Policy-Rekursion):

- `public.get_my_role()` → Rolle des eingeloggten Users (`schema.sql`)
- `public.get_my_student_id()` → eigene `students.id` (Migration 011)
- `public.is_parent_of_student(uuid)` → ist User Elternteil dieses Schülers (Migration 011)

## Rollen-Hierarchie

`admin` > `coach` > `parent` > `student`

---

## 3. Auth & Personen

### profiles
- **Zweck:** Erweitert Supabase `auth.users` um Rolle und Anzeigename.
- **Spalten:** `id` (PK, FK→`auth.users` ON DELETE CASCADE), `email` (not null), `role` (CHECK `student|parent|coach|admin`), `full_name`, `created_at`.
- **Beziehungen:** Wurzel für `students`, `parent_student`, alle `*_coach_id`/`owner_id`.
- **RLS:** jeder liest eigenes Profil; Coach/Admin lesen alle; Eltern lesen ihre Kinder (via `parent_student`).

### students
- **Zweck:** Schülerdetails (1:1 zu einem Profil mit `role='student'`).
- **Spalten:** `id` (PK), `profile_id` (FK→`profiles` CASCADE), `class_level` (CHECK 5–13), `school_name`, `school_type` (CHECK `Gymnasium|Gesamtschule|Realschule|Hauptschule`).
- **RLS (seit Migr. 011):** eigener Schüler (`profile_id=auth.uid()`); Eltern lesen; Coach/Admin alles.

### parent_student
- **Zweck:** Eltern-Kind-Verknüpfung (m:n).
- **Spalten:** `parent_id` (FK→`profiles`), `student_id` (FK→**`profiles`**, nicht `students`!), PK (`parent_id`,`student_id`).
- **RLS:** Elternteil und Schüler lesen eigene Verknüpfung; Coach/Admin alles.

### student_subjects
- **Zweck:** Schüler-Fach-Verknüpfung (m:n). Basis-Tabelle; RLS-Policies seit Migr. 011.
- **Spalten:** `student_id` (FK→`students` CASCADE), `subject_id` (FK→`subjects` CASCADE), PK (`student_id`,`subject_id`).
- **RLS:** Schüler eigene; Eltern lesen eigenes Kind; Coach/Admin alles.

---

## 4. Inhalte / Aufgaben

### subjects
- **Zweck:** Fach.
- **Spalten:** `id` (PK), `name` (not null, **ohne** CHECK-Constraint — siehe Drift D-09).
- **Seed:** `Mathematik`, `Deutsch`, `Englisch`.
- **RLS:** Lesen für alle authentifizierten User.

### skill_clusters
- **Zweck:** Themencluster pro Fach. Für Mathematik = 5 KMK-Kompetenzbereiche (klassenstufenübergreifend, Kl. 8–10).
- **Spalten:** `id` (PK), `subject_id` (FK→`subjects` CASCADE), `name`, `class_level_min`/`class_level_max` (CHECK 5–13), `sort_order`.
- **Seed (Migr. 001):** Zahl & Rechnen · Algebra & Funktionen · Geometrie & Messen · Daten & Zufall · Sachrechnen & Modellieren.
- **RLS:** Lesen für alle authentifizierten User.

### microskills
- **Zweck:** Atomare Lernziele innerhalb eines Clusters (z. B. „M8.TG.01 – Terme vereinfachen").
- **Spalten:** `id` (PK), `cluster_id` (FK→`skill_clusters` CASCADE), `code` (unique), `name`, `description`, `class_level` (CHECK 5–13), `prerequisite_ids` (uuid[]), `sort_order`, `cognitive_type` (CHECK `FACT|TRANSFER|ANALYSIS`), `estimated_minutes`, `curriculum_ref` (letzte drei aus Migr. 005).
- **Beziehungen:** `prerequisite_ids` zeigt auf andere `microskills.id`.
- **RLS:** Lesen für alle authentifizierten User.

### tasks
- **Zweck:** Lern-/Aufgabeninhalte (manuell oder importiert). *(Dies ist „aufgaben".)*
- **Spalten:** `id` (PK), `microskill_id` (FK→`microskills` SET NULL), `cluster_id` (FK→`skill_clusters` SET NULL), `content_type` (CHECK `exercise|exercise_group|article|video|course`), `title`, `question`, `solution`, `hint`, `common_errors`, `coach_note`, `difficulty` (CHECK 1–5), `estimated_minutes` (default 3), `class_level` (CHECK 5–13), `is_active`, `created_at`, `cognitive_type`, `input_type` (CHECK `MC|FREE_INPUT|STEPS|MATCHING|DRAW`), `is_diagnostic`, `curriculum_ref`, `question_payload` (jsonb), `typical_errors` (text[]), `source` (not null default `unbekannt`), `source_ref`, `assets` (jsonb default `[]`).
- **Constraints/Indexes:** `tasks_source_ref_unique` UNIQUE (`source`,`source_ref`) (Migr. 008); Indizes für Diagnostic-Pickup, `source`, `assets`.
- **Endzustand-Hinweis:** **keine** `serlo_*`-Spalten (von Migr. 006 entfernt).
- **RLS:** Lesen für alle authentifizierten User; Schreiben **nur Admin**.

### task_coach_metadata
- **Zweck:** Optionale Coach-Hinweise pro Aufgabe.
- **Spalten:** `id` (PK), `task_id` (FK→`tasks` CASCADE), `typical_errors`, `observation_hints`, `intervention_triggers`, `updated_at`.
- **RLS:** **nur** Read für Coach/Admin — **kein Write-Policy** (mit aktiver RLS kein Client-Write, Drift D-10).

---

## 5. Behavior-Tracking

### behavior_snapshots
- **Zweck:** APPEND-ONLY Roh-Verhaltensdaten pro Aufgaben-Submit (Bedenkzeit, Revisionen, Hint-Nutzung …). Spalten 1:1 zur Capture-Seite `src/types/diagnosis.ts`.
- **Spalten:** `id` (PK), `user_id` (FK→`profiles` CASCADE), `task_id` (FK→`tasks` CASCADE), `submitted_at`, `answer_text`, `thinking_time_ms`, `task_duration_ms`, `revision_count`, `rewrite_count`, `hint_used`, `hint_request_time_ms`, `answer_length`, `time_after_completion_ms`, `screening_test_id` (FK→`screening_tests` CASCADE, additiv aus Migr. 014).
- **RLS:** User insert/select eigene; Coach/Admin lesen alle. **Append-only** (kein update/delete).

---

## 6. Erstgespräch (Lead-Funnel)

### leads
- **Zweck:** Erstkontakt **vor** Account (Funnel-Stufe A). Interne PII.
- **Spalten:** `id`, `created_at`, `full_name` (not null), `contact_email`, `contact_phone`, `class_level` (CHECK 5–13), `school_type` (CHECK), `school_name`, `subjects` (text[]), `goal` (CHECK `IMPROVE_GRADES|CLOSE_GAPS|EXAM_PREP|GENERAL`), `known_weak_topics` (text[]), `source`, `status` (CHECK `new|contacted|onboarding_scheduled|converted|rejected`), `owner_id` (FK→`profiles` SET NULL), `notes`, `converted_student_id` (FK→`students` SET NULL), `contacted_at`, `onboarding_scheduled_at`.
- **RLS:** **nur Coach/Admin** (kein anon/Self-Service — PII).

### intake_sessions
- **Zweck:** Strukturiertes Erstgespräch-Protokoll am bereits angelegten Schüler (Stufe B).
- **Spalten:** `id`, `created_at`, `student_id` (FK→`students` CASCADE), `lead_id` (FK→`leads` SET NULL), `coach_id` (FK→`profiles` SET NULL), `conducted_at`, `goals`, `motivation`, `learning_history`, `parent_expectations`, `known_weak_topics` (text[]), `agreed_next_steps`, `notes`, `status` (CHECK `draft|final`).
- **RLS:** Coach/Admin Vollzugriff; Eltern lesen Protokoll des eigenen Kindes.

---

## 7. Screening

### screening_tests
- **Zweck:** Mutables Aggregat pro (Schüler, Fach); max. 1 aktiver Lauf je Paar.
- **Spalten:** `id`, `created_at`, `student_id` (FK→`students` CASCADE), `subject`, `status` (CHECK `in_progress|completed|aborted`), `coach_id` (FK→`profiles` SET NULL), `coach_note`, `generated_test` (jsonb), `generated_test_version` (smallint, default 1), `result_summary` (jsonb), `estimated_total_minutes`, `started_at`, `completed_at`.
- **Constraints:** `screening_tests_active_unique` (partial unique, `status='in_progress'`).
- **RLS:** Schüler liest **und schreibt** eigene (Migr. 023: insert/update für stillen `/screening`-Lauf); Eltern lesen; Coach/Admin alles.

### screening_ratings
- **Zweck:** APPEND-ONLY Coach-Bewertung (1–4) zu einem `behavior_snapshot` innerhalb eines Laufs.
- **Spalten:** `id`, `created_at`, `behavior_snapshot_id` (FK→`behavior_snapshots` CASCADE), `screening_test_id` (FK→`screening_tests` CASCADE), `rating` (CHECK 1–4), `coach_id` (FK→`profiles` SET NULL).
- **RLS:** Insert Coach/Admin; Lesen eigener Schüler/Eltern/Coach/Admin. **Append-only.**

### screening_items
- **Zweck:** Eigene Itembank (getrennt von `tasks`). Trägt sowohl autogradebare Edvance-Items als auch manuell kodierte VERA-8-Items.
- **Spalten (Basis 022):** `id`, `created_at`, `cluster_id` (FK→`skill_clusters` CASCADE, **nullable seit 029**), `class_level` (not null, CHECK 5–13), `topic`, `skill_code`, `skill_label`, `level` (CHECK 1–3, nullable seit 029), `curriculum_seq`, `input_type` (not null, CHECK `MC|NUMERIC|MATCHING|STEPS_FINAL|OPEN`), `prompt`, `payload` (jsonb), `canonical` (jsonb, nullable seit 029), `check_type` (not null, CHECK `mc_index|numeric|matching_set|normalized|manual`), `tolerance`, `typical_errors` (text[]), `explanation`, `source` (default `edvance_original`), `active` (default false).
- **Spalten (028):** `afb` (CHECK `I|II|III`), `phase` (CHECK `sprint|tiefe`); Cross-Constraint `screening_items_open_iff_manual` = (`input_type='OPEN'`) ⇔ (`check_type='manual'`).
- **Spalten (029 VERA-8):** `iqb_titel` (UNIQUE), `kompetenzfelder` (text[]), `aufgabe_typ`, `teilaufgaben` (jsonb), `kontext`, `loesung_pro_ta` (jsonb), `akzeptierte_antworten` (jsonb), `kodierung`, `kommentar_highlights` (jsonb), `urls` (jsonb), `datei_ext`, `quelle`, `fix_anker` (bool), `meta` (jsonb).
- **RLS:** authentifizierte lesen nur `active=true`; Coach lesen alles; Admin r/w alles.

### screening_item_results
- **Zweck:** APPEND-ONLY Ergebnis pro Item/Lauf.
- **Spalten:** `id`, `created_at`, `screening_test_id` (FK CASCADE), `screening_item_id` (FK CASCADE), `cluster_id` (FK→`skill_clusters` CASCADE, **NOT NULL** — siehe Drift D-11), `level` (CHECK 1–3), `correct` (**nullable seit 028** — offene Items haben kein Auto-Grade), `answer` (jsonb), `duration_ms`.
- **RLS:** Schüler insert/select eigene (über eigenen `screening_test`); Eltern/Coach/Admin lesen. **Append-only.**

### screening_item_ratings
- **Zweck:** APPEND-ONLY manuelle Coach-Bewertung offener Items (erreichtes AFB).
- **Spalten:** `id`, `created_at`, `screening_item_result_id` (FK CASCADE), `coach_id` (FK→`profiles` SET NULL), `reached_afb` (CHECK `I|II|III`), `note`.
- **RLS:** Coach/Admin insert+read; **Schüler/Eltern kein Direktzugriff** (CLAUDE §6). **Append-only.**

---

## 8. Tarif / Zuordnung / Fokus

### tiers
- **Zweck:** Tarif-Katalog (ersetzt hardcodierte Konstante).
- **Spalten:** `id`, `name` (unique), `price_cents`, `features` (jsonb), `sort_order`, `active`.
- **Seed:** Basic (8900) · Standard (12900) · Premium (16900).
- **RLS:** alle authentifizierten lesen; nur Admin schreibt.

### student_subscriptions
- **Zweck:** Gewählter Tarif pro Schüler.
- **Spalten:** `id`, `created_at`, `student_id` (FK CASCADE), `tier_id` (FK→`tiers`), `status` (CHECK `active|paused|cancelled`), `started_at`, `ended_at`.
- **RLS:** Schüler eigene; Eltern lesen; Coach/Admin alles.

### student_coach
- **Zweck:** Schüler↔Coach-Zuordnung.
- **Spalten:** `student_id` (FK CASCADE), `coach_id` (FK→`profiles` CASCADE), `assigned_at`, `active`, PK (`student_id`,`coach_id`).
- **RLS:** Zuweisung nur Admin; Coach liest eigene; Schüler/Eltern lesen eigene.

### student_focus_areas
- **Zweck:** Coach/Admin setzt Schwerpunkte pro Schüler (gewichtet die Adaptive-Engine).
- **Spalten:** `id`, `created_at`, `student_id` (FK CASCADE), `cluster_id` (FK→`skill_clusters` CASCADE), `coach_id` (FK→`profiles` SET NULL), `source` (default `klassenarbeit`), `note`, `active`.
- **RLS:** Coach/Admin r/w; Eltern lesen eigenes Kind; Schüler kein Zugriff.

---

## 9. Session-Betrieb

### coaching_sessions
- **Zweck:** Geplante/laufende Präsenz-Sessions eines Coaches. *(Dies ist „sessions".)*
- **Spalten:** `id`, `created_at`, `coach_id` (FK→`profiles` CASCADE), `room`, `scheduled_at` (not null), `status` (CHECK `upcoming|active|done`).
- **RLS:** Coach r/w eigene; Admin alles; Schüler lesen eigene; Eltern lesen eigene (Migr. 024).

### session_students
- **Zweck:** Anwesenheit pro Schüler in einer Session.
- **Spalten:** `session_id` (FK→`coaching_sessions` CASCADE), `student_id` (FK→`students` CASCADE), `attendance` (CHECK `present|absent|unknown`), PK (`session_id`,`student_id`).
- **RLS:** Schüler/Eltern lesen eigene; Coach r/w (eigene Sessions); Admin alles.

### interventions
- **Zweck:** Eingriff-Tracking. Eine veränderbare Zeile pro Vorgang (`started_at` → `resolved_at`). Dauer nie gespeichert.
- **Spalten:** `id`, `created_at`, `session_id` (FK CASCADE), `student_id` (FK CASCADE), `coach_id` (FK→`profiles` CASCADE), `started_at`, `resolved_at`, `note`.
- **RLS:** Coach r/w (eigene Sessions); Admin alles; Eltern lesen eigenes Kind; **Schüler kein Zugriff**.

---

## 10. Fortschritt & Gamification

### student_task_progress
- **Zweck:** Aufgaben-Abschluss (ersetzt localStorage).
- **Spalten:** `student_id` (FK CASCADE), `task_id` (FK→`tasks` CASCADE), `completed_at`, PK (`student_id`,`task_id`).
- **RLS:** Schüler r/w eigene; Eltern/Coach/Admin lesen.

### student_progress
- **Zweck:** Abgeleiteter Totals-Spiegel pro Schüler. **Nur** via Security-Definer-Trigger `apply_xp_event` geschrieben (kein Client-Write-Policy).
- **Spalten:** `student_id` (PK, FK CASCADE), `xp_total`, `level`, `last_activity`, `presence_streak_weeks`, `presence_streak_last_week_start`, `presence_streak_multiplier` (numeric(3,2)), `home_streak_sessions`, `home_streak_last_completed_at`.
- **Endzustand-Hinweis:** `streak_days` wurde von Migr. 036 **gedroppt** (ersetzt durch Zwei-Streak-Modell aus 032).
- **RLS:** Schüler eigene; Eltern/Coach/Admin lesen.

### xp_events
- **Zweck:** APPEND-ONLY XP-Vergabe; speist `student_progress` via Trigger.
- **Spalten:** `id`, `created_at`, `student_id` (FK CASCADE), `task_id` (FK→`tasks` SET NULL), `xp` (not null), `reason`.
- **RLS:** Schüler insert/select eigene; Eltern/Coach/Admin lesen. **Append-only.**
- **Trigger:** `xp_events_apply` AFTER INSERT → `apply_xp_event()`. ⚠️ **Funktion ist im Endzustand defekt** (referenziert gedropptes `streak_days`) — siehe Drift **D-01**.

### xp_rules
- **Zweck:** Admin-konfigurierbare XP-Gewichtung pro `content_type`.
- **Spalten:** `content_type` (PK), `base_xp`, `difficulty_multiplier`, `updated_at`.
- **Seed:** exercise (20/5), video (10/0), article (10/0), exercise_group (0/0), course (0/0).
- **RLS:** Admin r/w; Coach/Admin lesen.

### badge_catalog
- **Zweck:** Badge-Definitionen (Rarity + Form). Platin (Shield) für Klassen-Abschlüsse 8/9/10.
- **Spalten:** `id` (text PK), `label`, `description`, `rarity` (`badge_rarity`), `form` (`badge_form`, default `round`), `klasse` (int, nullable), `trigger`, `created_at`.
- **Seed:** 10 reguläre + 3 Platin-Badges (Migr. 034).
- **RLS:** Lesen für alle (`true`); Schreiben nur Admin.

### student_badges
- **Zweck:** Verliehene Badges pro Schüler.
- **Spalten:** `student_id` (FK→`students` CASCADE), `badge_id` (FK→`badge_catalog`), `awarded_at`, PK (`student_id`,`badge_id`).
- **RLS:** Lesen: eigener Schüler / Coach/Admin / Eltern; Schreiben: Admin+Coach.

### streak_repair_inventory
- **Zweck:** Inventory für Streak-Repair-Token (Power-Up).
- **Spalten:** `student_id` (PK, FK→`students` CASCADE), `tokens`, `earned_total`, `used_total`, `updated_at`.
- **RLS:** Lesen: eigener Schüler / Coach/Admin; Schreiben: **nur Admin**.

---

## 11. Elternreport

### parent_reports
- **Zweck:** Kuratierter Report (`draft` → `published`).
- **Spalten:** `id`, `created_at`, `student_id` (FK CASCADE), `period_start`/`period_end` (date), `summary` (jsonb), `coach_note`, `status` (CHECK `draft|published`), `published_at`.
- **RLS:** Eltern/Schüler lesen **nur `published`** (eigenes Kind/sich); Coach/Admin r/w.

### parent_report_generations
- **Zweck:** APPEND-ONLY Log jeder erfolgreichen KI-Report-Generierung (Kosten-Guardrail).
- **Spalten:** `id`, `created_at`, `coach_id` (uuid, **ohne FK**; null = System/Service-Role), `student_id` (FK CASCADE), `model`.
- **RLS:** **nur** Read für Coach/Admin. Insert ausschließlich via Service-Role aus der Edge Function (umgeht RLS) → **kein** insert/update/delete-Policy.

---

## 12. Funktionen & Trigger

| Funktion | Quelle | Zweck |
|---|---|---|
| `get_my_role()` | schema.sql | Rolle ohne RLS lesen |
| `get_my_student_id()` | 011 | eigene `students.id` |
| `is_parent_of_student(uuid)` | 011 | Elternschaft prüfen |
| `apply_xp_event()` | 019 | Trigger-Fn: rechnet `student_progress` fort. ⚠️ defekt (D-01) |
| `complete_task(uuid)` | 026 | atomarer, idempotenter Task-Abschluss (+XP) |
| `app_provision_student(…)` | 021 | atomare Lead→Student-Conversion (nur `service_role`) |
| `calc_presence_multiplier(int)` | 032 | Präsenz-Streak → XP-Multiplikator |
| `mastery_stage(numeric)` | 033 | Score 0..100 → 5-Stufen-Label |
| `mastery_stage_from_level(int)` | 033 | Level 1..10 → 5-Stufen-Label |

**Trigger:** `xp_events_apply` AFTER INSERT ON `xp_events` → `apply_xp_event()`.

## 13. Storage-RLS (`storage.objects`)

- **Bucket `task-assets`** (public; Migr. 010): Admin insert/update/delete; Lesen public (Bucket-Setting).
- **Bucket `screening-uploads`** (privat; Migr. 031): Schüler insert/select/delete eigene (Pfad `{student_id}/…`); Eltern select eigenes Kind; Coach/Admin select alle; Admin delete (DSGVO Art. 17).

---

## 14. Beziehungen (Kurzüberblick)

- `subjects 1—n skill_clusters 1—n microskills 1—n tasks` (Tasks können auch nur am Cluster hängen).
- `tasks 1—1 task_coach_metadata` (optional).
- `microskills.prerequisite_ids[]` → andere `microskills.id`.
- `profiles 1—1 students`; `parent_student` verknüpft `profiles`(Eltern) ↔ `profiles`(Schüler).
- `screening_tests 1—n {behavior_snapshots, screening_ratings, screening_item_results}`.
- `screening_item_results 1—n screening_item_ratings`.
- `coaching_sessions 1—n session_students`; `coaching_sessions 1—n interventions`.
- `xp_events` → Trigger → `student_progress`; `student_progress 1—1 streak_repair_inventory`.

## 15. RLS-Grundmuster

- Coach/Admin sehen i. d. R. alles; Eltern nur eigene Kinder (via `parent_student`/`is_parent_of_student`); Schüler nur sich.
- Append-only-Tabellen (`behavior_snapshots`, `xp_events`, `screening_ratings`, `screening_item_results`, `screening_item_ratings`, `parent_report_generations`) haben bewusst kein update/delete-Policy.
- Content (`subjects`/`skill_clusters`/`microskills`/`tasks`): Lesen für alle authentifizierten; Schreiben auf `tasks` nur Admin.
- `student_progress`: read-only für Clients; Schreiben nur via Trigger.

---

## 16. SQL-Dateien & Edge Functions

- [`schema.sql`](../schema.sql) — **Single Source of Truth** (konsolidiert 001-036).
- [`schema_content.sql`](../schema_content.sql) — **DEPRECATED** (Historie; nicht mehr ausführen).
- `migrations/001_*.sql … 036_*.sql` — chronologische Änderungshistorie (unverändert, nicht editieren).
- [`DRIFT_REPORT.md`](./DRIFT_REPORT.md) — dokumentierte Abweichungen der Altquellen + Type-Drift.

**Edge Functions:**
- `supabase/functions/provision_student` — ruft `app_provision_student` (Migr. 021). Aufruf nur über `src/lib/supabase/provision.ts`.
- `supabase/functions/generate_parent_report` — KI-Elternreport (Anthropic). Aufruf nur über `src/lib/supabase/generateParentReport.ts`. Schreibt nach `parent_report_generations` (Service-Role). Secrets: `ANTHROPIC_API_KEY`, Guardrail-Limits `PR_COACH_DAILY_LIMIT` (30), `PR_STUDENT_WINDOW_DAYS` (7), `PR_STUDENT_WINDOW_LIMIT` (5), `PR_GLOBAL_MONTHLY_LIMIT` (3000).
