# Retro — P00b+ : Schema-Abgleich, Migrations-Umzug & DB-Autonomie

**Datum:** 2026-07-11
**Branch:** `auto/P00b-plus-schema-abgleich-20260711-1108`
**Spec:** `prompts/infra/P00b-plus-schema-abgleich.md`
**Modus:** Lauf war als *beaufsichtigt* geplant, lief faktisch **headless** (`claude -p`).
Genau daran sind Phase 4 und die Guard-Anpassung gescheitert (siehe „Was offen ist").

---

## Das Wichtigste in einem Absatz

Die 43 Migrationen in `migrations/` konnten die DB **nie** aufbauen — sie sind
Inkremente auf ein Basis-Schema, das nur per Hand aus `schema.sql` existierte. Also
wurde `schema.sql` zur konsolidierten Baseline gemacht und lokal bewiesen. **Dabei kam
der eigentliche Fund heraus:** eine aus Migrationen gebaute DB ist für die App *tot* —
`anon`/`authenticated`/`service_role` hatten auf **keiner** Tabelle DML-Rechte. Hätten
wir Phase 4 (Prod-Neuaufbau) blind ausgeführt, wäre die Prod-App danach bei **jedem**
Query in `permission denied for table` gelaufen. Der Reset wurde **nicht** ausgeführt.

---

## Was gebaut wurde

| | |
|---|---|
| `supabase/migrations/20250101000000_baseline.sql` | Konsolidierte Struktur aus `schema.sql`, generiert |
| `supabase/migrations/20260711120000_api_role_grants.sql` | Beweis-Migration — schließt den Grants-Defekt |
| `supabase/seed.sql` | Idempotente Katalogdaten (Abschnitt 14 aus `schema.sql`) |
| `supabase/migrations_archive/` | Die 43 historischen Inkremente (`git mv`, Historie erhalten, **nicht mehr ausgeführt**) |
| `supabase/tests/inv1_mastery_gate.test.sql` | pgTAP, FernUSG-Invariante, 8/8 grün |
| `scripts/db/migrate-verify.sh` | Neuaufbau(lokal) → lint → pgTAP → Drift → typecheck/test |
| `scripts/db/{db_introspect,schema_abgleich,build_baseline,move_migrations,archive_migrations}.py` | Das Werkzeug dahinter |
| `docs/audits/SCHEMA-ABGLEICH.md` | Der Abgleich |
| `docs/runbooks/DB-MIGRATIONEN.md` | Wie eine Migration künftig läuft |

Beweislage: `db lint` sauber · `db diff` leer (kein Drift) · pgTAP 8/8 · typecheck grün ·
53/53 Unit-Tests grün.

---

## Die drei Entscheidungen

### 1. Baseline statt Replay der 43 Migrationen

Nicht vermutet, sondern gemessen — `supabase start` gegen die umgezogene Kette:

```
Applying migration 20250101000001_competency_areas.sql...
ERROR: relation "skill_clusters" does not exist (SQLSTATE 42P01)
```

Migration 001 macht `delete from skill_clusters`, aber **keine** Migration legt
`skill_clusters` je an. Das Basis-Schema (profiles/students/subjects/skill_clusters/
microskills/tasks) wurde per Hand im SQL-Editor angewendet. Die 43 Dateien sind reine
Inkremente darauf — deshalb kann die Kette per Konstruktion nicht von Null laufen.

→ `schema.sql` ist die einzige verlässliche Wahrheit. Sie wurde zur Baseline.
Die 43 Dateien liegen unverändert im Archiv (Provenienz), werden aber nicht mehr
ausgeführt. **Nichts davon reaktivieren.**

### 2. Die Spec-Annahmen stimmten nicht

Die Spec ging von fehlendem `tasks.task_type` und einer fehlenden Tabelle `task_assets`
aus. Beides existiert im Code **nirgends**:

- `task_type` — 0 Treffer in `src/`, `supabase/`, `schema.sql` und allen 43 Migrationen.
  Der Diskriminator heißt `content_type`.
- `task_assets` als **Tabelle** — es gibt kein `.from('task_assets')`. Der String ist
  ausschließlich der Storage-Bucket `task-assets` (mit Bindestrich) bzw. ein Policy-Name.
  `tasks.assets` ist eine **jsonb-Spalte** (Migration 009). Kein Join-Table, keine Lücke.

Dafür kamen **zwei echte Bugs** heraus, die niemand gesucht hatte (siehe unten).

### 3. `anon` bekommt nur SELECT

Supabase' Default wäre volles DML für `anon`. Bewusst nicht übernommen: es existiert
keine einzige anon-Policy, RLS liefert `anon` also ohnehin keine Zeile. Kein
Schreibrecht heißt: eine künftige Tabelle, bei der RLS vergessen wird, ist nicht
sofort welt-beschreibbar. Das ist die klassische Supabase-Falle.

---

## Der Fund, der den Prod-Reset gerettet hat

`anon`/`authenticated`/`service_role` hatten auf **keiner** der 35 Tabellen ein
SELECT/INSERT/UPDATE/DELETE — nur `REFERENCES,TRIGGER,TRUNCATE`.

**Ursache:** Postgres vergibt Rechte an neuen Tabellen über `ALTER DEFAULT PRIVILEGES`,
abhängig davon, **wer** die Tabelle anlegt:

| Default-Privileges FOR ROLE | anon / authenticated / service_role |
|---|---|
| `supabase_admin` | `arwdDxtm` — volles DML |
| `postgres` | `Dxtm` — **kein** DML |

Migrationen laufen als `postgres`. Also landet jede Tabelle ohne DML-Rechte. In der
bisherigen Prod-DB fiel das nie auf, weil sie **nie aus Migrationen gebaut wurde** — die
Rechte kamen dort implizit zustande und standen deshalb auch nie in `schema.sql`.

Das ist genau die Fehlerklasse, für die dieser ganze Lauf existiert: etwas, das in Prod
„schon immer funktioniert hat", ohne dass irgendwo stand, *warum*.

---

## Zwei Bugs, die beim Abgleich herausfielen

Beide in `supabase/functions/generate_parent_report/index.ts`, beide scheitern **still**
(`?? []` / `?? null`) — der Elternbericht degradiert unbemerkt. **Nicht mitgefixt**
(DB-Session; brauchen eigenen Test + Review):

- **`index.ts:327`** — `admin.from('clusters')`. Die Tabelle heißt `skill_clusters`.
  `clusterNames` ist damit **immer leer** → der Bericht verliert alle Cluster-Namen.
- **`index.ts:304-306`** — `.select('xp_total, streak_days, level')`.
  `student_progress.streak_days` hat Migration 036 gedroppt. PostgREST antwortet 400 →
  XP/Level fallen still weg.

---

## Was offen ist

### 1. Prod-Zugang fehlt — Phase 4 **nicht** ausgeführt

Zwei Blocker:

1. **`DATABASE_URL` in `.env` enthält noch den Platzhalter `[YOUR-PASSWORD]`** aus dem
   Dashboard. Es sind schlicht keine Zugangsdaten hinterlegt.
2. Der Direkt-Host `db.<ref>.supabase.co` löst **nur auf IPv6** auf; WSL2 hat keine
   IPv6-Route (`Network is unreachable`). Es braucht den **IPv4-Pooler** (Supavisor,
   Session-Mode) aus dem Dashboard → *Connect*:
   ```
   postgresql://postgres.<ref>:<passwort>@aws-<N>-<region>.pooler.supabase.com:5432/postgres
   ```

Der Ist-Zustand der **echten** Prod-DB ist damit weiterhin **unbekannt**. Für den
Neuaufbau ist das nicht blockierend (Daten sind wegwerfbar, der Zielzustand steht), aber
der Abgleich hat deshalb nur drei statt vier Spalten.

### 2. Phase 4 — die Befehle für Rasit (bewusst von Hand)

> ⚠️ Löscht **alle** Prod-Daten.

```bash
# 0. Pooler-URL in .env eintragen, dann read-only gegenprüfen:
python3 scripts/db/db_introspect.py          # zeigt den Prod-Ist-Zustand

# 1. Ist-Zustand sichern (Beweisstück)
npx supabase link --project-ref <ref>
npx supabase db dump --file prod-backup-$(date +%F).sql

# 2. Prod aus den Migrationen neu aufbauen
npx supabase db reset --linked

# 3. Verifizieren: 35 Relationen, schema_migrations gefüllt, Grants gesetzt
python3 scripts/db/db_introspect.py
```

**Ohne die Grants-Migration wäre Schritt 2 fatal gewesen.** Sie ist jetzt drin.

Danach zusätzlich in Studio anlegen (Buckets sind kein Schema):
`task-assets` (public) und `screening-uploads` (privat).

### 3. `guard-bash.sh` blockiert den eigenen Flow

Der Guard blockt pauschal `supabase db reset` — also auch den **lokalen** Neuaufbau,
den `migrate-verify.sh` als Beweis braucht. `.claude/hooks/**` ist eine geschützte Zone;
der headless-Lauf konnte die Datei nicht ändern (und hat den Guard bewusst **nicht** über
ein Skript umgangen — er ist die geltende Kontrolle, nicht bloß eine Absicht).

Wie kaputt die Regel ist, hat sie selbst gezeigt: sie hat den **Commit** blockiert, weil
die Commit-*Message* die Zeichenfolge enthielt.

Der exakte Patch (lokal erlauben, Remote sperren) steht in `AUTONOMY_NOTES.md`.
Bis dahin läuft `migrate-verify.sh` nur von Hand.

### 4. `schema.sql` ist jetzt redundant

Die ausführbare Wahrheit ist `supabase/migrations/`. `schema.sql` liegt weiter im Root
und **driftet ab dem nächsten Migrations-PR**. Entweder als generiertes Artefakt neu
erzeugen (`supabase db dump`) oder löschen. CLAUDE.md §10 („SQL immer in schema.sql
dokumentieren") gilt faktisch nicht mehr und gehört angepasst.

---

## Was der nächste Lauf zuerst tun sollte

1. `guard-bash.sh` patchen (AUTONOMY_NOTES.md §1) — sonst ist der DB-Flow nicht autonom.
2. Pooler-URL besorgen → Prod-Ist-Zustand erheben → Phase 4 bewusst fahren.
3. Die zwei `generate_parent_report`-Bugs fixen (eigener PR, eigener Test).
4. `schema.sql`-Frage entscheiden.
