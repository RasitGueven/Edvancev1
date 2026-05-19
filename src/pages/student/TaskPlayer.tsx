import { useEffect, useRef, useState, type JSX, type KeyboardEvent } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, ArrowRight, ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Card, CardContent } from '@/components/ui/card'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { TaskAnswerArea } from '@/components/edvance/tasks/TaskAnswerArea'
import { ToastBanner } from '@/components/edvance'
import { useAuth } from '@/hooks/useAuth'
import { useBehaviorTracker } from '@/hooks/useBehaviorTracker'
import {
  getClusterById,
  getTaskById,
  getTasksByClusterOrdered,
} from '@/lib/supabase/tasks'
import { persistBehaviorSnapshot } from '@/lib/supabase/behavior'
import { completeTask } from '@/lib/supabase/taskProgress'
import { MathContent } from '@/lib/render/MathContent'
import type { SkillCluster, Task } from '@/types'

type ContentType = Task['content_type']

const TYPE_LABEL: Record<ContentType, string> = {
  exercise: 'Aufgabe',
  exercise_group: 'Mini-Test',
  article: 'Artikel',
  video: 'Video',
  course: 'Kurs',
}

const TYPE_BADGE: Record<ContentType, { bg: string; fg: string }> = {
  exercise: { bg: 'color-mix(in srgb, var(--primary) 12%, transparent)', fg: 'var(--primary)' },
  exercise_group: { bg: 'color-mix(in srgb, var(--primary) 12%, transparent)', fg: 'var(--primary)' },
  article: { bg: 'color-mix(in srgb, var(--success) 12%, transparent)', fg: 'var(--success)' },
  video: { bg: 'color-mix(in srgb, var(--warning) 12%, transparent)', fg: 'var(--warning)' },
  course: { bg: 'color-mix(in srgb, var(--level-purple) 12%, transparent)', fg: 'var(--level-purple)' },
}

