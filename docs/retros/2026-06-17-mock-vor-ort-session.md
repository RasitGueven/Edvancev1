# Retro: Vor-Ort-Session Mock (Tablet) — `/mock/session`

**Datum:** 2026-06-17
**Branch:** `claude/confident-heisenberg-uh75b4`
**Typ:** Klickbarer Frontend-Prototyp (kein Backend, kein Auth, kein Supabase)

## Was gebaut wurde

Ein vollständig durchklickbarer Mock der kompletten Vor-Ort-Session (11 Screens)
unter `/mock/session`. State liegt komplett in-memory (`useReducer`), nichts wird
persistiert. Produktion bleibt unberührt — es kam nur eine neue Route dazu.

### Architektur

- **Datenschicht** (`src/lib/mocks/session.ts`): Beispiel-Session „Lineare
  Funktionen", Klasse 9. Sieben gestaffelte Aufgaben (AFB I → III) als JSON-Stub,
  Skill-Tree mit gemischten Zuständen, Badges in vier Rarities, Coach-Daten.
  Aufgaben-Prompts/Hinweise/Coach-Notiz sind bewusst deutsche Strings (simulierter
  DB-Content, i18n-exempt laut CLAUDE.md §12).
- **Zustandsmaschine** (`src/lib/mocks/sessionMachine.ts`): reiner, testbarer
  Reducer. Enthält die Navigations-Invarianten, XP/Level-Mathematik, den
  Presence-Multiplikator und die Abschluss-Sequenz (Boss → Level-Up → stiller
  Abschluss). `displayStage()` erzwingt Hard Rule §6 (kein „Mastered" ohne
  `coachGranted`).
- **Orchestrator** (`src/pages/mock/session/MockSession.tsx`): mappt
  `state.screen` auf Screen-Komponenten und blendet Boss-/Level-Up-/Streak-Repair
  als Overlays ein (wiederverwendet aus `@/components/edvance/moments`).
- **Screens** (`src/pages/mock/session/screens/`): je ein File pro Screen.
- **Komponenten** (`src/pages/mock/session/components/`): dunkle Student-Surfaces
  (Shell, CTA-Button, Hub-Kachel, WeekStreak, Skill-Tree, Hint-Panel, Feedback-Bar,
  Task-Stub). Primitives (`XPBar`, `MasteryBar`, `StreakPill`, `RarityBadge`,
  `EmptyState`, `EdvanceCard`, `Modal`, `AvatarInitials`) wurden wiederverwendet.

### Reuse statt Neubau

- **JSXGraph** war bereits über `tasks/CoordinateInputWidget.tsx` integriert
  (echte Lib, Drag + Snap-to-Grid). Aufgabe 6 (`y = x + 1`) nutzt sie direkt —
  der Integrationspunkt ist damit bewiesen, ohne neue Dependency.
- **Emotional Moments** (`moments/BossChallengeModal`, `LevelUpModal`,
  `StreakRepairFlow`) erfüllen bereits die ≤3s- und Rot→Lila-Regeln. Direkt genutzt.

## Navigation & Invarianten (in der Maschine, getestet)

- Hub → {Session (3), Fortschritt (9), Trophäen (10), Avatar (disabled)}.
- In-Session linear: 3 → 4 (⇄ 5/6) → 7 → (8 bedingt) → 11.
- **Fortschritt/Trophäen sind aus dem Task-Flow nicht erreichbar** —
  `OPEN_PROGRESS`/`OPEN_TROPHIES` greifen nur in `hub`/`complete` (Schutz der 60 Min).
- Boss-Challenge nur bei > 80 % korrekt, Level-Up nur bei Level-Sprung — beide
  über Flags genau 1× pro Session.
- Mastered wird nie vom Mock gesetzt; nur `coachGranted: true` zeigt es an.

14 `node:test`-Fälle (`npm run test:mock`, via tsx) decken Navigation, XP-Vergabe,
Boss/Level-Up-Sequenz, Streak-Repair, Restart und `displayStage` ab.

## Entscheidungen bei Mehrdeutigkeit (Auto-Modus)

