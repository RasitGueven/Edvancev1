import { useEffect, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { CheckCircle2, Mail } from 'lucide-react'
import { LoadingPulse } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { formatBerlinDateTime } from '@/lib/datetime'
import { listLeadMailVersand, terminBestaetigungSenden } from '@/lib/supabase/leadMail'
import { terminMail } from '@/lib/terminBestaetigung'
import type { Lead, LeadMailVersand } from '@/types'

type TerminBestaetigungModalProps = {
  /** Lead, dessen Termin bestaetigt wird; null = geschlossen. */
  lead: Lead | null
  onClose: () => void
}

const HINWEIS =
  'rounded-xl border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] px-4 py-3 text-sm leading-relaxed text-[var(--color-text-primary)]'

/**
 * Terminbestaetigung an die Eltern: Vorschau der Mail, dann Senden ueber
 * hello@ (Edge Function mail_senden). Kein Automatismus — der Admin loest aus.
 * Erneut senden geht; der Hinweis darueber sagt, wann zuletzt und ob die
 * letzte Mail noch den aktuellen Termin nannte.
 */
export function TerminBestaetigungModal({ lead, onClose }: TerminBestaetigungModalProps): JSX.Element {
  const { t, i18n } = useTranslation('leads')
  const { t: tv } = useTranslation('vertraege')
  const { t: tc } = useTranslation('common')
  const [log, setLog] = useState<LeadMailVersand[] | null>(null)
  const [sending, setSending] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [gesendetAn, setGesendetAn] = useState<string | null>(null)

  const leadId = lead?.id ?? null
  useEffect(() => {
    if (!leadId) return
    let active = true
    setLog(null)
    setFehler(null)
    setGesendetAn(null)
    void listLeadMailVersand(leadId).then(({ data, error }) => {
      if (!active) return
      setLog(data ?? [])
      if (error) setFehler(error)
    })
    return () => {
      active = false
    }
  }, [leadId])

  const mail = lead ? terminMail(lead, (k, v) => tv(k, v)) : null
  const an = (lead?.contact_email ?? '').trim()
  const letzte = log?.find((v) => v.anlass === 'terminbestaetigung') ?? null
  const letzteOk = log?.find((v) => v.anlass === 'terminbestaetigung' && v.fehler === null) ?? null
  const datum = (iso: string): string => formatBerlinDateTime(iso, i18n.language)

  const sperre =
    an === ''
      ? t('bestaetigung.keineMail')
      : mail === null
        ? t('bestaetigung.keinTermin')
        : mail.platzhalter
          ? t('bestaetigung.platzhalter')
          : null

  const senden = async (): Promise<void> => {
    if (!leadId || sperre !== null || sending) return
    setSending(true)
    setFehler(null)
    const res = await terminBestaetigungSenden(leadId)
    const neu = await listLeadMailVersand(leadId)
    setLog(neu.data ?? log)
    setSending(false)
    if (res.error) {
      setFehler(res.error)
      return
    }
    setGesendetAn(res.data?.an ?? an)
  }

  return (
    <Modal
      open={lead !== null}
      onClose={onClose}
      size="lg"
      title={t('bestaetigung.title')}
      description={lead ? t('bestaetigung.description', { name: lead.full_name }) : undefined}
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={sending}>
            {tc('close')}
          </Button>
          <span title={sperre ?? undefined}>
            <Button
              disabled={sperre !== null || sending || log === null}
              loading={sending}
              onClick={() => void senden()}
            >
              <Mail className="h-4 w-4" />
              {letzteOk || gesendetAn ? t('bestaetigung.erneut') : t('bestaetigung.senden')}
            </Button>
          </span>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {an !== '' ? t('bestaetigung.an', { email: an }) : t('bestaetigung.keineMail')}
        </p>

        {log === null && <LoadingPulse lines={1} />}

        {gesendetAn && (
          <div className="flex items-center gap-2 text-sm text-[var(--color-success)]">
            <CheckCircle2 className="h-4 w-4 shrink-0" />
            {t('bestaetigung.gesendet', { email: gesendetAn })}
          </div>
        )}

        {!gesendetAn && letzteOk && (
          <p className={HINWEIS}>
            {t('bestaetigung.schonGesendet', {
              date: datum(letzteOk.erfolgt_at),
              email: letzteOk.empfaenger,
            })}
            {letzteOk.termin_at !== lead?.erstgespraech_at && letzteOk.termin_at && (
              <> {t('bestaetigung.alterTermin', { date: datum(letzteOk.termin_at) })}</>
            )}
          </p>
        )}

        {!gesendetAn && letzte && letzte.fehler !== null && (
          <p className="text-sm text-[var(--color-error-exam)]">
            {t('bestaetigung.letzterFehler', { date: datum(letzte.erfolgt_at), fehler: letzte.fehler })}
          </p>
        )}

        {mail?.platzhalter && <p className={HINWEIS}>{t('bestaetigung.platzhalter')}</p>}

        {mail && (
          <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
            <p className="text-xs text-[var(--color-text-tertiary)]">{t('bestaetigung.vorschau')}</p>
            <p className="text-sm font-semibold text-[var(--color-text-primary)]">{mail.betreff}</p>
            <p
              data-testid="termin-mail-text"
              className="whitespace-pre-line text-sm leading-relaxed text-[var(--color-text-primary)]"
            >
              {mail.text}
            </p>
          </div>
        )}

        {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}
      </div>
    </Modal>
  )
}
