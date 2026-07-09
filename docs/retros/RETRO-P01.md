# RETRO-P01 — Kalibrierung: DiagnosticsPage-Refactor

**Datum:** 2026-07-09
**Branch:** `auto/P01-diagnostics-refactor-20260709-1338`
**Spec:** `prompts/features/P01-diagnostics-refactor.md`
**Zweck:** Erster autonomer Lauf nach P00 — das Autonomie-Fundament (Hooks,
Stop-Gate, Tests, CI) an einer reinen Struktur-Aufgabe kalibrieren.

---

## Wichtigster Befund: Die Extraktion war schon da

Die Spec geht von einer `DiagnosticsPage.tsx` mit ~427 Zeilen aus. Die Discovery
hat gezeigt: **Phase 1 und Phase 2 waren zum Startzeitpunkt bereits erledigt** —
nicht durch diesen Lauf, sondern durch Commit `3c79328` (2026-05-17,
*„feat: Diagnose-Aufgaben-Verwaltung verständlich"*). Die Spec war zu diesem
Punkt veraltet.

Dieser Lauf hat die Extraktion daher **nicht wiederholt und nicht angefasst**.
Er hat den Zustand verifiziert und die fehlenden Phasen 3 (Tests) und 4 (Doku)
nachgezogen. Die Commits 1 und 2 aus der Spec-Reihenfolge entfallen — es gibt
nichts zu committen, was nicht schon in der Historie steht. Leere Commits zu
erzeugen, nur um die Checkliste abzuhaken, wäre Theater gewesen.

## Zeilenzahlen

| Datei | Vorher (`3c79328~1`) | Jetzt |
|---|---|---|
| `src/pages/admin/DiagnosticsPage.tsx` | 427 | **136** |
| `src/pages/admin/diagnostics/NewTaskForm.tsx` | – | **193** |
| `src/pages/admin/diagnostics/TaskRow.tsx` | – | **153** |
| `src/pages/admin/diagnostics/shared.ts` | – | **15** |

Alle Dateien unter dem 400-Zeilen-Limit (CLAUDE.md §4). Das 427-Zeilen-Problem
existiert seit dem 17.05. nicht mehr.

## Was dieser Lauf gebaut hat

Neue Dateien, alle unter `src/pages/admin/` (keine Zeile in `src/lib/`,
`migrations/`, `schema.sql`):

| Datei | Zeilen | Inhalt |
|---|---|---|
| `diagnostics/testFixtures.ts` | 50 | `makeTask` / `makeSubject` / `makeCluster` |
| `diagnostics/TaskRow.test.tsx` | 87 | 6 Tests |
| `diagnostics/NewTaskForm.test.tsx` | 113 | 6 Tests |
| `DiagnosticsPage.test.tsx` | 98 | 4 Tests |

Abgedeckt:

- **`TaskRow`** — rendert Titel/Frage-Fallback, Badge-Zustand und die drei
  Enum-Selects aus dem Task-Objekt; „Speichern" ruft `updateTaskDiagnostic` mit
  dem bearbeiteten Patch und feuert danach `onSaved`; Lib-Fehler wird angezeigt
  und `onSaved` bleibt stumm; Vorschau-Toggle blendet ein/aus.
- **`NewTaskForm`** — rendert alle Felder; leere Frage validiert und ruft die Lib
  nicht; Eingabe + Submit ruft `createDiagnosticTask` mit getrimmter Frage und
  den gewählten Enum-Werten und meldet über `onCreated` nach oben;
  Cluster-Auswahl lädt Microskills; Lib-Fehler unterdrückt `onCreated`.
- **`DiagnosticsPage`** — `EmptyState` „Cluster wählen" ohne Cluster,
  `EmptyState` „Keine Aufgaben" bei leerer Liste, genau n `TaskRow` für n Tasks
  (inkl. Prop-Contract über die Task-`id`), Fehleranzeige aus dem Lib-Aufruf.

Keine echten Supabase-Calls: `@/lib/supabase/tasks` ist in jedem Test als Spy
gemockt. Im Page-Test sind zusätzlich `NewTaskForm`/`TaskRow` gestubbt, damit der
Test wirklich nur die Orchestrierung prüft; im `TaskRow`-Test ist
`TaskPreviewCard` gestubbt (kein Markdown-/KaTeX-Rendering).

## Bestätigen die Tests, dass sich nichts geändert hat?

**Nein — und das muss man sauber trennen.** Die Tests sind *nach* der Extraktion
geschrieben. Sie können nicht rückwirkend beweisen, dass `3c79328` verhaltensneutral
war; dafür hätten sie vorher existieren müssen. Was sie leisten: Sie schreiben das
heutige Verhalten der drei Komponenten fest, sodass **künftige** Refactorings an
dieser Stelle abgesichert sind. Genau das war die Lücke, die dieser Lauf schließt.

Dieser Lauf selbst hat an `DiagnosticsPage.tsx`, `NewTaskForm.tsx`, `TaskRow.tsx`
und `shared.ts` **keine Zeile geändert** — Verhaltensneutralität ist hier trivial
erfüllt, weil kein Produktivcode angefasst wurde.

## Kalibrierungs-Erkenntnisse zum Autonomie-Fundament

1. **`post-edit-check.sh` greift und ist schnell.** Jede geschriebene Datei wurde
   sofort durch ESLint + 400-Zeilen-Check geschickt. Kein Fehlalarm.
2. **`guard-paths.sh` wurde nicht ausgelöst** — der Lauf hat `src/lib/**` nie
   berührt. Die Sperre blieb unbewiesen (kein Negativtest).
3. **Bash ist im autonomen Lauf enger als erwartet.** `npm run typecheck`,
   `npm run lint`, `npm run test` und `npx vitest run` waren *alle* nicht
   ausführbar (Permission-Gate), ebenso jedes Kommando mit Pipe (`|`) oder `&&`.
   Konsequenz: Der Lauf konnte die Tests **nicht selbst grün sehen** und war
   vollständig auf das `Stop`-Gate als einzige Verifikationsinstanz angewiesen.
   Das ist eine harte Einschränkung — Test-Iteration wird zum Blindflug mit einem
   40-Zeilen-Log als einzigem Feedback.
   **Empfehlung:** `npm run typecheck|lint|test` und `npx vitest run` in die
   Bash-Allowlist von `.claude/settings.json` aufnehmen. Sie sind read-only
   bezogen auf `src/` und genau die Kommandos, die CLAUDE.md §4 verlangt.
4. **Die Spec war veraltet.** Ein autonomer Lauf muss Discovery ernst nehmen und
   darf die Spec-Prämisse nicht glauben. Hätte der Lauf blind „extrahiert", wäre
   ein Duplikat oder ein sinnloser Umbau entstanden.
   **Empfehlung:** Specs vor dem Lauf gegen `HEAD` prüfen, oder Phase 1 explizit
   mit einem Abbruchkriterium versehen („wenn schon extrahiert: Phase 2 skippen").

## Offene Punkte

In `AUTONOMY_NOTES.md` festgehalten, bewusst **nicht** in diesem Lauf umgesetzt:

1. `NewTaskForm`/`TaskRow` rufen die Supabase-Lib selbst auf (Spec bevorzugt
   Parent-owned Lib-Call) — Datenfluss-Änderung, unzulässig im reinen Refactor.
2. Selects ohne `id`/`htmlFor`-Verknüpfung → a11y-Lücke.
3. i18n-Schuld (CLAUDE.md §12): hardcodierte deutsche Strings in allen drei Dateien.
4. Doppeltes Select-Trio in `NewTaskForm` und `TaskRow` → gemeinsamer Baustein,
   gehört ins Foundation-Fenster.
5. `SELECT_CLASS` in `shared.ts` ist ein Pass-Through auf `SELECT_SM`.
