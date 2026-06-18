import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check, Eye } from 'lucide-react'
import { cn } from '@/lib/utils'

interface FeedbackBarProps {
  result: 'correct' | 'wrong'
  /** Bei korrekter Antwort: verdiente XP (XP-Tick). */
  xp?: number
}

/**
 * Antwort-Feedback (Screen 6) im Task-Screen.
 *  - richtig: weiches Grün, kurze Bestätigung, XP-Tick (countUp/float)
 *  - falsch:  weiches Rot, nicht demotivierend, kein „Falsch!"-Hammer
 * Beides helle, semantische Surfaces (Tokens) auf der dunklen Bühne.
 */
export function FeedbackBar({ result, xp }: FeedbackBarProps): JSX.Element {
  const { t } = useTranslation('mock')
  const correct = result === 'correct'

  return (
    <div
      role="status"
      aria-live="polite"
      className={cn(
        'animate-fly-in flex items-center gap-3 rounded-[var(--radius-lg)] p-4',
        correct
          ? 'bg-[var(--color-success-answer-light)]'
          : 'bg-[var(--color-error-answer-light)]',
      )}
    >
      <span
        className={cn(
          'flex h-9 w-9 shrink-0 items-center justify-center rounded-[var(--radius-full)]',
          correct ? 'bg-[var(--color-success-answer)]' : 'bg-[var(--color-error-answer)]',
        )}
      >
        {correct ? (
          <Check className="h-5 w-5 text-[var(--color-bg-surface)]" aria-hidden="true" />
        ) : (
          <Eye className="h-5 w-5 text-[var(--color-bg-surface)]" aria-hidden="true" />
        )}
      </span>

      <div className="min-w-0 flex-1">
        <p
          className={cn(
            'text-sm font-semibold',
            correct ? 'text-[var(--color-success-answer)]' : 'text-[var(--color-error-answer)]',
          )}
        >
          {correct ? t('session.feedback.correctTitle') : t('session.feedback.wrongTitle')}
        </p>
        <p className="text-sm text-[var(--color-text-secondary)]">
          {correct ? t('session.feedback.correctBody') : t('session.feedback.wrongBody')}
        </p>
      </div>

      {correct && typeof xp === 'number' && (
        <span className="animate-xp-float text-base font-bold text-[var(--color-gold-warning)]">
          {t('session.feedback.xpEarned', { xp })}
        </span>
      )}
    </div>
  )
}
