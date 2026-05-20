import type { JSX } from 'react'

type Props = {
  options: string[]
  selected: number | null
  onChange: (idx: number) => void
  disabled: boolean
}

const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']

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
              'flex min-h-[52px] w-full items-start gap-3 rounded-xl border-2 p-3 text-left transition-all',
              active
                ? 'border-[var(--primary)] bg-[color-mix(in_srgb,var(--primary)_8%,white)]'
                : 'border-[var(--border)] bg-card hover:border-[var(--primary-light)]',
              disabled ? 'cursor-not-allowed opacity-60' : 'cursor-pointer',
            ].join(' ')}
          >
            <span
              className={[
                'flex h-7 w-7 shrink-0 items-center justify-center rounded-full text-xs font-bold',
                active ? 'text-white' : 'text-primary',
              ].join(' ')}
              style={{ background: active ? 'var(--primary)' : 'var(--primary-pale)' }}
            >
              {LETTERS[i] ?? i + 1}
            </span>
            <span className="flex-1 pt-0.5 text-sm leading-relaxed text-foreground">{opt}</span>
          </button>
        )
      })}
    </div>
  )
}
