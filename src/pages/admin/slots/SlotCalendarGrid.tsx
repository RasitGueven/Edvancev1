// Wochenkalender der Slot-Auswahl (S10) — reines Rendering der Kalenderzellen.
//
// Layout- und Sortierlogik lebt in src/lib/slotGrid.ts (rein, getestet); diese
// Komponente übersetzt Slots + Favoriten-Zustand in große Touch-Karten fürs iPad.

import { Fragment, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EdvanceBadge } from '@/components/edvance'
import {
  CALENDAR_WEEKDAYS,
  fillLevel,
  slotsAt,
  timeRows,
  type SlotFillLevel,
} from '@/lib/slotGrid'
import type { SlotWithLoad } from '@/types'

interface SlotCalendarGridProps {
  slots: SlotWithLoad[]
  favouriteIds: string[]
  onToggle: (slot: SlotWithLoad) => void
}

// 'almost' ist bewusst die auffälligste Stufe — das Auffüllen bestehender
// Slots ist das Betriebsziel der Gründerrunde (siehe slotGrid.ts).
const FILL_STYLES: Record<SlotFillLevel, string> = {
  empty:
    'bg-[var(--color-bg-surface)] border border-[var(--color-border)] hover:border-[var(--color-primary)]',
  filling:
    'bg-[var(--color-primary-light)] border border-[var(--color-primary)] hover:brightness-95',
  almost:
    'bg-[var(--color-gold-warning-light)] border-2 border-[var(--color-accent)] shadow-md hover:brightness-95',
  full: 'bg-[var(--color-bg-subtle)] border border-[var(--color-border)] opacity-60 cursor-not-allowed',
}

function SlotTile({
  slot,
  rank,
  onToggle,
}: {
  slot: SlotWithLoad
  rank: number | null
  onToggle: (slot: SlotWithLoad) => void
}): JSX.Element {
  const { t } = useTranslation('slots')
  const level = fillLevel(slot)
  const full = level === 'full'

  return (
    <div
      aria-disabled={full || undefined}
      aria-label={full ? t('picker.card.full') : rank ? t('picker.card.deselect') : t('picker.card.select')}
    >
      <EdvanceCard
        onClick={full ? undefined : () => onToggle(slot)}
        className={`flex min-h-[44px] flex-col gap-1.5 rounded-xl p-3 transition-colors ${FILL_STYLES[level]}`}
      >
        <span className="text-sm font-semibold text-[var(--color-text-primary)]">
          {t('picker.card.room', { room: slot.room })}
        </span>
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {full
            ? t('picker.card.full')
            : t('picker.card.load', { belegt: slot.belegt, capacity: slot.capacity })}
        </span>
        {rank && (
          <EdvanceBadge variant="primary" className="mt-1 w-fit">
            {t('picker.card.rank', { rang: rank })}
          </EdvanceBadge>
        )}
      </EdvanceCard>
    </div>
  )
}

export function SlotCalendarGrid({
  slots,
  favouriteIds,
  onToggle,
}: SlotCalendarGridProps): JSX.Element {
  const { t } = useTranslation('slots')
  const rows = timeRows(slots)

  return (
    <div className="grid grid-cols-6 gap-3">
      <div />
      {CALENDAR_WEEKDAYS.map((weekday) => (
        <div
          key={weekday}
          className="text-center text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]"
        >
          {t(`weekdayShort.${weekday}`)}
        </div>
      ))}

      {rows.map((time) => (
        <Fragment key={time}>
          <div className="flex items-start justify-end pr-2 pt-3 text-sm font-semibold text-[var(--color-text-secondary)]">
            {time}
          </div>
          {CALENDAR_WEEKDAYS.map((weekday) => (
            <div key={`${weekday}-${time}`} className="flex flex-col gap-2">
              {slotsAt(slots, weekday, time).map((slot) => {
                const idx = favouriteIds.indexOf(slot.id)
                return (
                  <SlotTile
                    key={slot.id}
                    slot={slot}
                    rank={idx === -1 ? null : idx + 1}
                    onToggle={onToggle}
                  />
                )
              })}
            </div>
          ))}
        </Fragment>
      ))}
    </div>
  )
}
