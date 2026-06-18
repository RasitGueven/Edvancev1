import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { CoordinateInputWidget } from '@/components/edvance/tasks/CoordinateInputWidget'
import { cn } from '@/lib/utils'
import type { SessionTask } from '@/lib/mocks/session'
import type { TaskAnswer } from './taskEval'

interface TaskStubProps {
  task: SessionTask
  answer: TaskAnswer
  onAnswerChange: (next: TaskAnswer) => void
  /** Nach korrekter Antwort: Eingaben einfrieren. */
  locked: boolean
}

/**
 * Schlanker, treuer Aufgaben-Renderer aus JSON: Multiple-Choice, numerische
 * Eingabe und – als Integrationsbeweis – ein echtes JSXGraph-Koordinatensystem.
 */
export function TaskStub({ task, answer, onAnswerChange, locked }: TaskStubProps): JSX.Element {
  const { t } = useTranslation('mock')

  return (
    <div className="flex flex-col gap-5">
      <p className="text-lg font-semibold leading-relaxed text-warm">{task.prompt}</p>

      {task.kind === 'mc' && answer.kind === 'mc' && (
        <div className="flex flex-col gap-3" role="radiogroup" aria-label={task.prompt}>
          {task.options.map((option, i) => {
            const selected = answer.index === i
            return (
              <button
                key={i}
                type="button"
                role="radio"
                aria-checked={selected}
                disabled={locked}
                onClick={() => onAnswerChange({ kind: 'mc', index: i })}
                className={cn(
                  'min-h-[44px] w-full rounded-[var(--radius-lg)] border px-4 py-3 text-left text-base transition-[background,transform] duration-200 ease-bounce active:scale-[0.99] disabled:pointer-events-none',
                  selected
                    ? 'border-transparent bg-[var(--color-bg-surface)] font-semibold text-[var(--color-primary)]'
                    : 'border-white/20 bg-white/10 text-warm hover:bg-white/15',
                )}
              >
                {option}
              </button>
            )
          })}
        </div>
      )}

      {task.kind === 'numeric' && answer.kind === 'numeric' && (
        <div className="flex items-center gap-3">
          <input
            type="text"
            inputMode="decimal"
            disabled={locked}
            value={answer.raw}
            onChange={(e) => onAnswerChange({ kind: 'numeric', raw: e.target.value })}
            placeholder={t('session.task.inputPlaceholder')}
            aria-label={task.prompt}
            className="min-h-[44px] w-44 rounded-[var(--radius-lg)] border border-white/25 bg-white/10 px-4 text-lg font-semibold text-warm placeholder:text-warm-42 focus:border-white/60 focus:outline-none disabled:opacity-60"
          />
          {task.unit && <span className="text-base text-warm-72">{task.unit}</span>}
        </div>
      )}

      {task.kind === 'coordinate' && answer.kind === 'coordinate' && (
        <div className="flex flex-col gap-2">
          <CoordinateInputWidget
            shape={task.shape}
            initialPoints={task.initialPoints}
            pointLabels={task.pointLabels}
            disabled={locked}
            onChange={(points) => onAnswerChange({ kind: 'coordinate', points })}
          />
          <p className="text-sm text-warm-56">{t('session.task.coordinateHelp')}</p>
        </div>
      )}
    </div>
  )
}
