import React from 'react'
import { cn } from '@/lib/utils'

interface EdvanceCardProps {
  children: React.ReactNode
  variant?: 'default' | 'raised' | 'navy' | 'blue-pale' | 'hero' | 'glass' | 'premium'
  accent?: 'none' | 'left-primary' | 'left-success' | 'left-warning' | 'left-destructive'
  className?: string
  onClick?: () => void
}

export function EdvanceCard({
  children,
  variant = 'default',
  accent = 'none',
  className,
  onClick,
}: EdvanceCardProps) {
  const variantStyles: Record<string, string> = {
    default:    'bg-[var(--surface)] border border-[var(--border)] shadow-premium-sm',
    raised:     'bg-[var(--surface-raised)] border border-[var(--border)] shadow-premium-md',
    navy:       'bg-[var(--brand-navy)] text-[var(--text-inverse)] border border-[var(--brand-navy)] shadow-premium-md',
    'blue-pale':'bg-[var(--primary-pale)] border border-[var(--primary-light)]',
    hero:       'bg-gradient-hero text-white border-0 shadow-premium-xl noise-overlay',
    glass:      'glass-light shadow-premium-md',
    premium:    'bg-gradient-surface border border-[var(--border)] shadow-premium-md',
  }

  const accentStyles: Record<string, string> = {
    none:               '',
    'left-primary':     'border-l-4 border-l-[var(--primary)]',
    'left-success':     'border-l-4 border-l-[var(--success)]',
    'left-warning':     'border-l-4 border-l-[var(--warning)]',
    'left-destructive': 'border-l-4 border-l-[var(--destructive)]',
  }

  const isInteractive = !!onClick
  const isDark = variant === 'navy' || variant === 'hero'

  return (
    <div
      className={cn(
        'rounded-[var(--radius-xl)] p-6',
        variantStyles[variant],
        accentStyles[accent],
        !isDark && 'transition-all duration-300 hover:shadow-premium-lg',
        isInteractive && 'cursor-pointer hover-lift',
        className,
      )}
      onClick={onClick}
    >
      {children}
    </div>
  )
}
