import type { CSSProperties } from 'react'
import { Link } from 'react-router-dom'
import { BookOpen, ChevronRight, FileText, FlaskConical, PlayCircle, Sparkles } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EmptyState, EdvanceBadge, EdvanceCard, MasteryBar } from '@/components/edvance'
import type {
  ClusterStatus,
  ClusterStatusLabel,
} from '@/lib/screening/recommendation'
import type { SkillCluster, Task } from '@/types'

const STATUS_VARIANT: Record<
  ClusterStatusLabel,
  'mastered' | 'warning' | 'gap'
> = {
  Sicher: 'mastered',
  Erkennbar: 'warning',
  Lücke: 'gap',
}

export type ClusterProgress = Record<string, { completed: number; total: number }>

type ContentType = Task['content_type']

// v2: Skilltree-Grün-Palette statt hardcoded Tints (siehe Migration-Doku Phase 7).
const CLUSTER_TINTS = [
  { bg: 'var(--color-primary-light)',          fg: 'var(--color-primary)' },
  { bg: 'var(--color-success-skilltree-light)', fg: 'var(--color-success-skilltree)' },
  { bg: 'var(--color-success-eltern-light)',   fg: 'var(--color-success-eltern)' },
  { bg: 'var(--color-gold-warning-light)',     fg: 'var(--color-gold-warning)' },
  { bg: 'var(--color-accent-streak-light)',    fg: 'var(--color-accent-streak)' },
]

export function RowIcon({ type }: { type: ContentType }): JSX.Element {
  if (type === 'video') return <PlayCircle className="h-5 w-5 shrink-0 text-[var(--color-gold-warning)]" />
  if (type === 'article') return <FileText className="h-5 w-5 shrink-0 text-[var(--color-success-eltern)]" />
  if (type === 'exercise_group' || type === 'course')
    return <FlaskConical className="h-5 w-5 shrink-0 text-[var(--color-primary)]" />
  return <BookOpen className="h-5 w-5 shrink-0 text-[var(--color-primary)]" />
}

export function FilterResults({
  loading,
  tasks,
  clusterNameById,
}: {
  loading: boolean
  tasks: Task[]
  clusterNameById: Record<string, string>
}): JSX.Element {
  if (loading) {
    return <p className="mt-6 text-sm text-muted">Suche …</p>
  }
  if (tasks.length === 0) {
    return (
      <div className="mt-6">
        <EmptyState icon="🔍" title="Keine Treffer" description="Probiere andere Suchbegriffe." />
      </div>
    )
  }
  return (
    <div className="mt-6 flex flex-col gap-1.5">
      <p className="mb-1 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {tasks.length} Treffer
      </p>
      <div className="rounded-[var(--radius-xl)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] shadow-xs overflow-hidden">
        <ul className="divide-y divide-[var(--color-border)]">
          {tasks.slice(0, 50).map((t) => (
            <li key={t.id}>
              <Link
                to={`/student/task/${t.id}`}
                className="flex min-h-[56px] items-center gap-3 px-4 py-3 transition-colors hover:bg-[var(--color-bg-app)]"
              >
                <RowIcon type={t.content_type} />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-[var(--color-text-primary)]">
                    {t.title ?? t.question?.slice(0, 80) ?? `task:${t.id.slice(0, 8)}`}
                  </p>
                  {t.cluster_id && clusterNameById[t.cluster_id] && (
                    <p className="text-xs text-[var(--color-text-tertiary)]">{clusterNameById[t.cluster_id]}</p>
                  )}
                </div>
                <ChevronRight className="h-4 w-4 shrink-0 text-[var(--color-text-tertiary)]" />
              </Link>
            </li>
          ))}
          {tasks.length > 50 && (
            <li className="px-4 py-2 text-xs text-[var(--color-text-tertiary)]">
              … und {tasks.length - 50} weitere – Suche präziser, um sie zu sehen.
            </li>
          )}
        </ul>
      </div>
    </div>
  )
}

export function RecommendationBanner({
  clusterId,
  clusterName,
}: {
  clusterId: string
  clusterName: string
}): JSX.Element {
  return (
    <EdvanceCard className="mt-6 flex flex-wrap items-center justify-between gap-4 p-6">
      <div className="flex items-start gap-3">
        <span
          className="flex h-10 w-10 shrink-0 items-center justify-center rounded-[var(--radius-lg)] bg-[var(--color-primary-light)] text-[var(--color-primary)]"
        >
          <Sparkles className="h-5 w-5" />
        </span>
        <div className="min-w-0">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Empfohlener Start
          </p>
          <p className="mt-0.5 text-base font-semibold text-[var(--color-text-primary)]">
            {clusterName}
          </p>
          <p className="mt-1 text-sm leading-relaxed text-[var(--color-text-secondary)]">
            Aus deinem Lernstand-Check – hier macht Üben gerade den größten
            Unterschied.
          </p>
        </div>
      </div>
      <Link to={`/student/cluster/${clusterId}`}>
        <Button size="lg">Loslegen</Button>
      </Link>
    </EdvanceCard>
  )
}

