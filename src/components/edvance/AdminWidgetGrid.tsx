import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { AdminStats } from '@/lib/supabase/adminStats'

type TileAccent = 'primary' | 'success' | 'warning' | 'levelup' | 'repair'
type TileSize = 'sm' | 'wide' | 'lg'

const ACCENT_CLS: Record<TileAccent, { chip: string; text: string; cta: string }> = {
  primary: {
    chip: 'bg-[color-mix(in_srgb,var(--color-primary)_14%,white)] text-[var(--color-primary)]',
    text: 'text-[var(--color-primary)]',
    cta: 'bg-[var(--color-primary)]',
  },
  success: {
    chip: 'bg-[color-mix(in_srgb,var(--color-success)_14%,white)] text-[var(--color-success)]',
    text: 'text-[var(--color-success)]',
    cta: 'bg-[var(--color-success)]',
  },
  warning: {
    chip: 'bg-[color-mix(in_srgb,var(--color-gold-warning)_14%,white)] text-[var(--color-gold-warning)]',
    text: 'text-[var(--color-gold-warning)]',
    cta: 'bg-[var(--color-gold-warning)]',
  },
  levelup: {
    chip: 'bg-[color-mix(in_srgb,var(--color-primary)_14%,white)] text-[var(--color-primary)]',
    text: 'text-[var(--color-primary)]',
    cta: 'bg-[var(--color-primary)]',
  },
  repair: {
    chip: 'bg-[color-mix(in_srgb,var(--color-moment-repair-purple)_14%,white)] text-[var(--color-moment-repair-purple)]',
    text: 'text-[var(--color-moment-repair-purple)]',
    cta: 'bg-[var(--color-moment-repair-purple)]',
  },
}

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
        <span className="text-3xl font-bold leading-none">{kpi.value}</span>
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
          <p className="text-xs font-semibold uppercase tracking-widest text-white/70">
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

type TileBadge = {
  label: string
  variant: 'primary' | 'success' | 'warning' | 'destructive' | 'muted'
}

export type AdminTileProps = {
  to: string
  icon: ReactNode
  title: string
  description?: string
  accent?: TileAccent
  size?: TileSize
  stat?: { value: number; caption: string } | null
  badge?: TileBadge | null
  cta?: string | null
  loading?: boolean
}

export function AdminTile({
  to,
  icon,
  title,
  description = '',
  accent = 'primary',
  size = 'sm',
  stat = null,
  badge = null,
  cta = null,
  loading = false,
}: AdminTileProps): JSX.Element {
  const cls = ACCENT_CLS[accent]

  return (
    <Link
      to={to}
      className={`${SIZE_CLASS[size]} block min-h-[44px] transition-transform duration-200 hover:-translate-y-1`}
    >
      <EdvanceCard className="flex h-full flex-col justify-between gap-4">
        <div className="flex items-start justify-between gap-3">
          <span
            className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)] ${cls.chip}`}
            aria-hidden="true"
          >
            {icon}
          </span>
          {badge && <EdvanceBadge variant={badge.variant}>{badge.label}</EdvanceBadge>}
        </div>

        <div className="flex flex-col gap-1.5">
          {stat &&
            (loading ? (
              <span className="h-9 w-16 rounded-[var(--radius-md)] bg-[var(--color-border)] animate-skeleton" />
            ) : (
              <span className={`text-3xl font-bold leading-none ${cls.text}`}>
                {stat.value}
              </span>
            ))}
          <span className="text-base font-semibold text-[var(--color-text-primary)]">
            {title}
          </span>
          <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {stat ? stat.caption : description}
          </span>
          {cta && (
            <span
              className={`mt-3 inline-flex w-fit items-center gap-1.5 rounded-[var(--radius-full)] px-4 py-2 text-sm font-semibold text-white ${cls.cta}`}
            >
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
