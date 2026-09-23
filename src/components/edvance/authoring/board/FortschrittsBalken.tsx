// Der Freigabe-Balken des Boards: freigegeben (gruen), zur Freigabe (gold),
// zurueckgewiesen (rot) — der Rest ist offen. Farbe hat Bedeutung: gruen ist
// fertig, gold wartet auf admin, rot braucht Arbeit.

import type { JSX } from 'react'
import type { Stand } from '@/lib/authoring/board'

function anteil(n: number, total: number): string {
  return `${total > 0 ? (n / total) * 100 : 0}%`
}

export function FortschrittsBalken({
  stand,
  className = '',
}: {
  stand: Stand
  className?: string
}): JSX.Element {
  return (
    <div
      className={`flex h-1.5 overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-bg-subtle)] ${className}`}
      role="progressbar"
      aria-valuemin={0}
      aria-valuemax={stand.total}
      aria-valuenow={stand.geprueft}
    >
      {/* Breiten sind berechnete Werte — der erlaubte Fall fuer Inline-Styles. */}
      <div className="h-full bg-[var(--color-success)]" style={{ width: anteil(stand.freigegeben, stand.total) }} />
      <div className="h-full bg-[var(--color-gold-warning)]" style={{ width: anteil(stand.zurFreigabe, stand.total) }} />
      <div className="h-full bg-[var(--color-destructive)]" style={{ width: anteil(stand.zurueckgewiesen, stand.total) }} />
    </div>
  )
}
