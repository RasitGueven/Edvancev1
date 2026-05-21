import type { JSX } from 'react'
import { Check } from 'lucide-react'

type Props = {
  options: string[]
  selected: number | null
  onChange: (idx: number) => void
  disabled: boolean
}

const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']

// Single-Choice. Aktive Auswahl: dezenter Primary-Rahmen + Check rechts —
// keine harten Farbschlachten. Touch-Target ≥ 56 px. Auf Tastatur
// reagieren Buttons nativ (Space/Enter), Radio-Semantik via aria-checked.
export function MCWidget({ options, selected, onChange, disabled }: Props): JSX.Element {
  return (
    <div className="flex flex-col gap-3" role="radiogroup" aria-label="Antwortoptionen">
      {options.map((opt, i) => {
        const active = selected === i
        return (
          <button
            key={i}
            type="button"
            role="radio"
            aria-checked={active}
            disabled={disabled}
            onClick={() => onChange(i)}
            className={[
              'group flex min-h-[56px] w-full items-center gap-3 rounded-[var(--radius-lg)] border-2 p-3 text-left transition-all duration-fast',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-[var(--color-primary)] focus-visible:ring-offset-2',
              active
                ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)] shadow-md'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] shadow-sm hover:-translate-y-0.5 hover:border-[var(--color-primary)] hover:shadow-md',
              disabled ? 'cursor-not-allowed opacity-60 hover:translate-y-0' : 'cursor-pointer',
            ].join(' ')}
          >
            <span
              className={[
                'flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-sm font-bold transition-colors',
                active
                  ? 'bg-[var(--color-primary)] text-white'
                  : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)] group-hover:bg-[var(--color-primary-light)] group-hover:text-[var(--color-primary)]',
              ].join(' ')}
            >
              {LETTERS[i] ?? i + 1}
            </span>
            <span className="flex-1 text-sm leading-relaxed text-[var(--color-text-primary)]">
              {opt}
            </span>
            {active && (
              <Check className="h-5 w-5 shrink-0 text-[var(--color-primary)]" />
            )}
          </button>
        )
      })}
    </div>
  )
}
