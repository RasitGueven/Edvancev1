import type { CSSProperties, ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { FlaskConical } from 'lucide-react'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { LastCluster } from '@/lib/lastCluster'

type StudentTileAccent = 'primary' | 'streak' | 'levelup' | 'xp'

const ACCENT_VAR: Record<StudentTileAccent, string> = {
  primary: 'var(--primary)',
  streak:  'var(--streak-orange)',
  levelup: 'var(--color-levelup)',
  xp:      'var(--xp-gold)',
}

// ─── ContinueTile (2×2 Hero) ─────────────────────────────────────────────────

function ContinueTile({ lastCluster }: { lastCluster: LastCluster | null }): JSX.Element {
  const to = lastCluster ? `/student/cluster/${lastCluster.id}` : '#lernpfad'
  const title = lastCluster ? lastCluster.name : 'Lernpfad starten'
  const eyebrow = lastCluster ? 'Weitermachen' : 'Einstieg'

  return (
    <Link
      to={to}
      className="col-span-2 md:row-span-2 block transition-transform duration-200 hover:-translate-y-1"
    >
      <EdvanceCard variant="hero" className="h-full flex flex-col justify-between min-h-[280px]">
        <div className="flex items-center gap-2">
          <span className="text-lg" aria-hidden="true">📖</span>
          <span className="text-xs font-semibold uppercase tracking-widest text-white/70">
            {eyebrow}
          </span>
        </div>
        <div className="flex flex-col gap-3">
          <p className="text-2xl font-bold leading-snug">{title}</p>
          <span className="inline-flex w-fit items-center gap-1.5 rounded-[var(--radius-full)] px-4 py-2 text-sm font-semibold bg-white/15 backdrop-blur-sm">
            Los geht's <span aria-hidden="true">→</span>
          </span>
        </div>
      </EdvanceCard>
    </Link>
  )
}

// ─── StudentStatTile (1×1) ────────────────────────────────────────────────────

type StudentStatTileProps = {
  accent: StudentTileAccent
  emoji: string
  value: number | string
  label: string
  loading?: boolean
}

function StudentStatTile({
  accent,
  emoji,
  value,
  label,
  loading = false,
}: StudentStatTileProps): JSX.Element {
  const accentColor = ACCENT_VAR[accent]
  const chipStyle: CSSProperties = {
    backgroundColor: `color-mix(in srgb, ${accentColor} 14%, white)`,
    color: accentColor,
  }

  return (
    <div className="col-span-1">
      <EdvanceCard className="h-full flex flex-col justify-between min-h-[120px]">
        <span
          className="flex h-10 w-10 items-center justify-center rounded-[var(--radius-lg)] text-xl"
          style={chipStyle}
          aria-hidden="true"
        >
          {emoji}
        </span>
        <div className="flex flex-col gap-0.5">
          {loading ? (
            <span className="h-9 w-14 rounded-[var(--radius-md)] bg-[var(--border)] animate-skeleton" />
          ) : (
            <span
              className="text-3xl font-bold leading-none"
              style={{ color: accentColor }}
            >
              {value}
            </span>
          )}
          <span className="text-xs text-[var(--text-muted)]">{label}</span>
        </div>
      </EdvanceCard>
    </div>
  )
}

// ─── StudentActionTile ────────────────────────────────────────────────────────

type StudentActionTileProps = {
  to: string
  icon: ReactNode
  eyebrow?: string
  title: string
  description?: string
}

function StudentActionTile({
  to,
  icon,
  eyebrow,
  title,
  description,
}: StudentActionTileProps): JSX.Element {
  const accentColor = ACCENT_VAR['primary']
  const chipStyle: CSSProperties = {
    backgroundColor: `color-mix(in srgb, ${accentColor} 14%, white)`,
    color: accentColor,
  }

  return (
    <Link
      to={to}
      className="col-span-1 md:col-span-2 block min-h-[44px] transition-transform duration-200 hover:-translate-y-1"
    >
      <EdvanceCard className="h-full flex flex-col justify-between gap-4">
        <div className="flex items-start justify-between gap-3">
          <span
            className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)]"
            style={chipStyle}
            aria-hidden="true"
          >
            {icon}
          </span>
          {eyebrow && (
            <EdvanceBadge variant="primary">{eyebrow}</EdvanceBadge>
          )}
        </div>
        <div className="flex flex-col gap-1">
          <span className="text-base font-semibold text-[var(--text-primary)]">{title}</span>
          {description && (
            <span className="text-xs leading-relaxed text-[var(--text-muted)]">{description}</span>
          )}
        </div>
      </EdvanceCard>
    </Link>
  )
}

// ─── StudentBentoGrid (exported) ──────────────────────────────────────────────

type StudentBentoGridProps = {
  xpTotal: number
  streakDays: number
  level: number
  lastCluster: LastCluster | null
  loading?: boolean
}

export function StudentBentoGrid({
  xpTotal,
  streakDays,
  level,
  lastCluster,
  loading = false,
}: StudentBentoGridProps): JSX.Element {
  return (
    <section className="grid grid-cols-2 gap-4 md:grid-cols-3 md:auto-rows-[minmax(140px,auto)] grid-flow-dense">
      <ContinueTile lastCluster={lastCluster} />
      <StudentStatTile
        accent="streak"
        emoji="🔥"
        value={streakDays}
        label="Tage am Stück"
        loading={loading}
      />
      <StudentStatTile
        accent="levelup"
        emoji="⭐"
        value={level}
        label="Level"
        loading={loading}
      />
      <StudentStatTile
        accent="xp"
        emoji="✨"
        value={xpTotal}
        label="XP gesamt"
        loading={loading}
      />
      <StudentActionTile
        to="/screening"
        icon={<FlaskConical className="h-5 w-5" />}
        eyebrow="Diagnose"
        title="Screening starten"
        description="Zeig, was du kannst"
      />
    </section>
  )
}
