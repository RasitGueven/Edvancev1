import { useEffect, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import { EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { getCoaches } from '@/lib/supabase/profiles'
import { listStudentsWithName } from '@/lib/supabase/students'
import {
  createSession,
  listSessionsForCoach,
  getSessionStudents,
  addStudentToSession,
} from '@/lib/supabase/sessions'
import { formatSessionDate } from '@/lib/datetime'
import type {
  Coach,
  CoachingSession,
  SessionStatus,
  StudentWithName,
} from '@/types'

const SELECT_CLASS =
  'h-11 rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 text-sm'

const STATUS_VARIANT: Record<SessionStatus, 'primary' | 'warning' | 'success'> = {
  upcoming: 'primary',
  active: 'warning',
  done: 'success',
}

const STATUS_LABEL: Record<SessionStatus, string> = {
  upcoming: 'Geplant',
  active: 'Läuft',
  done: 'Erledigt',
}

function SessionRow({
  session,
  students,
}: {
  session: CoachingSession
  students: StudentWithName[]
}): JSX.Element {
  const [assigned, setAssigned] = useState<string[]>([])
  const [loading, setLoading] = useState(true)
  const [pick, setPick] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = (): void => {
    setLoading(true)
    void getSessionStudents(session.id).then(({ data }) => {
      setAssigned((data ?? []).map((s) => s.student_id))
      setLoading(false)
    })
  }

  useEffect(load, [session.id])

  const nameById = (id: string): string =>
    students.find((s) => s.id === id)?.full_name ?? 'Unbenannt'

  const add = async (): Promise<void> => {
    if (!pick) return
    setBusy(true)
    setError(null)
    const { error: err } = await addStudentToSession(session.id, pick)
    setBusy(false)
    if (err) {
      setError(err)
      return
    }
    setPick('')
    load()
  }

  const available = students.filter((s) => !assigned.includes(s.id))

  return (
    <EdvanceCard className="flex flex-col gap-3 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="text-base font-semibold text-[var(--text-primary)]">
          {formatSessionDate(session.scheduled_at)} Uhr
        </span>
        <EdvanceBadge variant={STATUS_VARIANT[session.status]}>
          {STATUS_LABEL[session.status]}
        </EdvanceBadge>
      </div>
      {session.room && (
        <span className="text-sm text-[var(--text-secondary)]">
          Raum {session.room}
        </span>
      )}

      <div className="flex flex-col gap-2">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
          Teilnehmer
        </p>
        {loading ? (
          <LoadingPulse type="list" lines={2} />
        ) : assigned.length === 0 ? (
          <p className="text-sm text-[var(--text-muted)]">Noch niemand zugewiesen.</p>
        ) : (
          <div className="flex flex-wrap gap-2">
            {assigned.map((id) => (
              <EdvanceBadge key={id} variant="muted">
                {nameById(id)}
              </EdvanceBadge>
            ))}
          </div>
        )}
      </div>

      {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

      {available.length > 0 && (
        <div className="flex flex-wrap items-center gap-2">
          <select
            aria-label="Schüler auswählen"
            className={SELECT_CLASS}
            value={pick}
            onChange={(e) => setPick(e.target.value)}
          >
            <option value="">Schüler zuweisen …</option>
            {available.map((s) => (
              <option key={s.id} value={s.id}>
                {s.full_name ?? 'Unbenannt'}
                {s.class_level ? ` · Kl. ${s.class_level}` : ''}
              </option>
            ))}
          </select>
          <Button size="sm" disabled={busy || !pick} onClick={add}>
            {busy ? 'Fügt hinzu …' : 'Zuweisen'}
          </Button>
        </div>
      )}
    </EdvanceCard>
  )
}

export function SchedulePage(): JSX.Element {
  const [coaches, setCoaches] = useState<Coach[]>([])
  const [students, setStudents] = useState<StudentWithName[]>([])
  const [error, setError] = useState<string | null>(null)

  const [formCoach, setFormCoach] = useState('')
  const [when, setWhen] = useState('')
  const [room, setRoom] = useState('')
  const [saving, setSaving] = useState(false)

  const [viewCoach, setViewCoach] = useState('')
  const [sessions, setSessions] = useState<CoachingSession[]>([])
  const [loadingSessions, setLoadingSessions] = useState(false)

  useEffect(() => {
    void getCoaches().then(({ data, error: e }) => {
      if (e) setError(e)
      setCoaches(data ?? [])
    })
    void listStudentsWithName().then(({ data }) => setStudents(data ?? []))
  }, [])

  const loadSessions = (coachId: string): void => {
    if (!coachId) {
      setSessions([])
      return
    }
    setLoadingSessions(true)
    void listSessionsForCoach(coachId).then(({ data }) => {
      setSessions(data ?? [])
      setLoadingSessions(false)
    })
  }

  useEffect(() => {
    loadSessions(viewCoach)
  }, [viewCoach])

  const submit = async (): Promise<void> => {
    if (!formCoach || !when) {
      setError('Coach und Zeitpunkt sind erforderlich.')
      return
    }
    setSaving(true)
    setError(null)
    const iso = new Date(when).toISOString()
    const { error: err } = await createSession(formCoach, iso, room.trim() || null)
    setSaving(false)
    if (err) {
      setError(err)
      return
    }
    setWhen('')
    setRoom('')
    if (viewCoach === formCoach) loadSessions(viewCoach)
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Stundenplan" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div>
          <Link
            to="/admin"
            className="mb-2 flex items-center gap-1 text-sm text-[var(--text-muted)]"
          >
            <ArrowLeft className="h-4 w-4" /> Admin
          </Link>
          <h1 className="text-2xl font-bold text-[var(--text-primary)]">Stundenplan</h1>
        </div>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
            Neue Session
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="s-coach">Coach *</Label>
              <select
                id="s-coach"
                className={SELECT_CLASS}
                value={formCoach}
                onChange={(e) => setFormCoach(e.target.value)}
              >
                <option value="">–</option>
                {coaches.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.full_name ?? 'Unbenannt'}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="s-when">Zeitpunkt *</Label>
              <Input
                id="s-when"
                type="datetime-local"
                value={when}
                onChange={(e) => setWhen(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="s-room">Raum</Label>
              <Input
                id="s-room"
                value={room}
                onChange={(e) => setRoom(e.target.value)}
              />
            </div>
          </div>
          <div>
            <Button onClick={submit} disabled={saving}>
              {saving ? 'Speichert …' : 'Session anlegen'}
            </Button>
          </div>
        </EdvanceCard>

        <div className="flex flex-col gap-2">
          <Label htmlFor="view-coach">Sessions eines Coaches verwalten</Label>
          <select
            id="view-coach"
            className={SELECT_CLASS}
            value={viewCoach}
            onChange={(e) => setViewCoach(e.target.value)}
          >
            <option value="">Coach wählen …</option>
            {coaches.map((c) => (
              <option key={c.id} value={c.id}>
                {c.full_name ?? 'Unbenannt'}
              </option>
            ))}
          </select>
        </div>

        {!viewCoach ? null : loadingSessions ? (
          <LoadingPulse type="list" lines={4} />
        ) : sessions.length === 0 ? (
          <EmptyState
            icon="📅"
            title="Keine Sessions"
            description="Lege oben die erste Session für diesen Coach an."
          />
        ) : (
          <div className="flex flex-col gap-4">
            {sessions.map((s) => (
              <SessionRow key={s.id} session={s} students={students} />
            ))}
          </div>
        )}
      </main>
    </div>
  )
}
