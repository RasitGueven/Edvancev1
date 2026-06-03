/**
 * Mastery-5-Stufen-Mapping (Frontend-Seitig).
 * Backend-Schema bleibt `level: 1..10` — diese Funktion bündelt die
 * Visualisierungs-Logik an einer Stelle (Hard Rule DESIGN_SYSTEM.md §6:
 * Mastered nur nach Coach-Bestätigung im Backend; diese Funktion
 * unterscheidet rein farblich).
 */

export type MasteryStage =
  | 'introduced'
  | 'developing'
  | 'progressing'
  | 'proficient'
  | 'mastered'

export function masteryStage(score: number): MasteryStage {
  if (score >= 85) return 'mastered'
  if (score >= 75) return 'proficient'
  if (score >= 60) return 'progressing'
  if (score >= 40) return 'developing'
  return 'introduced'
}

export function masteryStageFromLevel(level: number): MasteryStage {
  return masteryStage(level * 10)
}

/**
 * Stage → CSS-Variable (Token aus tokens.css, nie hardcodierte Farbe).
 * Reihenfolge & Farben gemäß Midnight-Academy-Spec §03.
 */
export const MASTERY_STAGE_COLOR: Record<MasteryStage, string> = {
  introduced: 'var(--color-mastery-introduced)',
  developing: 'var(--color-mastery-developing)',
  progressing: 'var(--color-mastery-progressing)',
  proficient: 'var(--color-mastery-proficient)',
  mastered: 'var(--color-mastery-mastered)',
}

/** Stage → deutsches Label (lokale Konvention: hart-deutsch wie StreakPill). */
export const MASTERY_STAGE_LABEL: Record<MasteryStage, string> = {
  introduced: 'Eingeführt',
  developing: 'In Entwicklung',
  progressing: 'Fortschritt',
  proficient: 'Sicher',
  mastered: 'Gemeistert',
}

/** Reihenfolge introduced → mastered (für Showcase/Iteration). */
export const MASTERY_STAGES: MasteryStage[] = [
  'introduced',
  'developing',
  'progressing',
  'proficient',
  'mastered',
]