type ClusterGridProps = {
  clusters: SkillCluster[]
  clusterProgress: ClusterProgress
  clusterStatusById?: Record<string, ClusterStatus>
  recommendedClusterId?: string | null
}

export function ClusterGrid({
  clusters,
  clusterProgress,
  clusterStatusById,
  recommendedClusterId,
}: ClusterGridProps): JSX.Element {
  return (
    <div className="mt-6 grid gap-4 sm:grid-cols-2">
      {clusters.map((c, idx) => {
        const tint = CLUSTER_TINTS[idx % CLUSTER_TINTS.length]
        const status = clusterStatusById?.[c.id]
        const isRecommended = recommendedClusterId === c.id
        const prog = clusterProgress[c.id] ?? { completed: 0, total: 0 }
        const blobStyle: CSSProperties = { background: tint.fg }
        const iconStyle: CSSProperties = { background: tint.bg, color: tint.fg }
        const barStyle: CSSProperties = {
          width: `${prog.total > 0 ? Math.round((prog.completed / prog.total) * 100) : 0}%`,
          backgroundColor: tint.fg,
        }

        return (
          <Link
            key={c.id}
            to={`/student/cluster/${c.id}`}
            className="group block rounded-[var(--radius-xl)] focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
          >
            <div
              className={`relative h-full overflow-hidden rounded-[var(--radius-xl)] border bg-[var(--color-bg-surface)] p-5 shadow-xs transition-all duration-300 group-hover:shadow-lg group-hover:-translate-y-0.5 min-h-[140px] flex flex-col justify-between ${
                isRecommended
                  ? 'border-[var(--color-primary)] ring-2 ring-[var(--color-primary)]'
                  : 'border-[var(--color-border)]'
              }`}
            >
              {/* Decorative blob */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-8 -top-8 h-24 w-24 rounded-full opacity-60 blur-2xl transition-opacity duration-300 group-hover:opacity-90"
                style={blobStyle}
              />

              {/* Top: icon + name + chevron */}
              <div className="relative flex items-start gap-4 flex-1">
                <span
                  className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)] shadow-xs"
                  style={iconStyle}
                >
                  <BookOpen className="h-5 w-5" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-base font-bold tracking-tight text-[var(--color-text-primary)]">
                    {c.name}
                  </p>
                  <p className="mt-0.5 text-xs text-[var(--color-text-tertiary)]">
                    Klasse {c.class_level_min}
                    {c.class_level_min !== c.class_level_max && ` – ${c.class_level_max}`}
                  </p>
                  {(isRecommended || status) && (
                    <div className="mt-2 flex flex-wrap items-center gap-2">
                      {isRecommended && (
                        <EdvanceBadge variant="primary">Empfohlen</EdvanceBadge>
                      )}
                      {status && (
                        <EdvanceBadge variant={STATUS_VARIANT[status.label]}>
                          {status.label}
                        </EdvanceBadge>
                      )}
                    </div>
                  )}
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-[var(--color-text-tertiary)] transition-all group-hover:translate-x-0.5 group-hover:text-[var(--color-primary)]" />
              </div>

              {/* Bottom: Screening-Lernstand + Fortschritt */}
              <div className="mt-4 flex flex-col gap-3">
                {status && (
                  <div>
                    <p className="mb-1.5 text-xs text-[var(--color-text-tertiary)]">
                      Lernstand-Check
                    </p>
                    <MasteryBar level={status.displayLevel} />
                  </div>
                )}
                {prog.total > 0 && (
                  <>
                    <p className="mb-1.5 text-xs text-[var(--color-text-tertiary)]">
                      {prog.completed} von {prog.total} Aufgaben
                    </p>
                    <div className="h-1.5 w-full overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-border)]">
                      <div
                        className="h-full rounded-[var(--radius-full)] transition-all duration-500"
                        style={barStyle}
                      />
                    </div>
                  </>
                )}
              </div>
            </div>
          </Link>
        )
      })}
    </div>
  )
}
