// Read-only Coach-/Admin-Sicht auf abgeschlossene adaptive Screenings:
// Schüler wählen → abgeschlossene Läufe listen → Cluster-Ergebnisse +
// Gesamtwerte. Coach = Beobachter; Punktzahlen hier erlaubt (nicht die
// §6-Schüler-Regel). Robust bei null/altem/nicht-adaptivem Summary.

import { useEffect, useState } from 'react'
import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import {
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
  MasteryBar,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Label } from '@/components/ui/label'
import { listStudentsWithName } from '@/lib/supabase/students'
import { listCompletedScreeningTests } from '@/lib/supabase/screening'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import { parseScreeningResult } from '@/lib/screening/screeningResult'
import { SCREENING_SUBJECT } from '@/lib/screening/screeningRuntime'
import { formatDateLongDe } from '@/lib/utils'
import type { ScreeningTest, StudentWithName } from '@/types'

const SELECT_CLASS =
  'h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm text-[var(--text-primary)]'

function formatCompleted(at: string | null): string {
  if (!at) return 'Datum unbekannt'
  const d = new Date(at)
  return Number.isNaN(d.getTime()) ? 'Datum unbekannt' : formatDateLongDe(d)
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

  useEffect(() => {
    listStudentsWithName().then(({ data, error: err }) => {
      setStudents(data ?? [])
      setError(err)
      setLoading(false)
    })
  }, [])

  // Cluster-Namen einmalig auflösen (Fach fix = SCREENING_SUBJECT).
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

  const selectedTest = tests.find((t) => t.id === selectedTestId) ?? null
  const parsed = selectedTest
    ? parseScreeningResult(selectedTest.result_summary)
    : null

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Screening-Ergebnisse" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/coach"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Coach-Dashboard
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Screening-Ergebnisse
          </h1>
          <p className="mt-1 text-sm text-[var(--text-secondary)]">
            Abgeschlossene Lernstand-Diagnosen pro Schüler:in einsehen.
          </p>
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

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
                        <span className="text-sm font-semibold text-[var(--text-primary)]">
                          {t.subject}
                        </span>
                        <span className="text-xs text-[var(--text-muted)]">
                          {formatCompleted(t.completed_at)}
                        </span>
                      </div>
                      <EdvanceBadge variant="success">Abgeschlossen</EdvanceBadge>
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
                    <div className="grid grid-cols-2 gap-4">
                      <EdvanceCard className="flex flex-col gap-1 p-6">
                        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                          Beantwortet gesamt
                        </span>
                        <span className="text-3xl font-bold text-[var(--text-primary)]">
                          {parsed.overallAnswered}
                        </span>
                      </EdvanceCard>
                      <EdvanceCard className="flex flex-col gap-1 p-6">
                        <span className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                          Richtig gesamt
                        </span>
                        <span className="text-3xl font-bold text-[var(--text-primary)]">
                          {parsed.overallPct}%
                        </span>
                      </EdvanceCard>
                    </div>

                    {parsed.clusters.length === 0 ? (
                      <EmptyState
                        icon="🧮"
                        title="Keine Cluster-Daten"
                        description="Der Lauf enthält keine auswertbaren Cluster."
                      />
                    ) : (
                      parsed.clusters.map((c) => (
                        <EdvanceCard
                          key={c.clusterId}
                          className="flex flex-col gap-3 p-5"
                        >
                          <div className="flex flex-wrap items-center justify-between gap-2">
                            <span className="text-sm font-semibold text-[var(--text-primary)]">
                              {clusterNames.get(c.clusterId) ?? c.clusterId}
                            </span>
                            <EdvanceBadge variant="muted">
                              Stufe {c.estimatedLevel}
                            </EdvanceBadge>
                          </div>
                          <MasteryBar level={c.displayLevel} showLabel />
                          <div className="flex flex-wrap gap-x-6 gap-y-1 text-xs text-[var(--text-secondary)]">
                            <span>Beantwortet: {c.answered}</span>
                            <span>Richtig: {c.correct}</span>
                            <span>Trefferquote: {Math.round(c.mastery * 100)}%</span>
                          </div>
                        </EdvanceCard>
                      ))
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