1. **Branch:** Der Auftrag nannte `feature/mock-vor-ort-session`. Die Web-Session
   ist jedoch fest an `claude/confident-heisenberg-uh75b4` gebunden (Umgebungs-
   Vorgabe: „NEVER push to a different branch"). Entwicklung daher dort, **nicht**
   nach `main`/`dev` gemergt. Isolations-Ziel (eigene Route, Produktion unberührt)
   ist erfüllt.
2. **v3-Tokens bereits gesetzt:** `src/styles/tokens.css` ist bereits vollständig
   v3-konform (Primary #334D7A, alle Rot/Grün/Gold/Mastery/Moment-Tokens,
   blau-getönte Schatten, Radii 6/10/14/20). Es gab **keine** veralteten Tokens
   (`#2D6A9F` o.ä.) zu überschreiben — der Abgleich war bereits erledigt. Light-
   Screens (Parent/Coach) bleiben unberührt. CSS-Einstieg ist `globals.css`
   (+ `tokens.css`), nicht `index.css` — dort wurde nichts geändert.
3. **Icons:** Der Auftrag nannte Tabler. Das Repo nutzt durchgängig `lucide-react`;
   für Konsistenz und um keine neue Dependency einzuführen (Guardrail §11), wurde
   `lucide-react` verwendet.
4. **Tests ohne Test-Runner:** Es gibt kein Vitest/Jest. Statt eine schwere
   Dependency einzuführen, laufen die Tests über Node's `node:test` via `tsx`
   (bereits vorhanden) — `npm run test:mock`. Null neue Dependencies.
5. **„Introduced"-Mastery-Farbe (laut Auftrag offen):** aufgelöst auf den
   bestehenden neutralen Token `--color-mastery-introduced` (#B8B8B4), konsistent
   mit `src/lib/mastery.ts`.
6. **Dynamische Prozent-Breiten** (XP-/Mastery-Bars) nutzen `style={{ width }}` —
   der einzige erlaubte Inline-Style-Fall (CLAUDE.md §11, „berechnete Prozente").
   Alle Farben laufen über Tokens; dynamische Token-Farben über statische
   Tailwind-Klassen-Maps (JIT-sicher), keine Hex/rgba in TSX.
7. **Restart = voller Reset** zum Hub, damit Rasit Level-Up und Boss beliebig oft
   wiederholt sehen kann (wiederholbarer Demo-Durchlauf).

## ⚠ Wichtig geflaggt: Antwort-Feedback (Screen 6) vs. CLAUDE.md §6

Der Review-Agent hat einen literalen Konflikt gefunden, der Rasits Aufmerksamkeit
verdient:

- **CLAUDE.md §6** (Abschnitt *Behavior-Tracking & Diagnosedaten*): „Kind-seitig:
  Niemals visuelles Feedback ob Antwort richtig/falsch."
- **Der Build-Auftrag (Screen 6)** verlangt dagegen explizit Sofort-Feedback:
  richtig = weiches Grün #27AE60, falsch = weiches Rot #E88080, „Schau nochmal hier".
- **Das Design-System v3** hat dafür **eigene Tokens**: `--color-success-answer`
  („Richtige Antwort") und `--color-error-answer` („Falsche Antwort (Student), ~2s,
  nicht demotivierend").

**Entscheidung (Auto-Modus):** Feedback wie im Auftrag spezifiziert umgesetzt.
Begründung: §6 steht im Kontext der **Diagnose-/Screening-Datenerhebung**
(BehaviorSnapshots) — dort soll das Kind sein Ergebnis nicht sehen, um die Rohdaten
nicht zu verfälschen. Die Vor-Ort-**Übungs**-Session ist ein anderer Kontext; das
v3-System hält dafür bewusst eigene Student-Feedback-Tokens vor, und der Build-
Auftrag fordert genau dieses Verhalten. Das verwendete „weiche Rot" ist der dafür
vorgesehene Token (kein harter Klassenarbeits-/Alert-Rot).
**Falls Rasit §6 strenger auslegen will**, lässt sich `FeedbackBar` auf eine rein
neutral-positive Variante reduzieren (eine Komponente, ein Ort).

## Geflaggt / am Rande behoben

- **Build-blockierender Syntaxfehler behoben** (`src/pages/student/TaskPlayer.tsx`):
  Zwei Ternary-Strings nutzten typografische Anführungszeichen (U+2018/U+2019) als
  Delimiter — ein verunglücktes Find-Replace auf diesem Branch. Das brach `tsc`
  **und** den esbuild/`vite build` für die ganze App. Minimal repariert
  (gerade Anführungszeichen, Anzeigetext unverändert) als eigener Commit, weil es
  den Mock-Build sonst blockiert hätte.
- **Pre-existing `tsc`-Fehler (out of scope):** `tsc -b` ist auf diesem Repo schon
  auf `dev` rot. Die verbleibenden Typfehler liegen ausschließlich in Dateien, die
  **identisch zu `dev`** sind (`src/lib/screening/*`, `tasks/TaskRenderer.tsx`,
  `lib/supabase/studentFocusAreas.ts`, `scripts/screening-sim.ts`). Sie sind
  Produktions-Code außerhalb dieses Auftrags (Guardrail §11) und wurden nicht
  angefasst. Die **neuen** Mock-Dateien sind `tsc`-sauber.

## Verifikation

- `npx vite build` → grün (App baut, inkl. JSXGraph-Aufgabe).
- `npm run test:mock` → 14/14 grün.
- Neue Dateien `tsc`-sauber (isoliert geprüft); keine Hex/rgba/`any` in TSX;
  alle 83 referenzierten i18n-Keys existieren in `de/mock.json`.
- Review-Agent-Audit gegen die 8 Hard Rules + Design-Regeln durchgeführt.

## Offene Punkte / später

- Übernahme in Produktion: Mock-Provider (`src/lib/mocks/session.ts`) durch echte
  Supabase-Queries ersetzen; Aufgaben über den echten SerloRenderer rendern.
- Kein Browser-Screenshot möglich (kein Headless-Driver in der Umgebung) —
  Verifikation über Build + Tests + Review statt visuell.
- Weitere Locales: Struktur (`de/mock.json`) steht, andere Sprachen optional leer.
