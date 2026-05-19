import { useEffect, useState, type JSX } from 'react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { User } from 'lucide-react'
import { EdvanceCard, EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { DashboardTiles } from '@/components/edvance/DashboardTiles'
import { useAuth } from '@/hooks/useAuth'
import { listStudentsWithName } from '@/lib/supabase/students'
import { getStudentProgress } from '@/lib/supabase/progress'
import { listReportsForStudent } from '@/lib/supabase/parentReports'
import { listUpcomingSessionsForStudent } from '@/lib/supabase/sessions'
import { formatSessionDate } from '@/lib/datetime'
import type {
  CoachingSession,
  ParentReport,
  StudentProgress,
  StudentWithName,
} from '@/types'

type ChildVM = {
  student: StudentWithName
  progress: StudentProgress | null
  reports: ParentReport[]
  nextSession: CoachingSession | null
}

const REPORT_SECTIONS: [string, string][] = [
  ['lernfortschritt', 'Lernfortschritt'],
  ['anwesenheit', 'Anwesenheit'],
  ['eingriffe', 'Eingriffe'],
  ['empfehlung', 'Empfehlung'],
]

export function ParentDashboard(): JSX.Element {
  const { user } = useAuth()
  const [children, setChildren] = useState<ChildVM[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    if (!user) return
    let cancelled = false
    void (async () => {
      // RLS filtert students auf die eigenen Kinder (is_parent_of_student).
      const { data: students, error: sErr } = await listStudentsWithName()
      if (cancelled) return
      if (sErr) {
        setError(sErr)
        setLoading(false)
        return
      }
      const vms: ChildVM[] = []
      for (const student of students ?? []) {
        const [{ data: progress }, { data: reports }, { data: sessions }] =
          await Promise.all([
            getStudentProgress(student.id),
            listReportsForStudent(student.id),
            listUpcomingSessionsForStudent(student.id),
          ])
        vms.push({
          student,
          progress,
          reports: reports ?? [],
          nextSession: sessions && sessions.length > 0 ? sessions[0] : null,
        })
      }
      if (!cancelled) {
        setChildren(vms)
        setLoading(false)
      }
    })()
    return () => {
      cancelled = true
    }
  }, [user])

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Eltern-Dashboard" sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <h1 className="text-2xl font-bold text-[var(--text-primary)]">Mein Kind</h1>

        {error && <p className="text-sm text-[var(--destructive)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : children.length === 0 ? (
          <EmptyState
            icon="👨‍👩‍👧"
            title="Noch keine Daten"
            description="Sobald dein Kind angelegt ist, erscheinen hier Fortschritt und Reports."
          />
        ) : (
          <>
            {children.length > 1 && (
              <>
                <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                  Schnellzugriff
                </h2>
                <DashboardTiles
                  tiles={children.map(({ student }) => ({
                    to: `#child-${student.id}`,
                    anchor: true,
                    icon: <User className="h-5 w-5" />,
                    title: student.full_name ?? 'Unbenannt',
                    description: 'Fortschritt & Reports ansehen',
                  }))}
                />
              </>
            )}
            {children.map(({ student, progress, reports, nextSession }) => (
            <div
              key={student.id}
              id={`child-${student.id}`}
              className="scroll-mt-20"
            >
            <EdvanceCard className="flex flex-col gap-4 p-6">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <span className="text-base font-semibold text-[var(--text-primary)]">
                  {student.full_name ?? 'Unbenannt'}
                  {student.class_level ? ` · Kl. ${student.class_level}` : ''}
                </span>
                <EdvanceBadge variant="primary">
                  Level {progress?.level ?? 1}
                </EdvanceBadge>
              </div>

              <div className="flex flex-wrap gap-x-8 gap-y-1 text-sm text-[var(--text-secondary)]">
                <span>{progress?.xp_total ?? 0} XP</span>
                <span>{progress?.streak_days ?? 0} Tage Streak</span>
              </div>

              <div className="flex flex-col gap-2">
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                  Nächste Session
                </p>
                {nextSession ? (
                  <p className="text-sm text-[var(--text-secondary)]">
                    {formatSessionDate(nextSession.scheduled_at)} Uhr
                    {nextSession.room ? ` · Raum ${nextSession.room}` : ''}
                  </p>
                ) : (
                  <p className="text-sm text-[var(--text-muted)]">
                    Noch kein Termin geplant.
                  </p>
                )}
              </div>

              <div className="flex flex-col gap-2">
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                  Reports
                </p>
                {reports.length === 0 ? (
                  <p className="text-sm text-[var(--text-muted)]">
                    Noch kein veröffentlichter Report.
                  </p>
                ) : (
                  reports.map((r) => (
                    <div
                      key={r.id}
                      className="rounded-xl border border-[var(--border)] p-4"
                    >
                      <p className="text-sm font-semibold text-[var(--text-primary)]">
                        {new Date(r.period_start).toLocaleDateString('de-DE')} –{' '}
                        {new Date(r.period_end).toLocaleDateString('de-DE')}
                      </p>
                      {REPORT_SECTIONS.map(([key, label]) => {
                        const v = (r.summary as Record<string, unknown> | null)?.[
                          key
                        ]
                        if (typeof v !== 'string' || v.trim() === '') return null
                        return (
                          <div key={key} className="mt-2">
                            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
                              {label}
                            </p>
                            <p className="mt-0.5 text-sm leading-relaxed text-[var(--text-secondary)]">
                              {v}
                            </p>
                          </div>
                        )
                      })}
                      {r.coach_note && (
                        <p className="mt-2 text-sm italic leading-relaxed text-[var(--text-secondary)]">
                          {r.coach_note}
                        </p>
                      )}
                    </div>
                  ))
                )}
              </div>
            </EdvanceCard>
            </div>
          ))}
          </>
        )}
      </main>
    </div>
  )
}
