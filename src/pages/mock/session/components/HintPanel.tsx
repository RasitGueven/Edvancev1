import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Lightbulb } from 'lucide-react'

interface HintPanelProps {
  hints: string[]
  /** Anzahl bereits aufgedeckter Hinweise (aus dem Session-State). */
  revealed: number
  onReveal: () => void
  onClose: () => void
}

/**
 * KI-Hint als eingleitendes Panel (Screen 5) — kein Vollbild, die Aufgabe
 * bleibt sichtbar. Info-Blau auf hellem Info-Surface. Gestuft: erst
 * Denkanstoß, dann konkreter — nie die fertige Lösung. Kein XP-Abzug.
 */
export function HintPanel({ hints, revealed, onReveal, onClose }: HintPanelProps): JSX.Element {
  const { t } = useTranslation('mock')
  const shown = Math.min(revealed, hints.length)
  const hasMore = shown < hints.length

  return (
    <div
      className="animate-fly-in rounded-[var(--radius-lg)] bg-[var(--color-primary-light)] p-5 shadow-lg"
      role="region"
      aria-label={t('session.hint.title')}
    >
      <div className="flex items-center gap-2 text-[var(--color-primary)]">
        <Lightbulb className="h-5 w-5" aria-hidden="true" />
        <h3 className="text-base font-semibold">{t('session.hint.title')}</h3>
        <span className="ml-auto text-xs font-semibold text-[var(--color-text-tertiary)]">
          {t('session.hint.stepLabel', { current: shown, total: hints.length })}
        </span>
      </div>

      <ol className="mt-3 flex flex-col gap-2">
        {hints.slice(0, shown).map((hint, i) => (
          <li
            key={i}
            className="rounded-[var(--radius-md)] bg-[var(--color-bg-surface)] px-4 py-3 text-sm leading-relaxed text-[var(--color-text-secondary)]"
          >
            {hint}
          </li>
        ))}
      </ol>

      <p className="mt-3 text-xs text-[var(--color-text-tertiary)]">
        {t('session.hint.noXpLoss')}
      </p>

      <div className="mt-4 flex flex-wrap gap-2">
        {hasMore ? (
          <button
            type="button"
            onClick={onReveal}
            className="min-h-[44px] rounded-[var(--radius-md)] bg-[var(--color-primary)] px-5 text-sm font-semibold text-[var(--color-bg-surface)] hover:bg-[var(--color-primary-hover)]"
          >
            {t('session.hint.more')}
          </button>
        ) : null}
        <button
          type="button"
          onClick={onClose}
          className="min-h-[44px] rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-5 text-sm font-semibold text-[var(--color-text-secondary)] hover:border-[var(--color-text-tertiary)]"
        >
          {t('session.hint.done')}
        </button>
      </div>
    </div>
  )
}
