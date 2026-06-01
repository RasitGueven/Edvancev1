import { useEffect, useMemo, useState, type JSX } from 'react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EmptyState, LoadingPulse, EdvanceCard, EdvanceBadge } from '@/components/edvance'
import { StudentBentoGrid } from '@/components/edvance/StudentWidgetGrid'
import { ClusterGrid, FilterResults, RecommendationBanner, type ClusterProgress } from '@/pages/student/ClusterGrid'
import { StudentDashboardFilters, TYPE_FILTERS, type TypeFilter } from '@/pages/student/StudentDashboardFilters'
import { useAuth } from '@/hooks/useAuth'
import { getClustersBySubject, getSubjects, getTasksByCluster } from '@/lib/supabase/tasks'
import { getStudentByProfile } from '@/lib/supabase/students'
import { getStudentProgress } from '@/lib/supabase/progress'
import { getCompletedTaskIds } from '@/lib/supabase/taskProgress'
import { listUpcomingSessionsForStudent } from '@/lib/supabase/sessions'
import { formatSessionDate } from '@/lib/datetime'
import { getResumePoint, type ResumePoint } from '@/lib/supabase/resume'
import { useScreeningRecommendation } from '@/pages/student/useScreeningRecommendation'
import { StudentHero } from '@/pages/student/StudentHero'
import type { CoachingSession, SkillCluster, Student, Subject, Task } from '@/types'



