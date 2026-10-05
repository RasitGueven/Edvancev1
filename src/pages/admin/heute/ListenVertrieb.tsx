import { Link } from 'react-router-dom'
import { ClipboardCheck, Inbox, MessagesSquare } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { LeadPlatz } from '@/lib/supabase/platz'
import type { Lead } from '@/types'
import { daysWaiting } from '../leads/boardModel'
import { ArbeitsListe, type ListenZeile } from './ArbeitsListe'
import { WARTEN_AMBER_TAGE } from './heuteModel'

/** Datum und Uhrzeit in Berliner Zeit, in der UI-Sprache. */
export function berlinZeit(iso: string, locale: string, mitDatum: boolean): string {
  return new Intl.DateTimeFormat(locale, {
    timeZone: 'Europe/Berlin',
    ...(mitDatum ? { weekday: 'short', day: 'numeric', month: 'short' } : {}),
    hour: '2-digit',
    minute: '2-digit',
  }).format(new Date(iso))
}

function leadMeta(lead: Lead, tl: (k: string, o?: Record<string, unknown>) => string): string {
  return [
    lead.class_level !== null ? tl('card.classShort', { level: lead.class_level }) : null,
    lead.subjects.length > 0 ? lead.subjects.join(', ') : null,
  ]
    .filter(Boolean)
    .join(' · ')
}

export function NeueLeadsListe({ leads, onTermin }: { leads: Lead[]; onTermin: (lead: Lead) => void }): JSX.Element {
  const { t } = useTranslation('admin')
  const { t: tl } = useTranslation('leads')
  const zeilen: ListenZeile[] = leads.map((lead) => {
    const tage = daysWaiting(lead.created_at)
    return {
      key: lead.id,
      titel: lead.full_name,
      unterzeile: leadMeta(lead, tl),
      rechts: (
        <>
          <EdvanceBadge variant={tage >= WARTEN_AMBER_TAGE ? 'warning' : 'muted'}>
            {t('heute.listen.neueLeads.seit', { count: tage })}
          </EdvanceBadge>
          <Button type="button" size="sm" variant="outline" className="min-h-[44px]" onClick={() => onTermin(lead)}>
            {t('heute.listen.neueLeads.termin')}
          </Button>
        </>
      ),
    }
  })
  return (
    <ArbeitsListe
      icon={Inbox}
      titel={t('heute.listen.neueLeads.titel')}
      unterzeile={t('heute.listen.neueLeads.unterzeile')}
      anzahl={leads.length}
      zeilen={zeilen}
      fussLabel={t('heute.listen.neueLeads.fuss')}
      fussZiel="/admin/leads"
    />
  )
}

export function ErstgespraecheListe({ leads }: { leads: Lead[] }): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const { t: tl } = useTranslation('leads')
  const zeilen: ListenZeile[] = leads.map((lead) => ({
    key: lead.id,
    titel: lead.full_name,
    unterzeile: t('heute.listen.erstgespraeche.termin', {
      zeit: lead.erstgespraech_at ? berlinZeit(lead.erstgespraech_at, i18n.language, true) : '—',
      ort: tl(`standort.${lead.erstgespraech_standort ?? 'koeln'}`),
    }),
    rechts:
      lead.class_level !== null ? (
        <EdvanceBadge variant="primary">{tl('card.classShort', { level: lead.class_level })}</EdvanceBadge>
      ) : undefined,
  }))
  return (
    <ArbeitsListe
      icon={MessagesSquare}
      titel={t('heute.listen.erstgespraeche.titel')}
      unterzeile={t('heute.listen.erstgespraeche.unterzeile')}
      anzahl={leads.length}
      zeilen={zeilen}
      fussLabel={t('heute.listen.erstgespraeche.fuss')}
      fussZiel="/admin/leads"
    />
  )
}

type LsaProps = {
  leads: Lead[]
  platzByLead: Record<string, LeadPlatz>
  reportByLead: Record<string, string>
  canStartContract: boolean
  busyLeadId: string | null
  onStartContract: (lead: Lead) => void
}

/**
 * Freigegebene und fertige Analysen. Ersetzt die frühere Karte „Heute
 * abgeschlossen“ (LsaTodayCard) unter dem Leads-Board: Der Name einer fertigen
 * Analyse führt in den Report, der Knopf startet den Vertrag wie auf dem Board.
 */
export function LsaListe({ leads, platzByLead, reportByLead, canStartContract, busyLeadId, onStartContract }: LsaProps): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const { t: tl } = useTranslation('leads')
  const lang = i18n.language
  const zeilen: ListenZeile[] = leads.map((lead) => {
    if (lead.status === 'lsa_fertig') {
      const report = reportByLead[lead.id]
      const busy = busyLeadId === lead.id
      return {
        key: lead.id,
        titel: report ? (
          <Link to={`/admin/report/${report}`} className="text-[var(--color-text-link)] hover:underline">
            {lead.full_name}
          </Link>
        ) : (
          lead.full_name
        ),
        unterzeile: lead.lsa_fertig_at
          ? t('heute.listen.lsa.fertigAm', { zeit: berlinZeit(lead.lsa_fertig_at, lang, true) })
          : t('heute.listen.lsa.fertig'),
        rechts: (
          <span title={canStartContract ? undefined : tl('card.startContractAdminOnly')}>
            <Button
              type="button"
              size="sm"
              className="min-h-[44px]"
              disabled={!canStartContract || busyLeadId !== null}
              onClick={() => onStartContract(lead)}
            >
              {busy ? tl('card.startingContract') : tl('card.startContract')}
            </Button>
          </span>
        ),
      }
    }
    const platz = platzByLead[lead.id]
    return {
      key: lead.id,
      titel: lead.full_name,
      unterzeile: platz
        ? t('heute.listen.lsa.platz', { platz: platz.label, bis: berlinZeit(platz.expires_at, lang, false) })
        : t('heute.listen.lsa.ohnePlatz'),
      rechts: <EdvanceBadge variant="primary">{t('heute.listen.lsa.laeuft')}</EdvanceBadge>,
    }
  })
  return (
    <ArbeitsListe
      icon={ClipboardCheck}
      titel={t('heute.listen.lsa.titel')}
      unterzeile={t('heute.listen.lsa.unterzeile')}
      anzahl={leads.length}
      zeilen={zeilen}
      fussLabel={t('heute.listen.lsa.fuss')}
      fussZiel="/admin/leads"
    />
  )
}