export function TaskPlayer(): JSX.Element {
  const { taskId } = useParams<{ taskId: string }>()
  const navigate = useNavigate()

  const [task, setTask] = useState<Task | null>(null)
  const [cluster, setCluster] = useState<SkillCluster | null>(null)
  const [siblings, setSiblings] = useState<Task[]>([])
  const [loading, setLoading] = useState<boolean>(true)
  const [error, setError] = useState<string | null>(null)

  const [hintShown, setHintShown] = useState<boolean>(false)
  const [submitted, setSubmitted] = useState<boolean>(false)
  const [xpToast, setXpToast] = useState<number | null>(null)

  const tracker = useBehaviorTracker()
  const startedTaskRef = useRef<string | null>(null)
  const completedRef = useRef<string | null>(null)
  const { user } = useAuth()

  // Task + Cluster + Siblings laden bei taskId-Aenderung.
  useEffect(() => {
    if (!taskId) return
    let cancelled = false
    setLoading(true)
    setError(null)
    setTask(null)
    setCluster(null)
    setSiblings([])
    setHintShown(false)
    setSubmitted(false)
    setXpToast(null)
    completedRef.current = null

    void (async () => {
      const taskResult = await getTaskById(taskId)
      if (cancelled) return
      if (taskResult.error) {
        setError(taskResult.error)
        setLoading(false)
        return
      }
      const t = taskResult.data
      if (!t) {
        setError('Aufgabe nicht gefunden.')
        setLoading(false)
        return
      }
      setTask(t)

      const followUp: Promise<unknown>[] = []
      if (t.cluster_id) {
        followUp.push(
          getClusterById(t.cluster_id).then(({ data }) => {
            if (!cancelled) setCluster(data)
          }),
        )
        followUp.push(
          getTasksByClusterOrdered(t.cluster_id).then(({ data }) => {
            if (!cancelled) setSiblings(data ?? [])
          }),
        )
      }
      await Promise.all(followUp)
      if (!cancelled) setLoading(false)
    })()

    return () => {
      cancelled = true
    }
  }, [taskId])

  // Behavior-Tracking starten bei Aufgaben-Wechsel (nur exercise).
  useEffect(() => {
    if (!task || task.content_type !== 'exercise') return
    if (startedTaskRef.current === task.id) return
    startedTaskRef.current = task.id
    tracker.startTracking()
  }, [task, tracker])

  const idx = task ? siblings.findIndex((s) => s.id === task.id) : -1
  const prev = idx > 0 ? siblings[idx - 1] : null
  const next = idx >= 0 && idx < siblings.length - 1 ? siblings[idx + 1] : null

  const goBack = (): void => {
    if (cluster) navigate(`/student/cluster/${cluster.id}`)
    else navigate(-1)
  }

  const goNext = (): void => {
    if (next) navigate(`/student/task/${next.id}`)
  }

  const handleHint = (): void => {
    if (hintShown) return
    setHintShown(true)
    tracker.onHintRequested()
  }

  // Abschluss persistieren (idempotent serverseitig; Ref schuetzt zusaetzlich
  // vor Doppel-RPC bei Doppelklick im selben Mount). XP-Toast nur bei
  // Erst-Abschluss – fuer Aufwand/Abschluss, NICHT an Korrektheit gekoppelt.
  const recordCompletion = async (): Promise<void> => {
    if (!task || completedRef.current === task.id) return
    completedRef.current = task.id
    const { data, error } = await completeTask(task.id)
    if (error) {
      console.error('[TaskPlayer] completeTask failed:', error)
      return
    }
    if (data?.newly_completed && data.awarded_xp > 0) {
      setXpToast(data.awarded_xp)
    }
  }

  const handleAnswerSubmit = async (answer: string): Promise<void> => {
    if (!task) return
    tracker.onLastKeystroke()
    const snapshot = tracker.getSnapshot(task.id, answer)
    setSubmitted(true)
    if (user) {
      const { error } = await persistBehaviorSnapshot(task.id, user.id, snapshot)
      if (error) console.error('[TaskPlayer] BehaviorSnapshot persist failed:', error, snapshot)
    }
    await recordCompletion()
  }

  const handleTextChange = (v: string): void => { tracker.onChange(v) }
  const handleKeyDown = (e: KeyboardEvent<HTMLTextAreaElement>): void => { tracker.onKeyDown(e) }
  const handleAcknowledgeNonExercise = async (): Promise<void> => {
    setSubmitted(true)
    await recordCompletion()
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-background">
        <EdvanceNavbar subtitle="Aufgabe" />
        <main className="mx-auto max-w-3xl px-4 py-8">
          <p className="text-sm text-muted">Lade Aufgabe …</p>
        </main>
      </div>
    )
  }

  if (error || !task) {
    return (
      <div className="min-h-screen bg-background">
        <EdvanceNavbar subtitle="Aufgabe" />
        <main className="mx-auto max-w-3xl px-4 py-8">
          <Card>
            <CardContent className="pt-6 text-sm text-destructive">
              {error ?? 'Unbekannter Fehler'}
            </CardContent>
          </Card>
          <Button variant="outline" onClick={() => navigate(-1)} className="mt-4">
            <ArrowLeft className="mr-1 h-4 w-4" /> Zurueck
          </Button>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle={TYPE_LABEL[task.content_type]} />
      {xpToast != null && (
        <ToastBanner
          type="xp"
          message="Stark gemacht!"
          xpAmount={xpToast}
          onClose={() => setXpToast(null)}
        />
      )}
      <main className="mx-auto max-w-3xl px-4 py-6">
        {/* Breadcrumb */}
        <div className="mb-4 flex items-center gap-3 text-sm">
          <button
            type="button"
            onClick={goBack}
            className="flex items-center gap-1 text-muted hover:text-foreground"
          >
            <ArrowLeft className="h-4 w-4" /> Zurueck
          </button>
          {cluster && (
            <span className="text-muted">
              <span className="mx-1">›</span>
              <span className="text-foreground">{cluster.name}</span>
            </span>
          )}
          {idx >= 0 && siblings.length > 0 && (
            <span className="ml-auto text-xs font-semibold uppercase tracking-wider text-muted">
              {idx + 1} / {siblings.length}
            </span>
          )}
        </div>

        {/* Type + Difficulty Badges */}
        <div className="mb-4 flex flex-wrap items-center gap-2">
          <TypeBadge type={task.content_type} />
          {task.difficulty != null && <DifficultyBadge difficulty={task.difficulty} />}
          {task.estimated_minutes != null && (
            <span className="text-xs font-semibold text-muted">
              ~{task.estimated_minutes} Min
            </span>
          )}
          {task.title && (
            <span className="ml-2 truncate text-sm font-semibold text-foreground">
              {task.title}
            </span>
          )}
        </div>

        {/* Hauptbereich – Content je content_type */}
        <Card className="mb-4">
          <CardContent className="pt-6">
            {task.content_type === 'video' ? (
              <VideoBlock task={task} />
            ) : task.content_type === 'exercise_group' || task.content_type === 'course' ? (
              <UnsupportedBlock type={task.content_type} />
            ) : (
              <MathContent text={task.question} />
            )}
          </CardContent>
        </Card>

        {/* Antwort- / Bestaetigungs-Bereich */}
        {!submitted && task.content_type === 'exercise' && (
          <Card className="mb-4">
            <CardContent className="pt-6">
              <TaskAnswerArea
                task={task}
                onSubmit={handleAnswerSubmit}
                onHintToggle={handleHint}
                hintShown={hintShown}
                disabled={submitted}
                onTextChange={handleTextChange}
                onKeyDown={handleKeyDown}
              />
            </CardContent>
          </Card>
        )}

        {!submitted && (task.content_type === 'video' || task.content_type === 'article') && (
          <div className="mb-4 flex justify-end">
            <Button onClick={handleAcknowledgeNonExercise} size="lg">
              {task.content_type === 'video' ? 'Video gesehen ✓' : 'Gelesen ✓'}
            </Button>
          </div>
        )}

        {submitted && (
          <Card className="mb-4">
            <CardContent className="flex items-center justify-between gap-4 py-5">
              <p className="text-sm font-semibold text-foreground">
                {task.content_type === 'exercise'
                  ? 'Danke, weiter geht’s.'
                  : 'Erledigt – weiter geht’s.'}
              </p>
              {next && (
                <Button onClick={goNext} size="lg">
                  Naechste <ArrowRight className="ml-1 h-4 w-4" />
                </Button>
              )}
            </CardContent>
          </Card>
        )}

        {/* Navigation */}
        {siblings.length > 0 && (
          <div className="flex items-center justify-between gap-3">
            <Button
              variant="outline"
              size="sm"
              onClick={() => prev && navigate(`/student/task/${prev.id}`)}
              disabled={!prev}
            >
              <ChevronLeft className="mr-1 h-4 w-4" /> Vorherige
            </Button>
            <span className="text-xs font-semibold text-muted">
              {idx + 1} von {siblings.length} in {cluster?.name ?? 'diesem Cluster'}
            </span>
            <Button
              variant="outline"
              size="sm"
              onClick={() => next && navigate(`/student/task/${next.id}`)}
              disabled={!next}
            >
              Naechste <ChevronRight className="ml-1 h-4 w-4" />
            </Button>
          </div>
        )}
      </main>
    </div>
  )
}

