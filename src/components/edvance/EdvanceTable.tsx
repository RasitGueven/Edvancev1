import { Fragment, type ReactNode } from 'react'

export type Spalte<T> = {
  key: string
  kopf: string
  /** Rechtsbuendig fuer Betraege und Zahlen. */
  rechts?: boolean
  zelle: (zeile: T) => ReactNode
}

type EdvanceTableProps<T> = {
  spalten: Spalte<T>[]
  zeilen: T[]
  zeileKey: (zeile: T) => string
  /** Klickbare Zeile — nur setzen, wenn es dahinter wirklich etwas gibt. */
  onZeile?: (zeile: T) => void
  /** Zusaetzliche Klassen je Zeile, etwa fuer eine Hervorhebung. */
  zeileClass?: (zeile: T) => string
  /** Dünne Zwischenzeile vor einer Zeile, wenn sich der Abschnitt ändert (null = kein Abschnitt). */
  abschnitt?: (zeile: T) => string | null
  beschriftung: string
}

/**
 * Tabelle fuer Admin-Listen.
 *
 * Die Karten-Regel des Designsystems gilt fuer Schueler-, Coach- und
 * Eltern-Flaechen (CLAUDE.md §11, Abschnitt "Tabellen im Admin"). Eine
 * Vertragsliste vergleicht bis zu zehn Felder je Zeile — auf einer Karte ist
 * das nicht mehr lesbar, und Spalten lassen sich darauf nicht vergleichen.
 *
 * Farben, Abstaende und Radien kommen auch hier aus den Tokens.
 */
export function EdvanceTable<T>({
  spalten,
  zeilen,
  zeileKey,
  onZeile,
  zeileClass,
  abschnitt,
  beschriftung,
}: EdvanceTableProps<T>): JSX.Element {
  return (
    <div className="overflow-x-auto rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-surface)]">
      <table className="w-full min-w-[42rem] border-collapse text-sm">
        <caption className="sr-only">{beschriftung}</caption>
        <thead>
          <tr className="border-b border-[var(--color-border)]">
            {spalten.map((s) => (
              <th
                key={s.key}
                scope="col"
                className={`px-4 py-3 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)] ${
                  s.rechts ? 'text-right' : 'text-left'
                }`}
              >
                {s.kopf}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {zeilen.map((zeile, i) => {
            const klick = onZeile !== undefined
            const titel = abschnitt?.(zeile) ?? null
            const neu = titel !== null && (i === 0 || abschnitt?.(zeilen[i - 1]) !== titel)
            return (
              <Fragment key={zeileKey(zeile)}>
              {neu && (
                <tr className="border-b border-[var(--color-border)] bg-[var(--color-bg-app)]">
                  <th scope="rowgroup" colSpan={spalten.length}
                    className="px-4 py-1 text-left text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
                    {titel}
                  </th>
                </tr>
              )}
              <tr
                {...(klick
                  ? {
                      tabIndex: 0,
                      role: 'button',
                      onClick: () => onZeile(zeile),
                      onKeyDown: (e: React.KeyboardEvent) => {
                        if (e.key === 'Enter' || e.key === ' ') {
                          e.preventDefault()
                          onZeile(zeile)
                        }
                      },
                    }
                  : {})}
                className={[
                  'border-b border-[var(--color-border)] last:border-b-0',
                  klick ? 'cursor-pointer hover:bg-[var(--color-bg-app)]' : '',
                  zeileClass?.(zeile) ?? '',
                ].join(' ')}
              >
                {spalten.map((s) => (
                  <td
                    key={s.key}
                    className={`px-4 py-3 align-middle text-[var(--color-text-primary)] ${
                      s.rechts ? 'text-right' : 'text-left'
                    }`}
                  >
                    {s.zelle(zeile)}
                  </td>
                ))}
              </tr>
              </Fragment>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
