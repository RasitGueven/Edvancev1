import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard, EdvanceBadge } from '@/components/edvance'
import { cn } from '@/lib/utils'
import type { MockTask } from '@/lib/mocks/firstSession'

interface PlanStepProps {
  tasks: MockTask[]
  /** True wenn Lehrer-Themen den Filter beeinflusst haben. */
  topicsDriven: boolean
  onStart: () => void
}

export function PlanStep({ tasks, topicsDriven, onStart }: PlanStepProps): JSX.Element {
  const { t } = useTranslation('student')

  return (
    <div className="flex flex-col gap-6 animate-fly-in">
      <div className="flex flex-col gap-1">
        <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('firstSession.plan.eyebrow')}
        </p>
        <h2 className="text-2xl font-bold text-[var(--color-text-primary)]">
          {t('firstSession.plan.title', { count: tasks.length })}
        </h2>
        <p className="text-sm text-[var(--color-text-secondary)]">
          {topicsDriven
            ? t('firstSession.plan.subtitleTopics')
            : t('firstSession.plan.subtitle')}
        </p>
      </div>

      <div className="flex flex-col gap-3">
        {tasks.map((task, idx) => (
          <EdvanceCard key={task.id} accent="primary">
            <div className="flex items-start justify-between gap-3">
              <div className="flex flex-1 flex-col gap-2 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="inline-flex h-7 w-7 items-center justify-center rounded-[var(--radius-full)] bg-[var(--color-primary)] text-xs font-bold text-white">
                    {idx + 1}
                  </span>
                  <span className="text-base font-semibold text-[var(--color-text-primary)] truncate">
                    {task.clusterName}
                  </span>
                </div>
                <p className="text-sm text-[var(--color-text-secondary)] line-clamp-2">
                  {task.question}
                </p>
                <div className="flex flex-wrap items-center gap-2">
                  <EdvanceBadge variant="skilltree">
                    {t(`firstSession.inputType.${task.inputType}`)}
                  </EdvanceBadge>
                  <EdvanceBadge variant="primary">
                    {t('firstSession.plan.durationMin', { min: task.durationMin })}
                  </EdvanceBadge>
                  <EdvanceBadge variant="muted">AFB {task.difficulty}</EdvanceBadge>
                </div>
              </div>
            </div>
          </EdvanceCard>
        ))}
      </div>

      <button
        type="button"
        onClick={onStart}
        className={cn(
          'min-h-[44px] w-full rounded-[var(--radius-lg)] px-6 py-3',
          'text-sm font-semibold text-white shadow-md transition-all duration-base',
          'bg-[var(--color-primary)] hover:bg-[var(--color-primary-hover)]',
        )}
      >
        {t('firstSession.plan.cta')}
      </button>
    </div>
  )
}
