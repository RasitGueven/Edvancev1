import type { JSX } from 'react'
import type { ScreeningTeilaufgabe } from '@/types'

type Props = {
  steps: ScreeningTeilaufgabe[]
  values: Record<string, string>
  onChange: (key: string, value: string) => void
  kontext?: string | null
  disabled?: boolean
}

const INPUT_BASE =
  'w-full rounded-[var(--radius-md)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm text-[var(--color-text-primary)] transition-colors duration-fast placeholder:text-[var(--color-text-tertiary)] focus:border-[var(--color-primary)] focus:outline-none disabled:opacity-60'

// Mehrteilige Aufgabe (VERA: 1a, 1b, 2a …). Jede Teilaufgabe in eigener
// Sub-Card mit prominentem Key-Badge, damit Schüler:innen den Fortschritt
// sehen. „Befüllt"-Indikator wechselt den Badge in den Primary-Stil.
export function MultiStepWidget({
  steps,
  values,
  onChange,
  kontext,
  disabled,
}: Props): JSX.Element {
  return (
    <div className="flex flex-col gap-4">
      {kontext && (
        <div className="rounded-[var(--radius-lg)] border-l-2 border-[var(--color-primary)] bg-[var(--color-primary-light)] p-4 text-sm leading-relaxed text-[var(--color-text-primary)]">
          {kontext}
        </div>
      )}
      {steps.map((ta) => {
        const isNumeric = ta.input_type === 'NUMERIC'
        const filled = (values[ta.key] ?? '').trim().length > 0
        return (
          <div
            key={ta.key}
            className="flex flex-col gap-3 rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4 shadow-sm"
          >
            <div className="flex items-start gap-3">
              <span
                className={[
                  'inline-flex h-7 min-w-[2.25rem] shrink-0 items-center justify-center rounded-[var(--radius-md)] px-2 text-xs font-bold transition-colors',
                  filled
                    ? 'bg-[var(--color-primary)] text-white'
                    : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]',
                ].join(' ')}
              >
                {ta.key}
              </span>
              <p className="flex-1 text-sm leading-relaxed text-[var(--color-text-primary)]">
                {ta.prompt}
              </p>
            </div>
            {isNumeric ? (
              <input
                type="text"
                inputMode="decimal"
                value={values[ta.key] ?? ''}
                onChange={(e) => onChange(ta.key, e.target.value)}
                disabled={disabled}
                placeholder="Zahl"
                className={`${INPUT_BASE} h-12`}
              />
            ) : (
              <textarea
                value={values[ta.key] ?? ''}
                onChange={(e) => onChange(ta.key, e.target.value)}
                disabled={disabled}
                rows={2}
                placeholder="Antwort"
                className={`${INPUT_BASE} min-h-[72px] resize-y py-2 leading-relaxed`}
              />
            )}
          </div>
        )
      })}
    </div>
  )
}
