import type { JSX } from 'react'
import { MathContent } from '@/lib/render/MathContent'
import type { TaskAnswerInputProps } from './types'

// Lückentext: payload.text trägt Marker {{id}}; jede Lücke wird zu einem Inline-
// Eingabefeld. Die akzeptierten Lösungen bleiben verborgen (kein Leak ans Kind).
export function ClozeInput({
  payload,
  answer,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  if (payload.input_type !== 'CLOZE') return null
  const blanks = answer?.input_type === 'CLOZE' ? answer.blanks : {}

  // Split mit Capture → ungerade Indizes sind Lücken-ids.
  const parts = payload.text.split(/\{\{(\w+)\}\}/)

  function update(id: string, val: string): void {
    onChange({ input_type: 'CLOZE', blanks: { ...blanks, [id]: val } })
  }

  return (
    <p className="flex flex-wrap items-center gap-x-1 gap-y-2 text-base leading-loose text-[var(--color-text-primary)]">
      {parts.map((part, i) =>
        i % 2 === 1 ? (
          <input
            key={`blank-${part}`}
            type="text"
            value={blanks[part] ?? ''}
            onChange={(e) => update(part, e.target.value)}
            disabled={disabled}
            aria-label={`Lücke ${(i + 1) / 2}`}
            className="inline-block min-w-[4ch] max-w-[14ch] rounded-[var(--radius-md)] border-2 border-[var(--color-primary)] bg-[var(--color-bg-surface)] px-2 py-1 text-center text-base font-semibold text-[var(--color-text-primary)] focus:outline-none focus:ring-2 focus:ring-[var(--color-primary)] disabled:opacity-60"
            style={{ width: `${Math.max(4, (blanks[part] ?? '').length + 1)}ch` }}
          />
        ) : part ? (
          <MathContent key={`text-${i}`} text={part} />
        ) : null,
      )}
    </p>
  )
}
