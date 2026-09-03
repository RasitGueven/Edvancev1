import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { cn } from '@/lib/utils'
import { EdvanceCard } from '@/components/edvance'
import type { AdminStats } from '@/lib/supabase/adminStats'

type Kpi = { value: number; label: string }

function KpiCell({ kpi, loading }: { kpi: Kpi; loading: boolean }): JSX.Element {
  return (
    <div className="flex flex-col gap-1">
      {loading ? (
        <span className="h-8 w-14 rounded-[var(--radius-md)] bg-white/20 animate-skeleton" />
      ) : (
        <span className="font-serif text-3xl font-semibold leading-none">{kpi.value}</span>
      )}
      <span className="text-xs font-semibold uppercase tracking-widest text-white/70">
        {kpi.label}
      </span>
    </div>
  )
}

/** Ueberblicks-Band ueber dem Kachelraster — drei Kennzahlen, kein Zeitstempel. */
export function AdminKpiBar({
  stats,
  loading,
}: {
  stats: AdminStats | null
  loading: boolean
}): JSX.Element {
  const { t } = useTranslation('admin')
  const kpis: Kpi[] = [
    { value: stats?.students ?? 0, label: t('dashboard.overview.students') },
    { value: stats?.leadsOpen ?? 0, label: t('dashboard.overview.leadsOpen') },
    { value: stats?.coaches ?? 0, label: t('dashboard.overview.coaches') },
  ]
  return (
    <EdvanceCard variant="hero-student" className="animate-fade-in">
      <div className="flex flex-col gap-5">
        <p className="text-xs font-semibold uppercase tracking-widest text-[color-mix(in_srgb,var(--color-stage-gold-edge)_85%,white)]">
          {t('dashboard.overview.heading')}
        </p>
        <div className="grid grid-cols-3 gap-6">
          {kpis.map((kpi) => (
            <KpiCell key={kpi.label} kpi={kpi} loading={loading} />
          ))}
        </div>
      </div>
    </EdvanceCard>
  )
}

export type AdminTileProps = {
  icon: ReactNode
  title: string
  description: string
  /** Zielroute. null bedeutet: das Ziel existiert noch nicht — Kachel bleibt inaktiv. */
  to?: string | null
  /** Gold-Hinweis oben rechts. Nur setzen, wenn ein Wert groesser null vorliegt. */
  badge?: string | null
  /** Reihe 1 ist hoeher als Reihe 2 und 3. */
  tall?: boolean
}

/**
 * Karteninhalt — fuer jede Kachel identisch: Icon oben links, optionaler Badge
 * oben rechts, Titel darunter, Beschreibung auf zwei Zeilen begrenzt.
 */
function AdminTileBody({
  icon,
  title,
  description,
  badge,
  badgeClass,
}: {
  icon: ReactNode
  title: string
  description: string
  badge: string | null
  badgeClass: string
}): JSX.Element {
  return (
    <EdvanceCard variant="admin-tile" className="flex h-full flex-col gap-4">
      <div className="flex items-start justify-between gap-3">
        <span
          className="admin-icon-tile flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)]"
          aria-hidden="true"
        >
          {icon}
        </span>
        {badge && (
          <span className={cn('shrink-0 text-xs font-semibold', badgeClass)}>{badge}</span>
        )}
      </div>
      <div className="flex flex-col gap-2">
        <span className="text-base font-semibold text-[var(--color-stage-text)]">{title}</span>
        <span className="line-clamp-2 text-xs leading-relaxed text-[color-mix(in_srgb,var(--color-stage-text)_56%,transparent)]">
          {description}
        </span>
      </div>
    </EdvanceCard>
  )
}

export function AdminTile({
  icon,
  title,
  description,
  to = null,
  badge = null,
  tall = false,
}: AdminTileProps): JSX.Element {
  const { t } = useTranslation('admin')
  const heightClass = tall ? 'min-h-72' : 'min-h-52'
  const mutedClass = 'text-[color-mix(in_srgb,var(--color-stage-text)_56%,transparent)]'

  // Ziel ohne Route: sichtbar, aber nicht bedienbar — kein Link, kein Hover.
  if (!to) {
    return (
      <div className={cn(heightClass, 'opacity-60')} aria-disabled="true">
        <AdminTileBody
          icon={icon}
          title={title}
          description={description}
          badge={t('dashboard.pending')}
          badgeClass={mutedClass}
        />
      </div>
    )
  }

  // Die gesamte Karte ist die Klickflaeche — kein Button darin.
  return (
    <Link
      to={to}
      className={cn(
        'admin-tile-link block rounded-[var(--radius-xl)]',
        'focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[var(--color-accent)]',
        heightClass,
      )}
    >
      <AdminTileBody
        icon={icon}
        title={title}
        description={description}
        badge={badge}
        badgeClass="text-[var(--color-accent)]"
      />
    </Link>
  )
}

/**
 * Eine Kachelreihe. Schmale Viewports einspaltig, sonst zwei oder drei Spalten.
 * auto-rows-fr haelt alle Reihen eines Rasters exakt gleich hoch.
 */
export function AdminTileRow({
  columns,
  children,
}: {
  columns: 2 | 3
  children: ReactNode
}): JSX.Element {
  return (
    <section
      className={cn(
        'grid auto-rows-fr grid-cols-1 gap-4',
        columns === 2 ? 'sm:grid-cols-2' : 'sm:grid-cols-3',
      )}
    >
      {children}
    </section>
  )
}
