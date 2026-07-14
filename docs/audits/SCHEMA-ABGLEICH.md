# Schema-Abgleich — Ist-Zustand (P00b+)

> Erzeugt von `scripts/db/schema_abgleich.py`. Stand: Phase 1–3 des P00b+-Laufs.

## Kernbefund (bitte zuerst lesen)

**Die 43 Migrationen in `migrations/` können die DB nicht aufbauen — und konnten es nie.**
Migration `001_competency_areas.sql` beginnt mit `delete from skill_clusters`, aber *keine*
Migration legt `skill_clusters` je an. Das Basis-Schema (profiles/students/subjects/
skill_clusters/microskills/tasks) existierte nur in `schema.sql` / `schema_content.sql` und
wurde per Hand im Supabase-SQL-Editor angewendet. Die 43 Dateien sind reine *Inkremente*
obendrauf.

Bewiesen, nicht vermutet — `supabase start` gegen die umgezogene Kette:

```
Applying migration 20250101000001_competency_areas.sql...
ERROR: relation "skill_clusters" does not exist (SQLSTATE 42P01)
```

**Empfehlung (umgesetzt):** `schema.sql` ist die einzige verlässliche Wahrheit für den
Neuaufbau. Daraus wurde die konsolidierte Baseline
`supabase/migrations/20250101000000_baseline.sql` erzeugt; die Katalogdaten liegen in
`supabase/seed.sql`. Die 43 Altdateien liegen unverändert in
`supabase/migrations_archive/` (Provenienz, aber nicht mehr ausgeführt).

## Die drei Behauptungen aus der Spec

Alle drei wurden gegen Code **und** DB geprüft. Zwei davon treffen nicht zu:

| Behauptung | Realität | Beleg |
|---|---|---|
| Code erwartet Spalte `tasks.task_type` | **Falsch.** `task_type` kommt in `src/`, `supabase/`, `schema.sql` und allen 43 Migrationen **kein einziges Mal** vor. Der Diskriminator heißt `content_type`. | `src/types/content.ts:50`, `schema.sql:285` |
| Code erwartet Tabelle `task_assets` | **Falsch.** Es gibt kein `.from('task_assets')`. Der String ist ausschließlich ein *Storage-Bucket* (`task-assets`, mit Bindestrich) bzw. ein Policy-/Dateiname. | `src/lib/supabase/storage.ts:8`, `schema.sql:1481-1493` |
| Verhältnis `tasks.assets` ↔ `task_assets` | `tasks.assets` ist eine **jsonb-Spalte** (Migration 009) mit `{url, alt, caption}[]`; `task-assets` ist der **Storage-Bucket**, in den die Bilder hochgeladen werden. Kein Join-Table, keine fehlende Tabelle. | `src/lib/supabase/tasks.ts:227-230`, `schema.sql:319` |

- `tasks.task_type` in der gebauten DB vorhanden: ❌
- `task_assets (TABELLE)` in der gebauten DB vorhanden: ❌
- `tasks.assets` in der gebauten DB vorhanden: ✅

## Diff-Tabelle: Tabelle × {DB · schema.sql · migrations_archive}

„DB" = die lokal aus der Baseline gebaute Datenbank (die Prod-DB ist von hier aus nicht
erreichbar, s.u.). „migrations/" = legt *diese* Migration die Tabelle an?

