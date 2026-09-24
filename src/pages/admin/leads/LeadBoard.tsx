import { useTranslation } from 'react-i18next'
import type { Lead } from '@/types'
import type { LeadPlatz } from '@/lib/supabase/platz'
import { BoardColumns } from './BoardColumns'
import { LeadCard } from './LeadCard'
import { leadsForColumn, type BoardColumn, type LeadFilters } from './boardModel'

type LeadBoardProps = {
  columns: BoardColumn[]
  leads: Lead[]
  filters: LeadFilters
  platzByLead: Record<string, LeadPlatz>
  reportByLead: Record<string, string>
  canStartContract: boolean
  busyLeadId: string | null
  onOpen: (lead: Lead) => void
  onOpenErstgespraech: (lead: Lead) => void
  onTermin: (lead: Lead) => void
  onAssignPlatz: (lead: Lead) => void
  onReject: (lead: Lead) => void
  onStartContract: (lead: Lead) => void
}

export function LeadBoard({
  columns,
  leads,
  filters,
  platzByLead,
  reportByLead,
  canStartContract,
  busyLeadId,
  ...handlers
}: LeadBoardProps): JSX.Element {
  const { t } = useTranslation('leads')
  const byKey = new Map(columns.map((c) => [c.key as string, c]))

  return (
    <BoardColumns
      maxFitting={4}
      columns={columns.map((column) => ({
        key: column.key,
        title: t(`columns.${column.key}.title`),
        emptyHint: t(`columns.${column.key}.empty`),
        items: leadsForColumn(leads, column, filters),
      }))}
      itemKey={(lead) => lead.id}
      renderItem={(lead, columnKey) => (
        <LeadCard
          lead={lead}
          platz={platzByLead[lead.id]}
          column={byKey.get(columnKey) as BoardColumn}
          reportSessionId={reportByLead[lead.id]}
          canStartContract={canStartContract}
          busy={busyLeadId === lead.id}
          {...handlers}
        />
      )}
    />
  )
}
