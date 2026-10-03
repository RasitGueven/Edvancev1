import { Check } from 'lucide-react'
import { cn } from '@/lib/utils'

export type ThemaChipZustand = 'frei' | 'aktuell' | 'behandelt'

type ThemaChipProps = {
  label: string
  zustand: ThemaChipZustand
  /** Vorbelegt aus dem Schulplan — Punkt-Markierung, Erklaerung in der Legende. */
  ausPlan?: boolean
  disabled?: boolean
  onClick: () => void
}

// Ein Thema als Chip (min 44px). Aktuell = Primary-Kante, behandelt = neutral
// mit Haken (bewusst kein Gruen: "behandelt" ist kein Mastered), aus dem
// Schulplan = zusaetzlicher Punkt. Farben nur aus Tokens.
export function ThemaChip({
  label,
  zustand,
  ausPlan = false,
  disabled = false,
  onClick,
}: ThemaChipProps): JSX.Element {
  const gewaehlt = zustand !== 'frei'
  return (
    <button
      type="button"
      aria-pressed={gewaehlt}
      disabled={disabled}
      onClick={onClick}
      className={cn(
        'inline-flex min-h-[44px] items-center gap-2 rounded-xl border px-4 py-2 text-left text-sm font-medium transition-colors disabled:opacity-60',
        zustand === 'aktuell' &&
          'border-[var(--color-primary)] bg-[var(--color-primary)] text-[var(--color-bg-surface)]',
        zustand === 'behandelt' &&
          'border-[var(--color-text-secondary)] bg-[var(--color-bg-subtle)] text-[var(--color-text-primary)]',
        zustand === 'frei' &&
          'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)] hover:border-[var(--color-primary)]',
      )}
    >
      {zustand === 'behandelt' && <Check className="h-4 w-4 shrink-0" aria-hidden />}
      <span>{label}</span>
      {ausPlan && (
        <span
          className="h-2 w-2 shrink-0 rounded-full bg-[var(--color-text-tertiary)]"
          aria-hidden
        />
      )}
    </button>
  )
}
