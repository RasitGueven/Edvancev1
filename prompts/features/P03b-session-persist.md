# P03b — Präsenz-Session an die DB anschließen

> `./scripts/claude-auto.sh prompts/features/P03b-session-persist.md` (BEAUFSICHTIGT laufen lassen — echter Produktcode.)
> Basis: KERNSCHLEIFE-GAP-AUDIT.md, Schritt 3. Ziel: /student/session/:id persistiert echten Aufgaben-Fortschritt + XP über den BESTEHENDEN serverseitigen Pfad — löst damit die Datenquelle für Resume, Coach-Ansicht, Mastery, Eltern-Report.

## Ist-Zustand-Check ZUERST (Pflicht, Lehre aus P01)
Nichts annehmen. Belege am realen Code (Datei:Zeile):
- Wie persistiert /student/task/:taskId heute? Finde den RPC `complete_task` (SECURITY DEFINER) und wie er aufgerufen wird (welche lib-Funktion, welche Parameter, wie XP fließt).
- Wie lädt /student/session/:id heute? Finde `src/pages/student/session/warmup.ts` (5 hardcodierte Aufgaben) und den Session-Flow (State-Machine, Grading, was in DB geht — laut Audit nur Attendance).
- Welche DB-Aufgaben-Ladefunktion nutzt der Task-Flow, die die Session wiederverwenden kann?
Schreibe die Befunde als kurzen "Ist-Zustand"-Block in die RETRO.

## HARTE Regeln
- **KEINE Schema-Migration, KEINE Änderung an `migrations/`, `schema.sql`, `src/lib/supabase/**` Kern-Clients.** Die Persistenz-Infrastruktur (`complete_task`-RPC) existiert bereits — du VERDRAHTEST sie nur in den Session-Flow, du baust sie nicht neu. Falls du doch eine Schema-/lib-Änderung für nötig hältst: NICHT tun, in AUTONOMY_NOTES.md beschreiben, Lauf stoppen und melden.
- Erlaubte Zone: `src/pages/student/session/**` und die Session-Komponenten/State. Bestehende lib-Funktionen NUR aufrufen, nicht ändern.
- **Verhalten der bestehenden `/student/task/:taskId`-Route bleibt unangetastet.** Du änderst nur die Session-Route.
- FernUSG bleibt gewahrt: Die Session vergibt weiterhin KEINE Mastery automatisch (Mastery bleibt Coach-only, das ist P03c). Session persistiert nur Aufgaben-Fortschritt + XP, nicht Mastery.
- Design Rules (keine hardcodierten Farben/Inline-Styles, 400-Zeilen-Limit) — Hooks erzwingen das ohnehin.

## Auftrag
1. Die Session-Runtime `/student/session/:id` so umbauen, dass sie **echte DB-Aufgaben** lädt (statt der 5 hardcodierten aus warmup.ts) und jeden abgeschlossenen Task über denselben serverseitigen Pfad persistiert, den der Task-Flow nutzt (`complete_task`-RPC) — sodass Fortschritt + XP real in der DB landen.
2. warmup.ts nicht ersatzlos löschen, falls es als Fallback/Seed dient — prüfen, ob es woanders referenziert wird; wenn nur hier genutzt, sauber ablösen und in RETRO vermerken.
3. Die Session muss weiterhin lauffähig sein (Aufgabe laden → lösen → abgeben → nächste), nur jetzt DB-gestützt.

## Tests (Pflicht — das ist der Verifikationsbeweis)
- Vitest-Tests für die neue Persistenz-Logik der Session: abgeschlossener Task ruft den Persistenz-Pfad mit korrekten Werten auf (Supabase/RPC gemockt, keine echten Calls).
- Test, dass die Session KEINE Mastery schreibt (FernUSG-Regression, analog INV-Tests).
- Bestehende Tests bleiben grün.

## Abschluss
- typecheck + lint + test grün (das Stop-Gate erzwingt es).
- RETRO `docs/retros/RETRO-P03b.md`: Ist-Zustand-Befunde, was verdrahtet wurde, welche der 4 abhängigen Lücken (Resume/Coach/Mastery-Datenquelle/Report) jetzt eine Datenquelle haben.
- AUTONOMY_NOTES.md fortschreiben, falls Schema-/lib-Wünsche auftraten.
- Commits konventionell, z.B. `feat(session): persist real task progress + XP in in-person session`.

## Abnahme-Checkliste
- [ ] Ist-Zustand-Block in RETRO (mit Datei:Zeile-Belegen)
- [ ] /student/session/:id lädt DB-Aufgaben + persistiert über bestehenden complete_task-Pfad
- [ ] /student/task/:taskId-Verhalten unverändert
- [ ] KEINE Migration/Schema/lib-Kern-Änderung (sonst in AUTONOMY_NOTES + gestoppt)
- [ ] Session vergibt keine Mastery (FernUSG-Test grün)
- [ ] typecheck + lint + test grün
- [ ] RETRO-P03b.md geschrieben
