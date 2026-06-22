import { useEffect, useMemo, useState, type JSX } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, BookOpen, Check, FileText, FlaskConical, PlayCircle } from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { EdvanceCard, EmptyState, LoadingPulse } from '@/components/edvance'
import { SessionButton } from '@/components/student'
import { useAuth } from '@/hooks/useAuth'
import { getClusterById, getTasksByClusterOrdered } from '@/lib/supabase/tasks'
import { getStudentByProfile } from '@/lib/supabase/students'
import { getCompletedTaskIds } from '@/lib/supabase/taskProgress'
import type { SkillCluster, Task } from '@/types'

type ProgressMap = Record<string, true>

export function ClusterView(): JSX.Element {
  const { clusterId } = useParams<{ clusterId: string }>()
  const navigate = useNavigate()
  const { user } = useAuth()

  const [cluster, setCluster] = useState<SkillCluster | null>(null)
  const [tasks, setTasks] = useState<Task[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)
  const [progress, setProgress] = useState<ProgressMap>({})

  useEffect(() => {
    if (!user) return
    let cancelled = false
    void (async () => {
      const { data: student } = await getStudentByProfile(user.id)
      if (cancelled || !student) return
      const { data: ids } = await getCompletedTaskIds(student.id)
      if (cancelled) return
      const map: ProgressMap = {}
      for (const id of ids ?? []) map[id] = true
      setProgress(map)
    })()
    return () => {
      cancelled = true
    }
  }, [user])

  useEffect(() => {
    if (!clusterId) return
    let cancelled = false
    setLoading(true)
    setError(null)

    void Promise.all([getClusterById(clusterId), getTasksByClusterOrdered(clusterId)]).then(
      ([clusterResult, tasksResult]) => {
        if (cancelled) return
        if (clusterResult.error) setError(clusterResult.error)
        else setCluster(clusterResult.data)
        if (tasksResult.error) setError(tasksResult.error)
        else setTasks(tasksResult.data ?? [])
        setLoading(false)
      },
    )

    return () => {
      cancelled = true
    }
  }, [clusterId])

  const grouped = useMemo(() => {
    const explain: Task[] = []
    const practice: Task[] = []
    const test: Task[] = []
    for (const t of tasks) {
      if (t.content_type === 'video' || t.content_type === 'article') explain.push(t)
      else if (t.content_type === 'exercise') practice.push(t)
      else test.push(t)
    }
    return { explain, practice, test }
  }, [tasks])

  if (loading) {
    return (
      <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
        <EdvanceNavbar subtitle="Cluster" />
        <div className="session-stage flex-1">
          <main className="mx-auto max-w-3xl px-4 py-8">
            <LoadingPulse />
          </main>
        </div>
      </div>
    )
  }

  if (error || !cluster) {
    return (
      <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
        <EdvanceNavbar subtitle="Cluster" />
        <div className="session-stage flex-1">
          <main className="mx-auto max-w-3xl px-4 py-8">
            <EdvanceCard className="text-sm text-destructive">
              {error ?? 'Cluster nicht gefunden.'}
            </EdvanceCard>
            <SessionButton
              variant="ghost"
              onClick={() => navigate(-1)}
              className="mt-4"
              icon={<ArrowLeft className="h-4 w-4" />}
            >
              Zurueck
            </SessionButton>
          </main>
        </div>
      </div>
    )
  }

  const totalExercises = grouped.practice.length
  const totalExplain = grouped.explain.length

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={cluster.name} />
      <div className="session-stage flex-1">
        <main className="mx-auto max-w-3xl px-4 py-6">
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="mb-3 inline-flex min-h-[44px] items-center gap-1 text-sm font-semibold text-warm-56 hover:text-warm"
          >
            <ArrowLeft className="h-4 w-4" /> Zurueck
          </button>

          <h1 className="text-display text-2xl text-warm">{cluster.name}</h1>
          <p className="mt-1 text-sm text-warm-72">
            Klasse {cluster.class_level_min}
            {cluster.class_level_min !== cluster.class_level_max && ` – ${cluster.class_level_max}`}
            {' · '}
            {totalExercises} Aufgaben
            {totalExplain > 0 && ` · ${totalExplain} Erklaerungen`}
          </p>

          {tasks.length === 0 ? (
            <EmptyState
              icon="📚"
              title="Noch keine Inhalte"
              description="Dieser Cluster hat noch keine Aufgaben oder Erklärungen."
            />
          ) : (
            <div className="mt-6 flex flex-col gap-6">
              <Section
                icon={<PlayCircle className="h-4 w-4" />}
                label="Erklaeren"
                tasks={grouped.explain}
                progress={progress}
                onClick={(id) => navigate(`/student/task/${id}`)}
              />
              <Section
                icon={<BookOpen className="h-4 w-4" />}
                label="Ueben"
                tasks={grouped.practice}
                progress={progress}
                onClick={(id) => navigate(`/student/task/${id}`)}
              />
              <Section
                icon={<FlaskConical className="h-4 w-4" />}
                label="Testen"
                tasks={grouped.test}
                progress={progress}
                onClick={(id) => navigate(`/student/task/${id}`)}
              />
            </div>
          )}
        </main>
      </div>
    </div>
  )
}

