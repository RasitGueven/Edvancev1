import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

interface XPBarProps {
  current: number
  max: number
  level: number
  levelName: string
}

export function XPBar({ current, max, level, levelName }: XPBarProps) {
  const [mounted, setMounted] = useState(false)
  const [pulse, setPulse] = useState(false)
  const pct = Math.min(100, (current / max) * 100)

  useEffect(() => {
    const raf = requestAnimationFrame(() => setMounted(true))
    return () => cancelAnimationFrame(raf)
  }, [])

  useEffect(() => {
    setPulse(true)
    const t = setTimeout(() => setPulse(false), 500)
    return () => clearTimeout(t)
  }, [current])

  return (
    <div className="flex items-center gap-3">
      <div
        className={cn(
          'flex-none flex items-center justify-center w-10 h-10',
          'rounded-[var(--radius-full)] text-sm font-bold text-[var(--brand-navy)]',
          'bg-[var(--xp-gold)] shadow-elevation-sm',
          pulse && 'animate-bounce-pop',
        )}
      >
        {level}
      </div>

      <div className="flex-1 min-w-0">
        <div className="flex items-center justify-between mb-1.5">
          <span className="text-xs font-semibold text-[var(--text-muted)]">{levelName}</span>
          <span
            className={cn(
              'text-xs font-bold text-[var(--xp-gold)]',
              pulse && 'animate-xp-pulse',
            )}
          >
            {current.toLocaleString('de-DE')} / {max.toLocaleString('de-DE')} XP
          </span>
        </div>
        <div className="h-2.5 w-full rounded-[var(--radius-full)] overflow-hidden bg-[var(--xp-gold-light)]">
          <div
            className="xp-bar-fill h-full rounded-[var(--radius-full)]"
            style={{ width: mounted ? `${pct}%` : '0%' }}
          />
        </div>
      </div>
    </div>
  )
}
