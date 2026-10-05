import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { useAuth } from '@/hooks/useAuth'
import { getDarfPruefen } from '@/lib/supabase/freigabe'
import type { ProtectedRouteProps } from '@/types'

/** Hinweis, den /coach zeigt, wenn das Pruefrecht fehlt (location.state). */
export const HINWEIS_KEIN_PRUEFRECHT = 'kein_pruefrecht'

function Laedt(): JSX.Element {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
    </div>
  )
}

export function ProtectedRoute({
  allowedRoles,
  children,
  umleitungFuer,
  pruefrecht = false,
}: ProtectedRouteProps): JSX.Element {
  const { t } = useTranslation('common')
  const { user, role, loading } = useAuth()
  const rolleOk = !!role && allowedRoles.includes(role)
  // Das Pruefrecht entscheidet die DB (darf_pruefen); die Route fragt nur nach.
  const [darf, setDarf] = useState<boolean | null>(null)

  useEffect(() => {
    if (!pruefrecht || !user || !rolleOk) return
    let aktiv = true
    void getDarfPruefen().then((res) => {
      if (aktiv) setDarf(res.data === true)
    })
    return () => {
      aktiv = false
    }
  }, [pruefrecht, user, rolleOk])

  if (loading || (user && role === null)) return <Laedt />

  if (!user) return <Navigate to="/login" replace />

  if (!rolleOk) {
    const ziel = role ? umleitungFuer?.[role] : undefined
    if (ziel) return <Navigate to={ziel} replace />
    return (
      <div className="flex min-h-screen flex-col items-center justify-center gap-2">
        <p className="text-xl font-semibold text-foreground">{t('zugriff.keinTitel')}</p>
        <p className="text-sm text-muted">{t('zugriff.keinText')}</p>
      </div>
    )
  }

  if (pruefrecht && darf === null) return <Laedt />
  if (pruefrecht && !darf) {
    return <Navigate to="/coach" replace state={{ hinweis: HINWEIS_KEIN_PRUEFRECHT }} />
  }

  return <>{children}</>
}
