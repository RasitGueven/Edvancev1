import { useEffect } from 'react'
import { ChevronLeft, ChevronRight } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { dieseWoche, kalenderwoche, wocheVerschieben, wochenSpanne } from './wochenNavigation.model'

/** Tasten gehören dem Eingabefeld, dem Dialog oder der Reiterleiste, nicht der Woche. */
function tasteGehoertAnderen(e: KeyboardEvent): boolean {
  if (e.defaultPrevented || e.altKey || e.ctrlKey || e.metaKey || e.shiftKey) return true
  const ziel = e.target instanceof HTMLElement ? e.target : null
  if (ziel && (ziel.isContentEditable || ziel.closest('input, textarea, select, [role="tablist"], [role="dialog"]'))) return true
  return document.querySelector('[role="dialog"][aria-modal="true"]') !== null
}

/**
 * Wochen blättern: "‹", Kalenderwoche mit Spanne, "›", "Diese Woche". Pfeiltasten links und rechts
 * blättern, solange kein Eingabefeld und kein Dialog den Fokus hat. Montag als ISO-Tag rein und raus (Berlin).
 */
export function WochenNavigation({
  montag,
  onWechsel,
  pfeiltasten = true,
}: {
  montag: string
  onWechsel: (montag: string) => void
  pfeiltasten?: boolean
}): JSX.Element {
  const { t, i18n } = useTranslation('common')
  const jetzt = dieseWoche()
  const istDieseWoche = wocheVerschieben(montag, 0) === jetzt

  useEffect(() => {
    if (!pfeiltasten) return undefined
    const taste = (e: KeyboardEvent): void => {
      if (e.key !== 'ArrowLeft' && e.key !== 'ArrowRight') return
      if (tasteGehoertAnderen(e)) return
      e.preventDefault()
      onWechsel(wocheVerschieben(montag, e.key === 'ArrowLeft' ? -1 : 1))
    }
    window.addEventListener('keydown', taste)
    return () => window.removeEventListener('keydown', taste)
  }, [montag, onWechsel, pfeiltasten])

  const knopf =
    'inline-flex h-11 w-11 items-center justify-center rounded-[var(--radius-md)] text-[var(--color-text-secondary)] transition-colors hover:bg-[var(--color-bg-subtle)] hover:text-[var(--color-primary)]'

  return (
    <div role="group" aria-label={t('wochenNavigation.label')} className="flex flex-wrap items-center gap-2">
      <button type="button" className={knopf} aria-label={t('wochenNavigation.vorige')} onClick={() => onWechsel(wocheVerschieben(montag, -1))}>
        <ChevronLeft aria-hidden="true" className="h-5 w-5" />
      </button>
      <span aria-live="polite" className="text-sm font-semibold tabular-nums text-[var(--color-text-primary)]">
        {t('wochenNavigation.kwSpanne', { kw: kalenderwoche(montag), spanne: wochenSpanne(montag, i18n.language) })}
      </span>
      <button type="button" className={knopf} aria-label={t('wochenNavigation.naechste')} onClick={() => onWechsel(wocheVerschieben(montag, 1))}>
        <ChevronRight aria-hidden="true" className="h-5 w-5" />
      </button>
      <button
        type="button"
        aria-current={istDieseWoche ? 'date' : undefined}
        onClick={() => onWechsel(jetzt)}
        className={`inline-flex min-h-[44px] items-center rounded-[var(--radius-md)] px-3 text-sm font-semibold transition-colors ${
          istDieseWoche
            ? 'text-[var(--color-text-tertiary)]'
            : 'text-[var(--color-primary)] hover:bg-[var(--color-primary-light)]'
        }`}
      >
        {t('wochenNavigation.dieseWoche')}
      </button>
    </div>
  )
}
