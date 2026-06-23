import type { JSX } from 'react'
import { MCWidget } from '../MCWidget'
import type { TaskAnswerInputProps } from './types'

// Einzelauswahl über das bestehende MCWidget (id-basiert statt index). Multi-
// Select ist im MVP einfach „eine id" — Mehrfachauswahl s. INPUT_TYPE_CANON §5.
export function MCInput({ payload, answer, onChange, disabled }: TaskAnswerInputProps): JSX.Element | null {
  if (payload.input_type !== 'MC') return null
  const selectedIds = answer?.input_type === 'MC' ? answer.selected : []
  const selectedIdx = payload.options.findIndex((o) => selectedIds.includes(o.id))
  return (
    <MCWidget
      options={payload.options.map((o) => o.label)}
      selected={selectedIdx >= 0 ? selectedIdx : null}
      onChange={(idx) => {
        const opt = payload.options[idx]
        if (opt) onChange({ input_type: 'MC', selected: [opt.id] })
      }}
      disabled={disabled ?? false}
    />
  )
}
