# AUTONOMY_NOTES

Verbesserungsideen, die in autonomen Läufen **bewusst nicht** umgesetzt wurden —
weil sie `src/lib/**`, das Schema oder geteilte Bausteine berühren, oder weil sie
über den Scope eines reinen Refactors hinausgehen. Umsetzung später beaufsichtigt
im Foundation-Fenster.

---

## P01 — Diagnostics-Refactor (2026-07-09)

### 1. `NewTaskForm` besitzt den Supabase-Schreibaufruf selbst

- **Was:** `NewTaskForm` ruft `createDiagnosticTask` (aus `src/lib/supabase/tasks.ts`)
  direkt auf und meldet dem Parent nur ein argumentloses `onCreated()`.
- **Warum notiert:** Die P01-Spec bevorzugt die Variante „Parent macht den Lib-Call,
  das Formular bekommt nur `onCreate(payload)`". Das umzubauen wäre eine
  Struktur-/Datenfluss-Änderung — in einem als „null Verhaltensänderung"
  deklarierten Refactor nicht zulässig.
- **Betroffene Symbole:** `NewTaskForm` (`src/pages/admin/diagnostics/NewTaskForm.tsx`),
  `DiagnosticsPage`, `createDiagnosticTask`.
- **Hinweis:** Gleiches gilt für `TaskRow` → `updateTaskDiagnostic`. `TaskRow` ist
  damit keine reine Präsentationskomponente, wie die Spec sie idealtypisch skizziert.

### 2. Selects ohne Label-Verknüpfung (a11y)

- **Was:** In `NewTaskForm` und `TaskRow` stehen `<Label>`-Elemente ohne `htmlFor`
  neben `<select>`-Elementen ohne `id`. Nur `Klassenstufe`, `Frage` und `Lösung`
  sind korrekt verknüpft.
- **Folge:** Screenreader lesen die Selects ohne Namen; Tests müssen die Selects
  über `getAllByRole('combobox')`-Indizes adressieren statt über `getByLabelText`.
- **Fix:** `id`/`htmlFor`-Paare ergänzen. Reine UI-Änderung, aber sichtbar im
  DOM-Contract → nicht in diesem Lauf.

### 3. i18n-Schuld (CLAUDE.md §12)

- **Was:** Alle drei Dateien enthalten hardcodierte deutsche Strings
  (`'Speichern'`, `'Frage erforderlich.'`, `'Diagnose-Aufgabe anlegen'`, die
  `EmptyState`-Texte usw.).
- **Warum notiert:** §12 verlangt Auslagerung beim Editieren. Die Extraktion hat
  die Strings aber nur verschoben, nicht neu geschrieben — und eine
  i18n-Migration bräuchte einen neuen Namespace (`admin`) unter `src/i18n/`,
  also einen geteilten Baustein.
- **Fix:** Eigener Lauf `admin`-Namespace + Keys.

### 4. Doppeltes Select-Trio (Schwierigkeit / Antwortformat / Anspruch)

- **Was:** `NewTaskForm` und `TaskRow` rendern dasselbe Dreier-Set aus
  `DIFFICULTY_OPTIONS`, `INPUT_TYPES`, `COG_TYPES` mit identischer Markup-Struktur.
