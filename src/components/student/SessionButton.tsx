import type { ReactNode, JSX } from 'react'
import { cn } from '@/lib/utils'

type SessionButtonVariant = 'primary' | 'ghost'

interface SessionButtonProps {
  children: ReactNode
  onClick?: () => void
  variant?: SessionButtonVariant
  disabled?: boolean
  /** Volle Breite (z.B. Haupt-CTA am Screen-Ende). */
  block?: boolean
  icon?: ReactNode
  type?: 'button' | 'submit'
  className?: string
  'aria-label'?: string
}

/**
 * CTA für die dunklen Schüler-Screens. Touch-Target ≥ 44px (Design-Regel §4),
 * Student-Motion (bounce, 200ms). Genau ein `primary` pro Screen.
 *  - primary: heller Surface-Button auf dunkler Bühne (klarer Fokus)
 *  - ghost:   Glas-Button (sekundäre Aktion)
 */
export function SessionButton({
  children,
  onClick,
  variant = 'primary',
  disabled = false,
  block = false,
  icon,
  type = 'button',
  className,
  'aria-label': ariaLabel,
}: SessionButtonProps): JSX.Element {
  const base =
    'inline-flex min-h-[44px] items-center justify-center gap-2 rounded-[var(--radius-xl)] px-6 text-base font-semibold transition-[transform,opacity,background] duration-200 ease-bounce active:scale-[0.98] disabled:pointer-events-none disabled:opacity-50'

  const byVariant =
    variant === 'primary'
      ? 'bg-[var(--color-bg-surface)] text-[var(--color-primary)] shadow-lg hover:opacity-90'
      : 'glass-button'

  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      aria-label={ariaLabel}
      className={cn(base, byVariant, block && 'w-full', className)}
    >
      {icon}
      {children}
    </button>
  )
}
