# Retro 2026-06-03 — v3 Midnight-Academy Reconciliation

## Kontext
Rasit übergab die verifizierte „Midnight Academy Design System Reference v1.0"
(Single Source of Truth, aus SharePoint). Zentraler Befund beim Audit:
**`src/styles/tokens.css` war bereits ~100% deckungsgleich mit der Spec** — die
v2-Migration (27.5.) wurde aus einem frühen Entwurf desselben Systems gebaut.
v3 ist daher **kein Rebuild**, sondern ein Reconciliation-Pass: die
*Implementierung* (Komponenten + globals.css-Utilities) an die jetzt verifizierte
Spec angleichen + eine Living-Reference-Seite.

## Entscheidungen (mit Rasit)
- Scope: Voll-Reconciliation (alle 5 Targets) + `/demo/v3` Showcase
- Genauigkeit: pragmatisch (klare Funktions-Abweichungen fixen, mikroskopische
  Zahlen-Drifts wo unsichtbar: lassen)
- Branch: `feature/v3-design-reconciliation` von `dev`

## Was gebaut wurde
1. **MasteryBar 4→5 Stufen** (`MasteryBar.tsx`): veraltetes 4-Tier-System
   (Lücke/Erkennbar/Sicher/Exzellent nach Level 1–10, falsche Farben) ersetzt
   durch die 5 Spec-Stufen (Introduced/Developing/Progressing/Proficient/Mastered).
   **API rückwärtskompatibel**: `level?: 1–10` bleibt (alle 6 Aufrufer übergeben
   das) und läuft durch `masteryStageFromLevel`. Neuer optionaler `score?: 0–100`
   hat Vorrang. Progressing nutzt den Spec-Track `--color-mastery-progressing-bg`.
2. **`lib/mastery.ts` erweitert**: `MASTERY_STAGE_COLOR` (Stage→CSS-Var),
   `MASTERY_STAGE_LABEL` (deutsch), `MASTERY_STAGES` (Reihenfolge) — Single Source,
   auch von der Demo-Seite genutzt. Schwellen-Logik NICHT dupliziert.
3. **Glas-Effekte** (`globals.css`): blur/opacity/border auf Spec
   (pill 12px/0.12, card 16px/0.10, button 8px/0.15, Border 0.5px); pill-Radius
   auf `--radius-xl`. `saturate()` als Enhancement behalten.
4. **Student-Gradienten** (`globals.css`): `.student-header`/`.student-hero` von
   Single-Linear auf die 3-Layer-Spec (2 Radial-Overlays + 145°/135° Linear,
   #3D5A8A→#334D7A→#263D6A/#243960). App-BG-Textur (2 zarte Midnight-Radials)
   auf `body`.
5. **Animations-Timing** (`globals.css`): flyIn 400ms/bounce, xpFloat 1200ms
   +Scale, countUp 500ms/bounce +Scale, barGrow 800ms/bounce +200ms Delay (`both`).
6. **`/demo/v3` Living Reference** (`pages/demo/v3/V3Showcase.tsx` + Route in
   `App.tsx`): Farben, Mastery 5 Stufen, Glas (nur auf dunkler Bühne, Hard Rule §3),
   XP/Streaks/Badges, Animationen mit Replay.

## Wichtige Erkenntnis (Blast-Radius)
Alle 6 MasteryBar-Aufrufer übergeben `level` 1–10 (Quelle: `parseScreeningResult`,
`displayLevel`). Hätte man die Prop auf Prozent umgestellt, wären alle still
gebrochen (Level 7 → 7% → grau). Deshalb API behalten + intern mappen.

## Verhaltensänderung (gewollt)
Bestehende Aufrufer (ScreeningResultsPage, ClusterGrid, Mock/Demo) zeigen jetzt die
5-Stufen-Farben statt des alten 4-Tier-Schemas — exakt das Ziel von Target #1.

## Out of Scope (Spec: „NOT YET DEFINED")
Typografie-Scale, Spacing-Grid, Badge-Namen/Trigger, XP-Werte, Level-Kurve,
Repair-Grant-Logik, Coins, Sound, Boss-Figur.

## Verifikation
- `npx tsc --noEmit` grün ✅
- `npx vite build` grün ✅ (nur bekannte Bundle-Size-Warnung, bestehender Tech-Debt)
- Visuell: `/demo/v3` rendert alle Sektionen; Mastery zeigt 5 Stufen korrekt.

## Offene Punkte / Folge
- Browser-Verifikation `/demo/v3` + bestehende MasteryBar-Surfaces durch Rasit
- Merge `feature/v3-design-reconciliation` → `dev` nach Sichtung
- Bundle-Code-Splitting (lazy routes) bleibt offener Tech-Debt
