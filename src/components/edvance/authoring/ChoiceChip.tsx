// Die Klick-Auswahl (Chip) — gross genug fuer Touch (44px). Frueher Teil der Pflege-Strecke, heute fuer die
// Filter im Item-Pflege-Board.

import type { JSX, ReactNode } from 'react'

export function ChoiceChip({
  selected,
  disabled,
  onClick,
  children,
}: {
  selected: boolean
  disabled?: boolean
  onClick: () => void
  children: ReactNode
}): JSX.Element {
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      aria-pressed={selected}
      className={`min-h-[44px] rounded-xl border px-4 text-sm font-semibold transition disabled:opacity-40 ${
        selected
          ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-white'
          : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]'
      }`}
    >
      {children}
    </button>
  )
}
