import { useEffect, useMemo, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import {
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
  MasteryBar,
  StatCard,
  CompetencyRadar,
  type RadarAxis,
} from '@/components/edvance'
import { PendingRatingsInbox } from '@/components/edvance/screening/PendingRatingsInbox'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Label } from '@/components/ui/label'
import { listStudentsWithName } from '@/lib/supabase/students'
import { listCompletedScreeningTests } from '@/lib/supabase/screening'
import { getResultsForTest } from '@/lib/supabase/screeningItems'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import { parseScreeningResult } from '@/lib/screening/screeningResult'
import { SCREENING_SUBJECT } from '@/lib/screening/screeningRuntime'
import {
  computeKpis,
  computeMedianByCluster,
  computePendingByCluster,
  formatMedianSeconds,
} from '@/lib/screening/results/kpis'
import { formatDateLongDe } from '@/lib/utils'
import type {
  ScreeningItemResult,
  ScreeningTest,
  StudentWithName,
} from '@/types'

const SELECT_CLASS =
  'h-11 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm text-[var(--color-text-primary)]'

function formatCompleted(at: string | null): string {
  if (!at) return 'Datum unbekannt'
  const d = new Date(at)
  return Number.isNaN(d.getTime()) ? 'Datum unbekannt' : formatDateLongDe(d)
}

function afbVariant(
  afb: 'I' | 'II' | 'III' | null,
): 'muted' | 'success' | 'primary' | 'xp' {
  if (afb === 'I') return 'success'
  if (afb === 'II') return 'primary'
  if (afb === 'III') return 'xp'
  return 'muted'
}

function confidenceMeta(
  c: 'low' | 'medium' | 'high',
): { variant: 'success' | 'muted' | 'warning'; label: string } {
  if (c === 'high') return { variant: 'success', label: 'Konfidenz hoch' }
  if (c === 'medium') return { variant: 'muted', label: 'Konfidenz mittel' }
  return { variant: 'warning', label: 'Konfidenz niedrig' }
}

