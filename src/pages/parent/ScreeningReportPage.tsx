import { useEffect, useState, type JSX } from 'react'
import {
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
  CompetencyRadar,
  type RadarAxis,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { listStudentsWithName } from '@/lib/supabase/students'
import { listCompletedScreeningTests } from '@/lib/supabase/screening'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import {
  parseScreeningResult,
  type ParsedClusterResult,
} from '@/lib/screening/screeningResult'
import { SCREENING_SUBJECT } from '@/lib/screening/screeningRuntime'
import { formatDateLongDe } from '@/lib/utils'
import type { ScreeningTest, StudentWithName } from '@/types'

type ChildReport = {
  student: StudentWithName
  test: ScreeningTest | null
}

function statusLabel(displayLevel: number): {
  label: string
  variant: 'success' | 'primary' | 'warning'
} {
  if (displayLevel <= 3) return { label: 'Lücke', variant: 'warning' }
  if (displayLevel <= 6) return { label: 'Erkennbar', variant: 'primary' }
  return { label: 'Sicher', variant: 'success' }
}

function clusterLabel(
  c: ParsedClusterResult,
  names: Map<string, string>,
): string {
  return names.get(c.clusterId) ?? c.clusterId
}

export function ScreeningReportPage(): JSX.Element {
  const [reports, setReports] = useState<ChildReport[]>([])
  const [clusterNames, setClusterNames] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let cancelled = false
    void (async () => {
      const { data: students, error: sErr } = await listStudentsWithName()
      if (cancelled) return
      if (sErr) {
        setError(sErr)
        setLoading(false)
        return
      }
      const rows: ChildReport[] = []
      for (const student of students ?? []) {
        const { data } = await listCompletedScreeningTests(student.id)
        rows.push({ student, test: (data ?? [])[0] ?? null })
      }
      const subs = await getSubjects()
      const subject = (subs.data ?? []).find((s) => s.name === SCREENING_SUBJECT)
      const names = new Map<string, string>()
      if (subject) {
        const cl = await getClustersBySubject(subject.id)
        for (const c of cl.data ?? []) names.set(c.id, c.name)
      }
      if (!cancelled) {
        setReports(rows)
        setClusterNames(names)
        setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [])

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Lernstand-Bericht" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Lernstand Ihres Kindes
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            Eine ruhige Übersicht: wo steht Ihr Kind aktuell, was läuft gut, wo
            unterstützen wir gezielt.
          </p>
        </div>

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="card" lines={4} />
        ) : reports.length === 0 ? (
          <EmptyState
            icon="👨‍👩‍👧"
            title="Noch kein Kind hinterlegt"
            description="Sobald Ihr Kind im System ist, sehen Sie hier den aktuellen Lernstand."
          />
        ) : (
          reports.map((r) => (
            <ChildReportCard
              key={r.student.id}
              report={r}
              clusterNames={clusterNames}
            />
          ))
        )}
      </main>
    </div>
  )
}

function ChildReportCard({
  report,
  clusterNames,
}: {
  report: ChildReport
  clusterNames: Map<string, string>
}): JSX.Element {
  const { student, test } = report
  const parsed = test ? parseScreeningResult(test.result_summary) : null
  const completedAt = test?.completed_at
    ? formatDateLongDe(new Date(test.completed_at))
    : null

  const radarAxes: RadarAxis[] = parsed
    ? parsed.clusters.map((c) => ({
        label: clusterLabel(c, clusterNames),
        value: c.displayLevel,
      }))
    : []

  const sorted = parsed ? [...parsed.clusters].sort((a, b) => b.displayLevel - a.displayLevel) : []
  const strengths = sorted.slice(0, 2)
  const gaps = [...sorted].reverse().slice(0, 2)

  return (
    <EdvanceCard variant="default" className="flex flex-col gap-6 p-6">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div>
          <h2 className="text-xl font-bold text-[var(--color-text-primary)]">
            {student.full_name ?? 'Ihr Kind'}
          </h2>
          {student.class_level && (
            <p className="text-xs text-[var(--color-text-tertiary)]">
              Klasse {student.class_level}
            </p>
          )}
        </div>
        {completedAt && (
          <EdvanceBadge variant="muted">Stand: {completedAt}</EdvanceBadge>
        )}
      </div>

      {!parsed || parsed.clusters.length === 0 ? (
        <EmptyState
          icon="🧪"
          title="Lernstand-Check folgt"
          description="Sobald der erste Check abgeschlossen ist, sehen Sie hier die Übersicht."
        />
      ) : (
        <>
          <div className="flex flex-col items-center gap-2">
            <CompetencyRadar axes={radarAxes} max={10} />
            <p className="text-xs text-[var(--color-text-tertiary)]">
              Je weiter außen, desto sicherer ist Ihr Kind in diesem Bereich.
            </p>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <ReportColumn
              title="Stärken"
              accent="success"
              items={strengths.map((c) => ({
                label: clusterLabel(c, clusterNames),
                status: statusLabel(c.displayLevel),
              }))}
              emptyText="Wir lernen Ihr Kind gerade erst kennen."
            />
            <ReportColumn
              title="Entwicklungsfelder"
              accent="warning"
              items={gaps.map((c) => ({
                label: clusterLabel(c, clusterNames),
                status: statusLabel(c.displayLevel),
              }))}
              emptyText="Aktuell keine deutlichen Lücken sichtbar."
            />
          </div>

          {test?.coach_note && (
            <div className="rounded-xl border border-[var(--color-primary-light)] bg-[var(--color-primary-light)] p-4">
              <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-primary)]">
                Notiz vom Coach
              </p>
              <p className="mt-2 text-sm leading-relaxed text-[var(--color-text-primary)]">
                {test.coach_note}
              </p>
            </div>
          )}
        </>
      )}
    </EdvanceCard>
  )
}

function ReportColumn({
  title,
  accent,
  items,
  emptyText,
}: {
  title: string
  accent: 'success' | 'warning'
  items: Array<{ label: string; status: ReturnType<typeof statusLabel> }>
  emptyText: string
}): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <p
        className="text-xs font-semibold uppercase tracking-widest"
        style={{
          color: accent === 'success' ? 'var(--color-success)' : 'var(--color-gold-warning)',
        }}
      >
        {title}
      </p>
      {items.length === 0 ? (
        <p className="text-sm text-[var(--color-text-tertiary)]">{emptyText}</p>
      ) : (
        items.map((it) => (
          <EdvanceCard
            key={it.label}
            className="flex items-center justify-between gap-2 p-3 border border-[var(--color-border)]"
          >
            <span className="text-sm text-[var(--color-text-primary)]">{it.label}</span>
            <EdvanceBadge variant={it.status.variant}>
              {it.status.label}
            </EdvanceBadge>
          </EdvanceCard>
        ))
      )}
    </div>
  )
}
