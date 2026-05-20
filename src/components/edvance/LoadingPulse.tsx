import React from 'react'
import { cn } from '@/lib/utils'

interface LoadingPulseProps {
  lines?: number
  type?: 'card' | 'list' | 'stat'
}

function SkeletonBlock({ className, style }: { className?: string; style?: React.CSSProperties }) {
  return (
    <div
      className={cn('rounded-[var(--radius-md)] bg-[var(--border)] animate-skeleton', className)}
      style={style}
    />
  )
}

export function LoadingPulse({ lines = 3, type = 'list' }: LoadingPulseProps) {
  if (type === 'card') {
    return (
      <div className="rounded-[var(--radius-xl)] p-6 border border-[var(--border)] shadow-card bg-[var(--surface)]">
        <SkeletonBlock className="h-5 w-1/2 mb-4" />
        <SkeletonBlock className="h-4 w-full mb-2" />
        <SkeletonBlock className="h-4 w-3/4 mb-2" />
        <SkeletonBlock className="h-4 w-5/6" />
      </div>
    )
  }

  if (type === 'stat') {
    return (
      <div className="grid grid-cols-3 gap-4">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            className="rounded-[var(--radius-xl)] p-6 border border-[var(--border)] shadow-card bg-[var(--surface)] flex items-start gap-3"
          >
            <SkeletonBlock className="w-12 h-12 rounded-[var(--radius-lg)] flex-none" />
            <div className="flex-1 flex flex-col gap-2">
              <SkeletonBlock className="h-8 w-16" />
              <SkeletonBlock className="h-3 w-full" />
            </div>
          </div>
        ))}
      </div>
    )
  }

  return (
    <div className="flex flex-col gap-3">
      {Array.from({ length: lines }).map((_, i) => (
        <div key={i} className="flex items-center gap-3">
          <SkeletonBlock className="w-10 h-10 rounded-[var(--radius-full)] flex-none" />
          <div className="flex-1 flex flex-col gap-1.5">
            <SkeletonBlock
              className="h-3.5"
              style={{ width: `${70 + (i % 3) * 10}%` } as React.CSSProperties}
            />
            <SkeletonBlock className="h-3 w-1/2" />
          </div>
        </div>
      ))}
    </div>
  )
}
