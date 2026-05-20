import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

interface MasteryBarProps {
  level: number
  showLabel?: boolean
  size?: 'sm' | 'md' | 'lg'
}

function getMasteryColor(level: number): string {
  if (level <= 3) return 'var(--destructive)'
  if (level <= 5) return 'var(--warning)'
  if (level <= 7) return 'var(--xp-gold)'
  return 'var(--success)'
}

function getMasteryLabel(level: number): string {
  if (level <= 3) return 'Lücke'
  if (level <= 5) return 'Erkennbar'
  if (level <= 7) return 'Sicher'
  return 'Exzellent'
}

export function MasteryBar({ level, showLabel = false, size = 'md' }: MasteryBarProps) {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    const id = requestAnimationFrame(() => setMounted(true))
    return () => cancelAnimationFrame(id)
  }, [])

  const clamped = Math.min(10, Math.max(1, level))
  const pct = (clamped / 10) * 100
  const color = getMasteryColor(clamped)
  const label = getMasteryLabel(clamped)

  const trackHeights: Record<string, string> = {
    sm: 'h-1.5',
    md: 'h-2.5',
    lg: 'h-4',
  }

  return (
    <div className="flex flex-col gap-1.5">
      {showLabel && (
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold uppercase tracking-wider text-[var(--text-muted)]">
            Niveau {clamped}/10
          </span>
          <span className="text-xs font-bold" style={{ color }}>
            {label}
          </span>
        </div>
      )}
      <div
        className={cn(
          'w-full rounded-[var(--radius-full)] overflow-hidden bg-[var(--border)]',
          trackHeights[size],
        )}
      >
        <div
          className="mastery-bar-fill h-full rounded-[var(--radius-full)]"
          style={{
            width: mounted ? `${pct}%` : '0%',
            backgroundColor: color,
          }}
        />
      </div>
    </div>
  )
}
