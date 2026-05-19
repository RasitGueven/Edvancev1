import { useEffect, useMemo, useState, type JSX } from 'react'
import { Search, X, Flame } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { XPBar, EmptyState, LoadingPulse, EdvanceCard, EdvanceBadge } from '@/components/edvance'
import { StudentBentoGrid } from '@/components/edvance/StudentWidgetGrid'
import { ClusterGrid, FilterResults, type ClusterProgress } from '@/pages/student/ClusterGrid'
import { useAuth } from '@/hooks/useAuth'
import { getClustersBySubject, getSubjects, getTasksByCluster } from '@/lib/supabase/tasks'
import { getStudentByProfile } from '@/lib/supabase/students'
import { getStudentProgress } from '@/lib/supabase/progress'
import { getCompletedTaskIds } from '@/lib/supabase/taskProgress'
import { listUpcomingSessionsForStudent } from '@/lib/supabase/sessions'
import { formatSessionDate } from '@/lib/datetime'
import { getResumePoint, type ResumePoint } from '@/lib/supabase/resume'
import type { CoachingSession, SkillCluster, Student, Subject, Task } from '@/types'

const XP_PER_LEVEL = 500

type ContentType = Task['content_type']
type TypeFilter = 'all' | ContentType

const TYPE_FILTERS: { value: TypeFilter; label: string }[] = [
  { value: 'all', label: 'Alle' },
  { value: 'exercise', label: 'Aufgaben' },
  { value: 'article', label: 'Artikel' },
  { value: 'video', label: 'Videos' },
]

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
  const [streakDays, setStreakDays] = useState<number>(0)
  const [level, setLevel] = useState<number>(1)
  const [resume, setResume] = useState<ResumePoint | null>(null)
  const [nextSession, setNextSession] = useState<CoachingSession | null>(null)
  const [sessionLoading, setSessionLoading] = useState<boolean>(true)

  // Student + progress
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
      setStreakDays(progress.streak_days)
      setLevel(progress.level)
    })()
    return () => {
      cancelled = true
    }
  }, [user])

  // Naechste Session laden, sobald student bekannt.
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

  // Subjects beim Mount.
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

  // Cluster bei Subject-Wechsel.
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

  // Tasks lazy laden, sobald Filter erstmals aktiv wird.
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

  // Cluster-Fortschritt berechnen sobald student + clusters geladen.
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
    <div className="relative min-h-screen overflow-hidden bg-[var(--background)]">
      <EdvanceNavbar subtitle="Mein Lernplan" />

      {/* Ambient background blobs */}
      <div aria-hidden="true" className="pointer-events-none absolute -right-32 top-1/3 h-96 w-96 rounded-full opacity-[0.07] blur-3xl" style={{ background: 'var(--xp-gold)' }} />
      <div aria-hidden="true" className="pointer-events-none absolute -left-24 bottom-1/4 h-80 w-80 rounded-full opacity-[0.08] blur-3xl" style={{ background: 'var(--color-levelup)' }} />
      <div aria-hidden="true" className="pointer-events-none absolute right-1/4 top-2/3 h-64 w-64 rounded-full opacity-[0.06] blur-3xl" style={{ background: 'var(--color-primary)' }} />

      {/* Hero-Section */}
      <section className="relative overflow-hidden bg-gradient-hero noise-overlay">
        <div
          aria-hidden="true"
          className="pointer-events-none absolute -top-24 -right-24 h-72 w-72 rounded-full opacity-20 blur-3xl"
          style={{ background: 'var(--color-moment-gold)' }}
        />
        <div className="mx-auto max-w-3xl px-4 py-8 text-white">
          <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
            <div className="min-w-0">
              <p className="text-eyebrow opacity-70">Heute · Mein Lernplan</p>
              <h1 className="text-display text-3xl mt-1.5 leading-none">
                Hi {displayName} 👋
              </h1>
              <p className="mt-2 text-sm opacity-80 max-w-md">
                Wähle ein Thema oder suche direkt nach einer Aufgabe.
              </p>
            </div>

            <div className="inline-flex items-center gap-2 rounded-full bg-white/10 backdrop-blur-sm px-3 py-1.5 text-xs font-semibold">
              <Flame className="h-3.5 w-3.5 text-[var(--color-moment-gold)]" />
              {streakDays} Tage Streak
            </div>
          </div>

          {/* XP-Card mit Glass-Effekt */}
          <div className="glass-dark rounded-[var(--radius-xl)] p-5">
            <XPBar
              current={xpTotal % XP_PER_LEVEL}
              max={XP_PER_LEVEL}
              level={level}
              levelName={`Level ${level}`}
            />
          </div>
        </div>
      </section>

      {/* Seam: soften the hard edge between hero and body */}
      <div aria-hidden="true" className="h-8 bg-gradient-to-b from-[var(--color-primary)] to-[var(--background)] opacity-20" />

      <main className="mx-auto max-w-3xl px-4 py-8">
        {error && (
          <Card className="mb-6">
            <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
          </Card>
        )}

        {/* Bento-Widget-Grid */}
        <div className="mb-8">
          <StudentBentoGrid
            xpTotal={xpTotal}
            streakDays={streakDays}
            level={level}
            resume={resume}
            loading={!student}
          />
        </div>

        {/* Nächste Session */}
        <div className="mb-8 flex flex-col gap-3">
          <p className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
            Nächste Session
          </p>
          {sessionLoading ? (
            <LoadingPulse type="card" />
          ) : nextSession ? (
            <EdvanceCard className="flex flex-wrap items-center justify-between gap-3 p-6">
              <div className="flex flex-col gap-1">
                <span className="text-base font-semibold text-[var(--text-primary)]">
                  {formatSessionDate(nextSession.scheduled_at)} Uhr
                </span>
                {nextSession.room && (
                  <span className="text-sm text-[var(--text-secondary)]">
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

        {/* Search + Filters */}
        <div id="lernpfad" className="flex flex-col gap-3">
          <div className="relative">
            <Search className="pointer-events-none absolute left-4 top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--text-muted)]" />
            <input
              type="search"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Suche nach Aufgabe, Video, Artikel …"
              className="h-12 w-full rounded-xl border border-[var(--border)] bg-[var(--surface)] pl-11 pr-11 text-sm shadow-premium-sm focus:border-[var(--color-primary)] focus:shadow-glow-primary focus:outline-none transition-all"
            />
            {search && (
              <button
                type="button"
                onClick={() => setSearch('')}
                aria-label="Suche leeren"
                className="absolute right-2 top-1/2 -translate-y-1/2 rounded-md p-1 text-muted hover:bg-background hover:text-foreground"
              >
                <X className="h-4 w-4" />
              </button>
            )}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {TYPE_FILTERS.map((f) => (
              <Button
                key={f.value}
                variant={typeFilter === f.value ? 'default' : 'outline'}
                size="sm"
                onClick={() => setTypeFilter(f.value)}
              >
                {f.label}
              </Button>
            ))}
            {isFiltering && (
              <button
                type="button"
                onClick={clearFilters}
                className="ml-auto text-xs font-semibold text-muted hover:text-foreground"
              >
                Filter zuruecksetzen
              </button>
            )}
          </div>
        </div>

        {/* Subject Tabs (nur wenn >1) */}
        {subjects.length > 1 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {subjects.map((s) => (
              <Button
                key={s.id}
                size="sm"
                variant={s.id === selectedSubjectId ? 'default' : 'outline'}
                onClick={() => setSelectedSubjectId(s.id)}
              >
                {s.name}
              </Button>
            ))}
          </div>
        )}

        {/* Body */}
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
          <ClusterGrid
            clusters={clusters}
            clusterProgress={clusterProgress}
          />
        )}
      </main>
    </div>
  )
}
