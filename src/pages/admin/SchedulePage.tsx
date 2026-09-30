import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  AdminHeader,
  EdvanceCard,
  EdvanceBadge,
  EmptyState,
  LoadingPulse,
} from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { getCoaches } from '@/lib/supabase/profiles'
import { listStudentsWithName } from '@/lib/supabase/students'
import {
  createSession,
  listSessionsForCoach,
  getSessionStudents,
  addStudentToSession,
  listPlatzKandidaten,
  KEIN_PLATZ_ZUGANG,
} from '@/lib/supabase/sessions'
import { formatSessionDate } from '@/lib/datetime'
import { SELECT_MD as SELECT_CLASS } from '@/lib/formStyles'
import { studentSelectLabel } from '@/lib/utils'
import type {
  Coach,
  CoachingSession,
  SessionStatus,
  StudentWithName,
} from '@/types'

const STATUS_VARIANT: Record<SessionStatus, 'primary' | 'warning' | 'success'> = {
  upcoming: 'primary',
  active: 'warning',
  done: 'success',
}

function SessionRow({
  session,
  students,
}: {
  session: CoachingSession
  students: StudentWithName[]
}): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [assigned, setAssigned] = useState<string[]>([])
  // Nur Kinder mit laufendem Vertrag am Datum der Session (P5b).
  const [kandidaten, setKandidaten] = useState<Set<string>>(new Set())
  const [kandidatenFehler, setKandidatenFehler] = useState(false)
  const [loading, setLoading] = useState(true)
  const [pick, setPick] = useState('')
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const load = (): void => {
    setLoading(true)
    void Promise.all([getSessionStudents(session.id), listPlatzKandidaten(session.id)]).then(
      ([teilnehmer, erlaubt]) => {
        setAssigned((teilnehmer.data ?? []).map((s) => s.student_id))
        setKandidaten(new Set(erlaubt.data ?? []))
        setKandidatenFehler(Boolean(erlaubt.error))
        if (erlaubt.error) setError(erlaubt.error)
        setLoading(false)
      },
    )
  }

  const sessionDatum = new Intl.DateTimeFormat(i18n.language, {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    timeZone: 'Europe/Berlin',
  }).format(new Date(session.scheduled_at))

  useEffect(load, [session.id])

  const nameById = (id: string): string =>
    students.find((s) => s.id === id)?.full_name ?? t('schedule.unbenannt')

  const add = async (): Promise<void> => {
    if (!pick) return
    setBusy(true)
    setError(null)
    const { error: err, code } = await addStudentToSession(session.id, pick)
    setBusy(false)
    if (err) {
      setError(code === KEIN_PLATZ_ZUGANG ? t('schedule.keinZugang', { datum: sessionDatum }) : err)
      return
    }
    setPick('')
    load()
  }

  const available = students.filter((s) => !assigned.includes(s.id) && kandidaten.has(s.id))

  return (
    <EdvanceCard className="flex flex-col gap-3 p-6">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <span className="text-base font-semibold text-[var(--color-text-primary)]">
          {t('schedule.zeitpunkt', { zeit: formatSessionDate(session.scheduled_at) })}
        </span>
        <EdvanceBadge variant={STATUS_VARIANT[session.status]}>
          {t(`schedule.status.${session.status}`)}
        </EdvanceBadge>
      </div>
      {session.room && (
        <span className="text-sm text-[var(--color-text-secondary)]">
          {t('schedule.raumAnzeige', { raum: session.room })}
        </span>
      )}

      <div className="flex flex-col gap-2">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('schedule.teilnehmer')}
        </p>
        {loading ? (
          <LoadingPulse type="list" lines={2} />
        ) : assigned.length === 0 ? (
          <p className="text-sm text-[var(--color-text-tertiary)]">{t('schedule.niemand')}</p>
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

      {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

      {!loading && !kandidatenFehler && available.length === 0 && (
        <p className="text-sm text-[var(--color-text-tertiary)]">{t('schedule.keineKandidaten')}</p>
      )}

      {available.length > 0 && (
        <div className="flex flex-wrap items-center gap-2">
          <select
            aria-label={t('schedule.kindWaehlen')}
            className={SELECT_CLASS}
            value={pick}
            onChange={(e) => setPick(e.target.value)}
          >
            <option value="">{t('schedule.kindZuweisenPlatzhalter')}</option>
            {available.map((s) => (
              <option key={s.id} value={s.id}>
                {studentSelectLabel(s)}
              </option>
            ))}
          </select>
          <Button size="sm" disabled={busy || !pick} onClick={add}>
            {busy ? t('schedule.fuegtHinzu') : t('schedule.zuweisen')}
          </Button>
        </div>
      )}
    </EdvanceCard>
  )
}

export function SchedulePage(): JSX.Element {
  const { t } = useTranslation('admin')
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
      setError(t('schedule.pflichtfelder'))
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
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('schedule.titel')} sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <AdminHeader
          eyebrow={t('schedule.eyebrow')}
          title={t('schedule.titel')}
          description={t('schedule.beschreibung')}
        />

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        <EdvanceCard className="flex flex-col gap-4 p-6">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('schedule.neueSession')}
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div className="flex flex-col gap-2">
              <Label htmlFor="s-coach">{t('schedule.coachPflicht')}</Label>
              <select
                id="s-coach"
                className={SELECT_CLASS}
                value={formCoach}
                onChange={(e) => setFormCoach(e.target.value)}
              >
                <option value="">–</option>
                {coaches.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.full_name ?? t('schedule.unbenannt')}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="s-when">{t('schedule.zeitpunktPflicht')}</Label>
              <Input
                id="s-when"
                type="datetime-local"
                value={when}
                onChange={(e) => setWhen(e.target.value)}
              />
            </div>
            <div className="flex flex-col gap-2">
              <Label htmlFor="s-room">{t('schedule.raum')}</Label>
              <Input
                id="s-room"
                value={room}
                onChange={(e) => setRoom(e.target.value)}
              />
            </div>
          </div>
          <div>
            <Button onClick={submit} disabled={saving}>
              {saving ? t('schedule.speichert') : t('schedule.sessionAnlegen')}
            </Button>
          </div>
        </EdvanceCard>

        <div className="flex flex-col gap-2">
          <Label htmlFor="view-coach">{t('schedule.sessionsVerwalten')}</Label>
          <select
            id="view-coach"
            className={SELECT_CLASS}
            value={viewCoach}
            onChange={(e) => setViewCoach(e.target.value)}
          >
            <option value="">{t('schedule.coachWaehlen')}</option>
            {coaches.map((c) => (
              <option key={c.id} value={c.id}>
                {c.full_name ?? t('schedule.unbenannt')}
              </option>
            ))}
          </select>
        </div>

        {!viewCoach ? null : loadingSessions ? (
          <LoadingPulse type="list" lines={4} />
        ) : sessions.length === 0 ? (
          <EmptyState
            icon="📅"
            title={t('schedule.leer.titel')}
            description={t('schedule.leer.beschreibung')}
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
