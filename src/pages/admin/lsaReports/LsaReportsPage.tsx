import { useEffect, useMemo, useState } from 'react'
import { Link } from 'react-router-dom'
import { FileDown, Presentation } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { EdvanceBadge, EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceTable, type Spalte } from '@/components/edvance/EdvanceTable'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { listLsaReports } from '@/lib/supabase/lsaReportListe'
import type { LsaReportListItem } from '@/types/report'
import { durchklickGrund } from './durchklickGrund'

/**
 * Menüpunkt „LSA-Reports“ (Bauauftrag LR-1): alle abgeschlossenen LSAs, neueste
 * oben. Je Zeile öffnet der Name den Bogen, „Präsentation“ die Tablet-Ansicht
 * und „PDF“ den Druckdialog des Bogens (ReportPage, ?aktion=pdf).
 *
 * Eine durchgeklickte LSA (LSA-R2) trägt das Kennzeichen „Nicht auswertbar“;
 * ihre Präsentation ist gesperrt, der Tooltip nennt den Grund.
 */
export function LsaReportsPage(): JSX.Element {
  const { t, i18n } = useTranslation('admin')
  const [liste, setListe] = useState<LsaReportListItem[] | null>(null)
  const [fehler, setFehler] = useState<string | null>(null)
  const [suche, setSuche] = useState('')

  useEffect(() => {
    let abgebrochen = false
    void listLsaReports().then((res) => {
      if (abgebrochen) return
      setFehler(res.error)
      setListe(res.data ?? [])
    })
    return () => {
      abgebrochen = true
    }
  }, [])

  const datum = useMemo(
    () =>
      new Intl.DateTimeFormat(i18n.language, {
        day: '2-digit',
        month: '2-digit',
        year: 'numeric',
        timeZone: 'Europe/Berlin',
      }),
    [i18n.language],
  )

  const name = (z: LsaReportListItem): string => z.first_name ?? t('lsaReports.ohneName')
  const begriff = suche.trim().toLocaleLowerCase(i18n.language)
  const treffer = (liste ?? []).filter(
    (z) => !begriff || (z.first_name ?? '').toLocaleLowerCase(i18n.language).includes(begriff),
  )

  const spalten: Spalte<LsaReportListItem>[] = [
    {
      key: 'kind',
      kopf: t('lsaReports.spalte.kind'),
      zelle: (z) => (
        <Link
          to={`/admin/report/${z.session_id}`}
          aria-label={t('lsaReports.aktion.bogenFuer', { name: name(z) })}
          className="inline-flex min-h-[44px] items-center font-semibold text-[var(--color-primary)] hover:underline"
        >
          {name(z)}
        </Link>
      ),
    },
    { key: 'klasse', kopf: t('lsaReports.spalte.klasse'), zelle: (z) => <span className="tabular-nums">{z.grade}</span> },
    { key: 'fach', kopf: t('lsaReports.spalte.fach'), zelle: (z) => z.subject },
    // Silbentrennung, damit lange Themen die Spalte im Hochformat nicht sprengen.
    { key: 'thema', kopf: t('lsaReports.spalte.thema'), zelle: (z) => <span className="hyphens-auto">{z.thema_label ?? ''}</span> },
    {
      key: 'datum',
      kopf: t('lsaReports.spalte.datum'),
      zelle: (z) => datum.format(new Date(z.completed_at)),
    },
    {
      key: 'kennzeichen',
      kopf: t('lsaReports.spalte.kennzeichen'),
      zelle: (z) => (
        <span className="flex flex-wrap gap-2">
          {z.auswertbar === false && (
            <EdvanceBadge variant="warning">{t('lsaReports.kennzeichen.nichtAuswertbar')}</EdvanceBadge>
          )}
          {z.testlauf ? (
            <EdvanceBadge variant="warning">{t('lsaReports.kennzeichen.testlauf')}</EdvanceBadge>
          ) : z.ist_test ? (
            <EdvanceBadge variant="muted">{t('lsaReports.kennzeichen.testkonto')}</EdvanceBadge>
          ) : null}
        </span>
      ),
    },
    {
      key: 'aktionen',
      kopf: t('lsaReports.spalte.aktionen'),
      zelle: (z) => (
        // Quer nebeneinander, im Hochformat untereinander in gleicher Breite.
        <span className="flex flex-col gap-2 lg:flex-row">
          {z.auswertbar === false ? (
            // Der Tooltip sitzt an der Hülle: ein deaktivierter Knopf meldet kein Hover.
            <span
              className="inline-flex"
              title={t('lsaReports.aktion.praesentationGesperrt', {
                grund: durchklickGrund(t, i18n.language, z.nicht_auswertbar_grund),
              })}
            >
              <Button type="button" variant="primary" className="w-full px-3" disabled>
                <Presentation className="h-4 w-4" aria-hidden />
                {t('lsaReports.aktion.praesentation')}
              </Button>
            </span>
          ) : (
            <Button asChild variant="primary" className="px-3">
              <Link
                to={`/admin/report/${z.session_id}?ansicht=praesentation`}
                aria-label={t('lsaReports.aktion.praesentationFuer', { name: name(z) })}
              >
                <Presentation className="h-4 w-4" aria-hidden />
                {t('lsaReports.aktion.praesentation')}
              </Link>
            </Button>
          )}
          <Button asChild variant="secondary" className="px-3">
            <Link
              to={`/admin/report/${z.session_id}?aktion=pdf`}
              aria-label={t('lsaReports.aktion.pdfFuer', { name: name(z) })}
            >
              <FileDown className="h-4 w-4" aria-hidden />
              {t('lsaReports.aktion.pdf')}
            </Link>
          </Button>
        </span>
      ),
    },
  ]

  return (
    <div className="flex flex-col gap-6">
      <PageHeader titel={t('lsaReports.titel')} satz={t('lsaReports.satz')} />
      {fehler && (
        <p className="rounded-[var(--radius-md)] bg-[var(--color-error-gap-light)] p-3 text-sm text-[var(--color-error-gap)]">
          {t('lsaReports.ladeFehler', { fehler })}
        </p>
      )}
      {liste === null ? (
        <LoadingPulse type="list" lines={6} />
      ) : liste.length === 0 ? (
        !fehler && <EmptyState icon="📋" title={t('lsaReports.leer')} description={t('lsaReports.leerText')} />
      ) : (
        <section className="flex flex-col gap-4" aria-label={t('lsaReports.titel')}>
          <Input
            type="search"
            value={suche}
            onChange={(e) => setSuche(e.target.value)}
            placeholder={t('lsaReports.suche')}
            aria-label={t('lsaReports.suche')}
            className="min-h-[44px] w-full max-w-xs"
          />
          {treffer.length === 0 ? (
            <EmptyState
              icon="🔎"
              title={t('lsaReports.keinTreffer')}
              description={t('lsaReports.keinTrefferText', { suche: suche.trim() })}
            />
          ) : (
            <EdvanceTable
              beschriftung={t('lsaReports.titel')}
              spalten={spalten}
              zeilen={treffer}
              zeileKey={(z) => z.session_id}
            />
          )}
        </section>
      )}
    </div>
  )
}