export function StudentDashboard(): JSX.Element {
  const { user } = useAuth()
  const firstName = (user?.email?.split('@')[0] ?? 'Lernender').split('.')[0]
  const displayName = firstName.charAt(0).toUpperCase() + firstName.slice(1)

  const [student, setStudent] = useState<Student | null>(null)
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [selectedSubjectId, setSelectedSubjectId] = useState<string | null>(null)
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [clusterProgress, setClusterProgress] = useState<ClusterProgress>({})
  const [loadingClusters, setLoadingClusters] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  const [xpTotal, setXpTotal] = useState<number>(0)
  const [presenceWeeks, setPresenceWeeks] = useState<number>(0)
  const [homeSessions, setHomeSessions] = useState<number>(0)
  const [presenceMultiplier, setPresenceMultiplier] = useState<number>(1)
  const [level, setLevel] = useState<number>(1)
  const [resume, setResume] = useState<ResumePoint | null>(null)
  const [nextSession, setNextSession] = useState<CoachingSession | null>(null)
  const [sessionLoading, setSessionLoading] = useState<boolean>(true)

  useEffect(() => {
    if (!user) return
    let cancelled = false
    void (async () => {
      const { data: s } = await getStudentByProfile(user.id)
      if (cancelled || !s) return
      setStudent(s)
      void getResumePoint(s.id).then(({ data }) => {
        if (!cancelled) setResume(data ?? null)
      })
      const { data: progress } = await getStudentProgress(s.id)
      if (cancelled || !progress) return
      setXpTotal(progress.xp_total)
      setPresenceWeeks(progress.presence_streak_weeks)
      setHomeSessions(progress.home_streak_sessions)
      setPresenceMultiplier(progress.presence_streak_multiplier)
      setLevel(progress.level)
    })()
    return () => {
      cancelled = true
    }
  }, [user])

  useEffect(() => {
    if (!student) return
    let cancelled = false
    setSessionLoading(true)
    void listUpcomingSessionsForStudent(student.id).then(({ data }) => {
      if (cancelled) return
      setNextSession(data && data.length > 0 ? data[0] : null)
      setSessionLoading(false)
    })
    return () => {
      cancelled = true
    }
  }, [student])

  const [search, setSearch] = useState<string>('')
  const [typeFilter, setTypeFilter] = useState<TypeFilter>('all')
  const [allTasks, setAllTasks] = useState<Task[] | null>(null)
  const [loadingTasks, setLoadingTasks] = useState<boolean>(false)

  const lowerSearch = search.trim().toLowerCase()
  const isFiltering = lowerSearch.length > 0 || typeFilter !== 'all'

  useEffect(() => {
    let cancelled = false
    void getSubjects().then(({ data, error: e }) => {
      if (cancelled) return
      if (e) {
        setError(e)
        return
      }
      const list = data ?? []
      setSubjects(list)
      if (list.length > 0) setSelectedSubjectId(list[0].id)
    })
    return () => {
      cancelled = true
    }
  }, [])

  useEffect(() => {
    if (!selectedSubjectId) return
    let cancelled = false
    setLoadingClusters(true)
    setAllTasks(null)
    void getClustersBySubject(selectedSubjectId).then(({ data, error: e }) => {
      if (cancelled) return
      setLoadingClusters(false)
      if (e) {
        setError(e)
        return
      }
      setClusters(data ?? [])
    })
    return () => {
      cancelled = true
    }
  }, [selectedSubjectId])

  useEffect(() => {
    if (!isFiltering || allTasks !== null || clusters.length === 0) return
    let cancelled = false
    setLoadingTasks(true)
    void Promise.all(clusters.map((c) => getTasksByCluster(c.id))).then((results) => {
      if (cancelled) return
      const flat: Task[] = []
      for (const r of results) {
        if (r.data) flat.push(...r.data)
      }
      setAllTasks(flat)
      setLoadingTasks(false)
    })
    return () => {
      cancelled = true
    }
  }, [isFiltering, allTasks, clusters])

  useEffect(() => {
    if (!student || clusters.length === 0) return
    let cancelled = false
    void (async () => {
      const { data: completedIds } = await getCompletedTaskIds(student.id)
      const completedSet = new Set(completedIds ?? [])
      const taskResults = await Promise.all(
        clusters.map((c) => getTasksByCluster(c.id))
      )
      if (cancelled) return
      const prog: ClusterProgress = {}
      clusters.forEach((c, i) => {
        const tasks = taskResults[i].data ?? []
        prog[c.id] = {
          total: tasks.length,
          completed: tasks.filter((t) => completedSet.has(t.id)).length,
        }
      })
      setClusterProgress(prog)
    })()
    return () => {
      cancelled = true
    }
  }, [student, clusters])

  const clusterNameById = useMemo(() => {
    const m: Record<string, string> = {}
    for (const c of clusters) m[c.id] = c.name
    return m
  }, [clusters])

  const {
    clusterStatusById,
    recommendedClusterId,
    orderedClusters,
    showRecommendation,
  } = useScreeningRecommendation(
    student?.id ?? null,
    clusters,
    clusterProgress,
    resume,
  )

  const filteredTasks = useMemo(() => {
    if (!allTasks) return []
    return allTasks.filter((t) => {
      if (typeFilter !== 'all' && t.content_type !== typeFilter) return false
      if (lowerSearch.length === 0) return true
      const inTitle = t.title?.toLowerCase().includes(lowerSearch) ?? false
      const inQuestion = t.question?.toLowerCase().includes(lowerSearch) ?? false
      return inTitle || inQuestion
    })
  }, [allTasks, typeFilter, lowerSearch])

  const clearFilters = (): void => {
    setSearch('')
    setTypeFilter('all')
  }

  return (
    <div className="relative min-h-screen overflow-hidden bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle="Mein Lernplan" />

      <StudentHero
        displayName={displayName}
        xpTotal={xpTotal}
        presenceWeeks={presenceWeeks}
        homeSessions={homeSessions}
        presenceMultiplier={presenceMultiplier}
        level={level}
      />

      <div aria-hidden="true" className="h-8 bg-gradient-to-b from-[var(--color-primary)] to-[var(--color-bg-app)] opacity-20" />

      <main className="mx-auto max-w-3xl px-4 py-8">
        {error && (
          <EdvanceCard className="mb-6">
            <p className="text-sm text-[var(--color-error-exam)]">{error}</p>
          </EdvanceCard>
        )}

        <div className="mb-8">
          <StudentBentoGrid
            xpTotal={xpTotal}
            presenceWeeks={presenceWeeks}
            level={level}
            resume={resume}
            loading={!student}
          />
        </div>

        <div className="mb-8 flex flex-col gap-3">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            Nächste Session
          </p>
          {sessionLoading ? (
            <LoadingPulse type="card" />
          ) : nextSession ? (
            <EdvanceCard className="flex flex-wrap items-center justify-between gap-3 p-6">
              <div className="flex flex-col gap-1">
                <span className="text-base font-semibold text-[var(--color-text-primary)]">
                  {formatSessionDate(nextSession.scheduled_at)} Uhr
                </span>
                {nextSession.room && (
                  <span className="text-sm text-[var(--color-text-secondary)]">
                    Raum {nextSession.room}
                  </span>
                )}
              </div>
              <EdvanceBadge variant="primary">Geplant</EdvanceBadge>
            </EdvanceCard>
          ) : (
            <EmptyState
              icon="📅"
              title="Noch keine Session geplant"
              description="Dein Coach trägt deinen nächsten Termin bald hier ein."
            />
          )}
        </div>

        <StudentDashboardFilters
          search={search}
          onSearchChange={setSearch}
          typeFilter={typeFilter}
          onTypeFilterChange={setTypeFilter}
          isFiltering={isFiltering}
          onClear={clearFilters}
          subjects={subjects}
          selectedSubjectId={selectedSubjectId}
          onSubjectChange={setSelectedSubjectId}
        />

        {isFiltering ? (
          <FilterResults
            loading={loadingTasks}
            tasks={filteredTasks}
            clusterNameById={clusterNameById}
          />
        ) : loadingClusters ? (
          <div className="mt-6">
            <LoadingPulse type="card" />
          </div>
        ) : clusters.length === 0 ? (
          <EmptyState
            icon="📚"
            title="Noch keine Themen"
            description="Frag deinen Coach – er richtet deinen Lernpfad ein."
          />
        ) : (
          <>
            {showRecommendation && recommendedClusterId && (
              <RecommendationBanner
                clusterId={recommendedClusterId}
                clusterName={
                  clusterNameById[recommendedClusterId] ?? 'Dein Lernpfad'
                }
              />
            )}
            <ClusterGrid
              clusters={orderedClusters}
              clusterProgress={clusterProgress}
              clusterStatusById={clusterStatusById}
              recommendedClusterId={recommendedClusterId}
            />
          </>
        )}
      </main>
    </div>
  )
}
