import type { JSX } from 'react'

type Props = {
  value: string
  onChange: (v: string) => void
  onEnter?: () => void
  unit?: string | null
  disabled?: boolean
}

// Zahleneingabe — Komma und Punkt erlaubt (grade.ts:toNumber). Größeres
// Touch-Target (56 px) für Tablets. Unit als Pill rechts integriert, damit
// Schüler:innen sehen, in welcher Einheit gerechnet wird.
export function NumericWidget({
  value,
  onChange,
  onEnter,
  unit,
  disabled,
}: Props): JSX.Element {
  return (
    <div className="flex items-stretch gap-2">
      <div className="relative flex-1">
        <input
          type="text"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Zahl eingeben …"
          inputMode="decimal"
          autoFocus
          disabled={disabled}
          onKeyDown={(e) => {
            if (e.key === 'Enter' && onEnter) onEnter()
          }}
          className="h-14 w-full rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 text-base font-medium text-[var(--color-text-primary)] transition-colors duration-fast placeholder:text-[var(--color-text-tertiary)] focus:border-[var(--color-primary)] focus:outline-none disabled:opacity-60"
        />
      </div>
      {unit && (
        <span className="inline-flex h-14 shrink-0 items-center rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-subtle)] px-4 text-sm font-semibold text-[var(--color-text-secondary)]">
          {unit}
        </span>
      )}
    </div>
  )
}
