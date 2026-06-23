import { useEffect, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ArrowRight, CalendarClock } from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { useAuth } from '@/hooks/useAuth'
import { getStudentByProfile } from '@/lib/supabase/students'
import { getStudentProgress } from '@/lib/supabase/progress'
import { getClustersForStudent, getMicroskillsByIds } from '@/lib/supabase/tasks'
import { getStudentMasteryMatrix } from '@/lib/supabase/competencyMastery'
import { listUpcomingSessionsForStudent } from '@/lib/supabase/sessions'
import { StudentHero } from './StudentHero'
import { ClusterGrid } from './ClusterGrid'
import { aggregateMastery, type MasteryDisplay } from './masteryMatrix'
import type {
  CoachingSession,
  SkillCluster,
  StudentCompetencyMastery,
  StudentProgress,
} from '@/types'

type LoadState = 'loading' | 'no-profile' | 'error' | 'ready'

export function StudentDashboard(): JSX.Element {
  const { t, i18n } = useTranslation('student')
  const { user } = useAuth()

  const [state, setState] = useState<LoadState>('loading')
  const [progress, setProgress] = useState<StudentProgress | null>(null)
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  // Per-Cluster-Mastery aus der Kompetenz-Matrix (eigene Skala, FernUSG-gedeckelt).
  const [clusterMastery, setClusterMastery] = useState<Record<string, MasteryDisplay>>({})
  // Nächste Präsenz-Session als Einstieg in den Session-Flow (best effort).
  const [todaySession, setTodaySession] = useState<CoachingSession | null>(null)

  useEffect(() => {
    if (!user) return
    let cancelled = false
    setState('loading')

    void (async () => {
      const { data: student, error: studentError } = await getStudentByProfile(user.id)
      if (cancelled) return
      if (studentError) {
        setState('error')
        return
      }
      if (!student) {
        setState('no-profile')
        return
      }

      const [progressRes, clustersRes] = await Promise.all([
        getStudentProgress(student.id),
        getClustersForStudent(student.id, student.class_level),
      ])
      if (cancelled) return
      if (clustersRes.error || progressRes.error) {
        setState('error')
        return
      }
      setProgress(progressRes.data ?? null)
      setClusters(clustersRes.data ?? [])
      setState('ready')

      // Nächste Präsenz-Session laden (Best effort, blockiert das Dashboard nicht).
      const { data: sessions } = await listUpcomingSessionsForStudent(student.id)
      if (!cancelled) setTodaySession(sessions?.[0] ?? null)

      // Per-Cluster-Mastery aus der Matrix nachladen (Best effort, blockiert das
      // Dashboard nicht). microskill_id → cluster_id über getMicroskillsByIds
      // auflösen, dann je Cluster FernUSG-gedeckelt aggregieren.
      const { data: rows } = await getStudentMasteryMatrix(student.id)
      if (cancelled || !rows || rows.length === 0) return
      const skillIds = [...new Set(rows.map((r) => r.microskill_id))]
      const { data: skills } = await getMicroskillsByIds(skillIds)
      if (cancelled) return
      const clusterBySkill = new Map(
        (skills ?? []).map((m) => [m.id, m.cluster_id] as [string, string]),
      )
      const rowsByCluster = new Map<string, StudentCompetencyMastery[]>()
      for (const row of rows) {
        const cid = clusterBySkill.get(row.microskill_id)
        if (!cid) continue
        const list = rowsByCluster.get(cid)
        if (list) list.push(row)
        else rowsByCluster.set(cid, [row])
      }
      const byCluster: Record<string, MasteryDisplay> = {}
      for (const [cid, clusterRows] of rowsByCluster) {
        const display = aggregateMastery(clusterRows)
        if (display) byCluster[cid] = display
      }
      setClusterMastery(byCluster)
    })()

    return () => {
      cancelled = true
    }
  }, [user])

  const meta = user?.user_metadata as { full_name?: string } | undefined
  const displayName = meta?.full_name ?? user?.email?.split('@')[0] ?? ''

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={t('dashboard.navSubtitle')} />

      {/* Dunkle „Midnight-Academy"-Bühne unter der Navbar (Hard Rule §3:
          Glass funktioniert nur hier). Glass-Chrome auf der Bühne, dichte
          Inhalte auf soliden Surface-Cards. */}
      <div className="session-stage flex-1">
        {state === 'loading' && (
          <main className="mx-auto max-w-3xl px-4 py-8">
            <LoadingPulse type="card" />
          </main>
        )}

        {state === 'no-profile' && (
          <main className="mx-auto max-w-3xl px-4 py-8">
            <EmptyState
              icon="🎓"
              title={t('dashboard.noProfileTitle')}
              description={t('dashboard.noProfileBody')}
            />
          </main>
        )}

        {state === 'error' && (
          <main className="mx-auto max-w-3xl px-4 py-8">
            <EmptyState icon="⚠️" title={t('dashboard.loadError')} description="" />
          </main>
        )}

        {state === 'ready' && (
          <>
            <StudentHero
              displayName={displayName}
              xpTotal={progress?.xp_total ?? 0}
              level={progress?.level ?? 1}
              presenceWeeks={progress?.presence_streak_weeks ?? 0}
              homeSessions={progress?.home_streak_sessions ?? 0}
              presenceMultiplier={progress?.presence_streak_multiplier ?? 1}
            />
            <main className="mx-auto max-w-3xl px-4 py-8">
              {todaySession && (
                <Link to={`/student/session/${todaySession.id}`} className="mb-6 block">
                  <EdvanceCard
                    variant="blue-pale"
                    accent="primary"
                    className="flex items-center gap-4"
                  >
                    <span className="flex h-12 w-12 flex-none items-center justify-center rounded-full bg-[var(--color-primary)] text-white">
                      <CalendarClock className="h-6 w-6" />
                    </span>
                    <div className="min-w-0 flex-1">
                      <p className="text-eyebrow text-[var(--color-primary)]">
                        {t('dashboard.todaySession.eyebrow')}
                      </p>
                      <p className="text-base font-semibold text-[var(--color-text-primary)]">
                        {t('dashboard.todaySession.title')}
                      </p>
                      <p className="text-sm text-[var(--color-text-secondary)]">
                        {t('dashboard.todaySession.time', {
                          time: new Intl.DateTimeFormat(i18n.language, {
                            hour: '2-digit',
                            minute: '2-digit',
                            timeZone: 'Europe/Berlin',
                          }).format(new Date(todaySession.scheduled_at)),
                        })}
                      </p>
                    </div>
                    <ArrowRight className="h-5 w-5 flex-none text-[var(--color-primary)]" />
                  </EdvanceCard>
                </Link>
              )}

              <h2 className="text-eyebrow text-warm-56">
                {t('dashboard.sectionLabel')}
              </h2>
              {clusters.length === 0 ? (
                <EmptyState
                  icon="🌱"
                  title={t('dashboard.emptyTitle')}
                  description={t('dashboard.emptyBody')}
                />
              ) : (
                <ClusterGrid
                  clusters={clusters}
                  clusterProgress={{}}
                  clusterMasteryById={clusterMastery}
                />
              )}
            </main>
          </>
        )}
      </div>
    </div>
  )
}