function TypeBadge({ type }: { type: ContentType }): JSX.Element {
  const { bg, fg } = TYPE_BADGE[type]
  return (
    <span
      className="rounded-md px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider"
      style={{ background: bg, color: fg }}
    >
      {TYPE_LABEL[type]}
    </span>
  )
}

function DifficultyBadge({ difficulty }: { difficulty: number }): JSX.Element {
  const dots = [1, 2, 3, 4, 5].map((i) => (
    <span
      key={i}
      className="inline-block h-1.5 w-1.5 rounded-full"
      style={{
        background: i <= difficulty ? 'var(--primary)' : 'var(--border-strong)',
      }}
    />
  ))
  return (
    <span className="inline-flex items-center gap-1 rounded-md px-2 py-1 text-xs font-semibold text-muted">
      {dots}
    </span>
  )
}

function VideoBlock({ task }: { task: Task }): JSX.Element {
  const url = task.question
  if (!url) return <p className="text-sm text-muted">– kein Video-Link –</p>
  return (
    <div className="flex flex-col gap-4">
      <a
        href={url}
        target="_blank"
        rel="noreferrer"
        className="inline-flex items-center gap-2 self-start rounded-lg border-2 border-border bg-card px-4 py-3 text-sm font-semibold text-primary hover:bg-primary/5"
      >
        {task.title ?? 'Video oeffnen'}
      </a>
      {task.solution && <MathContent text={task.solution} />}
    </div>
  )
}

function UnsupportedBlock({ type }: { type: ContentType }): JSX.Element {
  return (
    <div className="rounded-lg border-2 border-dashed border-border p-6 text-center">
      <p className="text-sm font-semibold text-muted">
        Inhaltstyp <code className="rounded bg-border-strong/40 px-1.5 py-0.5">{type}</code>{' '}
        ist noch nicht unterstuetzt.
      </p>
    </div>
  )
}
