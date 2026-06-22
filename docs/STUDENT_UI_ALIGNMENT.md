# Student-UI-Alignment — Audit vor dem Refactor

> Phase-A-Audit (read-only). Ziel: die echten Schüler-Surfaces
> (`/student`, `/student/cluster/:id`, `/student/task/:id`) auf das Look-and-Feel
> der Referenz `src/pages/mock/session/**` heben und das CSS so aufräumen, dass
> alle Werte aus `src/styles/tokens.css` fließen. **Datenbindung, Routen und Logik
> bleiben 1:1 — reine Präsentation.**
>
> Entscheidungen (mit Rasit abgestimmt): **volle Dark-Bühne** für alle drei
> Surfaces · reusable Mock-Komponenten **nach `src/components/student/` verschieben**
> und Mock-Imports umbiegen · Arbeit auf Branch `dev`, **nicht pushen**.

---

## 1. Inventar — Mock-Designsprache (`src/pages/mock/session/**`)

Durchgängig **dunkle „Midnight-Academy"-Bühne**. Baukasten aus `components/` + `screens/`.

### Bühne & Chrome
| Element | Klasse / Token | Quelle |
|---|---|---|
| Dunkle Bühne | `.session-stage` (Navy-Gradient + Top-/Horizont-Glow + Noise) | `session.css:8` |
| Sticky-Header | `.session-header` (blur 10px, `rgba(16,32,56,…)`) | `session.css:47` |
| Warme Typo | `.text-warm`, `.text-warm-72/56/42` | `session.css:55` |
| Shell-Wrapper | `SessionShell` (maxWidth sm/md/lg, `header`, `center`, `showExit`) | `components/SessionShell.tsx` |

### Hub / Übersicht
| Element | Klasse / Token |
|---|---|
| Glass-Kachel | `EdvanceCard variant="glass"` → `.glass-card` (dunkel-only) |
| Primär-CTA-Kachel | `.session-cta` (Gold-Kante + Glow) · `.session-icon-tile` (Gold-Icon) |
| Gedimmte Kachel | `.session-card-dimmed` (opacity 0.62) |
| Hub-Kachel-Komponente | `HubTile` (title/description/icon/onClick/emphasis/disabled) |
| Hover | `translateY(-3px)`, `--ease-bounce`, `--session-sh-lg` |

### Task-Bearbeitung
- `TaskStub` rendert MC / numeric / coordinate aus **eigenem** `SessionTask`-Format
  (Mock-spezifisch, **nicht** datenkompatibel zum echten TaskPlayer).
- Touch-Targets `min-h-[44px]`, `rounded-lg`, `active:scale-[0.98/0.99]`, 200 ms.
- `TaskScreen`: Progress-Counter `n / m`, AFB-Badge (`bg-white/10`), animierte XP-Bar.

### Mastery
- 5-Stufen-Optik in `components/masteryClasses.ts` → `STAGE_BG` / `STAGE_TEXT`
  (`bg-[var(--color-mastery-*)]`), Stufen `introduced → developing → progressing →
  proficient → mastered`.
- Quelle der Stufenlogik: `src/lib/mastery.ts` (`masteryStage`, `masteryStageFromLevel`,
  `MASTERY_STAGE_LABEL`). **Kommentar dort dokumentiert bereits Hard Rule §6**:
  „Mastered nur nach Coach-Bestätigung im Backend; diese Funktion unterscheidet rein farblich."
- `MasteryScreen` zeigt „Gemeistert" nur, wenn `coachGranted === true` (Gate vorhanden).

### Streak
- `WeekStreak` (`states: DayState[7]`, `popIndex?`) — 7 Kreise, `Flame`-Icon auf
  `--color-accent-streak`, `animate-count-up`.

### Feedback / Hints
| Komponente | Farben / Motion |
|---|---|
| `FeedbackBar` (`result`, `xp?`) | correct → `--color-success-answer(-light)`; wrong → `--color-error-answer(-light)`; `animate-fly-in`, XP `animate-xp-float` |
| `HintPanel` (`hints`, `revealed`, `onReveal`, `onClose`) | `--color-primary-light` Panel, weiße Hint-Items, „kein XP-Abzug"; `animate-fly-in` |

### Buttons / Motion-Tokens
- `SessionButton` (`variant: primary | ghost`, `block`, `icon`) — primary = weiße Fläche
  + `text-[var(--color-primary)]` + `shadow-lg`; ghost = `.glass-button`.
