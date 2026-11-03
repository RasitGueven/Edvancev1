import { useCallback, useEffect, useState } from 'react'
import { Mail } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'
import { lsaReportMail, type LsaReportEmpfaenger } from '@/lib/lsaReportMail'
import { ladeLsaReportEmpfaenger } from '@/lib/supabase/lsaReportMail'
import type { ReportData } from '@/types'
import { LsaReportMailModal } from './LsaReportMailModal'
import { mailSperre } from './mailSperre'

type Props = {
  data: ReportData | null
  admin: boolean
  /** Bericht oder Pakete laden noch. */
  laedt: boolean
  ungespeichert: boolean
}

/**
 * „Per E-Mail senden“ auf der Report-Seite (Bauauftrag LR-2). Gesperrt nur aus
 * den Gründen in mailSperre, mit dem Grund als Tooltip (Muster AktionenKarte).
 * Das PDF entsteht aus dem Bogen, den die Seite gerade zeigt — mit demselben
 * Preise-Schalter und Ausblick wie „Drucken“ (Entscheidung 2).
 */
export function LsaReportMailKnopf({ data, admin, laedt, ungespeichert }: Props): JSX.Element {
  const { t } = useTranslation('report')
  const { t: tv } = useTranslation('vertraege')
  const [offen, setOffen] = useState(false)
  const [empfaenger, setEmpfaenger] = useState<LsaReportEmpfaenger | null | 'laedt'>('laedt')

  const leadId = data?.leadId ?? null
  useEffect(() => {
    if (!admin || !leadId) {
      setEmpfaenger(null)
      return
    }
    let active = true
    setEmpfaenger('laedt')
    void ladeLsaReportEmpfaenger(leadId).then(({ data: lead }) => active && setEmpfaenger(lead))
    return () => {
      active = false
    }
  }, [admin, leadId])

  const lead = empfaenger === 'laedt' ? null : empfaenger
  const sperre = mailSperre({
    admin,
    laedt: laedt || data === null || empfaenger === 'laedt',
    nichtAuswertbar: data?.auswertbar === false,
    elternMail: lead?.contact_email ?? null,
    ungespeichert,
  })
  const mail = data && lead ? lsaReportMail(lead, data.analysedAt, data.testlauf, (k, v) => tv(k, v)) : null

  const erzeugePdf = useCallback(async (): Promise<Blob> => {
    const bogen = document.querySelector<HTMLElement>('.eb-ansicht .eb-bogen')
    if (!bogen || !mail) throw new Error('No report sheet on the page')
    const { bogenZuPdf } = await import('@/lib/report/bogenPdf')
    return bogenZuPdf(bogen, mail.datei.replace(/\.pdf$/, ''))
  }, [mail])

  return (
    <>
      <span className="inline-flex" title={sperre ? t(`actions.emailGesperrt.${sperre}`) : undefined}>
        <Button type="button" variant="secondary" disabled={sperre !== null} onClick={() => setOffen(true)}>
          <Mail className="mr-2 h-4 w-4" />
          {t('actions.email')}
        </Button>
      </span>
      {data && mail && lead && (
        <LsaReportMailModal
          open={offen}
          onClose={() => setOffen(false)}
          sessionId={data.sessionId}
          an={(lead.contact_email ?? '').trim()}
          mail={mail}
          erzeugePdf={erzeugePdf}
        />
      )}
    </>
  )
}
