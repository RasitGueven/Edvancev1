// FR-2 F3 / IU-1 U3: gemeinsame Bausteine von „Gezielt prüfen“ (Aufgabenliste je Kompetenz, Prüfziel-Umschalter,
// Filter-Hinweis).
import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { PruefBoardZeile } from '@/types'

/** Aufgaben einer Kompetenz; nur, was im Board steht (Klick öffnet die Prüfansicht). */
export function AufgabenListe({ ids, board, onOeffne }: {
  ids: string[]
  board: PruefBoardZeile[]
  onOeffne: (taskId: string) => void
}): JSX.Element {
  const { t } = useTranslation('pruefen')
  const zeile = new Map(board.map((z) => [z.task_id, z]))
  return (
    <ul className="flex flex-col">
      {ids.map((id) => {
        const z = zeile.get(id)
        if (!z) return null
        return (
          <li key={id}>
            <button type="button" onClick={() => onOeffne(id)} data-testid={`ziel-${id}`}
              className="flex min-h-[44px] w-full items-center justify-between gap-2 rounded-[var(--radius-md)] px-2 text-left text-sm hover:bg-[var(--color-bg-subtle)]">
              <span>{z.kurztitel}</span>
              <span className="text-xs text-[var(--color-text-tertiary)]">{t(`status.${z.lena_status}`)}</span>
            </button>
          </li>
        )
      })}
    </ul>
  )
}

import { PRUEFZIELE } from '@/lib/pruefung/gezielt'
export { PRUEFZIELE }

/** „Alle | MSA (ZP10)“ oben in der Liste. */
export function ZielUmschalter({ ziel, onWahl }: { ziel: string | null; onWahl: (ziel: string | null) => void }): JSX.Element {
  const { t } = useTranslation('pruefen')
  const wahl: (string | null)[] = [null, ...PRUEFZIELE]
  return (
    <div role="group" aria-label={t('gezielt.ziel.label')} className="flex flex-wrap gap-2">
      {wahl.map((z) => {
        const an = z === ziel
        return (
          <button key={z ?? 'alle'} type="button" aria-pressed={an} onClick={() => onWahl(z)}
            className={`min-h-[44px] rounded-[var(--radius-full)] border px-4 text-sm font-semibold transition-colors ${
              an ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-text-inverse)]'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:text-[var(--color-primary)]'}`}>
            {z ? t(`gezielt.ziel.${z}`) : t('gezielt.ziel.alle')}
          </button>
        )
      })}
    </div>
  )
}

/** „Gefiltert: … · Filter aufheben“ beim Sprung aus der Inhalte-Übersicht (?skill=). */
export function FilterHinweis({ kompetenz, onAufheben }: { kompetenz: string; onAufheben: () => void }): JSX.Element {
  const { t } = useTranslation('pruefen')
  return (
    <p className="flex flex-wrap items-center gap-2 text-sm text-[var(--color-text-secondary)]" data-testid="gezielt-filter">
      <span className="font-semibold text-[var(--color-text-primary)]">{t('gezielt.filter.gefiltert', { kompetenz })}</span>
      <span aria-hidden="true">·</span>
      <button type="button" onClick={onAufheben} className="min-h-[44px] font-semibold text-[var(--color-text-link)] hover:underline">
        {t('gezielt.filter.aufheben')}
      </button>
    </p>
  )
}
