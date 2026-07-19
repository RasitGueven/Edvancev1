import { useCallback, useEffect, useState } from 'react'
import { useParams } from 'react-router-dom'
import { Printer, Mail } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { AdminHeader, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { ReportBody } from '@/components/edvance/report/ReportBody'
import { ReportOutlook } from '@/components/edvance/report/ReportOutlook'
import { Button } from '@/components/ui/button'
import { getReportData } from '@/lib/supabase/lsaReport'
import {
  EMPTY_NOTES,
  getReportNotes,
  saveReportNotes,
} from '@/lib/supabase/reportNotes'
import type { ReportData, ReportNotes } from '@/types'

/**
 * Eltern-Report zu einer LSA-Sitzung (/admin/report/:sessionId).
 *
 * Read-only gegenüber den Sitzungsdaten — geschrieben werden ausschließlich die
 * zwei Coach-Freitexte im Ausblick. Die Bewertung richtig/falsch stammt aus
 * lsa_responses.correct (serverseitig gesetzt); Lösungen erreichen den Client
 * nie.
 */
export function ReportPage(): JSX.Element {
  const { sessionId } = useParams<{ sessionId: string }>()
  const { t } = useTranslation('report')

  const [data, setData] = useState<ReportData | null>(null)
  const [notes, setNotes] = useState<ReportNotes>(EMPTY_NOTES)
  const [notesUnavailable, setNotesUnavailable] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)

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

  const name = data?.firstName?.trim() || 'Ihr Kind'

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <div className="print-hide">
        <EdvanceNavbar subtitle="Report" sticky />
      </div>

      <main className="report-sheet mx-auto flex max-w-3xl flex-col gap-6 px-4 py-8">
        <div className="print-hide">
          <AdminHeader
            eyebrow={t('page.eyebrow')}
            title={loading ? t('head.title') : name}
            backTo="/admin/leads"
            backLabel={t('page.back')}
            actions={
              <>
                <Button
                  type="button"
                  variant="secondary"
                  onClick={() => window.print()}
                >
                  <Printer className="mr-2 h-4 w-4" />
                  {t('actions.print')}
                </Button>
                {/* Es gibt im Projekt keine Mail-Infrastruktur (kein Resend/
                    SMTP, keine sendende Edge Function). Der Knopf bleibt
                    deshalb bewusst deaktiviert statt zu scheitern. */}
                <Button
                  type="button"
                  variant="secondary"
                  disabled
                  title={t('actions.emailTooltip')}
                >
                  <Mail className="mr-2 h-4 w-4" />
                  {t('actions.email')}
                </Button>
              </>
            }
          />
        </div>

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
              <ReportBody data={data} />
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
              />
            </>
          )
        )}
      </main>
    </div>
  )
}
