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
