import { masteryStageFromLevel, type MasteryStage } from '@/lib/mastery'

/**
 * Mastery-Stufe → statische Token-Klassen (JIT-sicher, kein Inline-Style).
 * Geteilte Ebene für Schüler-Surfaces: Skill-Tree (Mock), Mastery-Moment (Mock)
 * und die echten Cluster-Karten teilen dieselben Farben (alle aus tokens.css).
 */
export const STAGE_BG: Record<MasteryStage, string> = {
  introduced: 'bg-[var(--color-mastery-introduced)]',
  developing: 'bg-[var(--color-mastery-developing)]',
  progressing: 'bg-[var(--color-mastery-progressing)]',
  proficient: 'bg-[var(--color-mastery-proficient)]',
  mastered: 'bg-[var(--color-mastery-mastered)]',
}

export const STAGE_TEXT: Record<MasteryStage, string> = {
  introduced: 'text-[var(--color-mastery-introduced)]',
  developing: 'text-[var(--color-mastery-developing)]',
  progressing: 'text-[var(--color-mastery-progressing)]',
  proficient: 'text-[var(--color-mastery-proficient)]',
  mastered: 'text-[var(--color-mastery-mastered)]',
}

/**
 * FernUSG / Hard Rule §6: „Mastered" darf nie aus dem Score/Screening selbst
 * entstehen — nur eine Coach-Bestätigung im Backend gewährt es. Ohne bestätigtes
 * `coachConfirmed` wird die oberste Stufe auf „proficient" gedeckelt (Schwellen-
 * Zustand = „in der Session zu bestätigen", die Optik nimmt nichts vorweg).
 * Spiegelt `displayStage` aus der Mock-Zustandsmaschine — bewusst presentation-only.
 */
export function displayMasteryStage(
  stage: MasteryStage,
  opts?: { coachConfirmed?: boolean },
): MasteryStage {
  if (stage === 'mastered' && !opts?.coachConfirmed) return 'proficient'
  return stage
}

/**
 * Screening-`displayLevel` (1–10) → angezeigte Mastery-Stufe, FernUSG-gedeckelt.
 * Reine Darstellungs-Ableitung; die Screening-Logik selbst bleibt unangetastet.
 */
export function masteryStageForLevel(
  level: number,
  opts?: { coachConfirmed?: boolean },
): MasteryStage {
  return displayMasteryStage(masteryStageFromLevel(level), opts)
}
