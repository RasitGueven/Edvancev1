import type { ReactNode } from 'react'

export type BoardColumnView<T> = {
  key: string
  title: string
  emptyHint: string
  items: T[]
}

type BoardColumnsProps<T> = {
  columns: BoardColumnView<T>[]
  /** Ab so vielen Spalten scrollt das Board waagerecht statt zu quetschen. */
  maxFitting: number
  itemKey: (item: T) => string
  renderItem: (item: T, columnKey: string) => ReactNode
}

/**
 * Kanban-Raster fuer Leads und Vertraege. Die Standardspalten teilen sich die
 * Breite und passen ohne waagerechtes Scrollen nebeneinander. Erst das
 * eingeschaltete Archiv macht eine weitere Spalte noetig — dann scrollt das
 * Board waagerecht. Kein Drag & Drop: der Status wechselt ueber die Karten.
 */
export function BoardColumns<T>({
  columns,
  maxFitting,
  itemKey,
  renderItem,
}: BoardColumnsProps<T>): JSX.Element {
  const scrolls = columns.length > maxFitting
  const grid = maxFitting === 3 ? 'lg:grid-cols-3' : 'lg:grid-cols-4'

  const body = (
    <div
      className={
        scrolls ? 'flex min-w-max gap-4' : `grid grid-cols-1 gap-4 sm:grid-cols-2 ${grid}`
      }
    >
      {columns.map((column) => (
        <section
          key={column.key}
          className={scrolls ? 'flex w-72 shrink-0 flex-col gap-4' : 'flex min-w-0 flex-col gap-4'}
        >
          {/* Die Anzahl steht direkt hinter dem eigenen Spaltennamen, damit
              sie nicht wie der Anfang der naechsten Spalte wirkt. */}
          <h2 className="flex min-w-0 items-baseline gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
            <span className="truncate">{column.title}</span>
            <span className="text-[var(--color-text-tertiary)]">{column.items.length}</span>
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
  )

  return scrolls ? <div className="-mx-4 overflow-x-auto px-4">{body}</div> : body
}
