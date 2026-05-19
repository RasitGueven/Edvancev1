import { useEffect, useState } from 'react'
import {
  BookOpen,
  CalendarClock,
  CreditCard,
  FlaskConical,
  GraduationCap,
  Inbox,
  ListChecks,
  UserPlus,
  Users,
  Zap,
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
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Übersicht
          </h1>
          <p className="text-sm leading-relaxed text-[var(--text-secondary)]">
            Steuere Onboarding, Leads, Tarife und Inhalte an einem Ort.
          </p>
        </header>

        <AdminKpiBar stats={stats} loading={loading} />

        <AdminTileGrid>
          <AdminTile
            to="/admin/onboarding"
            icon={<GraduationCap className={ICON_CLASS} />}
            title="Schüler-Onboarding"
            description="Neue Schüler in fünf Schritten anlegen und einem Coach zuweisen."
            accent="primary"
            size="lg"
            cta="Neuen Schüler anlegen"
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
          <AdminTile
            to="/admin/xp-rules"
            icon={<Zap className={ICON_CLASS} />}
            title="XP-Gewichtung"
            description="XP pro Aufgabentyp und Schwierigkeit festlegen."
            accent="success"
            size="sm"
          />
          <AdminTile
            to="/admin/tiers"
            icon={<CreditCard className={ICON_CLASS} />}
            title="Tarife"
            accent="success"
            size="sm"
            stat={{
              value: stats?.tiersActive ?? 0,
              caption: `von ${stats?.tiersTotal ?? 0} Tarifen aktiv`,
            }}
            loading={loading}
          />
          <AdminTile
            to="/admin/diagnostics"
            icon={<FlaskConical className={ICON_CLASS} />}
            title="Diagnostik"
            description="Aufgaben als Diagnose markieren und Inhalte pflegen."
            accent="levelup"
            size="sm"
          />
          <AdminTile
            to="/admin/screening-items"
            icon={<ListChecks className={ICON_CLASS} />}
            title="Screening-Items"
            accent="repair"
            size="wide"
            stat={{
              value: stats?.screeningItems ?? 0,
              caption: 'Items im Screening-Pool',
            }}
            loading={loading}
          />
          <AdminTile
            to="/admin/lambacher-preview"
            icon={<BookOpen className={ICON_CLASS} />}
            title="Lambacher-Vorschau"
            description="Importierte Lambacher-Inhalte als Vorschau prüfen."
            accent="primary"
            size="wide"
          />
        </AdminTileGrid>
      </main>
    </div>
  )
}
