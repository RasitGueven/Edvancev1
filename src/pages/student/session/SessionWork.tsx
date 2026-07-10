import { useRef, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check, MessageCircle, Sparkles } from 'lucide-react'
import { MathContent } from '@/lib/render/MathContent'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { Button } from '@/components/ui/button'
import { TaskAnswer, emptyAnswer, isAnswerReady } from '@/components/edvance/tasks/answer'
import { evaluate } from '@/lib/answer/evaluators'
import { completeTask } from '@/lib/supabase/taskProgress'
import type { StudentAnswer } from '@/types'
import type { SessionTask } from './sessionQueue'

type Checked = { correct: boolean | null }

export type SessionResult = { solved: number; xp: number }

// Lernpfad-Arbeit in der Session: rendert echte DB-Aufgaben über die Renderer-
// Registry und wertet über evaluators.ts aus. FernUSG / CLAUDE §6: NIE rotes
// „falsch" — nur feiern (richtig) oder neutral (Coach geht es mit dir durch).
//
// Persistenz läuft über denselben serverseitigen Pfad wie /student/task/:taskId:
// completeTask → RPC complete_task (SECURITY DEFINER, idempotent, XP nur beim
// Erst-Abschluss). Wie dort gilt: Abschluss = Abgabe, NICHT Korrektheit.
// Mastery schreibt die Session bewusst NICHT — die bleibt Coach-only (FernUSG).
export function SessionWork({
  tasks,
  onDone,
}: {
  tasks: SessionTask[]
  onDone: (result: SessionResult) => void
}): JSX.Element {
  const { t } = useTranslation('student')
  const [idx, setIdx] = useState(0)
  const task = tasks[idx]
  const [answer, setAnswer] = useState<StudentAnswer>(() => emptyAnswer(task.payload))
  const [checked, setChecked] = useState<Checked | null>(null)
  const [solved, setSolved] = useState(0)
  const [saving, setSaving] = useState(false)
  const xpRef = useRef(0)
  const persistedRef = useRef<Set<string>>(new Set())

  const isLast = idx === tasks.length - 1
  const ready = isAnswerReady(task.payload, answer)

  async function check(): Promise<void> {
    const res = evaluate(task.payload.input_type, task.payload, answer)
    setChecked(res)
    if (res.correct === true) setSolved((s) => s + 1)
    await persist(task.id)
  }

  // Serverseitig idempotent; das Ref verhindert zusätzlich den Doppel-RPC im
  // selben Mount. Ein Persistenz-Fehler blockiert die Session nicht — der/die
  // Schüler:in arbeitet weiter, der Coach sieht den Stand notfalls live.
  async function persist(taskId: string): Promise<void> {
    if (persistedRef.current.has(taskId)) return
    persistedRef.current.add(taskId)
    setSaving(true)
    const { data, error } = await completeTask(taskId)
    setSaving(false)
    if (error) {
      console.error('[SessionWork] completeTask failed:', error)
      return
    }
    if (data?.newly_completed) xpRef.current += data.awarded_xp
  }

  function next(): void {
    if (isLast) {
      onDone({ solved, xp: xpRef.current })
      return
    }
    const ni = idx + 1
    setIdx(ni)
    setAnswer(emptyAnswer(tasks[ni].payload))
    setChecked(null)
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-eyebrow text-warm-56">
        {t('session.work.progress', { current: idx + 1, total: tasks.length })}
      </p>

      <EdvanceCard className="flex flex-col gap-5 p-6">
        <div className="text-base font-medium leading-relaxed text-[var(--color-text-primary)]">
          <MathContent text={task.prompt} />
        </div>

        <TaskAnswer
          key={task.id}
          payload={task.payload}
          answer={answer}
          onChange={setAnswer}
          disabled={checked !== null}
        />

        {checked && <Feedback result={checked} />}

        <div className="flex justify-end">
          {checked ? (
            <Button size="lg" disabled={saving} onClick={next}>
              {isLast ? t('session.work.finish') : t('session.work.next')}
            </Button>
          ) : (
            <Button size="lg" disabled={!ready || saving} onClick={() => void check()}>
              {t('session.work.check')}
            </Button>
          )}
        </div>
      </EdvanceCard>
    </div>
  )
}

function Feedback({ result }: { result: Checked }): JSX.Element {
  const { t } = useTranslation('student')
  if (result.correct === null) {
    return (
      <Banner
        tone="coach"
        icon={<MessageCircle className="h-5 w-5" />}
        text={t('session.feedback.coach')}
      />
    )
  }
  if (result.correct) {
    return (
      <Banner
        tone="success"
        icon={<Sparkles className="h-5 w-5" />}
        text={t('session.feedback.correct')}
      />
    )
  }
  // Bewusst NEUTRAL (kein Rot, kein „falsch") — FernUSG / CLAUDE §6.
  return (
    <Banner tone="neutral" icon={<Check className="h-5 w-5" />} text={t('session.feedback.tryAgain')} />
  )
}

function Banner({
  tone,
  icon,
  text,
}: {
  tone: 'success' | 'neutral' | 'coach'
  icon: JSX.Element
  text: string
}): JSX.Element {
  const cls = {
    success:
      'border-[var(--color-success)] bg-[var(--color-success-light)] text-[var(--color-success)]',
    coach:
      'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)]',
    neutral:
      'border-[var(--color-border)] bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
  }[tone]
  return (
    <div
      className={`flex items-center gap-2.5 rounded-[var(--radius-lg)] border-2 px-4 py-3 text-sm font-semibold ${cls}`}
    >
      {icon}
      <span>{text}</span>
    </div>
  )
}
