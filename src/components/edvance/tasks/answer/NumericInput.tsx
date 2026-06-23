import type { JSX } from 'react'
import { NumericWidget } from '../NumericWidget'
import type { TaskAnswerInputProps } from './types'

export function NumericInput({
  payload,
  answer,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  if (payload.input_type !== 'NUMERIC') return null
  const value = answer?.input_type === 'NUMERIC' ? answer.value : ''
  return (
    <NumericWidget
      value={value}
      onChange={(v) => onChange({ input_type: 'NUMERIC', value: v })}
      disabled={disabled}
    />
  )
}
