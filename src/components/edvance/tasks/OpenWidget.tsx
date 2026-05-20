import type { JSX } from 'react'

type Props = {
  value: string
  onChange: (v: string) => void
  kontext?: string | null
  disabled?: boolean
}

// Freitext-Antwort (VERA-OPEN). Bewertet hybrid: Match in akzeptierte_antworten
// → auto-graded; sonst landet das Item in der Coach-Rating-Inbox. Kein
// Submit-on-Enter — Mehrzeilenantworten brauchen Newlines.
export function OpenWidget({ value, onChange, kontext, disabled }: Props): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      {kontext ? (
        <div className="rounded-xl border border-[var(--border)] bg-[var(--background)] p-4 text-sm leading-relaxed text-[var(--text-secondary)]">
          {kontext}
        </div>
      ) : null}
      <textarea
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Deine Antwort …"
        autoFocus
        rows={3}
        disabled={disabled}
        className="min-h-[88px] w-full rounded-xl border-2 border-[var(--border)] bg-card p-3 text-sm leading-relaxed text-foreground transition-colors focus:border-[var(--primary)] focus:outline-none disabled:opacity-60"
      />
    </div>
  )
}
