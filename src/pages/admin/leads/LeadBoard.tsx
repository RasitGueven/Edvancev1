import type { Lead } from '@/types'
import type { LeadPlatz } from '@/lib/supabase/platz'
import { LeadCard } from './LeadCard'
import { leadsForColumn, type BoardColumn, type LeadFilters } from './boardModel'

type LeadBoardProps = {
  columns: BoardColumn[]
  leads: Lead[]
  filters: LeadFilters
  platzByLead: Record<string, LeadPlatz>
  onOpen: (lead: Lead) => void
  onOpenErstgespraech: (lead: Lead) => void
  onMarkContacted: (lead: Lead) => void
  onAssignPlatz: (lead: Lead) => void
  onConvert: (lead: Lead) => void
  onReject: (lead: Lead) => void
}

/**
 * Die vier Standardspalten teilen sich die Breite als Raster und passen damit
 * ohne waagerechtes Scrollen nebeneinander. Erst das eingeschaltete Archiv
 * macht eine fuenfte Spalte noetig — dann scrollt das Board waagerecht, statt
 * die Spalten unlesbar schmal zu quetschen. Kein Drag & Drop: der Status
 * wechselt ueber die Karten.
 */
export function LeadBoard({
  columns,
  leads,
  filters,
  platzByLead,
  onOpen,
  onOpenErstgespraech,
  onMarkContacted,
  onAssignPlatz,
  onConvert,
  onReject,
}: LeadBoardProps): JSX.Element {
  const scrolls = columns.length > 4

  const body = (
    <div
      className={
        scrolls
          ? 'flex min-w-max gap-4'
          : 'grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4'
      }
    >
      {columns.map((column) => {
        const columnLeads = leadsForColumn(leads, column, filters)
        return (
          <section
            key={column.key}
            className={
              scrolls
                ? 'flex w-72 shrink-0 flex-col gap-4'
                : 'flex min-w-0 flex-col gap-4'
            }
          >
            {/* Die Anzahl steht direkt hinter dem eigenen Spaltennamen, damit
                sie nicht wie der Anfang der naechsten Spalte wirkt. */}
            <h2 className="flex min-w-0 items-baseline gap-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
              <span className="truncate">{column.title}</span>
              <span className="text-[var(--color-text-tertiary)]">
                {columnLeads.length}
              </span>
            </h2>
            {columnLeads.length === 0 ? (
              <p className="text-xs text-[var(--color-text-tertiary)]">
                {column.emptyHint}
              </p>
            ) : (
              columnLeads.map((lead) => (
                <LeadCard
                  key={lead.id}
                  lead={lead}
                  platz={platzByLead[lead.id]}
                  column={column}
                  onOpen={onOpen}
                  onOpenErstgespraech={onOpenErstgespraech}
                  onMarkContacted={onMarkContacted}
                  onAssignPlatz={onAssignPlatz}
                  onConvert={onConvert}
                  onReject={onReject}
                />
              ))
            )}
          </section>
        )
      })}
    </div>
  )

  return scrolls ? <div className="-mx-4 overflow-x-auto px-4">{body}</div> : body
}
