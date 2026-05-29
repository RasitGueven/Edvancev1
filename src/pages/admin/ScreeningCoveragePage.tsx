import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import {
  EdvanceBadge,
  EdvanceCard,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import { listScreeningItems } from '@/lib/supabase/screeningItems'
import {
  AFB_VALUES,
  PHASE_VALUES,
  buildCoverage,
  cellStatus,
  getCell,
  type CoverageStatus,
} from '@/lib/screening/v2/coverage'
import type {
  ScreeningAfb,
  ScreeningItem,
  ScreeningPhase,
  SkillCluster,
  Subject,
} from '@/types'

const SELECT_CLASS =
  'h-10 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-2 text-sm'

const STATUS_LABEL: Record<CoverageStatus, string> = {
  missing: 'fehlt',
  thin: 'dünn',
  ok: 'ok',
}

const STATUS_DOT: Record<CoverageStatus, string> = {
  missing: 'bg-[var(--color-error-exam)]',
  thin: 'bg-[var(--color-gold-warning)]',
  ok: 'bg-[var(--color-success)]',
}

const PHASE_LABEL: Record<ScreeningPhase, string> = {
  sprint: 'Sprint',
  tiefe: 'Tiefe',
}

function ClusterRow({
  cluster,
  items,
}: {
  cluster: SkillCluster
  items: ScreeningItem[]
}): JSX.Element {
  const matrix = useMemo(() => buildCoverage(items), [items])

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <h3 className="text-base font-semibold text-[var(--color-text-primary)]">
          {cluster.name}
        </h3>
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {items.filter((i) => i.afb && i.phase).length} v2-Items
        </span>
      </div>
      <div className="grid grid-cols-[auto_repeat(3,minmax(0,1fr))] gap-2 text-sm">
        <div />
        {AFB_VALUES.map((afb) => (
          <div
            key={`h-${afb}`}
            className="text-center text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]"
          >
            AFB {afb}
          </div>
        ))}
        {PHASE_VALUES.map((phase) => (
          <PhaseRow
            key={`r-${phase}`}
            phase={phase}
            clusterId={cluster.id}
            matrix={matrix}
          />
        ))}
      </div>
    </EdvanceCard>
  )
}

function PhaseRow({
  phase,
  clusterId,
  matrix,
}: {
  phase: ScreeningPhase
  clusterId: string
  matrix: ReturnType<typeof buildCoverage>
}): JSX.Element {
  return (
    <>
      <div className="flex items-center text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {PHASE_LABEL[phase]}
      </div>
      {AFB_VALUES.map((afb) => (
        <CoverageCellView
          key={`${phase}-${afb}`}
          clusterId={clusterId}
          phase={phase}
          afb={afb}
          matrix={matrix}
        />
      ))}
    </>
  )
}

function CoverageCellView({
  clusterId,
  phase,
  afb,
  matrix,
}: {
  clusterId: string
  phase: ScreeningPhase
  afb: ScreeningAfb
  matrix: ReturnType<typeof buildCoverage>
}): JSX.Element {
  const cell = getCell(matrix, clusterId, phase, afb)
  const status = cellStatus(cell)
  return (
    <div className="flex flex-col items-center gap-1 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-2 py-2">
      <div className="flex items-center gap-1.5">
        <span className={`h-2 w-2 rounded-full ${STATUS_DOT[status]}`} />
        <span className="text-xs text-[var(--color-text-tertiary)]">
          {STATUS_LABEL[status]}
        </span>
      </div>
      <span className="text-base font-bold text-[var(--color-text-primary)]">
        {cell.activeCount}
      </span>
      {cell.draftCount > 0 && (
        <span className="text-[10px] text-[var(--color-text-tertiary)]">
          +{cell.draftCount} Entwurf
        </span>
      )}
    </div>
  )
}

export function ScreeningCoveragePage(): JSX.Element {
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [subjectId, setSubjectId] = useState('')
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [items, setItems] = useState<ScreeningItem[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    getSubjects().then(({ data }) => {
      setSubjects(data ?? [])
      if (data && data.length > 0) setSubjectId(data[0].id)
    })
  }, [])

  useEffect(() => {
    if (!subjectId) return
    getClustersBySubject(subjectId).then(({ data }) => setClusters(data ?? []))
  }, [subjectId])

  useEffect(() => {
    setLoading(true)
    listScreeningItems({}).then(({ data, error: err }) => {
      setItems(data ?? [])
      setError(err)
      setLoading(false)
    })
  }, [])

  const itemsByCluster = useMemo(() => {
    const m = new Map<string, ScreeningItem[]>()
    for (const it of items) {
      const arr = m.get(it.cluster_id) ?? []
      arr.push(it)
      m.set(it.cluster_id, arr)
    }
    return m
  }, [items])

  const totals = useMemo(() => {
    const v2 = items.filter((i) => i.afb && i.phase)
    return {
      v2: v2.length,
      active: v2.filter((i) => i.active).length,
      draft: v2.filter((i) => !i.active).length,
      legacy: items.length - v2.length,
    }
  }, [items])

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Screening-Coverage" sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/admin"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
          >
            <ArrowLeft className="h-4 w-4" /> Admin
          </Link>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Screening-Coverage (v2)
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            Lücken im Pool sichtbar machen: pro Cluster, Phase und AFB. Rot =
            fehlt, gelb = nur ein Item, grün = ausreichend.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          <select
            className={SELECT_CLASS}
            value={subjectId}
            onChange={(e) => setSubjectId(e.target.value)}
          >
            {subjects.map((s) => (
              <option key={s.id} value={s.id}>
                {s.name}
              </option>
            ))}
          </select>
          <div className="flex flex-wrap gap-2">
            <EdvanceBadge variant="mastered">{totals.active} aktiv</EdvanceBadge>
            <EdvanceBadge variant="warning">
              {totals.draft} Entwurf
            </EdvanceBadge>
            <EdvanceBadge variant="muted">
              {totals.legacy} Legacy (v1)
            </EdvanceBadge>
          </div>
        </div>

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : clusters.length === 0 ? (
          <EmptyState
            icon="📭"
            title="Keine Cluster für dieses Fach"
            description="Wähle ein anderes Fach oder lege zuerst Cluster an."
          />
        ) : totals.v2 === 0 ? (
          <EmptyState
            icon="🌱"
            title="Noch keine v2-Items"
            description="v2 startet leer. Lege Items im Item-Editor mit afb + phase an — sie erscheinen hier sofort."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {clusters.map((c) => (
              <ClusterRow
                key={c.id}
                cluster={c}
                items={itemsByCluster.get(c.id) ?? []}
              />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
