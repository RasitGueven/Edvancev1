# Retro 2026-05-17 — Farbsystem-Feinschliff (Level-Up Premium-Türkis)

Branch: `feature/levelup-tuerkis` (von `dev`).

## Was gebaut wurde

Aus dem Design-Workshop: Level-Up ist ein **Meilenstein** und bekommt eine
eigene Premium-**Türkis**-Identität — abgesetzt von Alltags-XP (Gold),
Task/Boss-Erfolg (Grün) und Streak-Verlust (Rot). Zusätzlich Token für
**Streak-Repair** (Lila „Power-up"), Gold vereinheitlicht, Tiefe via
Gradient+Glow statt flachem Fill.

**P1 — Tokens (`src/styles/tokens.css`, `globals.css`)**
- `--color-levelup #0E9E96` (UI/Badge), `--color-moment-levelup #19C9BC`
  (leuchtend auf Navy), `--color-levelup-on #04302D` (Text-On, WCAG)
- `--gradient-levelup` (1FD3C6→0B8B85), `--shadow-glow-levelup`
- `--color-moment-repair #8B5CF6` + `-on #FFFFFF`, `--gradient-repair`
- `--color-accent-light #FBEAD0` (Accent/XP-Badge-BG)
- Legacy auf Single Source umgebogen: `--xp-gold`→`var(--color-accent)`,
  `--xp-gold-light`→`var(--color-accent-light)`,
  `--level-purple`→`var(--color-moment-repair)`
- `@theme inline`-Mapping + Utilities `.bg-gradient-levelup`,
  `.bg-gradient-repair`, `.shadow-glow-levelup`

**P2 — Consumer**
- `ScenarioCelebration`: Level-Badge → `--gradient-levelup` +
  `--shadow-glow-levelup` auf Navy (Tiefe)
- `EdvanceBadge`: Varianten `levelup` (Türkis) + `repair` (Lila)
- `ToastBanner`: Typ `levelup` (`.toast-levelup` Türkis-Gradient)
- `XPBar`: nutzt durch P1 automatisch das vereinheitlichte Gold

**P3 — Sichtbarkeit/Doku**
- `DesignShowcase`: neue Gruppe „Emotionale Momente" (Level-Up,
  Moment-Levelup, Repair, Boss-Grün, Streak-Rot, Moment-Bühne);
  Gamification-Gruppe zeigt vereinheitlichtes Gold
- `/demo/design` Level-Up-Tab zeigt Türkis (via ScenarioCelebration)

## Moment-Mapping (Single Source: tokens.css)

| Moment | Token | Farbe |
|---|---|---|
| Alltags-XP / Badges | `--color-accent` (=`--xp-gold`) | Gold `#E8A020` |
| Level-Up (Meilenstein) | `--color-levelup` / `--color-moment-levelup` + `--gradient-levelup` | Türkis |
| Task-/Boss-Erfolg | `--color-moment-green` auf `--color-moment-bg` | Grün/Navy |
| Streak-Verlust | `--color-moment-red` | Rot |
| Streak-Repair | `--color-moment-repair` | Lila |

## Offene Punkte / Risiken

- Türkis-/Repair-Hexwerte sind kalibrierte Vorschläge → final visuell +
  WCAG-AA prüfen (`/showcase`, `/demo/design`); Nachjustierung nur an
  einer Stelle (`tokens.css`).
- `--xp-gold` minimal verschoben (#F59E0B→#E8A020, gewollt: Konsistenz).
- Vollständige Streak-Repair- und Boss-Gradient-Flows sind nur token-/
  badge-/toast-seitig vorbereitet — UI-Flows = separater Schritt.
- Branch noch nicht in `dev`/`main` (Merge nur auf ausdrückliche Freigabe).