- Motion: `--ease-bounce` (`cubic-bezier(.34,1.56,.64,1)`), `--ease-out`,
  `--duration-base` (200 ms). Keyframes alle in `globals.css:250–299`.

---

## 2. Inventar — Zielseiten heute (`src/pages/student/**`)

| Datei | Optik heute | Route |
|---|---|---|
| `StudentDashboard.tsx` | **Hell** `bg-[var(--color-bg-app)]`, `EdvanceNavbar`, `StudentHero` + `ClusterGrid` | `/student` |
| `StudentHero.tsx` | **Schon dunkel**: `.student-hero` + `.light-source`, Glass-`EdvanceCard` mit `XPBar`, 2× `StreakPill` | (Teil von `/student`) |
| `ClusterGrid.tsx` | **Hell**: weiße Cards (`bg-[var(--color-bg-surface)] shadow-xs`), Blob-Hover, `MasteryBar`, `EdvanceBadge` | (Teil von `/student`) |
| `ClusterView.tsx` | **Hell** `bg-background`, 3 Sektionen (Erklären/Üben/Test), Task-Listen-Rows | `/student/cluster/:clusterId` |
| `TaskPlayer.tsx` | **Hell** `bg-background`, weiße `EdvanceCard` mit `MathContent`/Widgets, Hint-Button, Submit-Bestätigung | `/student/task/:taskId` |
| `TaskPlayerBlocks.tsx` | TypeBadge/DifficultyBadge/VideoBlock (nutzt `color-mix` mit Tokens) | — |
| `StudentDashboardFilters.tsx` | Helle Such-/Filter-Pills (`id="lernpfad"`) — **aktuell nicht in Dashboard eingebunden** | — |
| `TaskWidgetDemo.tsx` | Dev-Demo `/demo/widgets` — **out of scope** | `/demo/widgets` |

### Datenbindung (muss 1:1 erhalten bleiben)
- **StudentDashboard**: `useAuth` → `getStudentByProfile` → `getStudentProgress` +
  `getClustersForStudent`; Load-State-Machine `loading|no-profile|error|ready`; Cleanup im `useEffect`.
- **ClusterView**: `useParams` → `getStudentByProfile` → `getCompletedTaskIds`
  (`ProgressMap`) → parallel `getClusterById` + `getTasksByClusterOrdered`; Gruppierung
  nach `content_type`, Sortierung Typ→Difficulty.
- **TaskPlayer**: `useParams` → `getTaskById` → `getClusterById` →
  `getTasksByClusterOrdered` (Geschwister); `useBehaviorTracker` (Telemetrie);
  RPC `completeTask` (Server berechnet XP, idempotent); `persistBehaviorSnapshot`;
  Dedup via `startedTaskRef` / `completedRef`.

### Mastery heute
- Nur in `ClusterGrid`: `clusterStatusById` (aus `lib/screening/recommendation.ts`,
  Screening-abgeleitet) → `STATUS_VARIANT` mappt **`Sicher → 'mastered'`** Badge +
  `MasteryBar level={status.displayLevel}`. **Kein Backend-Coach-Confirm-Feld** an den
  Pages. → **Verstoß-Risiko gegen Hard Rule §6** (s. §6 unten).

---

## 3. Divergenz-Liste (Ziel ≠ Referenz)

| Aspekt | Zielseiten heute | Referenz (Mock) | Maßnahme |
|---|---|---|---|
| Hintergrund | Hell `--color-bg-app` / `bg-background` | Dunkle `.session-stage` | Bühne übernehmen (alle 3 Surfaces) |
| Cards | Weiß `shadow-xs` | Glass-Karten (dunkel-only) | Chrome → Glass; **dichter Inhalt → solide Surface-Card** (lesbar) |
| Hub-Kacheln | Weiße Cluster-Cards | `HubTile`/`session-cta` | `HubTile`-Optik anwenden |
| Skill-/Cluster-Ansicht | Flache Listen-Rows | `SkillTree` (Marker + Linien) | Verbundene Reihen-Optik, Marker aus Completion |
| Task-Screen | Weiße Card + Hint-Button | Progress/AFB/XP-Top, `FeedbackBar`, `HintPanel` | Mock-Layout um echte Widgets legen |
| Feedback | Inline-Bestätigung | `FeedbackBar` (positiv/neutral) | `FeedbackBar` anwenden, **kein Rot für falsch** |
| Motion | `duration-300/500` generisch | `--ease-bounce` 200 ms, `animate-fly-in/count-up` | Motion-Tokens angleichen |
| Mastery-Optik | `Sicher → mastered`-Badge | 5-Stufen + Coach-Gate | Cap auf `proficient` ohne Confirm |

