import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Lightbulb } from 'lucide-react'
import { SessionShell } from '../components/SessionShell'
import { SessionButton } from '../components/SessionButton'
import { TaskStub } from '../components/TaskStub'
import { HintPanel } from '../components/HintPanel'
import { FeedbackBar } from '../components/FeedbackBar'
import { initialAnswer, answerReady, evaluateTask, type TaskAnswer } from '../components/taskEval'
import { MOCK_SESSION_TASKS } from '@/lib/mocks/session'
import { XP_PER_LEVEL, xpInLevel } from '@/lib/mocks/sessionMachine'
import type { ScreenProps } from '../screenProps'

type Checked = 'none' | 'correct' | 'wrong'

/**
 * Screen 4 — Aufgaben-Flow (Arbeits-Screen). Maximal ruhig: ein Fokus, ein
 * primärer CTA. Hint (Screen 5) gleitet als Panel ein, Feedback (Screen 6)
 * erscheint inline. Keine Celebration-Farben hier.
 */
export function TaskScreen({ state, dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const task = MOCK_SESSION_TASKS[state.taskIndex]

  const [answer, setAnswer] = useState<TaskAnswer>(() => initialAnswer(task))
  const [checked, setChecked] = useState<Checked>('none')
  const [hintOpen, setHintOpen] = useState(false)

  const isLast = state.taskIndex === state.taskCount - 1
  const solved = checked === 'correct'
  const gainedXp = Math.round(task.xp * state.presenceMultiplier)

  const handleAnswerChange = (next: TaskAnswer): void => {
    if (solved) return
    setAnswer(next)
    if (checked === 'wrong') setChecked('none')
  }

  const handleCheck = (): void => {
    const correct = evaluateTask(task, answer)
    dispatch({ type: 'ANSWER', correct, baseXp: task.xp })
    setChecked(correct ? 'correct' : 'wrong')
  }

  const handleHint = (): void => {
    if (state.hintLevel[state.taskIndex] === 0) dispatch({ type: 'REVEAL_HINT' })
    setHintOpen(true)
  }

  const topBar = (
    <div className="mb-6 flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <span className="text-sm font-semibold text-warm-72">
          {t('session.task.progress', {
            current: state.taskIndex + 1,
            total: state.taskCount,
          })}
        </span>
        <span className="rounded-[var(--radius-sm)] bg-white/10 px-2 py-0.5 text-xs font-bold text-warm-72">
          {t('session.task.afb', { level: task.afb })}
        </span>
      </div>
      <div className="h-1 w-full overflow-hidden rounded-[var(--radius-full)] bg-white/10">
        <div
          className="xp-bar-fill h-full rounded-[var(--radius-full)]"
          style={{ width: `${(xpInLevel(state.xp) / XP_PER_LEVEL) * 100}%` }}
        />
      </div>
    </div>
  )

  return (
    <SessionShell maxWidth="md">
      {topBar}

      <div className="flex flex-col gap-5">
        <TaskStub task={task} answer={answer} onAnswerChange={handleAnswerChange} locked={solved} />

        {checked !== 'none' && (
          <FeedbackBar result={checked} xp={checked === 'correct' ? gainedXp : undefined} />
        )}

        {hintOpen && (
          <HintPanel
            hints={task.hints}
            revealed={state.hintLevel[state.taskIndex]}
            onReveal={() => dispatch({ type: 'REVEAL_HINT' })}
            onClose={() => setHintOpen(false)}
          />
        )}

        <div className="flex flex-col-reverse gap-3 pt-1 sm:flex-row sm:items-center sm:justify-between">
          {!solved ? (
            <SessionButton
              variant="ghost"
              icon={<Lightbulb className="h-5 w-5" aria-hidden="true" />}
              onClick={handleHint}
            >
              {t('session.task.hint')}
            </SessionButton>
          ) : (
            <span />
          )}

          {solved ? (
            <SessionButton onClick={() => dispatch({ type: 'NEXT_TASK' })}>
              {isLast ? t('session.task.toMastery') : t('session.task.continue')}
            </SessionButton>
          ) : (
            <SessionButton disabled={!answerReady(answer)} onClick={handleCheck}>
              {t('session.task.check')}
            </SessionButton>
          )}
        </div>
      </div>
    </SessionShell>
  )
}
