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
  onAssignPlatz: (lead: Lead) => void
  onConvert: (lead: Lead) => void
  onReject: (lead: Lead) => void
}

// Vier bis fuenf Spalten nebeneinander; auf schmalen Schirmen scrollt das
// Board waagerecht, statt die Spalten zu stapeln — die Pipeline bleibt so als
// Abfolge lesbar. Kein Drag & Drop: der Status wechselt ueber die Karten.
export function LeadBoard({
  columns,
  leads,
  filters,
  platzByLead,
  onOpen,
  onOpenErstgespraech,
  onAssignPlatz,
  onConvert,
  onReject,
}: LeadBoardProps): JSX.Element {
  return (
    <div className="-mx-4 overflow-x-auto px-4">
      <div className="flex min-w-max gap-4">
        {columns.map((column) => {
          const columnLeads = leadsForColumn(leads, column, filters)
          return (
            <section key={column.key} className="flex w-72 shrink-0 flex-col gap-4">
              <div className="flex items-center justify-between gap-2">
                <h2 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-muted)]">
                  {column.title}
                </h2>
                <span className="text-xs font-semibold text-[var(--color-text-tertiary)]">
                  {columnLeads.length}
                </span>
              </div>
              {columnLeads.length === 0 ? (
                <p className="text-xs text-[var(--color-text-tertiary)]">{column.emptyHint}</p>
              ) : (
                columnLeads.map((lead) => (
                  <LeadCard
                    key={lead.id}
                    lead={lead}
                    platz={platzByLead[lead.id]}
                    column={column.key}
                    onOpen={onOpen}
                    onOpenErstgespraech={onOpenErstgespraech}
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
    </div>
  )
}
