import React from 'react'
import { cn } from '@/lib/utils'

interface ProgressStepProps {
  steps: string[]
  current: number
}

export function ProgressStep({ steps, current }: ProgressStepProps) {
  return (
    <div className="flex items-center">
      {steps.map((step, idx) => {
        const isPast   = idx < current
        const isActive = idx === current
        const isLast   = idx === steps.length - 1

        return (
          <React.Fragment key={idx}>
            <div className="flex flex-col items-center gap-1.5 min-w-0">
              <div
                className={cn(
                  'w-8 h-8 rounded-[var(--radius-full)] flex items-center justify-center',
                  'text-xs font-bold border-2 transition-all duration-200',
                  isPast   && 'bg-[var(--success)] border-[var(--success)] text-white',
                  isActive && 'bg-[var(--primary)] border-[var(--primary)] text-white scale-110 shadow-elevation-sm',
                  !isPast && !isActive && 'bg-transparent border-[var(--border-strong)] text-[var(--text-muted)]',
                )}
              >
                {isPast ? '✓' : idx + 1}
              </div>
              <span
                className={cn(
                  'text-xs max-w-[64px] text-center leading-tight',
                  isActive && 'font-semibold text-[var(--primary)]',
                  isPast   && 'text-[var(--success)]',
                  !isPast && !isActive && 'text-[var(--text-muted)]',
                )}
              >
                {step}
              </span>
            </div>
            {!isLast && (
              <div
                className={cn(
                  'flex-1 h-0.5 mb-5 mx-1 transition-colors duration-300',
                  isPast ? 'bg-[var(--success)]' : 'bg-[var(--border)]',
                )}
              />
            )}
          </React.Fragment>
        )
      })}
    </div>
  )
}
