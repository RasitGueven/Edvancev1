import type { ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'

type Props = {
  /** Kleine Zeile über dem Titel, z. B. „Vertrieb“. */
  rubrik?: string
  titel: string
  /** Ein Satz, was die Seite tut. */
  satz?: string
  /** Höchstens eine Primäraktion (Entscheidung 6); bricht unter den Titel um. */
  aktionen?: ReactNode
  /** Detailseiten: Zurück-Link zu ihrer Liste. */
  zurueckZu?: string
  zurueckLabel?: string
}

/** Kompakter Seitenkopf der Hülle: kein Navy-Band, Titel in Fraunces 30 px. */
export function PageHeader({ rubrik, titel, satz, aktionen, zurueckZu, zurueckLabel }: Props): JSX.Element {
  return (
    <header className="flex flex-col gap-2">
      {zurueckZu && zurueckLabel && (
        <Link
          to={zurueckZu}
          className="inline-flex min-h-[44px] items-center gap-2 self-start text-sm font-semibold text-[var(--color-text-link)] hover:underline"
        >
          <ArrowLeft aria-hidden="true" className="h-4 w-4" />
          {zurueckLabel}
        </Link>
      )}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div className="flex min-w-0 flex-col gap-2">
          {rubrik && (
            <p className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">{rubrik}</p>
          )}
          <h1 className="font-serif text-3xl font-semibold leading-tight text-[var(--color-text-primary)]">{titel}</h1>
          {satz && <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{satz}</p>}
        </div>
        {aktionen && <div className="flex flex-wrap items-center gap-2">{aktionen}</div>}
      </div>
    </header>
  )
}