---

## 4. CSS-Hygiene — hardcodierte Werte zum Tokenisieren

> Die Student-**Pages** selbst sind bereits hex-frei (durchweg `var(--…)` + `color-mix`).
> Alle harten Farbliterale stecken in den **Styles**:

### `globals.css`
| Zeile | Wert | Kontext |
|---|---|---|
| 158 | `rgba(51, 30, 100, 0.25)` | `.student-header` Indigo-Tiefe-Radial |
| 159 | `#3D5A8A`, `#334D7A`, `#263D6A` | `.student-header` Linear-Gradient-Stops |
| 165 | `rgba(20, 10, 60, 0.30)` | `.student-hero` Indigo-Tiefe-Radial |
| 166 | `#3D5A8A`, `#334D7A`, `#243960` | `.student-hero` Linear-Gradient-Stops |
| 322–323 | `rgba(51, 77, 122, 0.04/0.03)` | Body-Radials (= `--color-primary`-Tint) |

### `session.css`
| Zeile | Wert | Kontext |
|---|---|---|
| 10–12 | `#2E3E63` / `#1E2B49` / `#14213D` | `--bg-top/mid/bottom` (Bühnen-Navy) |
| 14 | `#F7F5EE` | `--session-text` (warmes Off-White) |
| 27 | `rgba(232, 160, 32, …)` | Top-Glow = `--color-accent`-Tint |
| 29 | `rgba(214, 118, 42, …)` | Horizont-Glow (eigene Farbe) |
| 48 | `rgba(16, 32, 56, …)` | `.session-header`-Gradient (= `--color-navy-deep`-Tint) |
| 79, 83, 86 | `rgba(232, 160, 32, …)` | `.session-cta`-Glow = `--color-accent`-Tint |
| 81, 82, 92, 94 | `rgba(232, 168, 67, …)` / `rgba(255, 242, 214, …)` | Gold-Kanten/Tile |
| 66 | `transition … 0.2s ease` | hartes `ease` statt `var(--ease-out)` |

