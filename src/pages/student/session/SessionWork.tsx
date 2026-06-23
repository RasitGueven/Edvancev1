import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check, MessageCircle, Sparkles } from 'lucide-react'
import { MathContent } from '@/lib/render/MathContent'
import { EdvanceCard } from '@/components/edvance/EdvanceCard'
import { Button } from '@/components/ui/button'
import { TaskAnswer, emptyAnswer, isAnswerReady } from '@/components/edvance/tasks/answer'
import { evaluate } from '@/lib/answer/evaluators'
import { WARMUP_TASKS } from './warmup'
import type { StudentAnswer } from '@/types'

type Checked = { correct: boolean | null }

// Lernpfad-Arbeit in der Session: rendert die Aufgaben über die Renderer-
// Registry und wertet über evaluators.ts aus. FernUSG / CLAUDE §6: NIE rotes
// „falsch" — nur feiern (richtig) oder neutral (Coach geht es mit dir durch).
export function SessionWork({ onDone }: { onDone: (solved: number) => void }): JSX.Element {
  const { t } = useTranslation('student')
  const [idx, setIdx] = useState(0)
  const task = WARMUP_TASKS[idx]
  const [answer, setAnswer] = useState<StudentAnswer>(() => emptyAnswer(task.payload))
  const [checked, setChecked] = useState<Checked | null>(null)
  const [solved, setSolved] = useState(0)

  const isLast = idx === WARMUP_TASKS.length - 1
  const ready = isAnswerReady(task.payload, answer)

  function check(): void {
    const res = evaluate(task.payload.input_type, task.payload, answer)
    setChecked(res)
    if (res.correct === true) setSolved((s) => s + 1)
  }

  function next(): void {
    if (isLast) {
      onDone(solved)
      return
    }
    const ni = idx + 1
    setIdx(ni)
    setAnswer(emptyAnswer(WARMUP_TASKS[ni].payload))
    setChecked(null)
  }

  return (
    <div className="flex flex-col gap-4">
      <p className="text-eyebrow text-warm-56">
        {t('session.work.progress', { current: idx + 1, total: WARMUP_TASKS.length })}
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
            <Button size="lg" onClick={next}>
              {isLast ? t('session.work.finish') : t('session.work.next')}
            </Button>
          ) : (
            <Button size="lg" disabled={!ready} onClick={check}>
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