- **Fix:** Eine gemeinsame `<TaskEnumSelects />`-Komponente. Das ist ein **neuer
  geteilter Baustein** → gehört laut CLAUDE.md („Hard Limits") ins
  Foundation-Fenster, nicht in ein Surface-Fenster.

### 5. `shared.ts` — `SELECT_CLASS` ist ein Pass-Through

- **Was:** `export const SELECT_CLASS = SELECT_SM` aus `src/lib/formStyles`.
- **Fix:** Entweder direkt `SELECT_SM` importieren oder den Alias begründen.
  Berührt `src/lib/**`-Konsumenten → bewusst gelassen.

---

## P03a — Kernschleifen-Gap-Audit (2026-07-09)

Der Lauf war reine Analyse; kein Produktivcode wurde angefasst. Dabei sind vier
Punkte aufgefallen, die eine Foundation-Entscheidung brauchen.

### 1. Verwaister Code: `StudentWidgetGrid`

- **Was:** `src/components/edvance/StudentWidgetGrid.tsx` hat null Importer im
  gesamten Repo. Enthält `ContinueTile` (Zeile 30), das `getResumePoint`
  konsumieren würde.
- **Warum:** Entweder verdrahten (Spec P03f, Session-Resume) oder entfernen.
  Aktuell ist es toter Code, der aber die einzige vorhandene UI für den
  Wiedereinstieg darstellt.
- **Empfehlung:** *nicht* löschen, bis P03f entschieden ist.

### 2. Toter Lib-Code in `src/lib/supabase/**`

Folgende exportierte Funktionen haben null Aufrufer. Entfernen würde die
`src/lib/**`-Zone berühren → gehört ins Foundation-Fenster, nicht in ein
Surface-Fenster.

| Symbol | Datei:Zeile | Anmerkung |
|---|---|---|
| `markTaskCompleted` | `src/lib/supabase/taskProgress.ts:6` | abgelöst durch `completeTask` (RPC `complete_task`) |
| `awardXp` | `src/lib/supabase/progress.ts:26` | abgelöst durch Trigger `apply_xp_event`; nur noch Test-Aufrufer in `inv2-gamification-isolation.test.ts` |
| `getActiveSubscription` | `src/lib/supabase/subscriptions.ts:21` | |
| `setSubscription` | `src/lib/supabase/subscriptions.ts:42` | |
| `assignCoach` | `src/lib/supabase/studentCoach.ts:5` | `setStudentCoach` wird stattdessen genutzt |
| `getCoachForStudent` | `src/lib/supabase/studentCoach.ts:27` | |
| `listStudentsForCoach` | `src/lib/supabase/studentCoach.ts:49` | |

**Achtung — nicht in diese Liste aufnehmen:** `getResumePoint`
(`resume.ts:16`), `deriveScreeningRecommendation` (`recommendation.ts:37`) und
`grantMastery` (`competencyMastery.ts:58`) haben zwar ebenfalls keine
UI-Aufrufer, werden aber in P03c/P03e/P03f gebraucht. `awardXp` wird durch
`inv2` als Invariante geschützt — Entfernung würde den Test mitnehmen; das ist
eine bewusste Entscheidung, keine Aufräumaktion.

### 3. Edge Function `generate_parent_report`: veraltetes Modell + fehlende Quellen

- **Datei:** `supabase/functions/generate_parent_report/index.ts:46`
- **Was:** `const MODEL = 'claude-sonnet-4-6'`. Die ID ist gültig, aber
  Vorgängergeneration. Aktuelles Sonnet-Modell ist `claude-sonnet-5`.
  Ein Upgrade ist **nicht** nur ein String-Tausch: Sonnet 5 lehnt
  `budget_tokens` sowie nicht-default `temperature`/`top_p`/`top_k` mit 400 ab,
  läuft standardmäßig mit adaptivem Thinking und nutzt einen neuen Tokenizer
  (~30 % mehr Tokens bei gleichem Text) — das berührt das Kosten-Guardrail über
  `parent_report_generations` (`index.ts:246`).
- **Warum offen gelassen:** Modellwechsel in einer Edge Function, die Eltern
  sichtbare Texte erzeugt, ist eine bewusste Produkt-/Kostenentscheidung.
- **Zweiter Punkt, gleiche Datei:** Der Report liest in `index.ts:297-328`
  weder `student_task_progress` noch `student_competency_mastery`. Sobald das
  Coach-Mastery-UI (P03c) steht, muss die Fakten-Sammlung um beide Quellen
  erweitert werden — sonst kann der Report keine Aussage über gelöste Aufgaben
  oder bestätigte Kompetenzen treffen. ⚖️ FernUSG: Mastery-Aussagen dürfen
  ausschließlich aus `student_competency_mastery.mastered` stammen, nie aus
  abgeleiteten Scores.

### 4. Migrations-Bedarf (Vorwarnung, noch keine Spec)

- **P03d (Mastery gated den Lernpfad):** Es existiert keine Tabelle, die
  Voraussetzungen zwischen Clustern/Mikroskills modelliert. Ohne die kann
  Mastery keinen nächsten Pfad-Schritt freischalten. → Schema-Entscheidung,
  **Konsensus-Trigger nach CLAUDE.md §8**, `ALLOW_MIGRATIONS=1` erforderlich.
- **P03e (Screening seedet den Lernpfad):** Eine persistierte Pfad-Reihenfolge
  pro Schüler:in existiert nicht. `student_focus_areas`
  (`migrations/030_student_focus_areas.sql:14`) existiert dagegen bereits samt
  RLS und Lese-Funktion — dort fehlt nur der Schreibpfad, keine Migration.

Details und Belege: `docs/audits/KERNSCHLEIFE-GAP-AUDIT.md`.

## P00b+ — Schema-Abgleich & DB-Autonomie (2026-07-11)

Vollständiger Kontext: `docs/audits/SCHEMA-ABGLEICH.md`, `docs/retros/2026-07-11-p00b-plus-db-autonomie.md`.

### 1. `guard-bash.sh` muss angepasst werden (blockiert aktuell den eigenen Flow)

`.claude/hooks/**` ist eine geschützte Zone — der autonome Lauf konnte die Datei
nicht selbst ändern. Nötig:

- **Entfernen:** das pauschale Muster `'supabase +db +reset'`. Es blockiert den
  **lokalen** Reset gegen die Docker-DB — also genau den Beweis-Schritt, den
  `scripts/db/migrate-verify.sh` braucht. Die lokale DB ist wegwerfbar.
- **Hinzufügen** (Remote bleibt für den Agenten gesperrt):
  - `supabase\s+([a-z-]+\s+)*db\s+push` → Remote-Apply
  - `supabase\s.*--linked` → richtet jedes db-Kommando gegen Remote
  - `--db-url` auf einen nicht-lokalen Host
  - `supabase\s+db\s+remote\s+commit`
  - freies `(DROP|TRUNCATE)\s+(TABLE|SCHEMA|DATABASE)` via `psql`/`docker … psql`

Bis das drin ist, läuft `migrate-verify.sh` nur von Hand (Rasit), nicht im Agenten.
**Solange nicht ändern und `db reset` auch nicht über ein Skript umgehen** — der
Guard ist die geltende Kontrolle, nicht die Absicht.

### 2. Zwei echte Bugs in `supabase/functions/generate_parent_report/index.ts`

Beim Code↔DB-Abgleich gefunden, **nicht** von diesem Lauf verursacht und bewusst
nicht mitgefixt (DB-Session, eigener Test/Review nötig). Beide scheitern **still**
(`?? []` / `?? null`), der Elternbericht degradiert unbemerkt:

- **`index.ts:327`** — `admin.from('clusters')`. Die Tabelle heißt
  **`skill_clusters`**; `clusters` existiert nirgends. `clusterNames` ist damit
  immer leer → der Bericht verliert **alle** Cluster-Namen.
- **`index.ts:304-306`** — `.select('xp_total, streak_days, level')`.
  `student_progress.streak_days` wurde von Migration 036 gedroppt (ersetzt durch
  `presence_streak_*` / `home_streak_*`, Migration 032). PostgREST antwortet 400 →
  XP/Level im Bericht fallen still weg.

Beides sind **Code**-Fehler gegen ein korrektes Schema — kein Migrationsbedarf.

### 3. Stale Pfad-Referenz nach dem Migrations-Umzug

`src/lib/supabase/storage.ts:3` verweist auf `migrations/010_task_assets_storage_rls.sql`.
Der Pfad ist jetzt `supabase/migrations_archive/20250101000010_task_assets_storage_rls.sql`.
Nur ein Kommentar, kein Verhalten — `src/lib/**` ist im autonomen Lauf gesperrt.

### 4. `schema.sql` ist jetzt redundant

Die ausführbare Wahrheit ist `supabase/migrations/`. `schema.sql` liegt weiter im
Root und **driftet ab dem nächsten Migrations-PR**. Entscheidung für Rasit: entweder
als generiertes Artefakt aus der lokalen DB neu erzeugen (`supabase db dump`) oder
löschen. Solange es existiert, gilt CLAUDE.md §10 („SQL immer in schema.sql
dokumentieren") faktisch nicht mehr — auch das gehört angepasst.

---

## C03 — LSA-Items-Import (2026-07-12)

### 1. `tasks` hat kein Lizenz-Feld — CC-BY-Attribution hat keinen Ort (rechtlich)

Alle 15 VERA-8-Items stehen unter **CC BY 4.0 (IQB/VERA-8), Attribution
erforderlich** (`lizenz_status` im Quell-JSON). `tasks` hat `source` / `source_ref`
(= Quelle), aber **keine Spalte für die Lizenz**. Der Import füllt deshalb
`source='VERA8_IQB'` + `source_ref=<IQB-UUID>`; der Lizenztext liegt **nirgends** in
der DB.

- **Was fehlt:** `alter table tasks add column license text` (+ ggf.
  `attribution text`), Backfill aus `lizenz_status`, und eine Anzeige der
  Attribution dort, wo das Item gerendert wird.
- **Warum nicht hier:** Schema-Änderung — Spec §6 verbietet Migration in diesem Lauf.
- **Dringlichkeit:** Das ist eine Lizenzauflage, keine Nettigkeit. Vor einem
  öffentlichen Launch mit diesen Items muss die Attribution sichtbar sein.

### 2. `input_type = 'short_input'` existiert nicht — Spec vs. CHECK-Constraint

Spec §3 verlangt `input_type='short_input'`. Das ist **kein erlaubter Spaltenwert**:
`tasks_input_type_check` lässt nur `MC|NUMERIC|SHORT_TEXT|TRUE_FALSE|FREE_TEXT|
MATCHING|CLOZE|COORDINATE` zu (gegen die Live-DB verifiziert: Insert wird
abgewiesen). `'short_input'` ist der Payload-*kind*, den `lsa_question_payload()`
für jedes Nicht-MC-Item baut — nicht der Diskriminator in der Spalte. Import nutzt
`NUMERIC` (alle 15 Lösungen sind Zahlen; `lsa_start` lässt `MC|SHORT_TEXT|NUMERIC`
in den Pool). Kein Handlungsbedarf, aber die Spec-Formulierung ist irreführend.

### 3. `cluster_id` ist faktisch Pflichtfeld für den LSA-Pool

`lsa_start` joint **INNER** auf `skill_clusters` → `subjects`. Ein Item ohne
`cluster_id` wird nie ausgespielt, ohne dass irgendwo ein Fehler auftaucht. Der
Import mappt `edvance_matrix.inhaltsfelder` → Cluster-Name. Vorschlag fürs
Foundation-Fenster: entweder `not null` auf `tasks.cluster_id` für `status='ready'`
(Partial-Constraint) oder ein Left-Join + explizite Warnung in `lsa_start`.

---

## A01 — Autoren-Tool für die Item-Pflege (2026-07-14)

Branch `feat/A01-autorentool`. Vollständige Begründung in `docs/retros/RETRO-A01.md`.

### 1. Drei fehlende Schema-Felder — Vorschlag liegt, nicht ausgeführt

Der Auftrag verbot eigenmächtiges Migrieren. Die additive Migration liegt deshalb in
**`docs/schema/A01-authoring.proposal.sql`** (bewusst *nicht* in
`supabase/migrations/` — dort würde sie bei einem `db push` still mitlaufen):

- `tasks.curriculum_grade` — der **Stoffanker**. `class_level` ist der Herkunfts-
  jahrgang (VERA ⇒ überall `8`), aber `lsa_start` filtert bereits
  `coalesce(t.class_level, p_grade) <= p_grade` und liest die Spalte damit
  *semantisch* als Stoffanker. Solange dort `8` steht, ist Klasse-7-Stoff für eine
  Klasse-7-LSA unsichtbar. **Das ist ein stiller Pool-Fehler, kein Kosmetikthema.**
- `task_solution_get(uuid)` — es gibt **keinen Lesepfad** zu `task_solutions`
  (kein Grant, nur `task_solution_upsert`). Ohne ihn kann ein Pflege-Tool die
  bestehende Lösung nur blind überschreiben.
- `tasks.reviewed_by` / `reviewed_at` + `task_status_set(uuid, text)` — Freigabe-
  Audit. Der Stempel muss aus `auth.uid()` kommen, nicht aus dem Request-Body.

**Betroffene Symbole:** `tasks`, `task_solutions`, `lsa_start`, `lsa_has_answers`.
**Nachlauf:** `lsa_start` auf `coalesce(t.curriculum_grade, t.class_level, p_grade)`
umstellen — **erst nach** der Pflege, sonst mischt ein halb gepflegter Pool zwei
Bedeutungen in einer Abfrage.

Bis zur Ausführung läuft das Tool im Degraded-Modus (`probeAuthoringSchema()`
fragt die DB, statt zu raten) und sagt im UI, was es nicht kann.

### 2. `<Button asChild>` ist kaputt — im geteilten Baustein, nicht gefixt

`src/components/ui/button.tsx` rendert immer `{loading && <Spinner/>}{children}`.
Mit `asChild` sieht Radix' `Slot` darin **zwei** Kinder und wirft
`React.Children.only expected to receive a single React element child` — also
**immer**, nicht nur während `loading`. Gefunden vom Smoke-Test der Pflege-Liste.

- **Warum nicht hier gefixt:** `src/components/ui/**` ist geteilter Baustein; der Fix
  (bei `asChild` die children direkt durchreichen, ohne Spinner-Slot) berührt jeden
  künftigen Aufrufer und gehört ins Foundation-Fenster.
- **Umgehung im A01-Code:** `buttonVariants({…})` als `className` auf dem `<Link>`
  (shadcn-idiomatisch, kein Slot).
- **Betroffene Symbole:** `Button` (`asChild`-Pfad), jeder künftige
  `<Button asChild><Link/></Button>`.

### 3. `known_errors` ist für Term-Aufgaben nicht speicherbar

Gefunden beim Content-Lauf Termumformung (`content/termumformung-01`). Zwei
Mechanismen greifen ineinander und schließen sich gegenseitig aus:

- `lsa_acceptance_valid` lässt `known_errors` **nur in einem Satz mit
  `canonical`** zu. Ohne `canonical` wird `acceptance` als
  Teilaufgaben-Abbildung gelesen (Schlüssel müssen `^[1-9][0-9]*$` sein) und
  `known_errors` fällt durch den CHECK.
- Sobald `acceptance` ein `canonical` hat, nimmt `lsa_grade` den Zahlen-Pfad.
  Dort zerlegt `lsa_split_value_unit` den Term `5x+4` in Wert `5` und Einheit
  `x+4` und vergleicht **nur den Wert**. Live geprüft: mit
  `canonical = "5x+4"` bewertet `lsa_grade` die Antworten `5x+9`, `5x+6`,
  `5x-4` und `5x` alle als `voll`.

Ein Term-Content kann also entweder korrekt bewertet werden **oder**
`known_errors` tragen — nicht beides. Der Lauf hat sich für die korrekte
Bewertung entschieden (`acceptance = NULL`) und die Fehlbilder als Kommentar in
der Seed-Datei abgelegt.

- **Warum nicht hier gefixt:** `lsa_grade` / `lsa_acceptance_valid` sind
  Schema-Zone, der Lauf hatte `ALLOW_MIGRATIONS=0`.
- **Was nötig wäre:** ein Weg, `known_errors` ohne `canonical` zu hinterlegen
  (z.B. `acceptance` mit `known_errors` als alleinigem erlaubten Schlüssel), ODER
  ein `lsa_grade`, das bei nicht-numerischem `canonical` auf den
  String-Vergleich zurückfällt statt auf `lsa_split_value_unit`.
- **Nicht tun:** `acceptance = {"1": {"canonical": …, "known_errors": …}}`. Das
  ist gültig und bewertet heute zufällig richtig (weil `lsa_grade` die
  Teil-Abbildung ignoriert), behauptet aber eine Teilaufgabe, die es nicht gibt
   — und kippt still, sobald `lsa_grade` die Abbildung auswertet.
- **Betroffene Symbole:** `lsa_acceptance_valid`, `lsa_acceptance_rule_valid`,
  `lsa_grade`, `lsa_split_value_unit`.

### 4. Kein `input_hint` im Schüler-Payload

`lsa_question_payload` liefert für alles außer MC und MULTI_PART
`{task_id, kind: 'short_input', prompt, assets, table, unit}` — **kein Feld für
den Eingabemodus**. Ein Kind kann einer Aufgabe nicht ansehen, ob eine Zahl, ein
Bruch oder ein Term `ax+b` erwartet wird; die App rät (bei Brüchen heute über
einen Umschalter, den das Kind bedienen muss).

Für die Term-Aufgaben ist das blockierend: Der Ziffernblock der App kann kein
`x` tippen. Der einzige Unterschied im Datenbestand ist bisher
`tasks.input_type` (`SHORT_TEXT` für Terme, `NUMERIC` für Zahlen) — und der
steht dem Frontend über den Payload gar nicht zur Verfügung.

- **Was nötig wäre:** `lsa_question_payload` um ein Feld ergänzen, das den
  erwarteten Eingabemodus nennt (aus `tasks.input_type` ableitbar oder als
  eigenes Content-Feld).
- **Betroffene Symbole:** `lsa_question_payload`, `src/types/database.ts`,
  Frontend `edvance-app` (`LsaAufgabe`, `Zahleneingabe`).
