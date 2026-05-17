import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { useAuth } from '@/hooks/useAuth'
import { listStudentsWithName } from '@/lib/supabase/students'
import {
  createIntakeSession,
  getIntakeByStudent,
  updateIntakeSession,
} from '@/lib/supabase/intake'
import type {
  IntakeInput,
  IntakeSession,
  StudentWithName,
} from '@/types'

const TEXTAREA_CLASS =
  'min-h-[80px] rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 text-sm text-[var(--text-primary)]'

type FormState = Omit<IntakeInput, 'student_id'> & { known_weak_topics_text: string }

const EMPTY_FORM: FormState = {
  conducted_at: '',
  goals: '',
  motivation: '',
  learning_history: '',
  parent_expectations: '',
  agreed_next_steps: '',
  notes: '',
  known_weak_topics_text: '',
}

function Field({
  label,
  value,
  onChange,
}: {
  label: string
  value: string
  onChange: (v: string) => void
}): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <Label>{label}</Label>
      <textarea
        className={TEXTAREA_CLASS}
        value={value}
        onChange={(e) => onChange(e.target.value)}
      />
    </div>
  )
}

export function IntakePage(): JSX.Element {
  const { user } = useAuth()
  const [students, setStudents] = useState<StudentWithName[]>([])
  const [studentId, setStudentId] = useState<string>('')
  const [sessions, setSessions] = useState<IntakeSession[]>([])
  const [form, setForm] = useState<FormState>(EMPTY_FORM)
  const [editingId, setEditingId] = useState<string | null>(null)
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

  const loadSessions = (sid: string): void => {
    if (!sid) {
      setSessions([])
      return
    }
    getIntakeByStudent(sid).then(({ data, error: err }) => {
      setSessions(data ?? [])
      if (err) setError(err)
    })
  }

  const selectStudent = (sid: string): void => {
    setStudentId(sid)
    setEditingId(null)
    setForm(EMPTY_FORM)
    loadSessions(sid)
  }

  const startEdit = (s: IntakeSession): void => {
    setEditingId(s.id)
    setForm({
      conducted_at: s.conducted_at ?? '',
      goals: s.goals ?? '',
      motivation: s.motivation ?? '',
      learning_history: s.learning_history ?? '',
      parent_expectations: s.parent_expectations ?? '',
      agreed_next_steps: s.agreed_next_steps ?? '',
      notes: s.notes ?? '',
      known_weak_topics_text: (s.known_weak_topics ?? []).join(', '),
    })
  }

  const buildInput = (): Omit<IntakeInput, 'student_id'> => ({
    conducted_at: form.conducted_at || null,
    goals: form.goals || null,
    motivation: form.motivation || null,
    learning_history: form.learning_history || null,
    parent_expectations: form.parent_expectations || null,
    agreed_next_steps: form.agreed_next_steps || null,
    notes: form.notes || null,
    known_weak_topics: form.known_weak_topics_text
      .split(',')
      .map((t) => t.trim())
      .filter(Boolean),
  })

  const save = async (): Promise<void> => {
    if (!studentId) return
    setBusy(true)
    setError(null)
    const payload = buildInput()
    const res = editingId
      ? await updateIntakeSession(editingId, payload)
      : await createIntakeSession({
          student_id: studentId,
          coach_id: user?.id ?? null,
          ...payload,
        })
    setBusy(false)
    if (res.error) {
      setError(res.error)
      return
    }
    setForm(EMPTY_FORM)
    setEditingId(null)
    loadSessions(studentId)
  }

  const finalize = async (id: string): Promise<void> => {
    setBusy(true)
    const { error: err } = await updateIntakeSession(id, { status: 'final' })
    setBusy(false)
    if (err) {
      setError(err)
      return
    }
    loadSessions(studentId)
  }

  const studentLabel = (s: StudentWithName): string =>
    `${s.full_name ?? 'Unbenannt'}${s.class_level ? ` · Kl. ${s.class_level}` : ''}`

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Erstgespräch" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/coach"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Coach-Dashboard
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">
            Erstgespräch-Protokoll
          </h1>
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={3} />
        ) : students.length === 0 ? (
          <EmptyState
            icon="🧑‍🎓"
            title="Keine Schüler"
            description="Es sind noch keine Schüler angelegt. Erst nach der Conversion verfügbar."
          />
        ) : (
          <>
            <EdvanceCard className="flex flex-col gap-2 p-6">
              <Label htmlFor="intake-student">Schüler</Label>
              <select
                id="intake-student"
                className="h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm"
                value={studentId}
                onChange={(e) => selectStudent(e.target.value)}
              >
                <option value="">– Schüler wählen –</option>
                {students.map((s) => (
                  <option key={s.id} value={s.id}>
                    {studentLabel(s)}
                  </option>
                ))}
              </select>
            </EdvanceCard>

            {studentId && (
              <>
                {sessions.length > 0 && (
                  <div className="flex flex-col gap-3">
                    <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                      Bisherige Protokolle
                    </p>
                    {sessions.map((s) => (
                      <EdvanceCard key={s.id} className="flex flex-col gap-2 p-5">
                        <div className="flex items-center justify-between">
                          <span className="text-sm text-[var(--text-secondary)]">
                            {new Date(s.created_at).toLocaleDateString('de-DE')}
                          </span>
                          <EdvanceBadge
                            variant={s.status === 'final' ? 'success' : 'warning'}
                          >
                            {s.status === 'final' ? 'Final' : 'Entwurf'}
                          </EdvanceBadge>
                        </div>
                        {s.goals && (
                          <p className="text-sm text-[var(--text-secondary)]">
                            {s.goals}
                          </p>
                        )}
                        {s.status === 'draft' && (
                          <div className="flex gap-2">
                            <Button size="sm" variant="outline" onClick={() => startEdit(s)}>
                              Bearbeiten
                            </Button>
                            <Button size="sm" disabled={busy} onClick={() => finalize(s.id)}>
                              Finalisieren
                            </Button>
                          </div>
                        )}
                      </EdvanceCard>
                    ))}
                  </div>
                )}

                <EdvanceCard className="flex flex-col gap-4 p-6">
                  <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                    {editingId ? 'Protokoll bearbeiten' : 'Neues Protokoll'}
                  </p>
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="conducted">Gesprächsdatum</Label>
                    <input
                      id="conducted"
                      type="date"
                      className="h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm"
                      value={form.conducted_at ?? ''}
                      onChange={(e) =>
                        setForm({ ...form, conducted_at: e.target.value })
                      }
                    />
                  </div>
                  <Field
                    label="Ziele"
                    value={form.goals ?? ''}
                    onChange={(v) => setForm({ ...form, goals: v })}
                  />
                  <Field
                    label="Motivation"
                    value={form.motivation ?? ''}
                    onChange={(v) => setForm({ ...form, motivation: v })}
                  />
                  <Field
                    label="Lernbiografie"
                    value={form.learning_history ?? ''}
                    onChange={(v) => setForm({ ...form, learning_history: v })}
                  />
                  <Field
                    label="Eltern-Erwartungen"
                    value={form.parent_expectations ?? ''}
                    onChange={(v) => setForm({ ...form, parent_expectations: v })}
                  />
                  <div className="flex flex-col gap-2">
                    <Label htmlFor="weak">Bekannte Schwächen (kommagetrennt)</Label>
                    <input
                      id="weak"
                      className="h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm"
                      value={form.known_weak_topics_text}
                      onChange={(e) =>
                        setForm({ ...form, known_weak_topics_text: e.target.value })
                      }
                    />
                  </div>
                  <Field
                    label="Vereinbarte nächste Schritte"
                    value={form.agreed_next_steps ?? ''}
                    onChange={(v) => setForm({ ...form, agreed_next_steps: v })}
                  />
                  <Field
                    label="Notizen"
                    value={form.notes ?? ''}
                    onChange={(v) => setForm({ ...form, notes: v })}
                  />
                  <div className="flex gap-2">
                    <Button onClick={save} disabled={busy}>
                      {busy ? 'Speichert…' : editingId ? 'Aktualisieren' : 'Protokoll anlegen'}
                    </Button>
                    {editingId && (
                      <Button
                        variant="outline"
                        onClick={() => {
                          setEditingId(null)
                          setForm(EMPTY_FORM)
                        }}
                      >
                        Abbrechen
                      </Button>
                    )}
                  </div>
                </EdvanceCard>
              </>
            )}
          </>
        )}
      </main>
    </div>
  )
}
