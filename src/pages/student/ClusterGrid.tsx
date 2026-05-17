import type { CSSProperties } from 'react'
import { Link } from 'react-router-dom'
import { BookOpen, ChevronRight, FileText, FlaskConical, PlayCircle } from 'lucide-react'
import { EmptyState } from '@/components/edvance'
import type { SkillCluster, Task } from '@/types'

// ─── Types ────────────────────────────────────────────────────────────────────

export type ClusterProgress = Record<string, { completed: number; total: number }>

type ContentType = Task['content_type']

// ─── Constants ────────────────────────────────────────────────────────────────

const CLUSTER_TINTS = [
  { bg: 'var(--color-primary-light)',     fg: 'var(--color-primary)' },
  { bg: 'var(--color-success-light)',     fg: 'var(--color-success)' },
  { bg: 'var(--color-warning-light)',     fg: 'var(--color-warning)' },
  { bg: 'var(--color-info-light)',        fg: 'var(--color-info)' },
  { bg: 'color-mix(in srgb, var(--xp-gold) 14%, white)', fg: 'var(--xp-gold)' },
]

// ─── RowIcon ──────────────────────────────────────────────────────────────────

export function RowIcon({ type }: { type: ContentType }): JSX.Element {
  if (type === 'video') return <PlayCircle className="h-5 w-5 shrink-0 text-warning" />
  if (type === 'article') return <FileText className="h-5 w-5 shrink-0 text-success" />
  if (type === 'exercise_group' || type === 'course')
    return <FlaskConical className="h-5 w-5 shrink-0 text-primary" />
  return <BookOpen className="h-5 w-5 shrink-0 text-primary" />
}

// ─── FilterResults ────────────────────────────────────────────────────────────

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
      <p className="mb-1 text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
        {tasks.length} Treffer
      </p>
      <div className="rounded-[var(--radius-xl)] border border-[var(--border)] bg-[var(--surface)] shadow-premium-sm overflow-hidden">
        <ul className="divide-y divide-[var(--border)]">
          {tasks.slice(0, 50).map((t) => (
            <li key={t.id}>
              <Link
                to={`/student/task/${t.id}`}
                className="flex min-h-[56px] items-center gap-3 px-4 py-3 transition-colors hover:bg-[var(--background)]"
              >
                <RowIcon type={t.content_type} />
                <div className="min-w-0 flex-1">
                  <p className="truncate text-sm font-semibold text-[var(--text-primary)]">
                    {t.title ?? t.question?.slice(0, 80) ?? `task:${t.id.slice(0, 8)}`}
                  </p>
                  {t.cluster_id && clusterNameById[t.cluster_id] && (
                    <p className="text-xs text-[var(--text-muted)]">{clusterNameById[t.cluster_id]}</p>
                  )}
                </div>
                <ChevronRight className="h-4 w-4 shrink-0 text-[var(--text-muted)]" />
              </Link>
            </li>
          ))}
          {tasks.length > 50 && (
            <li className="px-4 py-2 text-xs text-[var(--text-muted)]">
              … und {tasks.length - 50} weitere – Suche präziser, um sie zu sehen.
            </li>
          )}
        </ul>
      </div>
    </div>
  )
}

// ─── ClusterGrid ──────────────────────────────────────────────────────────────

type ClusterGridProps = {
  clusters: SkillCluster[]
  clusterProgress: ClusterProgress
  onClusterClick: (id: string, name: string) => void
}

export function ClusterGrid({
  clusters,
  clusterProgress,
  onClusterClick,
}: ClusterGridProps): JSX.Element {
  return (
    <div className="mt-6 grid gap-4 sm:grid-cols-2">
      {clusters.map((c, idx) => {
        const tint = CLUSTER_TINTS[idx % CLUSTER_TINTS.length]
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
            onClick={() => onClusterClick(c.id, c.name)}
            className="group block rounded-[var(--radius-xl)] focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
          >
            <div className="relative h-full overflow-hidden rounded-[var(--radius-xl)] border border-[var(--border)] bg-gradient-surface p-5 shadow-premium-sm transition-all duration-300 group-hover:shadow-premium-lg group-hover:-translate-y-0.5 min-h-[140px] flex flex-col justify-between">
              {/* Decorative blob */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-8 -top-8 h-24 w-24 rounded-full opacity-60 blur-2xl transition-opacity duration-300 group-hover:opacity-90"
                style={blobStyle}
              />

              {/* Top: icon + name + chevron */}
              <div className="relative flex items-start gap-4 flex-1">
                <span
                  className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)] shadow-premium-sm"
                  style={iconStyle}
                >
                  <BookOpen className="h-5 w-5" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-base font-bold tracking-tight text-[var(--text-primary)]">
                    {c.name}
                  </p>
                  <p className="mt-0.5 text-xs text-[var(--text-muted)]">
                    Klasse {c.class_level_min}
                    {c.class_level_min !== c.class_level_max && ` – ${c.class_level_max}`}
                  </p>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-[var(--text-muted)] transition-all group-hover:translate-x-0.5 group-hover:text-[var(--color-primary)]" />
              </div>

              {/* Bottom: progress bar */}
              <div className="mt-4">
                {prog.total > 0 && (
                  <>
                    <p className="mb-1.5 text-xs text-[var(--text-muted)]">
                      {prog.completed} von {prog.total} Aufgaben
                    </p>
                    <div className="h-1.5 w-full overflow-hidden rounded-[var(--radius-full)] bg-[var(--border)]">
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
