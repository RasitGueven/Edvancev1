import type { ReactNode, JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { X } from 'lucide-react'

interface SessionShellProps {
  children: ReactNode
  /** Optionaler, immer sichtbarer (sticky) Header — z.B. die Hub-Leiste. */
  header?: ReactNode
  /** Vertikal zentrieren (z.B. Check-in). */
  center?: boolean
  /** Dezenter Exit-Link nach /mock — nur außerhalb des Task-Flows. */
  showExit?: boolean
  maxWidth?: 'sm' | 'md' | 'lg'
}

const MAX_WIDTH: Record<NonNullable<SessionShellProps['maxWidth']>, string> = {
  sm: 'max-w-md',
  md: 'max-w-2xl',
  lg: 'max-w-3xl',
}

/**
 * Dunkle „Midnight Academy"-Bühne für alle Schüler-Screens des Mocks.
 * Glas-Effekte funktionieren ausschließlich auf dieser Bühne (Hard Rule §3).
 */
export function SessionShell({
  children,
  header,
  center = false,
  showExit = false,
  maxWidth = 'md',
}: SessionShellProps): JSX.Element {
  const { t } = useTranslation('mock')
  const widthClass = MAX_WIDTH[maxWidth]

  return (
    <div className="session-stage relative min-h-screen w-full overflow-x-hidden">
      {showExit && (
        <Link
          to="/mock"
          aria-label={t('session.common.exit')}
          className="glass-button absolute right-4 top-4 z-30 inline-flex h-11 w-11 items-center justify-center rounded-[var(--radius-full)]"
        >
          <X className="h-5 w-5" aria-hidden="true" />
        </Link>
      )}

      {header && (
        <div className="session-header sticky top-0 z-20">
          <div className={`mx-auto w-full ${widthClass} px-4 py-3`}>{header}</div>
        </div>
      )}

      <div
        className={
          center
            ? 'relative z-10 flex min-h-screen flex-col items-center justify-center px-4 py-10'
            : 'relative z-10 px-4 py-6'
        }
      >
        <div className={`mx-auto w-full ${widthClass}`}>{children}</div>
      </div>
    </div>
  )
}
