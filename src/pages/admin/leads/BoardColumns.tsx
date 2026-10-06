import type { ReactNode } from 'react'

export type BoardColumnView<T> = {
  key: string
  title: string
  emptyHint: string
  items: T[]
}

type BoardColumnsProps<T> = {
  columns: BoardColumnView<T>[]
  /** Mehr Spalten als diese wischen immer seitlich statt zu quetschen. */
  maxFitting: number
  itemKey: (item: T) => string
  renderItem: (item: T, columnKey: string) => ReactNode
  /** Zaehlt ein Eintrag in der Spaltenzahl? Testkonten nicht (Entscheidung 27). */
  zaehlt?: (item: T) => boolean
}

/**
 * Kanban-Raster der Leads (Entscheidung 8). Die Spalten teilen sich die Breite
 * (grid, minmax(0,1fr)). Reicht die Inhaltsbreite nicht (unter
 * --container-board-leads), wischen die Spalten seitlich mit Scroll-Snap,
 * jede --container-board-spalte breit — sie brechen nicht in Bloecke um.
 * Gemessen wird der Inhaltsbereich (Container-Query), nicht der Viewport.
 * Mehr Spalten als `maxFitting` (eingeschaltetes Archiv) wischen immer.
 * Kein Drag & Drop: der Status wechselt ueber die Karten.
 */
export function BoardColumns<T>({
  columns,
  maxFitting,
  itemKey,
  renderItem,
  zaehlt = () => true,
}: BoardColumnsProps<T>): JSX.Element {
  const teilt = columns.length <= maxFitting
  const reihe = [
    'flex snap-x snap-mandatory gap-4 overflow-x-auto pb-2',
    teilt && '@board-leads:grid @board-leads:grid-flow-col @board-leads:auto-cols-[minmax(0,1fr)] @board-leads:overflow-visible',
  ]
    .filter(Boolean)
    .join(' ')
  const spalte = [
    'flex w-board-spalte shrink-0 snap-start flex-col gap-4',
    teilt && '@board-leads:w-auto @board-leads:min-w-0',
  ]
    .filter(Boolean)
    .join(' ')

  return (
    <div className="@container">
      <div className={reihe}>
        {columns.map((column) => (
          <section key={column.key} aria-label={column.title} className={spalte}>
            {/* Die Anzahl steht direkt hinter dem eigenen Spaltennamen, damit
                sie nicht wie der Anfang der naechsten Spalte wirkt. */}
            <h2 className="flex min-w-0 items-baseline gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              <span className="truncate">{column.title}</span>
              <span className="text-[var(--color-text-tertiary)]">{column.items.filter(zaehlt).length}</span>
            </h2>
            {column.items.length === 0 ? (
              <p className="text-xs text-[var(--color-text-tertiary)]">{column.emptyHint}</p>
            ) : (
              column.items.map((item) => (
                <div key={itemKey(item)} className="min-w-0">
                  {renderItem(item, column.key)}
                </div>
              ))
            )}
          </section>
        ))}
      </div>
    </div>
  )
}
