import { Link } from 'react-router-dom'
import { BookOpen, ChevronRight, FileText, FlaskConical, PlayCircle, Sparkles } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { EmptyState, EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { EdvanceBadgeVariant } from '@/components/edvance/EdvanceBadge'
import { cn } from '@/lib/utils'
import { STAGE_BG, masteryStageForLevel } from '@/components/student'
import type {
  ClusterStatus,
  ClusterStatusLabel,
} from '@/lib/screening/recommendation'
import type { SkillCluster, Task } from '@/types'

// FernUSG / Hard Rule §6: „Sicher" (oberste Screening-Stufe) darf NICHT als
// dauerhaftes „Mastered" erscheinen — auf die proficient-Optik gedeckelt, bis
// eine Coach-Bestätigung im Backend vorliegt. Reines Visual-Mapping.
const STATUS_VARIANT: Record<ClusterStatusLabel, EdvanceBadgeVariant> = {
  Sicher: 'mastery-proficient',
  Erkennbar: 'warning',
  Lücke: 'gap',
}

export type ClusterProgress = Record<string, { completed: number; total: number }>

type ContentType = Task['content_type']

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
    return <p className="mt-6 text-sm text-warm-72">Suche …</p>
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
      <p className="mb-1 text-eyebrow text-warm-56">
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
      {clusters.map((c) => {
        const status = clusterStatusById?.[c.id]
        const isRecommended = recommendedClusterId === c.id
        const prog = clusterProgress[c.id] ?? { completed: 0, total: 0 }
        const pct = prog.total > 0 ? Math.round((prog.completed / prog.total) * 100) : 0
        // FernUSG-gedeckelte Stufe — „mastered" erst mit Coach-Bestätigung.
        const stage = status ? masteryStageForLevel(status.displayLevel) : null

        return (
          <Link
            key={c.id}
            to={`/student/cluster/${c.id}`}
            className="group block rounded-[var(--radius-lg)] focus:outline-none focus-visible:ring-2 focus-visible:ring-white/40"
          >
            <div
              className={cn(
                'glass-card relative flex min-h-[140px] flex-col justify-between p-5 text-warm transition-transform duration-200 ease-bounce group-hover:-translate-y-0.5',
                isRecommended && 'session-cta',
              )}
            >
              <div className="flex items-start gap-4">
                <span
                  className={cn(
                    'flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)]',
                    isRecommended ? 'session-icon-tile' : 'bg-white/15 text-warm',
                  )}
                >
                  <BookOpen className="h-5 w-5" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-base font-bold tracking-tight text-warm">{c.name}</p>
                  <p className="mt-0.5 text-xs text-warm-56">
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
                <ChevronRight className="h-5 w-5 shrink-0 text-warm-72 transition-transform group-hover:translate-x-0.5" />
              </div>

              <div className="mt-4 flex flex-col gap-3">
                {status && stage && (
                  <div>
                    <p className="mb-1.5 text-xs text-warm-56">Lernstand-Check</p>
                    <div className="h-2 w-full overflow-hidden rounded-[var(--radius-full)] bg-white/15">
                      <div
                        className={cn(
                          'mastery-bar-fill h-full rounded-[var(--radius-full)]',
                          STAGE_BG[stage],
                        )}
                        style={{ width: `${Math.min(100, Math.max(0, status.displayLevel * 10))}%` }}
                      />
                    </div>
                  </div>
                )}
                {prog.total > 0 && (
                  <div>
                    <p className="mb-1.5 text-xs text-warm-56">
                      {prog.completed} von {prog.total} Aufgaben
                    </p>
                    <div className="h-1.5 w-full overflow-hidden rounded-[var(--radius-full)] bg-white/15">
                      <div
                        className="h-full rounded-[var(--radius-full)] bg-[var(--color-accent-streak)] transition-all duration-500"
                        style={{ width: `${pct}%` }}
                      />
                    </div>
                  </div>
                )}
              </div>
            </div>
          </Link>
        )
      })}
    </div>
  )
}
