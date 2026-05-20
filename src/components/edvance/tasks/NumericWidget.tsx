import type { JSX } from 'react'
import { Input } from '@/components/ui/input'

type Props = {
  value: string
  onChange: (v: string) => void
  onEnter?: () => void
  unit?: string | null
  disabled?: boolean
}

// Zahleneingabe — Komma und Punkt erlaubt, Grading normalisiert beides
// (siehe grade.ts:toNumber). Größeres Touch-Target (min 52px) für Tablets.
export function NumericWidget({
  value,
  onChange,
  onEnter,
  unit,
  disabled,
}: Props): JSX.Element {
  return (
    <div className="flex items-center gap-3">
      <Input
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder="Zahl eingeben …"
        inputMode="decimal"
        autoFocus
        disabled={disabled}
        className="h-[52px] flex-1 rounded-xl text-base"
        onKeyDown={(e) => {
          if (e.key === 'Enter' && onEnter) onEnter()
        }}
      />
      {unit ? (
        <span className="text-sm font-semibold text-[var(--text-secondary)]">
          {unit}
        </span>
      ) : null}
    </div>
  )
}
