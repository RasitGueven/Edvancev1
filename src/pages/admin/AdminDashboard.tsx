import { useEffect, useState } from 'react'
import {
  CalendarClock,
  Inbox,
  PenLine,
  UserPlus,
  Users,
} from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import {
  AdminKpiBar,
  AdminTile,
  AdminTileGrid,
} from '@/components/edvance/AdminWidgetGrid'
import { getAdminStats, type AdminStats } from '@/lib/supabase/adminStats'

const ICON_CLASS = 'h-6 w-6'

export function AdminDashboard(): JSX.Element {
  const [stats, setStats] = useState<AdminStats | null>(null)
  const [loading, setLoading] = useState<boolean>(true)

  useEffect(() => {
    let active = true
    getAdminStats().then(({ data }) => {
      if (!active) return
      setStats(data)
      setLoading(false)
    })
    return () => {
      active = false
    }
  }, [])

  const leadsNew = stats?.leadsNew ?? 0

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Admin" />

      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 py-8 sm:px-6 sm:py-10">
        <header className="flex flex-col gap-1 animate-fade-in">
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Übersicht
          </h1>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            Steuere Inhalte, Leads, Stundenplan und Coaches an einem Ort.
          </p>
        </header>

        <AdminKpiBar stats={stats} loading={loading} />

        <AdminTileGrid>
          <AdminTile
            to="/admin/authoring"
            icon={<PenLine className={ICON_CLASS} />}
            title="Autoren-Tool"
            description="Aufgaben erstellen, prüfen, Stoffanker setzen und für die LSA freigeben — das zentrale Inhalts-Werkzeug."
            accent="primary"
            size="lg"
            cta="Inhalte pflegen"
          />
          <AdminTile
            to="/admin/leads"
            icon={<Inbox className={ICON_CLASS} />}
            title="Leads"
            accent={leadsNew > 0 ? 'warning' : 'primary'}
            size="wide"
            stat={{
              value: stats?.leadsOpen ?? 0,
              caption: 'offene Leads in Bearbeitung',
            }}
            badge={leadsNew > 0 ? { label: `${leadsNew} neu`, variant: 'warning' } : null}
            loading={loading}
          />
          <AdminTile
            to="/admin/schedule"
            icon={<CalendarClock className={ICON_CLASS} />}
            title="Stundenplan"
            description="Sessions anlegen und Schüler einem Coach-Termin zuweisen."
            accent="warning"
            size="wide"
          />
          <AdminTile
            to="/admin/coaches"
            icon={<UserPlus className={ICON_CLASS} />}
            title="Coaches"
            description="Coach-Accounts anlegen und Zugangsdaten vergeben."
            accent="success"
            size="sm"
          />
          <AdminTile
            to="/admin/assignments"
            icon={<Users className={ICON_CLASS} />}
            title="Coach-Zuordnung"
            description="Schüler ihrem Coach zuweisen oder umhängen."
            accent="success"
            size="sm"
          />
        </AdminTileGrid>
      </main>
    </div>
  )
}
