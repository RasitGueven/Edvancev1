import { Link } from 'react-router-dom'
import { CalendarClock, FileText, MonitorSmartphone, Pencil } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { formatBerlinDateTime } from '@/lib/datetime'
import type { Lead } from '@/types'
import type { LeadPlatz } from '@/lib/supabase/platz'
import { AgeLine } from './AgeLine'
import { CardMenu, type CardMenuItem } from './CardMenu'
import { ageDisplay, followUpDays, stateTimestamp, type BoardColumn } from './boardModel'

type LeadCardProps = {
  lead: Lead
  platz?: LeadPlatz
  column: BoardColumn
  /** Juengste abgeschlossene LSA-Session — Ziel des Report-Links. */
  reportSessionId?: string
  /** Vertraege startet nur die Verwaltung (RPC vertrag_starten ist admin-only). */
  canStartContract: boolean
  /** Laeuft fuer diesen Lead gerade eine Aktion? Sperrt Doppelklicks. */
  busy: boolean
  /** Wizard auf Schritt 1 (Stammdaten) oeffnen — Klick auf den Namen. */
  onOpen: (lead: Lead) => void
  /** Wizard direkt auf Schritt 2 (Erstgespraech) oeffnen. */
  onOpenErstgespraech: (lead: Lead) => void
  /** Termin-Modal: erstmals (Spalte 1) oder zum Aendern. */
  onTermin: (lead: Lead) => void
  onAssignPlatz: (lead: Lead) => void
  onReject: (lead: Lead) => void
  onStartContract: (lead: Lead) => void
}

export function LeadCard({
  lead,
  platz,
  column,
  reportSessionId,
  canStartContract,
  busy,
  onOpen,
  onOpenErstgespraech,
  onTermin,
  onAssignPlatz,
  onReject,
  onStartContract,
}: LeadCardProps): JSX.Element {
  const { t, i18n } = useTranslation('leads')
  const age = ageDisplay(lead, column)
  const followUp = column.followUp ? followUpDays(stateTimestamp(lead)) : null
  // Leere Werte fallen raus, damit keine Trennpunkte ins Leere zeigen.
  const meta = [
    lead.class_level !== null ? t('card.classShort', { level: lead.class_level }) : null,
    lead.school_type,
    lead.subjects.length > 0 ? lead.subjects.join(', ') : null,
  ].filter((part): part is string => part !== null && part !== '')

  // Ablehnen steht im Overflow — ausser in "Analyse abgeschlossen", wo es als
  // eigener Button neben "Vertrag starten" steht. Im Archiv gibt es nichts mehr.
  const reject: CardMenuItem = {
    label: t('card.reject'),
    onSelect: () => onReject(lead),
    danger: true,
  }
  const menuItems: CardMenuItem[] =
    column.key === 'neu'
      ? [{ label: t('card.captureErstgespraech'), onSelect: () => onOpenErstgespraech(lead) }, reject]
      : column.key === 'gespraech'
        ? [{ label: t('card.editTermin'), onSelect: () => onTermin(lead) }, reject]
        : column.key === 'analyse'
          ? [reject]
          : []

  return (
    <EdvanceCard className="flex min-w-0 flex-col gap-3 p-4">
      <div className="flex min-w-0 items-start justify-between gap-2">
        {/* full_name ist NOT NULL — kein Rueckfall auf den Rufnamen. Zwei
            Leads mit gleichem Rufnamen muessen hier unterscheidbar sein,
            deshalb bricht der Name auf zwei Zeilen um statt zu kuerzen. */}
        <button
          type="button"
          onClick={() => onOpen(lead)}
          title={lead.full_name}
          className="line-clamp-2 min-w-0 flex-1 break-words text-left text-base font-semibold text-[var(--color-text-primary)] hover:text-[var(--color-primary)]"
        >
          {lead.full_name}
        </button>
        <CardMenu items={menuItems} />
      </div>

      <AgeLine age={age} followUp={followUp} />

      {meta.length > 0 && (
        <p className="truncate text-xs text-[var(--color-text-secondary)]">{meta.join(' · ')}</p>
      )}

      {lead.erstgespraech_at && (
        <div className="flex items-center gap-2 text-xs text-[var(--color-text-secondary)]">
          <CalendarClock className="h-3.5 w-3.5 shrink-0" />
          <span className="min-w-0 flex-1 truncate">
            {t('card.terminAt', {
              date: formatBerlinDateTime(lead.erstgespraech_at, i18n.language),
              location: t(`standort.${lead.erstgespraech_standort ?? 'koeln'}`),
            })}
          </span>
          {column.key === 'gespraech' && (
            <button
              type="button"
              aria-label={t('card.editTermin')}
              title={t('card.editTermin')}
              onClick={() => onTermin(lead)}
              className="rounded-full p-1 text-[var(--color-text-tertiary)] hover:bg-[var(--color-bg-app)]"
            >
              <Pencil className="h-3.5 w-3.5" />
            </button>
          )}
        </div>
      )}

      {platz && (
        <EdvanceBadge variant="success">
          <MonitorSmartphone className="mr-1 inline h-3.5 w-3.5" />
          {platz.label}
        </EdvanceBadge>
      )}

      {lead.status === 'rejected' && lead.rejection_reason && (
        <p className="text-xs text-[var(--color-text-secondary)]">
          {t('card.rejectedReason', {
            reason:
              lead.rejection_reason === 'sonstiges' && lead.rejection_note
                ? lead.rejection_note
                : t(`reasons.${lead.rejection_reason}`),
          })}
        </p>
      )}

      {reportSessionId && column.key === 'entscheidung' && (
        <Link
          to={`/admin/report/${reportSessionId}`}
          className="inline-flex min-h-[44px] items-center gap-2 text-sm font-medium text-[var(--color-primary)] hover:underline"
        >
          <FileText className="h-4 w-4" />
          {t('card.report')}
        </Link>
      )}

      {/* Eine Primaeraktion je Spalte — der naechste Schritt im Trichter. */}
      {column.key === 'neu' && (
        <Button size="sm" disabled={busy} onClick={() => onTermin(lead)}>
          {t('card.markContacted')}
        </Button>
      )}
      {column.key === 'gespraech' && (
        <Button size="sm" onClick={() => onOpenErstgespraech(lead)}>
          {t('card.captureErstgespraech')}
        </Button>
      )}
      {column.key === 'analyse' && (
        <>
          <Button size="sm" onClick={() => onAssignPlatz(lead)}>
            {t('card.assignPlatz')}
          </Button>
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('card.analysisRunning')}</p>
        </>
      )}
      {column.key === 'entscheidung' && (
        <div className="grid grid-cols-2 gap-2">
          <Button size="sm" variant="outline" disabled={busy} onClick={() => onReject(lead)}>
            {t('card.reject')}
          </Button>
          <span title={canStartContract ? undefined : t('card.startContractAdminOnly')}>
            <Button
              size="sm"
              className="w-full"
              disabled={busy || !canStartContract}
              onClick={() => onStartContract(lead)}
            >
              {busy ? t('card.startingContract') : t('card.startContract')}
            </Button>
          </span>
        </div>
      )}
    </EdvanceCard>
  )
}
