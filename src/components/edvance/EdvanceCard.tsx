import type { ReactNode } from 'react'
import { cn } from '@/lib/utils'

/**
 * EdvanceCard-Varianten — v2 + Backwards-Compat-Aliase.
 *
 * Neue Aufrufe sollten die semantischen v2-Namen verwenden:
 * - `default`         Standard Card (Surface + Border)
 * - `subtle`          Hintergrund-Subtle (für Section-Hintergründe)
 * - `hero-student`    dunkler Verlauf + Light-Source (NUR Schüler-Hero)
 * - `hero-parent`     flach, kein Verlauf (Eltern-Hero)
 *
 * Legacy-Aliase (bleiben aus BC, neue Pages sollen v2 nutzen):
 * - `raised` / `premium` → wie `default` mit etwas mehr Schatten
 * - `navy` / `hero` / `glass` → wie `hero-student`
 * - `blue-pale` → `subtle` mit Primary-Light Tint
 */
export type EdvanceCardVariant =
  | 'default'
  | 'subtle'
  | 'hero-student'
  | 'hero-parent'
  | 'raised'
  | 'navy'
  | 'blue-pale'
  | 'hero'
  | 'glass'
  | 'premium'

/**
 * Accent-Streifen — v2-Set (semantische Status-Kontexte) + Legacy-Aliase.
 */
export type EdvanceCardAccent =
  | 'none'
  | 'primary'
  | 'gap'
  | 'exam'
  | 'answer-wrong'
  | 'streak-lost'
  | 'coach-emergency'
  | 'strength'
  | 'answer-right'
  | 'mastered'
  | 'skilltree'
  /* Legacy */
  | 'left-primary'
  | 'left-success'
  | 'left-warning'
  | 'left-destructive'

interface EdvanceCardProps {
  children: ReactNode
  variant?: EdvanceCardVariant
  accent?: EdvanceCardAccent
  className?: string
  onClick?: () => void
}

const VARIANT_STYLES: Record<EdvanceCardVariant, string> = {
  default:        'bg-[var(--color-bg-surface)] border border-[var(--color-border)] shadow-xs rounded-[var(--radius-lg)] p-6',
  subtle:         'bg-[var(--color-bg-subtle)] border border-[var(--color-border)] rounded-[var(--radius-lg)] p-6',
  'hero-student': 'student-hero light-source text-white border-0 rounded-[var(--radius-xl)] p-6 shadow-xl',
  'hero-parent':  'bg-[var(--color-bg-surface)] border border-[var(--color-border)] rounded-[var(--radius-xl)] p-6 shadow-md',
  /* Legacy-Aliase */
  raised:         'bg-[var(--color-bg-surface)] border border-[var(--color-border)] shadow-md rounded-[var(--radius-lg)] p-6',
  premium:        'bg-[var(--color-bg-surface)] border border-[var(--color-border)] shadow-md rounded-[var(--radius-lg)] p-6',
  navy:           'student-hero light-source text-white border-0 rounded-[var(--radius-xl)] p-6 shadow-xl',
  hero:           'student-hero light-source text-white border-0 rounded-[var(--radius-xl)] p-6 shadow-xl',
  glass:          'glass-card shadow-md rounded-[var(--radius-lg)] p-6',
  'blue-pale':    'bg-[var(--color-primary-light)] border border-[var(--color-primary-light)] rounded-[var(--radius-lg)] p-6',
}

const ACCENT_STYLES: Record<EdvanceCardAccent, string> = {
  none:              '',
  primary:           'border-l-4 border-l-[var(--color-primary)]',
  gap:               'border-l-4 border-l-[var(--color-error-gap)]',
  exam:              'border-l-4 border-l-[var(--color-error-exam)]',
  'answer-wrong':    'border-l-4 border-l-[var(--color-error-answer)]',
  'streak-lost':     'border-l-4 border-l-[var(--color-error-streak)]',
  'coach-emergency': 'border-l-4 border-l-[var(--color-error-coach)]',
  strength:          'border-l-4 border-l-[var(--color-success-eltern)]',
  'answer-right':    'border-l-4 border-l-[var(--color-success-answer)]',
  mastered:          'border-l-4 border-l-[var(--color-mastery-mastered)]',
  skilltree:         'border-l-4 border-l-[var(--color-success-skilltree)]',
  /* Legacy */
  'left-primary':     'border-l-4 border-l-[var(--color-primary)]',
  'left-success':     'border-l-4 border-l-[var(--color-success)]',
  'left-warning':     'border-l-4 border-l-[var(--color-gold-warning)]',
  'left-destructive': 'border-l-4 border-l-[var(--color-error-exam)]',
}

export function EdvanceCard({
  children,
  variant = 'default',
  accent = 'none',
  className,
  onClick,
}: EdvanceCardProps) {
  const isInteractive = !!onClick
  const isDark = variant === 'hero-student' || variant === 'navy' || variant === 'hero'

  return (
    <div
      className={cn(
        VARIANT_STYLES[variant],
        ACCENT_STYLES[accent],
        !isDark && 'transition-shadow duration-200 hover:shadow-md',
        isInteractive && 'cursor-pointer hover-lift',
        className,
      )}
      onClick={onClick}
    >
      {children}
    </div>
  )
}
