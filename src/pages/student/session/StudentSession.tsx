import { useEffect, useState, type JSX } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ArrowRight, DoorOpen, MapPin, ShieldCheck } from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { getStudentByProfile } from '@/lib/supabase/students'
import { listUpcomingSessionsForStudent, setAttendance } from '@/lib/supabase/sessions'
import { getStudentMasteryMatrix } from '@/lib/supabase/competencyMastery'
import { SessionWork } from './SessionWork'
import { loadSessionQueue, type SessionTask } from './sessionQueue'
import type { CoachingSession } from '@/types'

type Phase = 'loading' | 'notfound' | 'checkin' | 'work' | 'complete'

export function StudentSession(): JSX.Element {
  const { id } = useParams<{ id: string }>()
  const { user } = useAuth()
  const { t } = useTranslation('student')
  const navigate = useNavigate()

  const [phase, setPhase] = useState<Phase>('loading')
  const [studentId, setStudentId] = useState<string | null>(null)
  const [session, setSession] = useState<CoachingSession | null>(null)
  const [awaiting, setAwaiting] = useState(0)
  const [solved, setSolved] = useState(0)
  const [xp, setXp] = useState(0)
  const [saving, setSaving] = useState(false)
  const [tasks, setTasks] = useState<SessionTask[]>([])

  useEffect(() => {
    if (!user || !id) return
    let cancelled = false
    setPhase('loading')

    void (async () => {
      const { data: student } = await getStudentByProfile(user.id)
      if (cancelled) return
      if (!student) {
        setPhase('notfound')
        return
      }
      setStudentId(student.id)

      // Kein getSessionById in der lib (Foundation-Freeze) → über die
      // RLS-gefilterte Upcoming-Liste auflösen. FLAG: dedizierter
      // getSessionForStudent(sessionId) wäre sauberer (laufende Sessions
      // fallen aus dem „upcoming"-Filter). Siehe docs/INPUT_TYPE_CANON.md.
      const { data: sessions } = await listUpcomingSessionsForStudent(student.id)
      if (cancelled) return
      setSession(sessions?.find((s) => s.id === id) ?? null)

      const { data: rows } = await getStudentMasteryMatrix(student.id)
      if (cancelled) return
      setAwaiting((rows ?? []).filter((r) => !r.mastered && r.score >= 85).length)

      const { data: queue } = await loadSessionQueue(student)
      if (cancelled) return
      setTasks(queue ?? [])

      setPhase('checkin')
    })()

    return () => {
      cancelled = true
    }
  }, [user, id])

  async function handleCheckIn(): Promise<void> {
    if (!id || !studentId) return
    setSaving(true)
    await setAttendance(id, studentId, 'present')
    setSaving(false)
    setPhase('work')
  }

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={t('session.checkin.eyebrow')} />
      <div className="session-stage flex-1">
        <main className="mx-auto flex max-w-2xl flex-col gap-6 px-4 py-8">
          <button
            type="button"
            onClick={() => navigate('/student')}
            className="inline-flex items-center gap-1.5 self-start text-xs font-semibold text-warm-56 hover:text-white"
          >
            <DoorOpen className="h-3.5 w-3.5" />
            {t('session.exit')}
          </button>

          {phase === 'loading' && <LoadingPulse type="card" />}

          {phase === 'notfound' && (
            <EmptyState
              icon="🔍"
              title={t('session.notFoundTitle')}
              description={t('session.notFoundBody')}
            />
          )}

          {phase === 'checkin' && (
            <>
              <p className="text-eyebrow text-warm-56">{t('session.checkin.eyebrow')}</p>
              <EdvanceCard className="flex flex-col gap-4 p-6">
                <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
                  {t('session.checkin.title')}
                </h1>
                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                  {t('session.checkin.body')}
                </p>
                {session?.room && (
                  <p className="inline-flex items-center gap-1.5 text-sm font-medium text-[var(--color-text-secondary)]">
                    <MapPin className="h-4 w-4 text-[var(--color-primary)]" />
                    {t('session.checkin.room', { room: session.room })}
                  </p>
                )}
                <Button size="lg" disabled={saving} onClick={() => void handleCheckIn()}>
                  {saving ? t('session.checkin.saving') : t('session.checkin.cta')}
                </Button>
              </EdvanceCard>
            </>
          )}

          {phase === 'work' && (
            <>
              <div className="flex flex-col gap-1">
                <p className="text-eyebrow text-warm-56">{t('session.focus.eyebrow')}</p>
                <h1 className="text-xl font-bold text-white">{t('session.focus.title')}</h1>
                <p className="text-sm leading-relaxed text-warm-56">{t('session.focus.body')}</p>
              </div>
              {tasks.length === 0 ? (
                <EmptyState
                  icon="🎉"
                  title={t('session.work.emptyTitle')}
                  description={t('session.work.emptyBody')}
                />
              ) : (
                <SessionWork
                  tasks={tasks}
                  onDone={({ solved: s, xp: earned }) => {
                    setSolved(s)
                    setXp(earned)
                    setPhase('complete')
                  }}
                />
              )}
            </>
          )}

          {phase === 'complete' && (
            <>
              <p className="text-eyebrow text-warm-56">{t('session.complete.eyebrow')}</p>
              <EdvanceCard className="flex flex-col gap-4 p-6">
                <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
                  {t('session.complete.title')}
                </h1>
                <p className="text-sm text-[var(--color-text-secondary)]">
                  {t('session.complete.solved', { count: solved })}
                </p>
                {xp > 0 && (
                  <p className="text-3xl font-bold text-[var(--color-primary)]">
                    {t('session.complete.xp', { count: xp })}
                  </p>
                )}

                <div className="flex flex-col gap-2 rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
                  <p className="inline-flex items-center gap-2 text-sm font-semibold text-[var(--color-text-primary)]">
                    <ShieldCheck className="h-4 w-4 text-[var(--color-primary)]" />
                    {t('session.mastery.note')}
                  </p>
                  {awaiting > 0 && (
                    <p className="text-sm text-[var(--color-text-secondary)]">
                      {t('session.mastery.awaiting', { count: awaiting })}
                    </p>
                  )}
                </div>

                <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                  {t('session.complete.body')}
                </p>
                <Button asChild size="lg">
                  <Link to="/student">
                    {t('session.lernpfad.cta')}
                    <ArrowRight className="ml-1.5 h-4 w-4" />
                  </Link>
                </Button>
              </EdvanceCard>
            </>
          )}
        </main>
      </div>
    </div>
  )
}
