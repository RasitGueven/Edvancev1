import { Outlet } from 'react-router-dom'
import { AppShell } from '@/components/edvance/shell/AppShell'
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
 * Layout-Route der Admin-Seiten. Nur die Rolle admin bekommt die Hülle; jede
 * andere Rolle sieht die Seite wie bisher (Coach auf /admin/akten bis zur
 * Coach-Sicht, Entscheidung 12). Die Zugriffsprüfung bleibt in der
 * ProtectedRoute jeder Kind-Route.
 */
export function AdminLayout(): JSX.Element {
  const { role } = useAuth()
  return role === 'admin' ? <AdminHuelle /> : <Outlet />
}
