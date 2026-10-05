import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import {
  CalendarClock,
  ClipboardCheck,
  FileText,
  FolderOpen,
  Inbox,
  PenLine,
  ScrollText,
  UserPlus,
} from 'lucide-react'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import {
  AdminKpiBar,
  AdminTile,
  AdminTileRow,
} from '@/components/edvance/AdminWidgetGrid'
import { getAdminStats, type AdminStats } from '@/lib/supabase/adminStats'

const ICON_CLASS = 'h-6 w-6'

export function AdminDashboard(): JSX.Element {
  const { t } = useTranslation('admin')
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
    // Startseite in der Hülle, heller Grund (Entscheidung 1). Die Kacheln
    // ersetzt H3 durch „Heute“.
    <>
      <PageHeader rubrik={t('dashboard.eyebrow')} titel={t('dashboard.title')} />

      <AdminKpiBar stats={stats} loading={loading} />

      <div className="flex flex-col gap-4">
        {/* Reihe 1 — zwei Karten über die volle Breite, höher als die übrigen. */}
        <AdminTileRow columns={2}>
          <AdminTile
            tall
            to="/admin/leads"
            icon={<Inbox className={ICON_CLASS} />}
            title={t('dashboard.tiles.leads.title')}
            description={t('dashboard.tiles.leads.description')}
            badge={
              leadsNew > 0 ? t('dashboard.badges.leadsNew', { count: leadsNew }) : null
            }
          />
          {/* Stundenplan und Slots sind eine Kachel: Sessions und Wochenraster
              gehoeren fuer die Verwaltung zusammen. Ziel bleibt der
              Stundenplan; /admin/slots existiert weiter, nur ohne Kachel. */}
          <AdminTile
            tall
            to="/admin/schedule"
            icon={<CalendarClock className={ICON_CLASS} />}
            title={t('dashboard.tiles.slots.title')}
            description={t('dashboard.tiles.slots.description')}
          />
        </AdminTileRow>

        {/* Reihe 2 und 3 — sechs Karten in einem Raster, damit beide Reihen
            exakt dieselbe Hoehe bekommen. Eltern-Reports und
            LSA-Ergebnisse haben noch keine Route und bleiben inaktiv. */}
        <AdminTileRow columns={3}>
          <AdminTile
            to="/admin/akten"
            icon={<FolderOpen className={ICON_CLASS} />}
            title={t('dashboard.tiles.studentRecord.title')}
            description={t('dashboard.tiles.studentRecord.description')}
          />
          <AdminTile
            to="/admin/coaches"
            icon={<UserPlus className={ICON_CLASS} />}
            title={t('dashboard.tiles.coaches.title')}
            description={t('dashboard.tiles.coaches.description')}
          />
          <AdminTile
            icon={<FileText className={ICON_CLASS} />}
            title={t('dashboard.tiles.parentReports.title')}
            description={t('dashboard.tiles.parentReports.description')}
          />
          <AdminTile
            icon={<ClipboardCheck className={ICON_CLASS} />}
            title={t('dashboard.tiles.lsaResults.title')}
            description={t('dashboard.tiles.lsaResults.description')}
          />
          <AdminTile
            to="/admin/authoring"
            icon={<PenLine className={ICON_CLASS} />}
            title={t('dashboard.tiles.content.title')}
            description={t('dashboard.tiles.content.description')}
          />
          <AdminTile
            to="/admin/vertraege"
            icon={<ScrollText className={ICON_CLASS} />}
            title={t('dashboard.tiles.contracts.title')}
            description={t('dashboard.tiles.contracts.description')}
          />
        </AdminTileRow>
      </div>
    </>
  )
}
