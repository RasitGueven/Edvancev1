import { useEffect, useMemo, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { BookOpen, ChevronRight, FileText, FlaskConical, PlayCircle, Search, X, Flame } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { XPBar } from '@/components/edvance'
import { DashboardTiles } from '@/components/edvance/DashboardTiles'
import { useAuth } from '@/hooks/useAuth'
import { getClustersBySubject, getSubjects, getTasksByCluster } from '@/lib/supabase/tasks'
import { getStudentByProfile } from '@/lib/supabase/students'
import { getStudentProgress } from '@/lib/supabase/progress'
import type { SkillCluster, Subject, Task } from '@/types'

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
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [selectedSubjectId, setSelectedSubjectId] = useState<string | null>(null)
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [loadingClusters, setLoadingClusters] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  const [xpTotal, setXpTotal] = useState<number>(0)
  const [streakDays, setStreakDays] = useState<number>(0)
  const [level, setLevel] = useState<number>(1)

  useEffect(() => {
    if (!user) return
    let cancelled = false
    void (async () => {
      const { data: student } = await getStudentByProfile(user.id)
      if (cancelled || !student) return
      const { data: progress } = await getStudentProgress(student.id)
      if (cancelled || !progress) return
      setXpTotal(progress.xp_total)
      setStreakDays(progress.streak_days)
      setLevel(progress.level)
    })()
    return () => {
      cancelled = true
    }
  }, [user])

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
    <div className="min-h-screen bg-[var(--background)]">
      <EdvanceNavbar subtitle="Mein Lernplan" />

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

      <main className="mx-auto max-w-3xl px-4 py-8">
        {error && (
          <Card className="mb-6">
            <CardContent className="pt-6 text-sm text-destructive">{error}</CardContent>
          </Card>
        )}

        <h2 className="mb-3 text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
          Schnellzugriff
        </h2>
        <div className="mb-8">
          <DashboardTiles
            tiles={[
              {
                to: '/screening',
                icon: <FlaskConical className="h-5 w-5" />,
                title: 'Screening starten',
                description: 'Zeig, was du kannst – wir finden deinen Lernstand',
              },
              {
                to: '#lernpfad',
                anchor: true,
                icon: <BookOpen className="h-5 w-5" />,
                title: 'Lernpfad',
                description: 'Themen durchsuchen und üben',
              },
            ]}
          />
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
              className="h-12 w-full rounded-xl border border-[var(--border)] bg-white pl-11 pr-11 text-sm shadow-premium-sm focus:border-[var(--color-primary)] focus:shadow-glow-primary focus:outline-none transition-all"
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
          <p className="mt-6 text-sm text-muted">Lade Themen …</p>
        ) : clusters.length === 0 ? (
          <Card className="mt-6">
            <CardContent className="pt-6 text-center text-sm text-muted">
              Noch keine Themen verfuegbar. Frag deinen Coach.
            </CardContent>
          </Card>
        ) : (
          <ClusterGrid clusters={clusters} />
        )}
      </main>
    </div>
  )
}

const CLUSTER_TINTS = [
  { bg: 'var(--color-primary-light)',     fg: 'var(--color-primary)' },
  { bg: 'var(--color-success-light)',     fg: 'var(--color-success)' },
  { bg: 'var(--color-warning-light)',     fg: 'var(--color-warning)' },
  { bg: 'var(--color-info-light)',        fg: 'var(--color-info)' },
  { bg: 'color-mix(in srgb, var(--xp-gold) 14%, white)', fg: '#9A6B00' },
]

