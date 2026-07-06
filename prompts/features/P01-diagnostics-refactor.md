# P01 — Kalibrierung: DiagnosticsPage-Refactor

> **Self-contained Claude-Code-Spec. Erster autonomer Testlauf nach P00.**
> Ausführen: `./scripts/claude-auto.sh prompts/features/P01-diagnostics-refactor.md`
> Zweck: reine Struktur-Aufgabe, um das Autonomie-Fundament (Hooks, Stop-Gate, Tests, CI) scharf zu kalibrieren. **Kein Verhalten darf sich ändern.**

---

## Kontext

- Stack: Vite + React 18 + TypeScript + Tailwind v4 + shadcn/ui + Supabase. Alle Supabase-Aufrufe liegen in `src/lib/`.
- `DiagnosticsPage.tsx` überschreitet das 400-Zeilen-Limit (CLAUDE.md §4, aktuell ~427 Zeilen). Sie rendert die Zwei-Panel-Seeding-UI für Diagnostik-Aufgaben (`tasks.is_diagnostic=true`): links ein Formular zum Anlegen neuer Aufgaben, rechts die Liste bestehender Aufgaben als Zeilen.
- Ziel: Datei unter 400 Zeilen bringen durch **Extraktion von zwei Komponenten** — `NewTaskForm` und `TaskRow` — ohne jede Verhaltens- oder UI-Änderung.

## Harte Regeln für diesen Lauf

- **Reiner Refactor. Null Verhaltensänderung, null sichtbare UI-Änderung, null Änderung an Datenfluss/Supabase-Aufrufen.** Wenn du in Versuchung kommst, „nebenbei" etwas zu verbessern: nicht tun. Notiere Verbesserungsideen in `AUTONOMY_NOTES.md`.
- **Erlaubte Dateizonen:** `src/**` (Komponenten, Tests). **Verboten:** `supabase/migrations/`, `supabase/schema.sql`, `src/lib/**` (Shared-Lib — in autonomen Läufen gesperrt). Falls du glaubst, eine Lib-Änderung zu brauchen: NICHT machen, in `AUTONOMY_NOTES.md` beschreiben und ohne sie lösen.
- Design Rules einhalten: keine Inline-Styles, keine hardcodierten Farben (nur CSS-Variablen), 44px Touch-Targets, `EmptyState`-Komponente für leere Zustände. Bestehende Klassen 1:1 übernehmen, nicht umstylen.
- Jede extrahierte Datei bleibt selbst unter 400 Zeilen.
- Konventionelle Commits. Am Ende Retro schreiben.

---

## Phase 1 — Discovery (erst lesen, dann planen)

1. `DiagnosticsPage.tsx` finden (`grep -r "DiagnosticsPage" src` / Routing `/admin/diagnostics`). Vollständig lesen.
2. Zeilenzahl bestätigen (`wc -l`).
3. Identifizieren und in einer kurzen Notiz festhalten (nicht committen, nur für deinen Plan):
   - **Formular-Block** → wird `NewTaskForm`: welche Props braucht er (State-Setter, Submit-Handler, ggf. `is_diagnostic`-Flag)? Welche lokalen States gehören ins Formular, welche bleiben im Parent?
   - **Listenzeilen-Block** → wird `TaskRow`: welche Props (task-Objekt, Handler wie onDelete/onEdit falls vorhanden)?
   - Welche Typen/Interfaces werden geteilt? (Liegen sie schon in einer Typdatei? Sonst am Verwendungsort belassen, nicht in lib verschieben.)
4. Prüfen, ob es bereits Tests zu dieser Seite gibt.

## Phase 2 — Extraktion

1. `TaskRow.tsx` erstellen (gleiches Verzeichnis wie DiagnosticsPage oder `./components/`, je nach vorhandener Konvention — nachschauen, nicht raten). Reine Präsentation, Props-getrieben, keine eigenen Supabase-Aufrufe. Markup/Klassen exakt aus dem Original übernehmen.
2. `NewTaskForm.tsx` erstellen. Formular-State kapseln; nach oben kommuniziert es über einen `onCreate`/`onSubmit`-Prop-Callback. Der Supabase-Schreibaufruf bleibt dort, wo er heute liegt (Parent oder lib) — **nicht verschieben**, nur den Aufruf über Prop auslösen, falls er heute inline im Formular steht und dafür kein Lib-Zugriff nötig wird. Wenn die Extraktion einen Lib-Zugriff erzwingen würde: Variante wählen, bei der der Parent den Lib-Call macht und dem Formular nur den Callback gibt.
3. `DiagnosticsPage.tsx` auf Orchestrierung reduzieren: Daten laden, State halten, `<NewTaskForm .../>` + Liste aus `<TaskRow .../>` rendern.
4. Imports/Typen sauber ziehen. `npm run typecheck` und `npm run lint` müssen grün sein (die Hooks erzwingen das ohnehin pro Datei).

## Phase 3 — Absicherung durch Tests

Da „kein Verhalten ändert sich" die zentrale Zusage ist, sichere sie mit leichten Component-Tests ab (Vitest + Testing Library):
- `NewTaskForm`: rendert die Felder; Eingabe + Submit ruft den `onCreate`-Callback mit den erwarteten Werten auf.
- `TaskRow`: rendert die Felder eines übergebenen Task-Objekts; vorhandene Aktions-Buttons feuern ihre Callbacks.
- `DiagnosticsPage`: rendert bei leerer Liste den `EmptyState`; rendert bei n Tasks n `TaskRow`.

Keine echten Supabase-Calls in Tests — Client mocken bzw. Callbacks als Spies. Tests klein halten.

## Phase 4 — Doku

- `docs/retros/RETRO-P01.md`: Vorher/Nachher-Zeilenzahlen (DiagnosticsPage + neue Dateien), was extrahiert wurde, ob Tests bestätigen dass sich nichts geändert hat, ob Ideen in AUTONOMY_NOTES.md gelandet sind.

---

## Abnahme-Checkliste (alles erfüllt, bevor du fertig meldest)

- [ ] `DiagnosticsPage.tsx` < 400 Zeilen · `NewTaskForm.tsx` < 400 · `TaskRow.tsx` < 400
- [ ] `npm run typecheck` grün · `npm run lint` grün · `npm run test` grün
- [ ] Keine Datei in `src/lib/`, `supabase/migrations/`, `supabase/schema.sql` verändert
- [ ] Keine hardcodierten Farben / Inline-Styles neu eingeführt; `EmptyState` weiter genutzt
- [ ] Component-Tests für NewTaskForm, TaskRow, DiagnosticsPage vorhanden und grün
- [ ] Supabase-Aufrufe funktional unverändert (gleiche Stelle, gleiche Signatur)
- [ ] `RETRO-P01.md` geschrieben; offene Verbesserungsideen in `AUTONOMY_NOTES.md`

**Commit-Reihenfolge:**
1. `refactor(diagnostics): extract TaskRow component`
2. `refactor(diagnostics): extract NewTaskForm component`
3. `test(diagnostics): component tests for extracted parts`
4. `docs: retro P01`