export function ScreeningResultsPage(): JSX.Element {
  const [students, setStudents] = useState<StudentWithName[]>([])
  const [studentId, setStudentId] = useState('')
  const [tests, setTests] = useState<ScreeningTest[]>([])
  const [selectedTestId, setSelectedTestId] = useState<string | null>(null)
  const [clusterNames, setClusterNames] = useState<Map<string, string>>(new Map())
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [results, setResults] = useState<ScreeningItemResult[]>([])
  const [resultsBusy, setResultsBusy] = useState(false)

  useEffect(() => {
    listStudentsWithName().then(({ data, error: err }) => {
      setStudents(data ?? [])
      setError(err)
      setLoading(false)
    })
  }, [])

  useEffect(() => {
    if (clusterNames.size > 0) return
    void (async () => {
      const subs = await getSubjects()
      const subject = (subs.data ?? []).find((s) => s.name === SCREENING_SUBJECT)
      if (!subject) return
      const cl = await getClustersBySubject(subject.id)
      const map = new Map<string, string>()
      for (const c of cl.data ?? []) map.set(c.id, c.name)
      setClusterNames(map)
    })()
  }, [clusterNames])

  const selectStudent = (sid: string): void => {
    setStudentId(sid)
    setSelectedTestId(null)
    setTests([])
    if (!sid) return
    setBusy(true)
    listCompletedScreeningTests(sid).then(({ data, error: err }) => {
      setTests(data ?? [])
      if (err) setError(err)
      setBusy(false)
    })
  }

  const studentLabel = (s: StudentWithName): string =>
    `${s.full_name ?? 'Unbenannt'}${s.class_level ? ` · Kl. ${s.class_level}` : ''}`

  useEffect(() => {
    if (!selectedTestId) {
      setResults([])
      return
    }
    setResultsBusy(true)
    getResultsForTest(selectedTestId).then(({ data, error: err }) => {
      setResults(data ?? [])
      if (err) setError(err)
      setResultsBusy(false)
    })
  }, [selectedTestId])

  const selectedTest = tests.find((t) => t.id === selectedTestId) ?? null
  const parsed = selectedTest
    ? parseScreeningResult(selectedTest.result_summary)
    : null
  const kpis = useMemo(() => computeKpis(results), [results])

  const medianByCluster = useMemo(() => computeMedianByCluster(results), [results])
  const pendingByCluster = useMemo(() => computePendingByCluster(results), [results])

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Screening-Ergebnisse" sticky />
      <main className="mx-auto flex max-w-5xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/coach"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
          >
            <ArrowLeft className="h-4 w-4" /> Coach-Dashboard
          </Link>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Screening-Ergebnisse
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            Abgeschlossene Lernstand-Diagnosen pro Schüler:in einsehen.
          </p>
        </div>

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : students.length === 0 ? (
          <EmptyState
            icon="🧑‍🎓"
            title="Keine Schüler"
            description="Es sind noch keine Schüler:innen angelegt."
          />
        ) : (
          <>
            <EdvanceCard className="flex flex-col gap-2 p-6">
              <Label htmlFor="sr-student">Schüler:in</Label>
              <select
                id="sr-student"
                className={SELECT_CLASS}
                value={studentId}
                onChange={(e) => selectStudent(e.target.value)}
              >
                <option value="">– Schüler:in wählen –</option>
                {students.map((s) => (
                  <option key={s.id} value={s.id}>
                    {studentLabel(s)}
                  </option>
                ))}
              </select>
            </EdvanceCard>

            {studentId && busy ? (
              <LoadingPulse type="list" lines={2} />
            ) : studentId && tests.length === 0 ? (
              <EmptyState
                icon="🧪"
                title="Keine abgeschlossenen Screenings"
                description="Für diese:n Schüler:in liegt noch kein abgeschlossener Lernstand-Check vor."
              />
            ) : (
              studentId && (
                <div className="flex flex-col gap-3">
                  {tests.map((t) => (
                    <EdvanceCard
                      key={t.id}
                      onClick={() =>
                        setSelectedTestId(t.id === selectedTestId ? null : t.id)
                      }
                      accent={t.id === selectedTestId ? 'left-primary' : 'none'}
                      className="flex cursor-pointer items-center justify-between gap-3 p-5"
                    >
                      <div className="flex flex-col gap-0.5">
                        <span className="text-sm font-semibold text-[var(--color-text-primary)]">
                          {t.subject}
                        </span>
                        <span className="text-xs text-[var(--color-text-tertiary)]">
                          {formatCompleted(t.completed_at)}
                        </span>
                      </div>
                      <EdvanceBadge variant="mastered">Abgeschlossen</EdvanceBadge>
                    </EdvanceCard>
                  ))}
                </div>
              )
            )}

            {selectedTest && (
              <div className="flex flex-col gap-4">
                {!parsed ? (
                  <EmptyState
                    icon="📄"
                    title="Kein auswertbares Ergebnis"
                    description="Dieser Test enthält keine adaptive Auswertung (älterer oder unvollständiger Lauf)."
                  />
                ) : (
                  <>
                    {resultsBusy ? (
                      <LoadingPulse type="card" lines={2} />
                    ) : (
                      <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
                        <StatCard
                          icon="📝"
                          label="Beantwortet"
                          value={parsed.overallAnswered}
                        />
                        <StatCard
                          icon="⚡"
                          label="Trefferquote"
                          value={`${parsed.overallPct}%`}
                          color="var(--color-success)"
                        />
                        <StatCard
                          icon="⏱️"
                          label="Ø Zeit / Aufgabe"
                          value={formatMedianSeconds(kpis.medianDurationMs)}
                          color="var(--color-primary)"
                        />
                        <StatCard
                          icon="🧑‍🏫"
                          label="Wartet auf Bewertung"
                          value={kpis.manualPending}
                          color={
                            kpis.manualPending > 0
                              ? 'var(--color-gold-warning)'
                              : 'var(--color-text-tertiary)'
                          }
                        />
                      </div>
                    )}

                    {parsed.clusters.length === 0 ? (
                      <EmptyState
                        icon="🧮"
                        title="Keine Cluster-Daten"
                        description="Der Lauf enthält keine auswertbaren Cluster."
                      />
                    ) : (
                      <EdvanceCard className="flex flex-col items-center gap-2 p-6">
                        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                          Kompetenz-Profil
                        </h2>
                        <CompetencyRadar
                          axes={parsed.clusters.map<RadarAxis>((c) => ({
                            label: clusterNames.get(c.clusterId) ?? c.clusterId,
                            value: c.displayLevel,
                          }))}
                          max={10}
                        />
                      </EdvanceCard>
                    )}

                    {parsed.clusters.length > 0 && (
                      <div className="flex flex-col gap-4">
                        <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                          Kompetenzbereiche
                        </h2>
                        {parsed.clusters.map((c) => {
                          const med = medianByCluster.get(c.clusterId) ?? 0
                          const pending = pendingByCluster.get(c.clusterId) ?? c.pending
                          const conf = confidenceMeta(c.confidence)
                          return (
                            <EdvanceCard
                              key={c.clusterId}
                              className="flex flex-col gap-3 p-5"
                            >
                              <div className="flex flex-wrap items-center justify-between gap-2">
                                <span className="text-base font-semibold text-[var(--color-text-primary)]">
                                  {clusterNames.get(c.clusterId) ?? c.clusterId}
                                </span>
                                <div className="flex flex-wrap items-center gap-2">
                                  {pending > 0 && (
                                    <EdvanceBadge variant="warning">
                                      {pending} offen
                                    </EdvanceBadge>
                                  )}
                                  <EdvanceBadge variant={afbVariant(c.reachedAfb)}>
                                    {c.reachedAfb ? `AFB ${c.reachedAfb}` : 'unter AFB I'}
                                  </EdvanceBadge>
                                  <EdvanceBadge variant={conf.variant}>
                                    {conf.label}
                                  </EdvanceBadge>
                                </div>
                              </div>
                              <MasteryBar level={c.displayLevel} showLabel />
                              <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-[var(--color-text-secondary)]">
                                <span>Beantwortet: {c.answered}</span>
                                <span>Richtig: {c.correct}</span>
                                <span>Trefferquote: {Math.round(c.mastery * 100)}%</span>
                                {med > 0 && (
                                  <span>Ø Zeit: {formatMedianSeconds(med)}</span>
                                )}
                              </div>
                            </EdvanceCard>
                          )
                        })}
                      </div>
                    )}

                    {!resultsBusy && (
                      <PendingRatingsInbox
                        results={results}
                        clusterNames={clusterNames}
                      />
                    )}
                  </>
                )}
              </div>
            )}
          </>
        )}
      </main>
    </div>
  )
}