| Tabelle | DB | schema.sql | angelegt in migrations/ | vom Code benutzt |
|---|:--:|:--:|---|:--:|
| `badge_catalog` | ✅ | ✅ | badge_rarity | ✅ |
| `behavior_snapshots` | ✅ | ✅ | behavior_snapshots | ✅ |
| `clusters` | ❌ | ❌ | **existiert nirgends** | ✅ |
| `coaching_sessions` | ✅ | ✅ | coaching_sessions | ✅ |
| `intake_sessions` | ✅ | ✅ | intake_sessions | ✅ |
| `interventions` | ✅ | ✅ | interventions | ✅ |
| `leads` | ✅ | ✅ | leads | ✅ |
| `microskills` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `parent_report_generations` | ✅ | ✅ | parent_report_generations | ✅ |
| `parent_reports` | ✅ | ✅ | parent_reports | ✅ |
| `parent_student` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ❌ |
| `process_competencies` | ✅ | ✅ | process_competencies | ✅ |
| `profiles` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `screening_item_ratings` | ✅ | ✅ | screening_v2 | ✅ |
| `screening_item_results` | ✅ | ✅ | screening_items | ✅ |
| `screening_items` | ✅ | ✅ | screening_items | ✅ |
| `screening_ratings` | ✅ | ✅ | screening | ✅ |
| `screening_tests` | ✅ | ✅ | screening | ✅ |
| `session_students` | ✅ | ✅ | coaching_sessions | ✅ |
| `skill_clusters` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `streak_repair_inventory` | ✅ | ✅ | streak_repair_inventory | ✅ |
| `student_badges` | ✅ | ✅ | badge_rarity | ✅ |
| `student_coach` | ✅ | ✅ | student_coach | ✅ |
| `student_competency_mastery` | ✅ | ✅ | competency_mastery | ✅ |
| `student_focus_areas` | ✅ | ✅ | student_focus_areas | ✅ |
| `student_progress` | ✅ | ✅ | gamification | ✅ |
| `student_subjects` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `student_subscriptions` | ✅ | ✅ | tiers_subscriptions | ✅ |
| `student_task_progress` | ✅ | ✅ | student_task_progress | ✅ |
| `students` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `subjects` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `task_coach_metadata` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ❌ |
| `tasks` | ✅ | ✅ | — (Basis-Schema, nie migriert) | ✅ |
| `tiers` | ✅ | ✅ | tiers_subscriptions | ✅ |
| `xp_events` | ✅ | ✅ | gamification | ✅ |
| `xp_rules` | ✅ | ✅ | xp_completion | ✅ |

## Spalten-Stichproben (inkl. der bekannten Streitfälle)

| Tabelle.Spalte | DB | schema.sql | Herkunft/Drop | Code-Fundstelle |
|---|:--:|:--:|---|---|
| `tasks.assets` | ✅ | ❌ | add column in task_assets | `src/lib/supabase/tasks.ts:228` |
| `tasks.content_type` | ✅ | ❌ | — (Basis-Schema) | `src/types/content.ts:50` |
| `tasks.input_type` | ✅ | ❌ | add column in diagnostic_fields | `src/lib/supabase/tasks.ts` |
| `screening_items.microskill_id` | ✅ | ❌ | add column in screening_item_microskill | `src/lib/supabase/screeningItems.ts` |
| `screening_items.canonical` | ✅ | ❌ | — (Basis-Schema) | `src/lib/supabase/screeningItems.ts` |
| `student_progress.xp_total` | ✅ | ❌ | — (Basis-Schema) | `src/lib/supabase/progress.ts:11` |
| `student_progress.level` | ✅ | ❌ | — (Basis-Schema) | `src/lib/supabase/progress.ts:11` |
| `student_progress.streak_days` | ❌ | ❌ | **gedroppt in drop_streak_days** | `supabase/functions/generate_parent_report/index.ts:305` |
| `student_competency_mastery.mastered` | ✅ | ❌ | — (Basis-Schema) | `src/lib/supabase/competencyMastery.ts` |

## Code → DB: echte Mismatches

Der Code greift auf Objekte zu, die es **nicht gibt**. Beides schlägt zur Laufzeit fehl,
wird aber im Edge-Function-Code stillschweigend verschluckt (`?? []` / `?? null`):

- **Tabelle `clusters` fehlt.** Abgefragt in `supabase/functions/generate_parent_report/index.ts:327`. Gemeint ist `skill_clusters` — der Elternbericht verliert dadurch **alle** Cluster-Namen.
- **`student_progress.streak_days` fehlt.** Selektiert in `supabase/functions/generate_parent_report/index.ts:304-306`, aber von Migration 036 gedroppt (ersetzt durch `presence_streak_*`/`home_streak_*`, Migration 032). PostgREST antwortet mit 400 → XP/Level im Elternbericht degradieren still.

