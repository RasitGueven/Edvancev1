import type { ReactNode } from 'react'
import { EdvanceCard } from '@/components/edvance'
import { Label } from '@/components/ui/label'

export function Section({ title, children }: { title: string; children: ReactNode }): JSX.Element {
  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {title}
      </h2>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">{children}</div>
    </EdvanceCard>
  )
}

export function Feld({
  id,
  label,
  hint,
  pflicht = false,
  wide = false,
  children,
}: {
  id: string
  label: string
  hint?: string | null
  /** Pflichtangabe — Sternchen wie in den uebrigen Formularen des Repos. */
  pflicht?: boolean
  wide?: boolean
  children: ReactNode
}): JSX.Element {
  return (
    <div className={`flex flex-col gap-2 ${wide ? 'sm:col-span-2' : ''}`}>
      <Label htmlFor={id}>
        {label}
        {pflicht && (
          <span aria-hidden="true" className="text-[var(--color-error-exam)]">
            {' *'}
          </span>
        )}
      </Label>
      {children}
      {hint && <p className="text-xs text-[var(--color-text-tertiary)]">{hint}</p>}
    </div>
  )
}
