import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { useAuth } from '@/hooks/useAuth'
import { getStudentByProfile } from '@/lib/supabase/students'
import { getStudentProgress } from '@/lib/supabase/progress'
import { getClustersForStudent } from '@/lib/supabase/tasks'
import { StudentHero } from './StudentHero'
import { ClusterGrid, type ClusterProgress } from './ClusterGrid'
import type { SkillCluster, StudentProgress } from '@/types'

type LoadState = 'loading' | 'no-profile' | 'error' | 'ready'

// Per-Cluster-Fortschritt ist im Dashboard-MVP noch nicht verdrahtet — die
// ClusterGrid blendet die Balken bei total=0 sauber aus.
const NO_PROGRESS: ClusterProgress = {}

export function StudentDashboard(): JSX.Element {
  const { t } = useTranslation('student')
  const { user } = useAuth()

  const [state, setState] = useState<LoadState>('loading')
  const [progress, setProgress] = useState<StudentProgress | null>(null)
  const [clusters, setClusters] = useState<SkillCluster[]>([])

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
    })()

    return () => {
      cancelled = true
    }
  }, [user])

  const meta = user?.user_metadata as { full_name?: string } | undefined
  const displayName = meta?.full_name ?? user?.email?.split('@')[0] ?? ''

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={t('dashboard.navSubtitle')} />

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
            <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
              {t('dashboard.sectionLabel')}
            </h2>
            {clusters.length === 0 ? (
              <EmptyState
                icon="🌱"
                title={t('dashboard.emptyTitle')}
                description={t('dashboard.emptyBody')}
              />
            ) : (
              <ClusterGrid clusters={clusters} clusterProgress={NO_PROGRESS} />
            )}
          </main>
        </>
      )}
    </div>
  )
}
