import type { ReactNode } from 'react'
import { EdvanceCard } from '@/components/edvance'

export type Zeile = { label: string; wert: ReactNode }

/** Ein Block der Detailansicht: Überschrift und Wertepaare. */
export function Datenblock({
  titel,
  zeilen,
  kinder,
}: {
  titel: string
  zeilen?: Zeile[]
  kinder?: ReactNode
}): JSX.Element {
  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {titel}
      </h2>
      {zeilen && zeilen.length > 0 && (
        <dl className="grid grid-cols-1 gap-x-6 gap-y-2 sm:grid-cols-2">
          {zeilen.map((z) => (
            <div key={z.label} className="flex flex-col gap-1">
              <dt className="text-xs text-[var(--color-text-tertiary)]">{z.label}</dt>
              <dd className="text-sm text-[var(--color-text-primary)]">{z.wert}</dd>
            </div>
          ))}
        </dl>
      )}
      {kinder}
    </EdvanceCard>
  )
}
