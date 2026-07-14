// Kleine Bausteine, die im Autoren-Tool mehrfach vorkommen.
// Alles darueber hinaus kommt aus @/components/edvance bzw. @/lib/formStyles.

import type { JSX, ReactNode } from 'react'
import { Plus, X } from 'lucide-react'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { EdvanceBadgeVariant } from '@/components/edvance/EdvanceBadge'
import { Input } from '@/components/ui/input'
import type { TaskStatus } from '@/types'

export const INPUT_CLS =
  'h-10 w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-surface)] px-3 text-sm text-[var(--color-text-primary)]'

export function Section({
  title,
  action,
  children,
}: {
  title: string
  action?: ReactNode
  children: ReactNode
}): JSX.Element {
  return (
    <EdvanceCard className="p-6">
      <div className="mb-4 flex items-center justify-between gap-2">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {title}
        </h3>
        {action}
      </div>
      <div className="flex flex-col gap-4">{children}</div>
    </EdvanceCard>
  )
}

export function Field({
  label,
  hint,
  children,
}: {
  label: string
  hint?: string
  children: ReactNode
}): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
        {label}
      </span>
      {children}
      {hint && (
        <span className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {hint}
        </span>
      )}
    </div>
  )
}

/** Eine Liste gleichartiger Textzeilen (Antworten, Hinweise, Coach-Hinweise). */
export function StringList({
  values,
  onChange,
  placeholder,
  addLabel,
  removeLabel,
  max,
}: {
  values: string[]
  onChange: (next: string[]) => void
  placeholder: string
  addLabel: string
  removeLabel: string
  max?: number
}): JSX.Element {
  const atMax = max != null && values.length >= max
  return (
    <div className="flex flex-col gap-2">
      {values.map((value, i) => (
        <div key={i} className="flex items-center gap-2">
          <Input
            value={value}
            placeholder={placeholder}
            onChange={(e) => {
              const next = [...values]
              next[i] = e.target.value
              onChange(next)
            }}
          />
          <IconButton
            label={removeLabel}
            onClick={() => onChange(values.filter((_, j) => j !== i))}
          >
            <X className="h-4 w-4" />
          </IconButton>
        </div>
      ))}
      {!atMax && (
        <AddButton label={addLabel} onClick={() => onChange([...values, ''])} />
      )}
    </div>
  )
}

export function AddButton({
  label,
  onClick,
}: {
  label: string
  onClick: () => void
}): JSX.Element {
  return (
    <button
      type="button"
      onClick={onClick}
      className="inline-flex min-h-[44px] items-center gap-2 self-start rounded-xl border border-dashed border-[var(--color-border)] px-3 text-xs font-semibold text-[var(--color-text-secondary)] transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary)]"
    >
      <Plus className="h-4 w-4" />
      {label}
    </button>
  )
}

export function IconButton({
  label,
  onClick,
  children,
}: {
  label: string
  onClick: () => void
  children: ReactNode
}): JSX.Element {
  return (
    <button
      type="button"
      onClick={onClick}
      title={label}
      aria-label={label}
      className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-[var(--color-border)] text-[var(--color-text-tertiary)] transition hover:border-[var(--color-destructive)] hover:text-[var(--color-destructive)]"
    >
      {children}
    </button>
  )
}

const STATUS_VARIANT: Record<TaskStatus, EdvanceBadgeVariant> = {
  draft: 'muted',
  review: 'warning',
  ready: 'success',
}

export function StatusBadge({
  status,
  label,
}: {
  status: TaskStatus
  label: string
}): JSX.Element {
  return <EdvanceBadge variant={STATUS_VARIANT[status]}>{label}</EdvanceBadge>
}
