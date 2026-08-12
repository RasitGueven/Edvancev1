import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { User } from 'lucide-react'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { DashboardTiles } from '@/components/edvance/DashboardTiles'
import { useAuth } from '@/hooks/useAuth'
import { listStudentsWithName } from '@/lib/supabase/students'
import { listReportsForStudent } from '@/lib/supabase/parentReports'
import { listUpcomingSessionsForStudent } from '@/lib/supabase/sessions'
import { formatSessionDate } from '@/lib/datetime'
import { studentSelectLabel } from '@/lib/utils'
import type { CoachingSession, ParentReport, StudentWithName } from '@/types'

/**
 * Eltern-Dashboard.
 *
 * KEINE Gamification (INV-4): XP, Level und Streaks sind die Sprache des
 * Schüler-Surface und motivieren dort. Gegenüber Eltern werden sie zur
 * Leistungskennzahl — ein Streak, der reißt, liest sich als Vorwurf, und ein
 * XP-Stand lädt zum Vergleich mit anderen Kindern ein. Der Elternblick zeigt
 * Termine und die vom Coach freigegebenen Reports, sonst nichts.
 *
 * Ansprache: Sie. Der Screen gehört den Eltern, nicht dem Kind.
 */
type ChildVM = {
  student: StudentWithName
  reports: ParentReport[]
  nextSession: CoachingSession | null
}

const REPORT_SECTIONS = [
  'lernfortschritt',
  'anwesenheit',
  'eingriffe',
  'empfehlung',
] as const

export function ParentDashboard(): JSX.Element {
  const { user } = useAuth()
  const { t, i18n } = useTranslation('parent')
  const [children, setChildren] = useState<ChildVM[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  // Datum über Intl mit der aktiven Locale (§12), nicht toLocaleDateString('de-DE').
  const dateFmt = new Intl.DateTimeFormat(i18n.language, {
    dateStyle: 'medium',
    timeZone: 'Europe/Berlin',
  })

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
        // getStudentProgress ist hier bewusst NICHT mehr geladen: der einzige
        // Konsument waren XP/Level/Streak.
        const [{ data: reports }, { data: sessions }] = await Promise.all([
          listReportsForStudent(student.id),
          listUpcomingSessionsForStudent(student.id),
        ])
        vms.push({
          student,
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
      <EdvanceNavbar subtitle={t('nav.subtitle')} sticky />
      <main className="mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <h1 className="text-2xl font-bold text-[var(--color-text-primary)]">
          {t('page.title')}
        </h1>

        {error && <p className="text-sm text-[var(--color-error-exam)]">{error}</p>}

        {loading ? (
          <LoadingPulse type="list" lines={4} />
        ) : children.length === 0 ? (
          <EmptyState
            icon="👨‍👩‍👧"
            title={t('empty.title')}
            description={t('empty.description')}
          />
        ) : (
          <>
            {children.length > 1 && (
              <>
                <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  {t('quickAccess.title')}
                </h2>
                <DashboardTiles
                  tiles={children.map(({ student }) => ({
                    to: `#child-${student.id}`,
                    anchor: true,
                    icon: <User className="h-5 w-5" />,
                    title: student.full_name ?? t('child.unnamed'),
                    description: t('quickAccess.tile'),
                  }))}
                />
              </>
            )}
            {children.map(({ student, reports, nextSession }) => (
            <div
              key={student.id}
              id={`child-${student.id}`}
              className="scroll-mt-20"
            >
            <EdvanceCard className="flex flex-col gap-4 p-6">
              <span className="text-base font-semibold text-[var(--color-text-primary)]">
                {studentSelectLabel(student)}
              </span>

              <div className="flex flex-col gap-2">
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  {t('nextSession.title')}
                </p>
                {nextSession ? (
                  <p className="text-sm text-[var(--color-text-secondary)]">
                    {formatSessionDate(nextSession.scheduled_at)}
                    {nextSession.room
                      ? ` · ${t('nextSession.room', { room: nextSession.room })}`
                      : ''}
                  </p>
                ) : (
                  <p className="text-sm text-[var(--color-text-tertiary)]">
                    {t('nextSession.none')}
                  </p>
                )}
              </div>

              <div className="flex flex-col gap-2">
                <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                  {t('reports.title')}
                </p>
                {reports.length === 0 ? (
                  <p className="text-sm text-[var(--color-text-tertiary)]">
                    {t('reports.none')}
                  </p>
                ) : (
                  reports.map((r) => (
                    <EdvanceCard
                      key={r.id}
                      className="p-4"
                    >
                      <p className="text-sm font-semibold text-[var(--color-text-primary)]">
                        {t('reports.period', {
                          from: dateFmt.format(new Date(r.period_start)),
                          to: dateFmt.format(new Date(r.period_end)),
                        })}
                      </p>
                      {REPORT_SECTIONS.map((key) => {
                        const v = (r.summary as Record<string, unknown> | null)?.[
                          key
                        ]
                        if (typeof v !== 'string' || v.trim() === '') return null
                        return (
                          <div key={key} className="mt-2">
                            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                              {t(`reports.section.${key}`)}
                            </p>
                            <p className="mt-0.5 text-sm leading-relaxed text-[var(--color-text-secondary)]">
                              {v}
                            </p>
                          </div>
                        )
                      })}
                      {r.coach_note && (
                        <p className="mt-2 text-sm italic leading-relaxed text-[var(--color-text-secondary)]">
                          {r.coach_note}
                        </p>
                      )}
                    </EdvanceCard>
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
