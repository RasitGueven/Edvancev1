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
