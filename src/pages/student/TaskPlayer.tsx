import { useEffect, useRef, useState, type JSX, type KeyboardEvent } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { ArrowLeft, ArrowRight, Check, ChevronLeft, ChevronRight } from 'lucide-react'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { TaskAnswerArea } from '@/components/edvance/tasks/TaskAnswerArea'
import { EdvanceCard, ToastBanner, LoadingPulse } from '@/components/edvance'
import { SessionButton } from '@/components/student'
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
import { AssetList } from '@/lib/render/AssetList'
import {
  TypeBadge,
  DifficultyBadge,
  VideoBlock,
  UnsupportedBlock,
  TYPE_LABEL,
} from './TaskPlayerBlocks'

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
      <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
        <EdvanceNavbar subtitle="Aufgabe" />
        <div className="session-stage flex-1">
          <main className="mx-auto max-w-3xl px-4 py-8">
            <LoadingPulse />
          </main>
        </div>
      </div>
    )
  }

  if (error || !task) {
    return (
      <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
        <EdvanceNavbar subtitle="Aufgabe" />
        <div className="session-stage flex-1">
          <main className="mx-auto max-w-3xl px-4 py-8">
            <EdvanceCard className="text-sm text-destructive">
              {error ?? 'Unbekannter Fehler'}
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

  return (
    <div className="flex min-h-screen flex-col bg-[var(--color-bg-app)]">
      <EdvanceNavbar subtitle={TYPE_LABEL[task.content_type]} />
      {xpToast != null && (
        <ToastBanner
          type="xp"
          message="Stark gemacht!"
          xpAmount={xpToast}
          onClose={() => setXpToast(null)}
        />
      )}
      {/* Dunkle Task-Bühne: warmes Chrome, dichter Lerninhalt auf soliden
          Surface-Cards (Hard Rule §3: kein Glass auf Weiß). */}
      <div className="session-stage flex-1">
        <main className="mx-auto max-w-3xl px-4 py-6">
          <div className="mb-4 flex items-center gap-3 text-sm">
            <button
              type="button"
              onClick={goBack}
              className="flex min-h-[44px] items-center gap-1 text-warm-56 hover:text-warm"
            >
              <ArrowLeft className="h-4 w-4" /> Zurueck
            </button>
            {cluster && (
              <span className="text-warm-56">
                <span className="mx-1">›</span>
                <span className="text-warm">{cluster.name}</span>
              </span>
            )}
            {idx >= 0 && siblings.length > 0 && (
              <span className="ml-auto text-xs font-semibold uppercase tracking-wider text-warm-56">
                {idx + 1} / {siblings.length}
              </span>
            )}
          </div>

          <div className="mb-4 flex flex-wrap items-center gap-2">
            <TypeBadge type={task.content_type} />
            {task.difficulty != null && <DifficultyBadge difficulty={task.difficulty} />}
            {task.estimated_minutes != null && (
              <span className="text-xs font-semibold text-warm-56">
                ~{task.estimated_minutes} Min
              </span>
            )}
            {task.title && (
              <span className="ml-2 truncate text-sm font-semibold text-warm">
                {task.title}
              </span>
            )}
          </div>

          <EdvanceCard className="mb-4">
            {task.content_type === 'video' ? (
              <VideoBlock task={task} />
            ) : task.content_type === 'exercise_group' || task.content_type === 'course' ? (
              <UnsupportedBlock type={task.content_type} />
            ) : (
              <>
              {task.assets && task.assets.length > 0 && <AssetList assets={task.assets} />}
              <MathContent text={task.question} />
            </>
            )}
          </EdvanceCard>

          {!submitted && task.content_type === 'exercise' && (
            <EdvanceCard className="mb-4">
              <TaskAnswerArea
                task={task}
                onSubmit={handleAnswerSubmit}
                onHintToggle={handleHint}
                hintShown={hintShown}
                disabled={submitted}
                onTextChange={handleTextChange}
                onKeyDown={handleKeyDown}
              />
            </EdvanceCard>
          )}

          {!submitted && (task.content_type === 'video' || task.content_type === 'article') && (
            <div className="mb-4 flex justify-end">
              <SessionButton onClick={handleAcknowledgeNonExercise}>
                {task.content_type === 'video' ? 'Video gesehen ✓' : 'Gelesen ✓'}
              </SessionButton>
            </div>
          )}

          {/* Neutral-positive Abschluss-Bestätigung — NIE richtig/falsch
              (FernUSG §6 / Hard Rule §6: kind-seitig kein Korrektheits-Feedback). */}
          {submitted && (
            <div className="mb-4 flex items-center justify-between gap-4 rounded-[var(--radius-lg)] bg-white/10 p-4 text-warm">
              <span className="flex items-center gap-3">
                <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-[var(--radius-full)] bg-white/15">
                  <Check className="h-5 w-5 text-warm" aria-hidden="true" />
                </span>
                <span className="text-sm font-semibold text-warm">
                  {task.content_type === 'exercise'
                    ? 'Danke, weiter geht’s.'
                    : 'Erledigt – weiter geht’s.'}
                </span>
              </span>
              {next && (
                <SessionButton onClick={goNext}>
                  Naechste <ArrowRight className="h-4 w-4" />
                </SessionButton>
              )}
            </div>
          )}

          {siblings.length > 0 && (
            <div className="flex items-center justify-between gap-3">
              <button
                type="button"
                onClick={() => prev && navigate(`/student/task/${prev.id}`)}
                disabled={!prev}
                className="glass-button inline-flex min-h-[44px] items-center gap-1 rounded-[var(--radius-md)] px-4 text-sm font-semibold disabled:pointer-events-none disabled:opacity-40"
              >
                <ChevronLeft className="h-4 w-4" /> Vorherige
              </button>
              <span className="text-xs font-semibold text-warm-56">
                {idx + 1} von {siblings.length} in {cluster?.name ?? 'diesem Cluster'}
              </span>
              <button
                type="button"
                onClick={() => next && navigate(`/student/task/${next.id}`)}
                disabled={!next}
                className="glass-button inline-flex min-h-[44px] items-center gap-1 rounded-[var(--radius-md)] px-4 text-sm font-semibold disabled:pointer-events-none disabled:opacity-40"
              >
                Naechste <ChevronRight className="h-4 w-4" />
              </button>
            </div>
          )}
        </main>
      </div>
    </div>
  )
}
