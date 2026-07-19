import { useEffect, useState } from 'react'
import {
  CalendarClock,
  CalendarHeart,
  HeartPulse,
  Inbox,
  LayoutGrid,
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
    <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle="Admin" />

      {/* Midnight-Bühne — die Schüler-Sprache trägt jetzt auch die Verwaltung. */}
      <div className="admin-stage flex-1">
        <main className="relative z-10 mx-auto flex max-w-6xl flex-col gap-8 px-4 py-10 sm:px-6">
          <header className="flex flex-col gap-2 animate-fade-in">
            <p className="text-eyebrow text-[color-mix(in_srgb,var(--color-stage-gold-edge)_85%,white)]">
              Edvance · Verwaltung
            </p>
            <h1 className="font-serif text-4xl font-semibold leading-tight text-warm">
              Übersicht
            </h1>
            <p className="max-w-xl text-sm leading-relaxed text-warm-72">
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
              size="lg"
              cta="Inhalte pflegen"
            />
            <AdminTile
              to="/admin/content-gesundheit"
              icon={<HeartPulse className={ICON_CLASS} />}
              title="Content-Gesundheit"
              description="Mängel im Item-Bestand auf einen Blick — tote Bildpfade, fehlende Stoffanker, Alt-Texte."
              size="wide"
            />
            <AdminTile
              to="/admin/leads"
              icon={<Inbox className={ICON_CLASS} />}
              title="Leads"
              size="wide"
              stat={{
                value: stats?.leadsOpen ?? 0,
                caption: 'offene Leads in Bearbeitung',
              }}
              flag={leadsNew > 0 ? `${leadsNew} neu` : null}
              loading={loading}
            />
            <AdminTile
              to="/admin/schedule"
              icon={<CalendarClock className={ICON_CLASS} />}
              title="Stundenplan"
              description="Sessions anlegen und Schüler einem Coach-Termin zuweisen."
              size="wide"
            />
            <AdminTile
              to="/admin/slots"
              icon={<LayoutGrid className={ICON_CLASS} />}
              title="Slots verwalten"
              description="Wochen-Zeitraster der Kleingruppen — Wochentag, Uhrzeit, Raum und Kapazität."
              size="sm"
            />
            <AdminTile
              to="/admin/slot-auswahl"
              icon={<CalendarHeart className={ICON_CLASS} />}
              title="Slot-Auswahl"
              description="Wochenkalender fürs Elterngespräch: Favoriten festhalten und fest zuweisen."
              size="sm"
            />
            <AdminTile
              to="/admin/coaches"
              icon={<UserPlus className={ICON_CLASS} />}
              title="Coaches"
              description="Coach-Accounts anlegen und Zugangsdaten vergeben."
              size="sm"
            />
            <AdminTile
              to="/admin/assignments"
              icon={<Users className={ICON_CLASS} />}
              title="Coach-Zuordnung"
              description="Schüler ihrem Coach zuweisen oder umhängen."
              size="sm"
            />
          </AdminTileGrid>
        </main>
      </div>
    </div>
  )
}
