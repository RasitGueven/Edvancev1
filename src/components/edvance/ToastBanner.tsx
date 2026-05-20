import { useEffect, useState } from 'react'
import { cn } from '@/lib/utils'

interface ToastBannerProps {
  type: 'success' | 'xp' | 'levelup' | 'warning' | 'error'
  message: string
  xpAmount?: number
  onClose?: () => void
}

const TOAST_CLASS: Record<string, string> = {
  success: 'toast-success',
  xp:      'toast-xp',
  levelup: 'toast-levelup',
  warning: 'toast-warning',
  error:   'toast-error',
}

const TOAST_ICON: Record<string, string> = {
  success: '✓',
  xp:      '🎉',
  levelup: '⬆️',
  warning: '⚠️',
  error:   '✕',
}

export function ToastBanner({ type, message, xpAmount, onClose }: ToastBannerProps) {
  const [exiting, setExiting] = useState(false)

  useEffect(() => {
    const hideTimer = setTimeout(() => setExiting(true), 2700)
    return () => clearTimeout(hideTimer)
  }, [])

  useEffect(() => {
    if (!exiting) return
    const closeTimer = setTimeout(() => onClose?.(), 200)
    return () => clearTimeout(closeTimer)
  }, [exiting, onClose])

  return (
    <div
      className={cn(
        'fixed top-6 left-1/2 z-50',
        'flex items-center gap-3 px-5 py-3',
        'rounded-[var(--radius-lg)] font-semibold border-[1.5px]',
        '-translate-x-1/2 min-w-[280px] max-w-[480px]',
        'shadow-elevation-lg',
        TOAST_CLASS[type],
        exiting ? 'animate-toast-out' : 'animate-toast-in',
      )}
      role="alert"
    >
      <span className={cn('text-xl leading-none', type === 'xp' && 'text-2xl')}>
        {TOAST_ICON[type]}
      </span>

      <span className="flex-1 text-sm">{message}</span>

      {type === 'xp' && xpAmount !== undefined && (
        <span className="text-xl font-bold leading-none animate-bounce-pop">
          +{xpAmount} XP
        </span>
      )}
    </div>
  )
}
