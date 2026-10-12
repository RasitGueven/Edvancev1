import { useTranslation } from 'react-i18next'
import { fachKuerzel } from './slotsFormat'

/**
 * "Kl. 8" und das Fach-Kürzel als neutraler Chip (Entscheidung 28: Fächer bekommen keine Farbe).
 * Der volle Fachname steht für Screenreader und beim Darüberfahren.
 */
export function KlasseFach({ klasse, fach }: { klasse: number | null; fach: string | null }): JSX.Element {
  const { t } = useTranslation('slots')
  const kuerzel = fachKuerzel(fach)
  return (
    <span className="inline-flex items-center gap-2 text-xs text-[var(--color-text-tertiary)]">
      {klasse !== null && <span className="tabular-nums">{t('kind.klasseKurz', { klasse })}</span>}
      {kuerzel && (
        <span title={fach ?? undefined} className="inline-flex h-5 min-w-5 items-center justify-center rounded-[var(--radius-full)] border border-[var(--color-border)] px-1 text-xs font-semibold text-[var(--color-text-secondary)]">
          <span aria-hidden="true">{kuerzel}</span>
          <span className="sr-only">{fach}</span>
        </span>
      )}
    </span>
  )
}
