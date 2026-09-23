// Eine Kachel der Board-Navigation (Bereich, Klasse, Fach): Name, Anzahl,
// Pruefstand, Balken. Ohne Aufgaben sichtbar, aber ausgegraut und nicht klickbar.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { Stand } from '@/lib/authoring/board'
import { FortschrittsBalken } from './FortschrittsBalken'

export function BoardKachel({
  titel,
  stand,
  onOpen,
}: {
  titel: string
  stand: Stand
  onOpen: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const leer = stand.total === 0

  return (
    <button
      type="button"
      onClick={onOpen}
      disabled={leer}
      title={leer ? t('board.leer') : undefined}
      className="flex min-h-[44px] flex-col gap-2 rounded-[var(--radius-xl)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-6 text-left shadow-card transition hover:border-[var(--color-primary)] hover:shadow-elevation-md disabled:cursor-not-allowed disabled:bg-[var(--color-bg-subtle)] disabled:opacity-60 disabled:shadow-none disabled:hover:border-[var(--color-border)]"
    >
      <span className="text-base font-semibold text-[var(--color-text-primary)]">{titel}</span>
      <span className="text-sm text-[var(--color-text-secondary)]">
        {leer
          ? t('board.leer')
          : t('board.kachelStand', { count: stand.total, total: stand.total, geprueft: stand.geprueft })}
      </span>
      {!leer && <FortschrittsBalken stand={stand} />}
    </button>
  )
}
