import { useCallback, useEffect, useState } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { Printer, Mail } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { LoadingPulse } from '@/components/edvance'
import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { ReportBody } from '@/components/edvance/report/ReportBody'
import { ReportOutlook } from '@/components/edvance/report/ReportOutlook'
import { Button } from '@/components/ui/button'
import { useAuth } from '@/hooks/useAuth'
import { getReportData } from '@/lib/supabase/lsaReport'
import {
  EMPTY_NOTES,
  getReportNotes,
  saveReportNotes,
} from '@/lib/supabase/reportNotes'
import { listTiers } from '@/lib/supabase/subscriptions'
import type { ReportData, ReportNotes, TierPlan } from '@/types'
import { TestlaufBanner } from './testmodus/TestlaufBanner'

/**
 * Eltern-Report zu einer LSA-Sitzung (/admin/report/:sessionId).
 *
 * Read-only gegenüber den Sitzungsdaten — geschrieben werden ausschließlich die
 * zwei Freitexte im Ausblick, seit X0 nur vom Admin (Entscheidung 26: Coaches
 * lesen Reports, schreiben sie nicht). Die Bewertung richtig/falsch stammt aus
 * lsa_responses.correct (serverseitig gesetzt); Lösungen erreichen den Client
 * nie.
 *
 * Zwei Fassungen (Bauauftrag R7, Entscheidung 1): ohne Parameter R6, mit
 * ?fassung=r7 der Druckbogen nach Muster E7. Umgestellt wird erst nach der
 * Abnahme; bis dahin schaltet der Knopf in den Aktionen um.
 */
export function ReportPage(): JSX.Element {
  const { sessionId } = useParams<{ sessionId: string }>()
  const { t } = useTranslation('report')
  const { t: tb } = useTranslation('elternbericht')
  const { role } = useAuth()
  const [suche, setSuche] = useSearchParams()
  const r7 = suche.get('fassung') === 'r7'

  const [data, setData] = useState<ReportData | null>(null)
  const [notes, setNotes] = useState<ReportNotes>(EMPTY_NOTES)
  const [notesUnavailable, setNotesUnavailable] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [tiers, setTiers] = useState<TierPlan[]>([])

  useEffect(() => {
    if (!sessionId) return
    let cancelled = false

    void (async () => {
      setLoading(true)
      const [report, storedNotes] = await Promise.all([
        getReportData(sessionId),
        getReportNotes(sessionId),
      ])
      if (cancelled) return

      if (report.error) setError(report.error)
      else setData(report.data)

      if (storedNotes.data) setNotes(storedNotes.data)
      setNotesUnavailable(storedNotes.unavailable)
      setLoading(false)
    })()

    return () => {
      cancelled = true
    }
  }, [sessionId])

  // Nur R7 zeigt die Mitgliedschaften (Seite 5). Ohne Pakete entfällt der Abschnitt.
  useEffect(() => {
    if (!r7) return
    let cancelled = false
    void listTiers().then((res) => {
      if (!cancelled) setTiers(res.data ?? [])
    })
    return () => {
      cancelled = true
    }
  }, [r7])

  const handleSave = useCallback(async () => {
    if (!sessionId) return
    setSaving(true)
    setSaved(false)
    const result = await saveReportNotes(sessionId, notes)
    setSaving(false)
    if (result.error) setError(result.error)
    else {
      setNotesUnavailable(result.unavailable)
      setSaved(true)
    }
  }, [sessionId, notes])

  const name = data?.firstName?.trim() || t('head.childFallback')
  const titel = loading ? t('head.title') : name

  const aktionen = (
    <>
      <Button
        type="button"
        variant="secondary"
        onClick={() => setSuche(r7 ? {} : { fassung: 'r7' }, { replace: true })}
      >
        {tb(r7 ? 'fassung.zuR6' : 'fassung.zuR7')}
      </Button>
      <Button type="button" variant="secondary" onClick={() => window.print()}>
        <Printer className="mr-2 h-4 w-4" />
        {t('actions.print')}
      </Button>
      {/* Es gibt im Projekt keine Mail-Infrastruktur (kein Resend/
          SMTP, keine sendende Edge Function). Der Knopf bleibt
          deshalb bewusst deaktiviert statt zu scheitern. */}
      <Button type="button" variant="secondary" disabled title={t('actions.emailTooltip')}>
        <Mail className="mr-2 h-4 w-4" />
        {t('actions.email')}
      </Button>
    </>
  )

  const ausblick = (
    <ReportOutlook
      name={name}
      notes={notes}
      onChange={(next) => {
        setNotes(next)
        setSaved(false)
      }}
      onSave={() => void handleSave()}
      saving={saving}
      saved={saved}
      unavailable={notesUnavailable}
      nurLesen={role !== 'admin'}
    />
  )

  const inhalt = (
    <>
      {error && (
        <p className="print-hide rounded-[var(--radius-md)] bg-[var(--color-error-gap-light)] p-3 text-sm text-[var(--color-error-gap)]">
          {error}
        </p>
      )}

      {loading ? (
        <LoadingPulse type="card" lines={5} />
      ) : (
        data && (
          <>
            {data.status === 'in_progress' && (
              <p className="print-hide rounded-[var(--radius-md)] bg-[var(--color-gold-warning-light)] p-3 text-sm text-[var(--color-gold-warning)]">
                {t('page.notFinished', { name })}
              </p>
            )}
            {data.testlauf && <TestlaufBanner />}
            <ReportBody data={data} />
            {ausblick}
          </>
        )
      )}
    </>
  )

  const kopf = (
    <div className="print-hide">
      <PageHeader
        rubrik={t('page.eyebrow')}
        titel={titel}
        zurueckZu="/admin/leads"
        zurueckLabel={t('page.back')}
        aktionen={aktionen}
      />
    </div>
  )

  // R7: eigener Wrapper, nicht .report-sheet — dessen Druckregeln gelten für R6.
  // Am Bildschirm Hinweise und Ausblick, auf Papier nur der Bogen.
  if (r7) {
    return (
      <div className="eb-ansicht flex flex-col gap-6">
        {kopf}
        {error && (
          <p className="print-hide rounded-[var(--radius-md)] bg-[var(--color-error-gap-light)] p-3 text-sm text-[var(--color-error-gap)]">
            {error}
          </p>
        )}
        {loading ? (
          <LoadingPulse type="card" lines={5} />
        ) : (
          data && (
            <>
              {data.status === 'in_progress' && (
                <p className="print-hide rounded-[var(--radius-md)] bg-[var(--color-gold-warning-light)] p-3 text-sm text-[var(--color-gold-warning)]">
                  {t('page.notFinished', { name })}
                </p>
              )}
              {data.testlauf && (
                <div className="print-hide">
                  <TestlaufBanner />
                </div>
              )}
              <ElternberichtBogen data={data} notes={notes} tiers={tiers} />
              <div className="print-hide @4xl:max-w-3xl">{ausblick}</div>
            </>
          )
        )}
      </div>
    )
  }

  // Ein Dokument: Lesebreite wie das Druckblatt, links im Inhaltsbereich.
  return (
    <div className="report-sheet flex flex-col gap-6 @4xl:max-w-3xl">
      {kopf}
      {inhalt}
    </div>
  )
}
