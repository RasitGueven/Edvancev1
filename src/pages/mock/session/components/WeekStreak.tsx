import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Flame } from 'lucide-react'
import { cn } from '@/lib/utils'

export type DayState = 'done' | 'today-done' | 'today-open' | 'empty'

interface WeekStreakProps {
  /** Genau 7 Einträge: Mo … So. */
  states: DayState[]
  /** Index, der gerade „aufgefüllt" wird (Pop-Animation am Session-Ende). */
  popIndex?: number
}

/**
 * Presence-Streak als Wochenkreise Mo–So (Amber-Flamme).
 * Erfüllte Tage in Amber, offene Tage neutral-grau (Token, kein Hex).
 */
export function WeekStreak({ states, popIndex }: WeekStreakProps): JSX.Element {
  const { t } = useTranslation('mock')
  const labels = t('session.hub.weekdays', { returnObjects: true }) as string[]

  return (
    <div className="flex items-end gap-2">
      {states.map((state, i) => {
        const filled = state === 'done' || state === 'today-done'
        const isToday = state === 'today-done' || state === 'today-open'
        return (
          <div key={i} className="flex flex-col items-center gap-1">
            <span
              className={cn(
                'flex h-8 w-8 items-center justify-center rounded-[var(--radius-full)] border text-[11px] font-bold',
                filled
                  ? 'border-transparent bg-[var(--color-accent-streak)] text-[var(--color-bg-surface)]'
                  : 'border-white/30 text-warm-56',
                isToday && !filled && 'border-[var(--color-accent-streak)] text-warm',
                popIndex === i && 'animate-count-up',
              )}
            >
              {filled ? <Flame className="h-4 w-4" aria-hidden="true" /> : labels[i]?.[0]}
            </span>
            <span className="text-[10px] text-warm-56">{labels[i]}</span>
          </div>
        )
      })}
    </div>
  )
}
