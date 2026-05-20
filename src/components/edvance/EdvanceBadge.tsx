import React from 'react'
import { cn } from '@/lib/utils'

interface EdvanceBadgeProps {
  children: React.ReactNode
  variant?:
    | 'primary'
    | 'success'
    | 'warning'
    | 'destructive'
    | 'muted'
    | 'xp'
    | 'streak'
    | 'levelup'
    | 'repair'
  className?: string
}

export function EdvanceBadge({
  children,
  variant = 'primary',
  className,
}: EdvanceBadgeProps) {
  const variantStyles: Record<string, string> = {
    primary:
      'bg-[var(--primary-pale)] text-[var(--primary)] border border-[var(--primary-light)]',
    success:
      'bg-[var(--success-light)] text-[var(--success)] border border-[var(--success)]',
    warning:
      'bg-[var(--warning-light)] text-[var(--warning)] border border-[var(--warning)]',
    destructive:
      'bg-[var(--destructive-light)] text-[var(--destructive)] border border-[var(--destructive)]',
    muted:
      'bg-[var(--border)] text-[var(--text-muted)] border border-[var(--border-strong)]',
    xp:
      'bg-[var(--xp-gold)] text-[var(--brand-navy)] border border-[var(--xp-gold)] font-bold',
    streak:
      'bg-[var(--streak-orange)] text-white border border-[var(--streak-orange)]',
    levelup:
      'bg-[var(--color-levelup)] text-[var(--color-levelup-on)] border border-[var(--color-levelup)] font-bold',
    repair:
      'bg-[var(--color-moment-repair)] text-[var(--color-moment-repair-on)] border border-[var(--color-moment-repair)] font-bold',
  }

  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-[var(--radius-full)] px-3 py-1',
        'text-xs font-semibold uppercase tracking-wider',
        variantStyles[variant],
        className,
      )}
    >
      {variant === 'streak' && '🔥'}
      {children}
    </span>
  )
}
