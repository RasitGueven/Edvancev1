import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { cn } from '@/lib/utils'
import { EdvanceCard } from '@/components/edvance'
import type { AdminStats } from '@/lib/supabase/adminStats'

type TileSize = 'sm' | 'wide' | 'lg'

const SIZE_CLASS: Record<TileSize, string> = {
  sm: 'col-span-1',
  wide: 'col-span-2 md:col-span-1 lg:col-span-2',
  lg: 'col-span-2 md:row-span-2 lg:row-span-2',
}

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

export function AdminKpiBar({
  stats,
  loading,
}: {
  stats: AdminStats | null
  loading: boolean
}): JSX.Element {
  const kpis: Kpi[] = [
    { value: stats?.students ?? 0, label: 'Schüler' },
    { value: stats?.leadsOpen ?? 0, label: 'Offene Leads' },
    { value: stats?.coaches ?? 0, label: 'Coaches' },
    { value: stats?.tiersActive ?? 0, label: 'Aktive Tarife' },
  ]
  return (
    <EdvanceCard variant="hero-student" className="animate-fade-in">
      <div className="flex flex-col gap-5">
        <div className="flex items-center justify-between gap-4">
          <p className="text-xs font-semibold uppercase tracking-widest text-[color-mix(in_srgb,var(--color-stage-gold-edge)_85%,white)]">
            Überblick
          </p>
          <span className="text-xs text-white/60">Stand: gerade eben</span>
        </div>
        <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
          {kpis.map((kpi) => (
            <KpiCell key={kpi.label} kpi={kpi} loading={loading} />
          ))}
        </div>
      </div>
    </EdvanceCard>
  )
}

export type AdminTileProps = {
  to: string
  icon: ReactNode
  title: string
  description?: string
  size?: TileSize
  stat?: { value: number; caption: string } | null
  /** Kleiner Gold-Hinweis (z. B. „3 neu") — als Text, keine Pill. */
  flag?: string | null
  cta?: string | null
  loading?: boolean
}

export function AdminTile({
  to,
  icon,
  title,
  description = '',
  size = 'sm',
  stat = null,
  flag = null,
  cta = null,
  loading = false,
}: AdminTileProps): JSX.Element {
  // Die eine prominente Kachel (Autoren-Tool) ist die große: warme Gold-Kante.
  const prominent = size === 'lg'

  return (
    <Link
      to={to}
      className={`${SIZE_CLASS[size]} block min-h-[44px]`}
    >
      <EdvanceCard
        variant="admin-tile"
        className={cn(
          'flex h-full flex-col justify-between gap-4',
          prominent && 'admin-tile-primary',
        )}
      >
        <div className="flex items-start justify-between gap-3">
          <span
            className="admin-icon-tile flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)]"
            aria-hidden="true"
          >
            {icon}
          </span>
          {flag && (
            <span className="text-xs font-semibold text-[var(--color-accent)]">{flag}</span>
          )}
        </div>

        <div className="flex flex-col gap-1.5">
          {stat &&
            (loading ? (
              <span className="h-9 w-16 rounded-[var(--radius-md)] bg-white/15 animate-skeleton" />
            ) : (
              <span className="font-serif text-3xl font-semibold leading-none text-[var(--color-stage-gold-edge)]">
                {stat.value}
              </span>
            ))}
          <span
            className={cn(
              'font-semibold text-[var(--color-stage-text)]',
              prominent ? 'font-serif text-xl' : 'text-base',
            )}
          >
            {title}
          </span>
          <span className="text-xs leading-relaxed text-[color-mix(in_srgb,var(--color-stage-text)_56%,transparent)]">
            {stat ? stat.caption : description}
          </span>
          {cta && (
            <span className="admin-cta-gold mt-3 inline-flex w-fit items-center gap-1.5 rounded-[var(--radius-full)] px-4 py-2 text-sm font-semibold">
              {cta}
              <span aria-hidden="true">→</span>
            </span>
          )}
        </div>
      </EdvanceCard>
    </Link>
  )
}

export function AdminTileGrid({ children }: { children: ReactNode }): JSX.Element {
  return (
    <section className="grid grid-flow-dense grid-cols-2 gap-4 md:grid-cols-3 md:auto-rows-[minmax(200px,auto)] lg:grid-cols-4">
      {children}
    </section>
  )
}
