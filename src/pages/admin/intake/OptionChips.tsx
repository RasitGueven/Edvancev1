// Klick-Auswahl fuer das Erstgespraech: eine Reihe grosser Touch-Targets
// (min 44px). Single- oder Multi-Select ueber dieselbe Optik. Farben nur aus
// Tokens, keine Pills mit Glow — matte Gold-/Primary-Kante im Aktiv-Zustand.
type Option<T> = { value: T; label: string }

type OptionChipsProps<T extends string | number> = {
  options: readonly Option<T>[]
  selected: T[]
  onToggle: (value: T) => void
  columns?: boolean
}

export function OptionChips<T extends string | number>({
  options,
  selected,
  onToggle,
  columns = false,
}: OptionChipsProps<T>): JSX.Element {
  return (
    <div className={columns ? 'grid grid-cols-2 gap-2 sm:grid-cols-3' : 'flex flex-wrap gap-2'}>
      {options.map((option) => {
        const active = selected.includes(option.value)
        return (
          <button
            key={String(option.value)}
            type="button"
            aria-pressed={active}
            onClick={() => onToggle(option.value)}
            className={`min-h-[44px] rounded-xl border px-4 py-2 text-sm font-medium transition-colors ${
              active
                ? 'border-[var(--color-primary)] bg-[color-mix(in_srgb,var(--color-primary)_10%,transparent)] text-[var(--color-text-primary)]'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]'
            }`}
          >
            {option.label}
          </button>
        )
      })}
    </div>
  )
}
