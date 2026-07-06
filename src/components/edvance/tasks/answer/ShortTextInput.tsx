import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { TaskAnswerInputProps } from './types'

export function ShortTextInput({
  payload,
  answer,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  const { t } = useTranslation('student')
  if (payload.input_type !== 'SHORT_TEXT') return null
  const value = answer?.input_type === 'SHORT_TEXT' ? answer.text : ''
  return (
    <input
      type="text"
      value={value}
      onChange={(e) => onChange({ input_type: 'SHORT_TEXT', text: e.target.value })}
      placeholder={t('taskAnswer.shortTextPlaceholder')}
      autoFocus
      disabled={disabled}
      className="h-14 w-full rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 text-base font-medium text-[var(--color-text-primary)] transition-colors duration-fast placeholder:text-[var(--color-text-tertiary)] focus:border-[var(--color-primary)] focus:outline-none disabled:opacity-60"
    />
  )
}
