import type { JSX } from 'react'

type Props = {
  value: string
  onChange: (v: string) => void
  kontext?: string | null
  disabled?: boolean
}

// Freitext-Antwort (VERA-OPEN). Bewertet hybrid: Match in akzeptierte_antworten
// → auto-graded; sonst landet das Item in der Coach-Rating-Inbox. Kein
// Submit-on-Enter — Mehrzeilenantworten brauchen Newlines. Zeichen-
// zähler dezent unten rechts, damit lange Antworten nicht überraschen.
export function OpenWidget({ value, onChange, kontext, disabled }: Props): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      {kontext && (
        <div className="rounded-[var(--radius-lg)] border-l-2 border-[var(--color-primary)] bg-[var(--color-primary-light)] p-4 text-sm leading-relaxed text-[var(--color-text-primary)]">
          {kontext}
        </div>
      )}
      <div className="relative">
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          placeholder="Deine Antwort …"
          autoFocus
          rows={4}
          disabled={disabled}
          className="min-h-[104px] w-full resize-y rounded-[var(--radius-lg)] border-2 border-[var(--color-border)] bg-[var(--color-bg-surface)] p-4 text-sm leading-relaxed text-[var(--color-text-primary)] transition-colors duration-fast placeholder:text-[var(--color-text-tertiary)] focus:border-[var(--color-primary)] focus:outline-none disabled:opacity-60"
        />
        {value.length > 0 && (
          <span className="pointer-events-none absolute bottom-2 right-3 text-[10px] font-medium tabular-nums text-[var(--color-text-tertiary)]">
            {value.length}
          </span>
        )}
      </div>
    </div>
  )
}
