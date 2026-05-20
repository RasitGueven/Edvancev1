import type { JSX } from 'react'
import type { ScreeningTeilaufgabe } from '@/types'

type Props = {
  steps: ScreeningTeilaufgabe[]
  values: Record<string, string>
  onChange: (key: string, value: string) => void
  kontext?: string | null
  disabled?: boolean
}

// Mehrteilige Aufgabe (VERA: 1a, 1b, 2a …). Jede Teilaufgabe bekommt einen
// eigenen Antwort-Slot; das Top-Level-Item wird nur als „komplett geantwortet"
// gewertet, wenn jede Teilaufgabe befüllt ist (siehe TaskRenderer.isReady).
export function MultiStepWidget({
  steps,
  values,
  onChange,
  kontext,
  disabled,
}: Props): JSX.Element {
  return (
    <div className="flex flex-col gap-4">
      {kontext ? (
        <div className="rounded-xl border border-[var(--border)] bg-[var(--background)] p-4 text-sm leading-relaxed text-[var(--text-secondary)]">
          {kontext}
        </div>
      ) : null}
      {steps.map((ta) => {
        const isNumeric = ta.input_type === 'NUMERIC'
        return (
          <div key={ta.key} className="flex flex-col gap-2">
            <div className="flex items-baseline gap-2">
              <span className="inline-flex h-6 min-w-[2rem] items-center justify-center rounded-md bg-[var(--primary-pale)] px-2 text-xs font-bold text-[var(--primary)]">
                {ta.key}
              </span>
              <p className="text-sm leading-relaxed text-[var(--text-primary)]">
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
                className="h-12 w-full rounded-xl border-2 border-[var(--border)] bg-card px-3 text-sm text-foreground transition-colors focus:border-[var(--primary)] focus:outline-none disabled:opacity-60"
              />
            ) : (
              <textarea
                value={values[ta.key] ?? ''}
                onChange={(e) => onChange(ta.key, e.target.value)}
                disabled={disabled}
                rows={2}
                placeholder="Antwort"
                className="min-h-[64px] w-full rounded-xl border-2 border-[var(--border)] bg-card p-3 text-sm leading-relaxed text-foreground transition-colors focus:border-[var(--primary)] focus:outline-none disabled:opacity-60"
              />
            )}
          </div>
        )
      })}
    </div>
  )
}
