import type { MasteryStage } from '@/lib/mastery'

/**
 * Mastery-Stufe → statische Token-Klassen (JIT-sicher, kein Inline-Style).
 * Zentral, damit Skill-Tree, Mastery-Moment und Detail dieselben Farben teilen.
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
