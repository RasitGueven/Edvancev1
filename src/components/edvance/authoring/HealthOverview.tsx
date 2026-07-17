// Die Zählerkacheln der Content-Gesundheit — jede Kachel ist ein Filter.
//
// Midnight-Sprache auf hellem Grund: Fraunces-Serif-Zahl, matte Gold-Kante am
// aktiven Filter, kein Glow, keine Badge-Pills. Die Zahl bleibt in Textfarbe
// (Gold auf Weiß wäre zu kontrastarm) — die Gold-Kante trägt die Auswahl.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import type { DefectCounts, HealthDefect } from '@/lib/authoring/health'
import { DEFECT_ORDER } from '@/lib/authoring/health'
import type { TaskStatus } from '@/types'

export type HealthFilter = 'all' | HealthDefect | `status:${TaskStatus}`

const STATUS_ORDER: TaskStatus[] = ['draft', 'review', 'ready']

function Tile({
  value,
  label,
  caption,
  active,
  onClick,
}: {
  value: number
  label: string
  caption: string
  active: boolean
  onClick: () => void
}): JSX.Element {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-pressed={active}
      className={cn(
        'flex min-h-[44px] flex-col items-start gap-1 rounded-[var(--radius-lg)] border bg-[var(--color-bg-surface)] p-5 text-left shadow-xs transition hover:shadow-elevation-md',
        active
          ? 'border-[var(--color-stage-gold-edge)]'
          : 'border-[var(--color-border)]',
      )}
    >
      <span className="font-serif text-3xl font-semibold leading-none text-[var(--color-text-primary)]">
        {value}
      </span>
      <span className="text-sm font-semibold text-[var(--color-text-primary)]">{label}</span>
      <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
        {caption}
      </span>
    </button>
  )
}

export function HealthOverview({
  counts,
  statusCounts,
  active,
  onSelect,
}: {
  counts: DefectCounts
  statusCounts: Record<TaskStatus, number>
  active: HealthFilter
  onSelect: (filter: HealthFilter) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  const select = (filter: HealthFilter) => onSelect(active === filter ? 'all' : filter)

  return (
    <div className="flex flex-col gap-6">
      <section className="flex flex-col gap-3">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('health.overview.defects')}
        </h2>
        <div className="grid grid-cols-2 gap-4 md:grid-cols-3 lg:grid-cols-6">
          {DEFECT_ORDER.map((defect) => (
            <Tile
              key={defect}
              value={counts[defect]}
              label={t(`health.tiles.${defect}`)}
              caption={t(`health.tiles.${defect}Caption`)}
              active={active === defect}
              onClick={() => select(defect)}
            />
          ))}
        </div>
      </section>

      <section className="flex flex-col gap-3">
        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('health.overview.byStatus')}
        </h2>
        <div className="grid grid-cols-3 gap-4">
          {STATUS_ORDER.map((status) => (
            <Tile
              key={status}
              value={statusCounts[status]}
              label={t(`status.${status}`)}
              caption={t('health.tiles.statusCaption')}
              active={active === `status:${status}`}
              onClick={() => select(`status:${status}`)}
            />
          ))}
        </div>
      </section>
    </div>
  )
}
