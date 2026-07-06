import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Check, X } from 'lucide-react'
import type { TaskAnswerInputProps } from './types'

export function TrueFalseInput({
  payload,
  answer,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  const { t } = useTranslation('student')
  if (payload.input_type !== 'TRUE_FALSE') return null
  const value = answer?.input_type === 'TRUE_FALSE' ? answer.value : null

  const options: { val: boolean; label: string; icon: JSX.Element }[] = [
    { val: true, label: t('taskAnswer.true'), icon: <Check className="h-5 w-5" /> },
    { val: false, label: t('taskAnswer.false'), icon: <X className="h-5 w-5" /> },
  ]

  return (
    <div className="grid grid-cols-2 gap-3" role="radiogroup" aria-label={t('taskAnswer.true') + ' / ' + t('taskAnswer.false')}>
      {options.map((o) => {
        const active = value === o.val
        return (
          <button
            key={String(o.val)}
            type="button"
            role="radio"
            aria-checked={active}
            disabled={disabled}
            onClick={() => onChange({ input_type: 'TRUE_FALSE', value: o.val })}
            className={[
              'flex min-h-[56px] items-center justify-center gap-2 rounded-[var(--radius-lg)] border-2 p-3 text-base font-semibold transition-all duration-fast',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2',
              active
                ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] text-[var(--color-primary)] shadow-md'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-primary)] hover:-translate-y-0.5 hover:border-[var(--color-primary)] hover:shadow-md',
              disabled ? 'cursor-not-allowed opacity-60 hover:translate-y-0' : 'cursor-pointer',
            ].join(' ')}
          >
            {o.icon}
            {o.label}
          </button>
        )
      })}
    </div>
  )
}
