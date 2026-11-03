import { useEffect, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'
import { CheckCircle2, FileText, Mail } from 'lucide-react'
import { LoadingPulse } from '@/components/edvance'
import { Modal } from '@/components/edvance/Modal'
import { Button } from '@/components/ui/button'
import { formatBerlinDateTime } from '@/lib/datetime'
import type { LsaReportMail } from '@/lib/lsaReportMail'
import { listLsaReportVersand, lsaReportHochladen, lsaReportSenden } from '@/lib/supabase/lsaReportMail'
import type { LeadMailVersand } from '@/types'

type LsaReportMailModalProps = {
  open: boolean
  onClose: () => void
  sessionId: string
  /** Eltern-Mail am Lead — nur zur Anzeige; die Edge Function liest sie selbst. */
  an: string
  mail: LsaReportMail
  /** Erzeugt das PDF aus dem Bogen der Seite (bogenZuPdf). */
  erzeugePdf: () => Promise<Blob>
}

const HINWEIS =
  'rounded-xl border border-[var(--color-gold-warning)] bg-[var(--color-gold-warning-light)] px-4 py-3 text-sm leading-relaxed text-[var(--color-text-primary)]'

function megabyte(bytes: number, sprache: string): string {
  return new Intl.NumberFormat(sprache, { style: 'unit', unit: 'megabyte', maximumFractionDigits: 1 }).format(
    bytes / 1_000_000,
  )
}

/**
 * Der Eltern-Bericht per Mail (Bauauftrag LR-2, Entscheidung 9), nach dem
 * Muster von TerminBestaetigungModal: „An: …“, Vorschau der Mail, Dateiname und
 * Größe des Anhangs. Das PDF entsteht beim Öffnen, damit Größe und ein
 * „zu groß“ vor dem Senden feststehen. Senden lädt es hoch und ruft
 * mail_senden. Scheitert der Versand, bleibt die Datei liegen und „Erneut
 * versuchen“ schickt dieselbe Datei, ohne neuen Upload.
 */
export function LsaReportMailModal({ open, onClose, sessionId, an, mail, erzeugePdf }: LsaReportMailModalProps): JSX.Element {
  const { t, i18n } = useTranslation('report')
  const { t: tc } = useTranslation('common')
  const [pdf, setPdf] = useState<Blob | null>(null)
  const [pdfFehler, setPdfFehler] = useState<string | null>(null)
  const [pfad, setPfad] = useState<string | null>(null)
  const [log, setLog] = useState<LeadMailVersand[] | null>(null)
  const [sending, setSending] = useState(false)
  const [fehler, setFehler] = useState<string | null>(null)
  const [gesendetAn, setGesendetAn] = useState<string | null>(null)
  const erzeuge = useRef(erzeugePdf)
  erzeuge.current = erzeugePdf

  useEffect(() => {
    if (!open) return
    let active = true
    setPdf(null)
    setPdfFehler(null)
    setPfad(null)
    setLog(null)
    setFehler(null)
    setGesendetAn(null)
    void listLsaReportVersand(sessionId).then(({ data, error }) => {
      if (!active) return
      setLog(data ?? [])
      if (error) setFehler(error)
    })
    erzeuge
      .current()
      .then((blob) => active && setPdf(blob))
      .catch((e: unknown) => {
        if (!active) return
        const zuGross = e instanceof Error && e.name === 'PdfZuGross'
        const bytes = zuGross ? (e as Error & { bytes: number }).bytes : 0
        const ohneSchrift = e instanceof Error && e.name === 'PdfOhneSchrift'
        setPdfFehler(
          zuGross
            ? t('mailDialog.zuGross', { groesse: megabyte(bytes, i18n.language) })
            : t(ohneSchrift ? 'mailDialog.ohneSchrift' : 'mailDialog.pdfFehler'),
        )
      })
    return () => {
      active = false
    }
  }, [open, sessionId, t, i18n.language])

  const letzteOk = log?.find((v) => v.fehler === null) ?? null
  const letzte = log?.[0] ?? null
  const datum = (iso: string): string => formatBerlinDateTime(iso, i18n.language)

  const senden = async (): Promise<void> => {
    if (!pdf || sending) return
    setSending(true)
    setFehler(null)
    let ziel = pfad
    if (!ziel) {
      const hoch = await lsaReportHochladen(sessionId, pdf)
      if (hoch.error || !hoch.data) {
        setSending(false)
        setFehler(t('mailDialog.uploadFehler', { fehler: hoch.error ?? '' }))
        return
      }
      ziel = hoch.data
      setPfad(ziel)
    }
    const res = await lsaReportSenden(sessionId, ziel)
    const neu = await listLsaReportVersand(sessionId)
    setLog(neu.data ?? log)
    setSending(false)
    if (res.error) {
      setFehler(res.error)
      return
    }
    setGesendetAn(res.data?.an ?? an)
  }

  const knopf =
    fehler && pfad ? t('mailDialog.erneutVersuchen') : letzteOk || gesendetAn ? t('mailDialog.erneutSenden') : t('mailDialog.senden')

  return (
    <Modal
      open={open}
      onClose={onClose}
      size="lg"
      title={t('mailDialog.title')}
      description={t('mailDialog.description')}
      footer={
        <>
          <Button variant="outline" onClick={onClose} disabled={sending}>
            {tc('close')}
          </Button>
          <span title={pdf ? undefined : (pdfFehler ?? t('mailDialog.pdfLaeuft'))}>
            <Button disabled={!pdf || sending} loading={sending} onClick={() => void senden()}>
              <Mail className="h-4 w-4" />
              {knopf}
            </Button>
          </span>
        </>
      }
    >
      <div className="flex flex-col gap-4">
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">{t('mailDialog.an', { email: an })}</p>

        {gesendetAn && (
          <div className="flex items-center gap-2 text-sm text-[var(--color-success)]">
            <CheckCircle2 className="h-4 w-4 shrink-0" />
            {t('mailDialog.gesendet', { email: gesendetAn })}
          </div>
        )}

        {log === null && <LoadingPulse lines={1} />}
        {!gesendetAn && letzteOk && (
          <p className={HINWEIS}>{t('mailDialog.zuletzt', { date: datum(letzteOk.erfolgt_at), email: letzteOk.empfaenger })}</p>
        )}
        {!gesendetAn && !fehler && letzte && letzte.fehler !== null && (
          <p className="text-sm text-[var(--color-error-exam)]">
            {t('mailDialog.letzterFehler', { date: datum(letzte.erfolgt_at), fehler: letzte.fehler })}
          </p>
        )}

        <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-bg-subtle)] p-4">
          <p className="text-xs text-[var(--color-text-tertiary)]">{t('mailDialog.vorschau')}</p>
          <p className="text-sm font-semibold text-[var(--color-text-primary)]">{mail.betreff}</p>
          <p data-testid="lsa-mail-text" className="whitespace-pre-line text-sm leading-relaxed text-[var(--color-text-primary)]">
            {mail.text}
          </p>
        </div>

        <div className="flex items-center gap-2 text-sm text-[var(--color-text-secondary)]" data-testid="lsa-mail-anhang">
          <FileText className="h-4 w-4 shrink-0" />
          {pdf
            ? t('mailDialog.anhang', { datei: mail.datei, groesse: megabyte(pdf.size, i18n.language) })
            : pdfFehler
              ? mail.datei
              : t('mailDialog.anhangEntsteht', { datei: mail.datei })}
        </div>

        {pdfFehler && <p className="text-sm text-[var(--color-error-exam)]">{pdfFehler}</p>}
        {fehler && <p className="text-sm text-[var(--color-error-exam)]">{fehler}</p>}
      </div>
    </Modal>
  )
}
