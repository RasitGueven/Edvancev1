import { Link } from 'react-router-dom'
import { FileText, Phone } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { formatDateOnly } from '@/lib/datetime'
import type { VertragMitLead } from '@/types'
import { AgeLine } from '../leads/AgeLine'
import { CardMenu, type CardMenuItem } from '../leads/CardMenu'
import { PapierAbschluss } from './PapierAbschluss'
import { formatEuro } from './VertragForm'
import { elternName, kindName, vertragAge, vertragFollowUp } from './vertragModel'
import { openUnterlagen } from './vertragUi'

type VertragCardProps = {
  vertrag: VertragMitLead
  /** Name des Pakets aus tiers, falls gewaehlt. */
  paket: string | null
  busy: boolean
  onPaperSigned: (vertrag: VertragMitLead, unterschriebenAm: string) => void
  onReject: (vertrag: VertragMitLead) => void
  onConvert: (vertrag: VertragMitLead) => void
}

export function VertragCard({
  vertrag,
  paket,
  busy,
  onPaperSigned,
  onReject,
  onConvert,
}: VertragCardProps): JSX.Element {
  const { t, i18n } = useTranslation('vertraege')
  const { t: tl } = useTranslation('leads')
  const eltern = elternName(vertrag)
  const telefon = vertrag.eltern_telefon ?? vertrag.lead.contact_phone
  const offen = vertrag.status === 'in_vorbereitung' || vertrag.status === 'unterschrift_ausstehend'
  const konvertierbar =
    vertrag.status === 'abgeschlossen' &&
    vertrag.lead.converted_student_id === null &&
    vertrag.lead.status !== 'converted'

  const menuItems: CardMenuItem[] = [
    ...(konvertierbar ? [{ label: tl('convert.action'), onSelect: () => onConvert(vertrag) }] : []),
    ...(offen ? [{ label: t('card.reject'), onSelect: () => onReject(vertrag), danger: true }] : []),
  ]

  return (
    <EdvanceCard className="flex min-w-0 flex-col gap-3 p-4">
      <div className="flex min-w-0 items-start justify-between gap-2">
        <Link
          to={`/admin/vertraege/${vertrag.id}`}
          className="line-clamp-2 min-w-0 flex-1 break-words text-base font-semibold text-[var(--color-text-primary)] hover:text-[var(--color-primary)]"
        >
          {kindName(vertrag)}
        </Link>
        <CardMenu items={menuItems} />
      </div>

      <AgeLine age={vertragAge(vertrag)} followUp={vertragFollowUp(vertrag)} />

      {(eltern || telefon) && (
        <div className="flex flex-col gap-1 text-xs text-[var(--color-text-secondary)]">
          {eltern && <p className="truncate">{t('card.parent', { name: eltern })}</p>}
          {telefon && (
            <a
              href={`tel:${telefon.replace(/[^\d+]/g, '')}`}
              className="inline-flex items-center gap-1 font-medium text-[var(--color-primary)] hover:underline"
            >
              <Phone className="h-3.5 w-3.5" />
              {telefon}
            </a>
          )}
        </div>
      )}

      {paket && vertrag.preis_cents !== null && (
        <p className="text-xs text-[var(--color-text-secondary)]">
          {t('card.paket', { paket, preis: formatEuro(vertrag.preis_cents, i18n.language) })}
        </p>
      )}

      {vertrag.status === 'abgeschlossen' && vertrag.unterschrieben_am && (
        <p className="text-xs text-[var(--color-text-secondary)]">
          {t('card.closedOn', { date: formatDateOnly(vertrag.unterschrieben_am, i18n.language) })}
        </p>
      )}

      {vertrag.status === 'abgelehnt' && vertrag.abgelehnt_grund && (
        <p className="text-xs text-[var(--color-text-secondary)]">
          {tl('card.rejectedReason', {
            reason: vertrag.abgelehnt_notiz ?? tl(`reasons.${vertrag.abgelehnt_grund}`),
          })}
        </p>
      )}

      {vertrag.status === 'in_vorbereitung' && (
        <Button size="sm" asChild>
          <Link to={`/admin/vertraege/${vertrag.id}`}>{t('card.capture')}</Link>
        </Button>
      )}
      {vertrag.status === 'unterschrift_ausstehend' && (
        <PapierAbschluss
          idPrefix={`card-${vertrag.id}`}
          saving={busy}
          onConfirm={(datum) => onPaperSigned(vertrag, datum)}
        />
      )}
      {(vertrag.status === 'unterschrift_ausstehend' || vertrag.status === 'abgeschlossen') && (
        <Button size="sm" variant="outline" onClick={() => openUnterlagen(vertrag.id)}>
          <FileText className="h-4 w-4" />
          {t('card.viewDocs')}
        </Button>
      )}
    </EdvanceCard>
  )
}
