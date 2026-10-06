import { Outlet, useLocation } from 'react-router-dom'
import { AppShell } from '@/components/edvance/shell/AppShell'
import { CoachLayout } from '@/components/edvance/coach/CoachLayout'
import { istFokusSeite } from '@/components/edvance/coach/coachNav'
import { useAuth } from '@/hooks/useAuth'
import { ADMIN_NAV } from './adminNav'
import { useAdminZaehler } from './useAdminZaehler'

function AdminHuelle(): JSX.Element {
  const zaehler = useAdminZaehler()
  return (
    <AppShell konfig={ADMIN_NAV} zaehler={zaehler}>
      <Outlet />
    </AppShell>
  )
}

/**
 * Layout-Route der Admin- und der Coach-Seiten: die Rolle entscheidet die
 * Hülle (Entscheidung 12, Coach-Sicht H6). Auf geteilten Routen (Akten,
 * Prüfen, Content-Gesundheit, Eltern-Report) sieht ein Admin die Admin-Hülle,
 * ein Coach die Coach-Hülle. Fokus-Seiten und andere Rollen bekommen nur die
 * Seite. Die Zugriffsprüfung bleibt in der ProtectedRoute jeder Kind-Route.
 */
export function AdminLayout(): JSX.Element {
  const { role } = useAuth()
  const { pathname } = useLocation()
  if (istFokusSeite(pathname)) return <Outlet />
  if (role === 'admin') return <AdminHuelle />
  if (role === 'coach') return <CoachLayout />
  return <Outlet />
}