**Plan (Phase C):** neue Token-Gruppe **BÜHNE/STAGE** in `tokens.css`
(`--color-stage-top/mid/bottom`, `--color-stage-text`, `--color-stage-hero-top`
(#3D5A8A), `--color-stage-hero-bottom` (#243960), `--color-stage-header-bottom`
(#263D6A), `--color-stage-glow-horizon` (#D6762A), `--color-stage-gold-edge` (#E8A867)).
Amber-Glows aus `--color-accent` via `color-mix(in srgb, var(--color-accent) X%, transparent)`.
Mid-Stop = `var(--color-primary)`. **Werte exakt erhalten → keine Optik-Änderung.**
Reine Weiß-/Schwarz-Alpha (Glass-Material, Light-Source, Noise) bleibt inline — das ist
Material-Opazität auf Neutral, keine Palettenfarbe (so behandelt der Code Glass bereits).

---

## 5. Tote CSS

Gezielter Usage-Sweep über `src/**/*.{ts,tsx}` für alle Kandidaten
(`glass-pill`, `session-cta`, `session-icon-tile`, `session-card-dimmed`, `hover-lift`,
`text-display`, `text-eyebrow`, `mastery-bar-fill`, `light-source`, `student-hero`,
`student-header`, alle `animate-*`, `toast-*`):

**Ergebnis: keine vollständig toten Selektoren gefunden.** Alle werden referenziert —
u.a. `.student-header` von `demo/v2|v3`, Glass/Toast/Animate von `components/edvance/**`,
die `.session-*`-Klassen vom Mock. → **Der Cleanup ist Tokenisierung, keine Löschung.**
Etwaige Einzel-Löschungen in Phase C werden vor Entfernung pro Selektor verifiziert;
erwartete Anzahl entfernter toter Selektoren ≈ 0.

---

## 6. FernUSG / Hard Rule §6 — Mastery-Guard

**Problem:** `ClusterGrid` zeigt `Sicher → 'mastered'` (dunkelgrünes „Mastered"-Badge),
abgeleitet rein aus Screening (`displayLevel`) — **ohne Backend-Coach-Bestätigung**.
Das nimmt den Mastered-Zustand visuell vorweg (Verstoß).

**Lösung (Presentation-only, keine Datenänderung):**
- Neuer Helper `displayMasteryStage(stage, { coachConfirmed })` (in der verschobenen
  `masteryClasses.ts`): deckelt `mastered → proficient`, solange `coachConfirmed` nicht
  truthy. Schwellen-Zustand = „in Session bestätigen", flippt nicht selbst.
- `ClusterGrid`: `STATUS_VARIANT` so anpassen, dass `Sicher` **nicht** triumphal als
  „Mastered" rendert (proficient-Grün, neutrales Label). `ClusterStatus`/Screening-Logik
  unverändert — nur das visuelle Mapping.
- `lib/mastery.ts` bleibt unverändert (Logik dort ist schon „rein farblich" dokumentiert).

> Hinweis: Migration `040_competency_mastery.sql` (Parallel-Fenster, Commit `ba801f6`)
> führt backend-seitig eine Mastery-Gate ein. Diese Pages binden sie noch **nicht** an
> (Supabase-Calls bleiben unverändert) → `coachConfirmed` ist hier effektiv immer false,
> d.h. FernUSG-sicher per Default.

---

## 7. Extraktions-Plan — Mock → geteilte, datenfähige Komponenten

Ziel-Pfad `src/components/student/**` (Student-Design-Sprache **isoliert**, kein Leak in
`src/components/edvance/**`, das Parent/Coach teilen). Verschieben aus
`src/pages/mock/session/components/`, Mock-Screen-Imports umbiegen, Barrel `index.ts`.

| Quelle | Ziel | Props (datenfähig) | Anpassung |
|---|---|---|---|
| `SessionShell.tsx` | `StudentStage.tsx` | `children`, `header?`, `center?`, `maxWidth?`, `exitTo?`, `exitLabel?` | von `useTranslation('mock')` + hartem `/mock`-Exit entkoppeln |
| `HubTile.tsx` | `HubTile.tsx` | `title`, `description`, `icon`, `onClick?`, `emphasis?`, `disabled?` | unverändert |
| `SkillTree.tsx` | `SkillTree.tsx` | `nodes`, `onSelect` | mit Completion-Status speisen (done/open/locked) |
| `WeekStreak.tsx` | `WeekStreak.tsx` | `states`, `popIndex?` | unverändert; nur bei echten 7-Tage-Daten |
| `FeedbackBar.tsx` | `FeedbackBar.tsx` | `result`, `xp?` | unverändert |
| `HintPanel.tsx` | `HintPanel.tsx` | `hints`, `revealed`, `onReveal`, `onClose` | unverändert |
| `SessionButton.tsx` | `StudentButton.tsx` | `variant`, `block?`, `icon?`, … | unverändert |
| `masteryClasses.ts` | `masteryClasses.ts` | `STAGE_BG`/`STAGE_TEXT` + **neu** `displayMasteryStage()` | FernUSG-Cap ergänzen |

**Nicht extrahiert / mock-spezifisch:** `TaskStub.tsx`, `taskEval.ts(.test)` —
eigenes `SessionTask`-Format, nicht datenkompatibel. Der echte `TaskPlayer` behält seine
realen Widgets (`MathContent`, `TaskAnswerArea`, MC/Steps/…); übernommen wird nur das
**Screen-Layout** (Progress/AFB/XP-Top + `FeedbackBar` + `HintPanel`-Look).

### Anwendung auf die Zielseiten
- **StudentDashboard + StudentHero + ClusterGrid** → Hub-/Übersichts-Optik (`StudentStage`,
  `HubTile`-Kacheln, Glass-Hero).
- **ClusterView** → `SkillTree`-/verbundene-Reihen-Optik, Marker aus `getCompletedTaskIds`.
- **TaskPlayer + TaskPlayerBlocks** → Task-Screen-Optik inkl. `FeedbackBar` + `HintPanel`,
  dichter Inhalt auf solider Surface-Card.

---

## 8. Leitprinzip & Safeguards

- Design-Sprache **extrahieren & anwenden** — **nicht** den gescripteten Mock-Flow in die
  echten Routen kopieren. Seiten bleiben routen-/datengebunden.
- **Lesbarkeit:** dunkle Bühne = Backdrop + Chrome (Glass). Dichter Lerninhalt
  (KaTeX/`MathContent`, Artikel, Aufgabentext) → **solide helle Surface-Card** auf der
  Bühne. **Kein Glass auf Weiß** (Hard Rule §3).
- Keine hardcodierten Hex außerhalb `tokens.css`. Shadows blau-getönt. Radii aus Tokens.
- Student-Stil ausschließlich in `src/components/student/**` → kein Leak nach Parent/Coach.
- Keine Casino-/Ranking-/Vergleichs-Mechanik.
