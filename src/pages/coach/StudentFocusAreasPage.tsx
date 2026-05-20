// Coach-/Admin-Editor für die Schwerpunkte einer Schüler:in. Diese fließen
// in den Adaptive-Engine als gewichtete Cluster — fokussierte Bereiche
// werden zuerst und mit höherer Fragenkappe geprüft. Quelle ist meist die
// letzte Klassenarbeit; Coach kann auch eigene Beobachtungen festhalten.

import { useEffect, useMemo, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Plus, X } from 'lucide-react'
import { useAuth } from '@/hooks/useAuth'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { listStudentsWithName } from '@/lib/supabase/students'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import { SCREENING_SUBJECT } from '@/lib/screening/screeningRuntime'
import {
  createFocusArea,
  listFocusAreasForStudent,
  setFocusAreaActive,
} from '@/lib/supabase/studentFocusAreas'
import type {
  SkillCluster,
  StudentFocusArea,
  StudentFocusSource,
  StudentWithName,
} from '@/types'

const SOURCES: { value: StudentFocusSource; label: string }[] = [
  { value: 'klassenarbeit', label: 'Klassenarbeit' },
  { value: 'beobachtung', label: 'Beobachtung' },
  { value: 'erstgespraech', label: 'Erstgespräch' },
  { value: 'sonstiges', label: 'Sonstiges' },
]

const SELECT_CLASS =
  'h-11 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm text-[var(--color-text-primary)]'

export function StudentFocusAreasPage(): JSX.Element {
  const { user } = useAuth()
  const [students, setStudents] = useState<StudentWithName[]>([])
  const [studentId, setStudentId] = useState('')
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [focus, setFocus] = useState<StudentFocusArea[]>([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const [draftCluster, setDraftCluster] = useState('')
  const [draftSource, setDraftSource] = useState<StudentFocusSource>('klassenarbeit')
  const [draftNote, setDraftNote] = useState('')

  useEffect(() => {
    let cancelled = false
    void (async () => {
      const [{ data: stu, error: sErr }, { data: subs }] = await Promise.all([
        listStudentsWithName(),
        getSubjects(),
      ])
      if (cancelled) return
      if (sErr) setError(sErr)
      setStudents(stu ?? [])
      const subject = (subs ?? []).find((s) => s.name === SCREENING_SUBJECT)
      if (subject) {
        const cl = await getClustersBySubject(subject.id)
        if (!cancelled) setClusters(cl.data ?? [])
      }
      if (!cancelled) setLoading(false)
    })()
    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (!studentId) {
      setFocus([])
      return
    }
    setBusy(true)
    void listFocusAreasForStudent(studentId).then(({ data, error: err }) => {
      setFocus(data ?? [])
      if (err) setError(err)
      setBusy(false)
    })
  }, [studentId])

  const clusterById = useMemo(
    () => new Map(clusters.map((c) => [c.id, c])),
    [clusters],
  )

  async function addFocus(): Promise<void> {
    if (!studentId || !draftCluster) return
    const { data, error: err } = await createFocusArea({
      student_id: studentId,
      cluster_id: draftCluster,
      coach_id: user?.id ?? null,
      source: draftSource,
      note: draftNote.trim() || null,
      active: true,
    })
    if (err || !data) {
      setError(err ?? 'Schwerpunkt konnte nicht gespeichert werden')
      return
    }
    setFocus((prev) => [data, ...prev])
    setDraftCluster('')
    setDraftNote('')
  }

  async function deactivate(id: string): Promise<void> {
    const { data, error: err } = await setFocusAreaActive(id, false)
    if (err || !data) {
      setError(err ?? 'Konnte nicht deaktiviert werden')
      return
    }
    setFocus((prev) => prev.map((f) => (f.id === id ? data : f)))
  }

  const activeFocus = focus.filter((f) => f.active)
  const inactiveFocus = focus.filter((f) => !f.active)

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Schwerpunkte" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/coach"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
          >
            <ArrowLeft className="h-4 w-4" /> Coach-Dashboard
          </Link>
          <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
            Schwerpunkte pro Schüler:in
          </h1>
          <p className="mt-1 text-sm text-[var(--color-text-secondary)]">
            Diese Cluster werden im nächsten Screening zuerst und tiefer
            geprüft. Quelle ist meist die letzte Klassenarbeit.
          </p>
        </div>

        {error && <p className="text-sm text-[var(--color-error-gap)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : (
          <>
            <EdvanceCard className="flex flex-col gap-2 p-6">
              <Label htmlFor="sf-student">Schüler:in</Label>
              <select
                id="sf-student"
                className={SELECT_CLASS}
                value={studentId}
                onChange={(e) => setStudentId(e.target.value)}
              >
                <option value="">– wählen –</option>
                {students.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.full_name ?? 'Unbenannt'}
                    {s.class_level ? ` · Kl. ${s.class_level}` : ''}
                  </option>
                ))}
              </select>
            </EdvanceCard>

            {studentId && (
              <EdvanceCard className="flex flex-col gap-3 p-6">
                <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  Neuen Schwerpunkt hinzufügen
                </h2>
                <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
                  <select
                    className={SELECT_CLASS}
                    value={draftCluster}
                    onChange={(e) => setDraftCluster(e.target.value)}
                  >
                    <option value="">– Kompetenz wählen –</option>
                    {clusters.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                  <select
                    className={SELECT_CLASS}
                    value={draftSource}
                    onChange={(e) =>
                      setDraftSource(e.target.value as StudentFocusSource)
                    }
                  >
                    {SOURCES.map((s) => (
                      <option key={s.value} value={s.value}>
                        {s.label}
                      </option>
                    ))}
                  </select>
                </div>
                <textarea
                  value={draftNote}
                  onChange={(e) => setDraftNote(e.target.value)}
                  placeholder="Notiz (optional) — z. B. „Lineare Funktionen schwach in KA 12. Mai"
                  rows={2}
                  className="min-h-[64px] w-full rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-3 text-sm leading-relaxed text-[var(--color-text-primary)] focus:border-[var(--color-primary)] focus:outline-none"
                />
                <Button
                  onClick={() => void addFocus()}
                  disabled={!draftCluster}
                  className="self-start rounded-[var(--radius-md)]"
                >
                  <Plus className="h-4 w-4" /> Schwerpunkt setzen
                </Button>
              </EdvanceCard>
            )}

            {studentId && busy ? (
              <LoadingPulse type="list" lines={2} />
            ) : (
              studentId && (
                <FocusList
                  title="Aktive Schwerpunkte"
                  items={activeFocus}
                  clusterById={clusterById}
                  onDeactivate={(id) => void deactivate(id)}
                  emptyText="Noch keine Schwerpunkte gesetzt — der Screening-Lauf läuft mit gleichgewichteten Clustern."
                />
              )
            )}

            {studentId && inactiveFocus.length > 0 && (
              <FocusList
                title="Archiv"
                items={inactiveFocus}
                clusterById={clusterById}
                onDeactivate={null}
                emptyText=""
              />
            )}
          </>
        )}
      </main>
    </div>
  )
}

