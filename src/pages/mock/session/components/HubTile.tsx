import type { ReactNode, JSX } from 'react'
import { ChevronRight } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { cn } from '@/lib/utils'

interface HubTileProps {
  title: string
  description: string
  icon: ReactNode
  onClick?: () => void
  /** Primäre, größte Kachel (Session starten). */
  emphasis?: boolean
  disabled?: boolean
  className?: string
}

/**
 * Absprung-Kachel im Hub — Glas-Card auf dunkler Bühne (Hard Rule §3).
 * Reicht `onClick` durch an EdvanceCard (hover-lift, cursor, Touch-Fläche groß).
 */
export function HubTile({
  title,
  description,
  icon,
  onClick,
  emphasis = false,
  disabled = false,
  className,
}: HubTileProps): JSX.Element {
  return (
    <EdvanceCard
      variant="glass"
      onClick={disabled ? undefined : onClick}
      className={cn(
        'text-warm',
        emphasis ? 'min-h-[148px] session-cta' : 'min-h-[112px]',
        disabled && 'session-card-dimmed',
        className,
      )}
    >
      <div className="flex h-full items-start gap-4">
        <span
          className={cn(
            'flex shrink-0 items-center justify-center rounded-[var(--radius-lg)]',
            emphasis ? 'session-icon-tile' : 'bg-white/15 text-warm',
            emphasis ? 'h-14 w-14' : 'h-11 w-11',
          )}
          aria-hidden="true"
        >
          {icon}
        </span>
        <div className="min-w-0 flex-1">
          <div className="flex items-center justify-between gap-2">
            <h3 className={cn('font-semibold', emphasis ? 'text-xl' : 'text-base')}>
              {title}
            </h3>
            {!disabled && (
              <ChevronRight className="h-5 w-5 shrink-0 text-warm-72" aria-hidden="true" />
            )}
          </div>
          <p className="mt-1 text-sm leading-relaxed text-warm-72">{description}</p>
        </div>
      </div>
    </EdvanceCard>
  )
}
