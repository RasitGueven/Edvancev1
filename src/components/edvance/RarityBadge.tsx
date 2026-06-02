import { cn } from '@/lib/utils'

export type BadgeRarity = 'bronze' | 'silver' | 'gold' | 'platinum'
export type BadgeForm = 'round' | 'shield'

interface RarityBadgeProps {
  rarity: BadgeRarity
  form?: BadgeForm
  /** Icon im Zentrum (string oder JSX). Default = '★' */
  children?: React.ReactNode
  label?: string
  size?: 'sm' | 'md' | 'lg'
  className?: string
}

const SIZE_PX: Record<NonNullable<RarityBadgeProps['size']>, number> = {
  sm: 40,
  md: 64,
  lg: 96,
}

/**
 * Rarity-Badge — Bronze · Silber · Gold · Platin
 * - Center immer Midnight-Navy (`--color-badge-center`)
 * - Platin: Conic-Gradient + Shimmer + Glitzer
 * - Shield-Form: clip-path Polygon (Pflicht für Klassen-Abschlüsse)
 *
 * Effekte bewusst minimal — Animationen erst nach DESIGN_SYSTEM-Audit aktiv.
 */
export function RarityBadge({
  rarity,
  form = 'round',
  children = '★',
  label,
  size = 'md',
  className,
}: RarityBadgeProps) {
  const px = SIZE_PX[size]

  const background = (() => {
    switch (rarity) {
      case 'bronze':
        return 'var(--color-badge-bronze)'
      case 'silver':
        return 'var(--color-badge-silver)'
      case 'gold':
        return 'var(--color-badge-gold)'
      case 'platinum':
        return `conic-gradient(from 180deg at 50% 50%,
          var(--color-badge-platinum-start) 0deg,
          var(--color-badge-platinum-mid) 120deg,
          var(--color-badge-platinum-end) 240deg,
          var(--color-badge-platinum-start) 360deg)`
    }
  })()

  const clipPath =
    form === 'shield'
      ? 'polygon(50% 0%, 95% 18%, 95% 65%, 50% 100%, 5% 65%, 5% 18%)'
      : undefined
  const borderRadius = form === 'round' ? '9999px' : undefined

  return (
    <div className={cn('inline-flex flex-col items-center gap-1.5', className)}>
      <div
        className="relative inline-flex items-center justify-center shadow-md"
        style={{ width: px, height: px, background, clipPath, borderRadius }}
        aria-label={label ?? rarity}
      >
        <div
          className="flex items-center justify-center bg-[var(--color-badge-center)] font-bold text-white"
          style={{
            width: px * 0.74,
            height: px * 0.74,
            borderRadius: form === 'round' ? '9999px' : '6px',
            fontSize: px * 0.32,
          }}
        >
          {children}
        </div>
      </div>
      {label && (
        <span className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-secondary)]">
          {label}
        </span>
      )}
    </div>
  )
}
