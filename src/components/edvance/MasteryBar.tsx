import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'
import {
  masteryStage,
  masteryStageFromLevel,
  MASTERY_STAGE_COLOR,
  MASTERY_STAGE_LABEL,
} from '@/lib/mastery'

interface MasteryBarProps {
  /** Pädagogisches Niveau 1–10 (Backend-Schema). Genau eines von level/score. */
  level?: number
  /** Kompetenz-Score 0–100 (%). Hat Vorrang vor `level`, wenn gesetzt. */
  score?: number
  showLabel?: boolean
  size?: 'sm' | 'md' | 'lg'
}

export function MasteryBar({ level, score, showLabel = false, size = 'md' }: MasteryBarProps) {
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    const id = requestAnimationFrame(() => setMounted(true))
    return () => cancelAnimationFrame(id)
  }, [])

  // Score-Pfad hat Vorrang; sonst Level 1–10 → %.
  const hasScore = typeof score === 'number'
  const pct = hasScore
    ? Math.min(100, Math.max(0, score!))
    : (Math.min(10, Math.max(1, level ?? 1)) / 10) * 100

  const stage = hasScore ? masteryStage(pct) : masteryStageFromLevel(level ?? 1)
  const color = MASTERY_STAGE_COLOR[stage]
  const label = MASTERY_STAGE_LABEL[stage]

  // Progressing nutzt laut Spec §03 einen eigenen, leicht grünlichen Track.
  const trackColor =
    stage === 'progressing'
      ? 'var(--color-mastery-progressing-bg)'
      : 'var(--color-border)'

  const trackHeights: Record<string, string> = {
    sm: 'h-1.5',
    md: 'h-2.5',
    lg: 'h-4',
  }

  return (
    <div className="flex flex-col gap-1.5">
      {showLabel && (
        <div className="flex items-center justify-between">
          <span className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)]">
            {hasScore ? `${Math.round(pct)}%` : `Niveau ${Math.min(10, Math.max(1, level ?? 1))}/10`}
          </span>
          <span className="text-xs font-bold" style={{ color }}>
            {label}
          </span>
        </div>
      )}
      <div
        className={cn(
          'w-full rounded-[var(--radius-full)] overflow-hidden',
          trackHeights[size],
        )}
        style={{ backgroundColor: trackColor }}
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
