import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EdvanceBadge, ToastBanner } from '@/components/edvance'
import { MCWidget } from '@/components/edvance/tasks/MCWidget'
import { NumericWidget } from '@/components/edvance/tasks/NumericWidget'
import { OpenWidget } from '@/components/edvance/tasks/OpenWidget'
import { MatchingWidget, type MatchPairs } from '@/components/edvance/tasks/MatchingWidget'
import { MultiStepWidget } from '@/components/edvance/tasks/MultiStepWidget'
import { cn } from '@/lib/utils'
import type { MockTask, MockTaskMC, MockTaskFreeInput, MockTaskMatching, MockTaskSteps } from '@/lib/mocks/firstSession'
import type { ScreeningTeilaufgabe } from '@/types'

interface TaskStepProps {
  tasks: MockTask[]
  taskIndex: number
  onSubmit: (correct: boolean, xpEarned: number) => void
  onAdvance: () => void
}

export function TaskStep({
  tasks,
  taskIndex,
  onSubmit,
  onAdvance,
}: TaskStepProps): JSX.Element {
  const { t } = useTranslation('student')
  const task: MockTask = tasks[taskIndex]
  const isLast = taskIndex === tasks.length - 1

  const [submitted, setSubmitted] = useState<boolean>(false)
  const [toastOpen, setToastOpen] = useState<boolean>(false)
  const [isCorrect, setIsCorrect] = useState<boolean>(false)

  const [mcSelected, setMcSelected] = useState<number | null>(null)
  const [freeText, setFreeText] = useState<string>('')
  const [matchingPairs, setMatchingPairs] = useState<MatchPairs>(new Map())
  const [stepsValues, setStepsValues] = useState<Record<string, string>>({})

  const handleSubmit = (): void => {
    if (submitted) return

    let correct = false

    if (task.inputType === 'MC') {
      if (mcSelected === null) return
      correct = mcSelected === (task as MockTaskMC).correctIndex
    } else if (task.inputType === 'FREE_INPUT') {
      const answer = freeText.trim()
      if (!answer) return
      correct = answer === (task as MockTaskFreeInput).correctAnswer
    } else if (task.inputType === 'MATCHING') {
      const taskData = task as MockTaskMatching
      if (matchingPairs.size !== taskData.left.length) return
      correct = isMatchingCorrect(matchingPairs, taskData.correctPairs)
    } else if (task.inputType === 'STEPS') {
      const taskData = task as MockTaskSteps
      if (!taskData.steps.every((s) => (stepsValues[s.key] ?? '').trim().length > 0)) return
      correct = isStepsCorrect(stepsValues, taskData.steps)
    }

    setSubmitted(true)
    setIsCorrect(correct)
    if (correct) {
      setToastOpen(true)
      onSubmit(true, task.xp)
    } else {
      onSubmit(false, 0)
    }
  }

  return (
    <div className="flex flex-col gap-6 animate-fly-in">
      {toastOpen && (
        <ToastBanner
          type="xp"
          message={t('firstSession.task.xpToast')}
          xpAmount={task.xp}
          onClose={() => setToastOpen(false)}
        />
      )}

      <div className="flex items-center justify-between">
        <EdvanceBadge variant="primary">
          {t('firstSession.task.progress', {
            current: taskIndex + 1,
            total: tasks.length,
          })}
        </EdvanceBadge>
        <EdvanceBadge variant="muted">AFB {task.difficulty}</EdvanceBadge>
      </div>

      <EdvanceCard>
        <div className="flex flex-col gap-5">
          <p className="text-xs font-semibold uppercase tracking-wider text-[var(--color-text-tertiary)]">
            {task.clusterName}
          </p>
          <p className="text-lg font-semibold text-[var(--color-text-primary)]">
            {task.question}
          </p>

          {task.inputType === 'MC' && (
            <MCWidget
              options={(task as MockTaskMC).options}
              selected={mcSelected}
              onChange={setMcSelected}
              disabled={submitted}
            />
          )}

          {task.inputType === 'FREE_INPUT' && (
            <NumericWidget
              value={freeText}
              onChange={setFreeText}
              disabled={submitted}
            />
          )}

          {task.inputType === 'MATCHING' && (
            <MatchingWidget
              left={(task as MockTaskMatching).left}
              right={(task as MockTaskMatching).right}
              pairs={matchingPairs}
              onChange={setMatchingPairs}
              disabled={submitted}
            />
          )}

          {task.inputType === 'STEPS' && (
            <MultiStepWidget
              steps={convertMockStepsToTeilaufgaben((task as MockTaskSteps).steps)}
              values={stepsValues}
              onChange={(key, value) => setStepsValues((prev) => ({ ...prev, [key]: value }))}
              disabled={submitted}
            />
          )}

          {submitted && (
            <div
              className={cn(
                'rounded-[var(--radius-md)] p-4 text-sm font-medium animate-fly-in',
                isCorrect
                  ? 'bg-[var(--color-success-answer-light)] text-[var(--color-success-answer)]'
                  : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
              )}
            >
              {isCorrect
                ? t('firstSession.task.feedbackRight')
                : t('firstSession.task.feedbackTryAgain')}
            </div>
          )}
        </div>
      </EdvanceCard>

      <button
        type="button"
        onClick={submitted ? onAdvance : handleSubmit}
        disabled={!submitted && !isAnswerReady(task, { mcSelected, freeText, matchingPairs, stepsValues })}
        className={cn(
          'min-h-[44px] w-full rounded-[var(--radius-lg)] px-6 py-3',
          'text-sm font-semibold text-white shadow-md transition-all duration-base',
          'bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)]',
          'disabled:cursor-not-allowed disabled:opacity-50',
        )}
      >
        {!submitted
          ? t('firstSession.task.submit')
          : isLast
            ? t('firstSession.task.finish')
            : t('firstSession.task.next')}
      </button>
    </div>
  )
}

interface AnswerState {
  mcSelected: number | null
  freeText: string
  matchingPairs: MatchPairs
  stepsValues: Record<string, string>
}

function isAnswerReady(task: MockTask, state: AnswerState): boolean {
  if (task.inputType === 'MC') return state.mcSelected !== null
  if (task.inputType === 'FREE_INPUT') return state.freeText.trim().length > 0
  if (task.inputType === 'MATCHING') {
    return state.matchingPairs.size === (task as MockTaskMatching).left.length
  }
  if (task.inputType === 'STEPS') {
    return (task as MockTaskSteps).steps.every((s) => (state.stepsValues[s.key] ?? '').trim().length > 0)
  }
  return false
}

function isMatchingCorrect(pairs: MatchPairs, correctPairs: [number, number][]): boolean {
  if (pairs.size !== correctPairs.length) return false
  for (const [left, right] of pairs.entries()) {
    const expected = correctPairs.find((p) => p[0] === left)?.[1]
    if (expected === undefined || expected !== right) return false
  }
  return true
}

function isStepsCorrect(values: Record<string, string>, steps: Array<{ key: string; correctAnswer: string }>): boolean {
  return steps.every((s) => (values[s.key] ?? '').trim() === s.correctAnswer)
}

function convertMockStepsToTeilaufgaben(
  steps: Array<{ key: string; prompt: string; correctAnswer: string }>,
): ScreeningTeilaufgabe[] {
  return steps.map((s) => ({
    key: s.key,
    prompt: s.prompt,
    input_type: 'NUMERIC',
  }))
}