Beides sind **Code**-Fehler, keine Schema-Lücken: die DB ist korrekt, der Edge-Function-Code
ist gegen ein veraltetes Schema geschrieben. Fix gehört in
`supabase/functions/generate_parent_report/index.ts` — nicht in eine Migration.

## Der gefährlichste Befund: die Tabellen-Grants fehlten komplett

Beim Neuaufbau aus der Baseline kam heraus: `anon`, `authenticated` und `service_role`
hatten auf **keiner einzigen** Tabelle in `public` ein SELECT/INSERT/UPDATE/DELETE.
Eine so gebaute DB ist für die App **tot** — jeder PostgREST-Query endet in
`permission denied for table …`. Das Schema selbst war dabei völlig korrekt.

**Ursache:** Postgres vergibt Rechte an neuen Tabellen über `ALTER DEFAULT PRIVILEGES`,
abhängig davon, *wer* die Tabelle anlegt. Im Supabase-Stack gilt:

| Default-Privileges FOR ROLE | anon / authenticated / service_role bekommen |
|---|---|
| `supabase_admin` | `arwdDxtm` — volles DML |
| `postgres` | `Dxtm` — **kein** DML |

Migrationen laufen als **`postgres`**. Also landete jede Tabelle ohne DML-Rechte.
In der bisherigen Prod-DB fiel das nie auf, weil sie **nie aus Migrationen gebaut**
wurde — die Rechte kamen dort implizit zustande und standen deshalb auch nie in
`schema.sql`.

**Das ist der Grund, warum ein Prod-Reset ohne diesen Fund die App zerlegt hätte.**
Behoben durch `supabase/migrations/20260711120000_api_role_grants.sql` — die setzt die
Grants *und* die Default-Privileges für künftige Tabellen (sonst hätte jede neue
Migration denselben Defekt wieder).

Ist-Stand der gebauten DB (`grant`-Zählung über alle Tabellen in `public`):

| Rolle | SELECT | INSERT | UPDATE | DELETE |
|---|:--:|:--:|:--:|:--:|
| `anon` | 35 | 0 | 0 | 0 |
| `authenticated` | 35 | 35 | 35 | 35 |
| `service_role` | 35 | 35 | 35 | 35 |

`anon` bekommt bewusst **nur** SELECT: es existiert keine einzige anon-Policy, RLS
liefert ihm also ohnehin keine Zeile (Ausnahme: `badge_catalog`, absichtlich öffentlich).
Kein anon-Schreibrecht heißt: eine künftige Tabelle, bei der RLS vergessen wird, ist
nicht sofort welt-beschreibbar.

## Prod-DB: nicht erreichbar (offen)

Der Ist-Zustand der **echten** Prod-DB konnte **nicht** erhoben werden. Zwei Gründe:

1. **`DATABASE_URL` in `.env` enthält noch den Platzhalter** `[YOUR-PASSWORD]` aus dem
   Supabase-Dashboard — es sind schlicht keine Zugangsdaten hinterlegt.
2. Der Direkt-Host `db.<ref>.supabase.co` löst **nur auf IPv6** auf; die WSL2-Umgebung hat
   keine IPv6-Route (`Network is unreachable`). Selbst mit Passwort bräuchte es den
   **IPv4-Pooler** (Supavisor, `postgres.<ref>@aws-N-<region>.pooler.supabase.com:5432`).

Sobald Rasit einen funktionierenden Pooler-String in `.env` legt, liefert
`python3 scripts/db/db_introspect.py` den Prod-Ist-Zustand und diese Tabelle bekommt ihre
vierte Spalte. Für den geplanten Neuaufbau ist das aber **nicht blockierend**: die Daten
sind wegwerfbar, und der Zielzustand steht fest (die Baseline).

## Zahlen der gebauten DB

- Relationen: **35**
- Enums: **2** (badge_form, badge_rarity)
- Funktionen: **10**
- Trigger: **2** (trg_enforce_mastery_gate, xp_events_apply)
- RLS-Policies: **93**
- Migrations-Tracking (`supabase_migrations.schema_migrations`): ✅ vorhanden — vorher gab es
  **keinerlei** Tracking, deshalb war nie feststellbar, welche Migration lief.