function ClusterGrid({ clusters }: { clusters: SkillCluster[] }): JSX.Element {
  return (
    <div className="mt-6 grid gap-4 sm:grid-cols-2">
      {clusters.map((c, idx) => {
        const tint = CLUSTER_TINTS[idx % CLUSTER_TINTS.length]
        return (
          <Link
            key={c.id}
            to={`/student/cluster/${c.id}`}
            className="group block rounded-[var(--radius-xl)] focus:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)]"
          >
            <div className="relative h-full overflow-hidden rounded-[var(--radius-xl)] border border-[var(--border)] bg-gradient-surface p-5 shadow-premium-sm transition-all duration-300 group-hover:shadow-premium-lg group-hover:-translate-y-0.5">
              {/* Decorative blob */}
              <div
                aria-hidden="true"
                className="pointer-events-none absolute -right-8 -top-8 h-24 w-24 rounded-full opacity-60 blur-2xl transition-opacity duration-300 group-hover:opacity-90"
                style={{ background: tint.fg }}
              />

              <div className="relative flex items-start gap-4">
                <span
                  className="flex h-12 w-12 shrink-0 items-center justify-center rounded-[var(--radius-lg)] shadow-premium-sm"
                  style={{ background: tint.bg, color: tint.fg }}
                >
                  <BookOpen className="h-5 w-5" />
                </span>
                <div className="min-w-0 flex-1">
                  <p className="text-base font-bold tracking-tight text-[var(--text-primary)]">
                    {c.name}
                  </p>
                  <p className="mt-0.5 text-xs text-[var(--text-muted)]">
                    Klasse {c.class_level_min}
                    {c.class_level_min !== c.class_level_max && ` – ${c.class_level_max}`}
                  </p>
                </div>
                <ChevronRight className="h-5 w-5 shrink-0 text-[var(--text-muted)] transition-all group-hover:translate-x-0.5 group-hover:text-[var(--color-primary)]" />
              </div>
            </div>
          </Link>
        )
      })}
    </div>
  )
}

function FilterResults({
  loading,
  tasks,
  clusterNameById,
}: {
  loading: boolean
  tasks: Task[]
  clusterNameById: Record<string, string>
}): JSX.Element {
  if (loading) {
    return <p className="mt-6 text-sm text-muted">Suche …</p>
  }
  if (tasks.length === 0) {
    return (
      <Card className="mt-6">
        <CardContent className="pt-6 text-center text-sm text-muted">
          Keine Treffer.
        </CardContent>
      </Card>
    )
  }
  return (
    <div className="mt-6 flex flex-col gap-1.5">
      <p className="mb-1 text-xs font-semibold uppercase tracking-widest text-muted">
        {tasks.length} Treffer
      </p>
      <Card>
        <CardContent className="p-0">
          <ul className="divide-y divide-border">
            {tasks.slice(0, 50).map((t) => (
              <li key={t.id}>
                <Link
                  to={`/student/task/${t.id}`}
                  className="flex min-h-[56px] items-center gap-3 px-4 py-3 transition-colors hover:bg-background"
                >
                  <RowIcon type={t.content_type} />
                  <div className="min-w-0 flex-1">
                    <p className="truncate text-sm font-semibold text-foreground">
                      {t.title ?? t.question?.slice(0, 80) ?? `task:${t.id.slice(0, 8)}`}
                    </p>
                    {t.cluster_id && clusterNameById[t.cluster_id] && (
                      <p className="text-xs text-muted">{clusterNameById[t.cluster_id]}</p>
                    )}
                  </div>
                  <ChevronRight className="h-4 w-4 shrink-0 text-muted" />
                </Link>
              </li>
            ))}
            {tasks.length > 50 && (
              <li className="px-4 py-2 text-xs text-muted">
                … und {tasks.length - 50} weitere – Suche praeziser, um sie zu sehen.
              </li>
            )}
          </ul>
        </CardContent>
      </Card>
    </div>
  )
}

function RowIcon({ type }: { type: ContentType }): JSX.Element {
  if (type === 'video') return <PlayCircle className="h-5 w-5 shrink-0 text-warning" />
  if (type === 'article') return <FileText className="h-5 w-5 shrink-0 text-success" />
  if (type === 'exercise_group' || type === 'course')
    return <FlaskConical className="h-5 w-5 shrink-0 text-primary" />
  return <BookOpen className="h-5 w-5 shrink-0 text-primary" />
}