function Section({
  icon,
  label,
  tasks,
  progress,
  onClick,
}: {
  icon: JSX.Element
  label: string
  tasks: Task[]
  progress: ProgressMap
  onClick: (taskId: string) => void
}): JSX.Element | null {
  if (tasks.length === 0) return null
  return (
    <section>
      <div className="mb-2 flex items-center gap-1.5 text-warm-56">
        {icon}
        <h2 className="text-eyebrow">{label}</h2>
      </div>
      <ol className="flex flex-col gap-2">
        {tasks.map((t) => (
          <li key={t.id}>
            <TaskRow task={t} done={!!progress[t.id]} onClick={() => onClick(t.id)} />
          </li>
        ))}
      </ol>
    </section>
  )
}

function TaskRow({
  task,
  done,
  onClick,
}: {
  task: Task
  done: boolean
  onClick: () => void
}): JSX.Element {
  const subtitle = subtitleFor(task)
  return (
    <button
      type="button"
      onClick={onClick}
      className="flex min-h-[56px] w-full items-center gap-3 rounded-[var(--radius-lg)] bg-white/10 px-4 py-3 text-left transition-[transform,background] duration-200 ease-bounce hover:bg-white/15 active:scale-[0.99]"
    >
      {done ? (
        <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-[var(--radius-full)] bg-[var(--color-mastery-proficient)] shadow-md">
          <Check className="h-4 w-4 text-warm" aria-hidden="true" />
        </span>
      ) : (
        <span
          className="h-7 w-7 shrink-0 rounded-[var(--radius-full)] border-2 border-white/30"
          aria-hidden="true"
        />
      )}
      <RowIcon type={task.content_type} />
      <div className="min-w-0 flex-1">
        <p className="truncate text-sm font-semibold text-warm">
          {task.title ?? task.question?.slice(0, 80) ?? `task:${task.id.slice(0, 8)}`}
        </p>
        {subtitle && <p className="text-xs text-warm-56">{subtitle}</p>}
      </div>
      {task.content_type === 'exercise' && task.difficulty != null && (
        <DifficultyDots difficulty={task.difficulty} />
      )}
    </button>
  )
}

function RowIcon({ type }: { type: Task['content_type'] }): JSX.Element {
  if (type === 'video')
    return <PlayCircle className="h-5 w-5 shrink-0 text-[var(--color-accent-streak)]" />
  if (type === 'article')
    return <FileText className="h-5 w-5 shrink-0 text-[var(--color-success-skilltree)]" />
  if (type === 'exercise_group' || type === 'course')
    return <FlaskConical className="h-5 w-5 shrink-0 text-warm-72" />
  return <BookOpen className="h-5 w-5 shrink-0 text-warm-72" />
}

function DifficultyDots({ difficulty }: { difficulty: number }): JSX.Element {
  return (
    <span className="ml-2 inline-flex shrink-0 items-center gap-0.5">
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          className={`h-1.5 w-1.5 rounded-full ${
            i <= difficulty ? 'bg-white/80' : 'bg-white/20'
          }`}
        />
      ))}
    </span>
  )
}

function subtitleFor(task: Task): string | null {
  if (task.content_type === 'video') {
    return task.estimated_minutes != null ? `${task.estimated_minutes}:00 Min` : 'Video'
  }
  if (task.content_type === 'article') {
    return task.estimated_minutes != null
      ? `Artikel · ~${task.estimated_minutes} Min Lesezeit`
      : 'Artikel'
  }
  if (task.content_type === 'exercise_group') {
    return `Mini-Test · ~${task.estimated_minutes ?? 12} Min`
  }
  if (task.content_type === 'course') return 'Kurs'
  return null
}