function FocusList({
  title,
  items,
  clusterById,
  onDeactivate,
  emptyText,
}: {
  title: string
  items: StudentFocusArea[]
  clusterById: Map<string, SkillCluster>
  onDeactivate: ((id: string) => void) | null
  emptyText: string
}): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </h2>
      {items.length === 0 ? (
        emptyText ? (
          <EmptyState icon="🎯" title="Noch leer" description={emptyText} />
        ) : null
      ) : (
        items.map((f) => {
          const cluster = clusterById.get(f.cluster_id)
          return (
            <EdvanceCard
              key={f.id}
              className="flex flex-col gap-2 p-5"
            >
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="text-sm font-semibold text-[var(--color-text-primary)]">
                    {cluster?.name ?? f.cluster_id}
                  </p>
                  <p className="text-xs text-[var(--color-text-tertiary)]">
                    {SOURCES.find((s) => s.value === f.source)?.label ?? f.source}
                    {' · '}
                    {new Date(f.created_at).toLocaleDateString('de-DE')}
                  </p>
                </div>
                {onDeactivate && (
                  <button
                    type="button"
                    onClick={() => onDeactivate(f.id)}
                    className="rounded-[var(--radius-md)] p-1 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-subtle)]"
                    aria-label="Deaktivieren"
                  >
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>
              {f.note && (
                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                  {f.note}
                </p>
              )}
            </EdvanceCard>
          )
        })
      )}
    </div>
  )
}
