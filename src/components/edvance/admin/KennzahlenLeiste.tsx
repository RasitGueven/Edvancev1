import { Link } from 'react-router-dom'
import { EdvanceCard } from '@/components/edvance'

export type KennzahlTon = 'neutral' | 'handeln'

export type Kennzahl = {
  key: string
  label: string
  wert: string
  unterzeile?: string
  /** Sprungziel; ohne Ziel ist das Feld nur Anzeige. */
  ziel?: string
  /** handeln = der Wert steht in der Handeln-Farbe (z. B. Kinder ohne Raum > 0). */
  ton?: KennzahlTon
}

/**
 * Container-Breite, ab der die fünf Felder nebeneinander stehen (Tokens --container-<breite> in
 * globals.css). Die Klassen stehen ausgeschrieben, damit Tailwind sie findet.
 */
export type KennzahlenBreite = 'heute-kpi' | 'slots-kpi'

const SPALTEN: Record<KennzahlenBreite, { raster: string; letzte: string }> = {
  'heute-kpi': { raster: '@heute-kpi:grid-cols-5', letzte: 'col-span-2 @heute-kpi:col-span-1' },
  'slots-kpi': { raster: '@slots-kpi:grid-cols-5', letzte: 'col-span-2 @slots-kpi:col-span-1' },
}

/**
 * Kennzahlen als schmale Leiste: eine Karte, fünf Felder, ab der Container-Breite nebeneinander, darunter
 * zwei Spalten. Ein Feld mit Ziel führt in seinen Bereich. Der umgebende Bereich braucht `@container`.
 */
export function KennzahlenLeiste({
  zahlen,
  label,
  breite = 'heute-kpi',
}: {
  zahlen: Kennzahl[]
  /** Name der Leiste für Screenreader (z. B. "Kennzahlen"). */
  label: string
  breite?: KennzahlenBreite
}): JSX.Element {
  const spalten = SPALTEN[breite]
  return (
    <EdvanceCard className="overflow-hidden p-0">
      <nav aria-label={label} className={`grid grid-cols-2 gap-px bg-[var(--color-border)] ${spalten.raster}`}>
        {zahlen.map((z, i) => {
          const klasse = `flex min-h-[44px] min-w-0 flex-col bg-[var(--color-bg-surface)] px-4 py-4 ${
            z.ziel ? 'hover:bg-[var(--color-bg-subtle)]' : ''
          } ${i === zahlen.length - 1 && zahlen.length % 2 === 1 ? spalten.letzte : ''}`
          const inhalt = (
            <>
              <span className="truncate text-xs font-semibold text-[var(--color-text-tertiary)]">{z.label}</span>
              <span
                className={`truncate font-serif text-2xl font-semibold tabular-nums ${
                  z.ton === 'handeln' ? 'text-[var(--color-error-coach)]' : 'text-[var(--color-text-primary)]'
                }`}
              >
                {z.wert}
              </span>
              {z.unterzeile !== undefined && (
                <span className="truncate text-xs text-[var(--color-text-secondary)]">{z.unterzeile}</span>
              )}
            </>
          )
          return z.ziel ? (
            <Link key={z.key} to={z.ziel} className={klasse}>
              {inhalt}
            </Link>
          ) : (
            <div key={z.key} className={klasse}>
              {inhalt}
            </div>
          )
        })}
      </nav>
    </EdvanceCard>
  )
}
