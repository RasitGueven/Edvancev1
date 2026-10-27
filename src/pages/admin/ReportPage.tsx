import { useCallback, useEffect, useRef, useState } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { Printer, Mail, Presentation } from 'lucide-react'
import { useTranslation } from 'react-i18next'
import { LoadingPulse } from '@/components/edvance'
import { ElternberichtBogen } from '@/components/edvance/elternbericht/Bogen'
import { Praesentation } from '@/components/edvance/praesentation/Praesentation'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { BerichtAnsicht } from '@/components/edvance/report/BerichtAnsicht'
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
import { durchklickGrund } from './lsaReports/durchklickGrund'
import { NichtAuswertbarBalken } from './lsaReports/NichtAuswertbarBalken'
import { KaAbweichungHinweis } from './lsaReports/KaAbweichungHinweis'
import { bogenBereit, druckDatum, druckeMitTitel } from './reportDruck'
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
 * Gezeigt wird der Eltern-Bericht R7 als Druckbogen nach Muster E7, am
 * Bildschirm eingepasst und mit dem Ausblick daneben (BerichtAnsicht). Die
 * alte Fassung R6 ist entfallen (Bauauftrag R7-7); ein altes ?fassung in der
 * URL wird beim Laden entfernt.
 *
 * Mit ?ansicht=praesentation liegt darüber die Tablet-Präsentation als
 * Vollbild (Anforderung Tablet-Präsentation, Entscheidung 1). Schließen
 * entfernt nur diesen Parameter; Report und Ausblick bleiben.
 *
 * Mit ?aktion=pdf (Liste LSA-Reports, LR-1) öffnet sich der Druckdialog genau
 * einmal von selbst, sobald Bericht, Pakete und Schriften da sind. Danach
 * fällt nur ?aktion aus der URL.
 *
 * Eine durchgeklickte LSA (auswertbar = false, LSA-R2) hat nur die Seite
 * „nicht auswertbar“, ohne Ausblick, darüber den Hinweisbalken mit „LSA
 * wiederholen“. Die Präsentation öffnet nicht: ?ansicht=praesentation fällt
 * aus der URL, es bleibt der Bogen.
 */

/** So lange nach der letzten Eingabe im Ausblick misst der Bogen neu. */
const NEU_MESSEN_MS = 400
export function ReportPage(): JSX.Element {
  const { sessionId } = useParams<{ sessionId: string }>()
  const { t, i18n } = useTranslation('report')
  const { t: tp } = useTranslation('praesentation')
  const { t: ta } = useTranslation('admin')
  const { role } = useAuth()
  const [suche, setSuche] = useSearchParams()
  const praesentation = suche.get('ansicht') === 'praesentation'
  // Bericht v4: Preise je Paket auf Seite 5, nur über den Schalter in der Ansicht (?preise=an).
  const preise = suche.get('preise') === 'an'
  const schaltePreise = (an: boolean): void =>
    setSuche(
      (alt) => {
        const neu = new URLSearchParams(alt)
        if (an) neu.set('preise', 'an')
        else neu.delete('preise')
        return neu
      },
      { replace: true },
    )

  const [data, setData] = useState<ReportData | null>(null)
  const [notes, setNotes] = useState<ReportNotes>(EMPTY_NOTES)
  // Was der Bogen zeigt: beim Laden sofort, Eingaben im Ausblick entprellt.
  const [bogenNotes, setBogenNotes] = useState<ReportNotes>(EMPTY_NOTES)
  const [notesUnavailable, setNotesUnavailable] = useState(false)
  // L5 Teil D: Spalten für „im Gespräch bestätigt“ vorhanden (sonst keine Schalter).
  const [bestaetigung, setBestaetigung] = useState(false)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [tiers, setTiers] = useState<TierPlan[]>([])
  const [pakete, setPakete] = useState<'offen' | 'laedt' | 'da' | 'fehler'>('offen')

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

      if (storedNotes.data) {
        setNotes(storedNotes.data)
        setBogenNotes(storedNotes.data)
      }
      setNotesUnavailable(storedNotes.unavailable)
      setBestaetigung(storedNotes.bestaetigung === true)
      setLoading(false)
    })()

    return () => {
      cancelled = true
    }
  }, [sessionId])

  // Die Fassung R6 gibt es nicht mehr: ?fassung fällt aus der URL, alle
  // anderen Parameter bleiben.
  useEffect(() => {
    if (!suche.has('fassung')) return
    setSuche(
      (alt) => {
        const neu = new URLSearchParams(alt)
        neu.delete('fassung')
        return neu
      },
      { replace: true },
    )
  }, [suche, setSuche])

  // Der Bogen (Seite 5) und die Präsentation (Empfehlung) brauchen die Pakete —
  // einmal je Seite geladen. Ohne Pakete entfällt dort nur der Abschnitt bzw.
  // die Empfehlungszeile.
  const angefragt = useRef(false)
  const gemountet = useRef(true)
  useEffect(() => {
    gemountet.current = true
    return () => {
      gemountet.current = false
    }
  }, [])
  useEffect(() => {
    if (angefragt.current) return
    angefragt.current = true
    setPakete('laedt')
    void listTiers().then((res) => {
      if (!gemountet.current) return
      setTiers(res.data ?? [])
      setPakete(res.error ? 'fehler' : 'da')
    })
  }, [])

  // Neu messen, wenn sich der Inhalt ändert (Entscheidung 5): Erst 400 ms nach
  // der letzten Eingabe bekommt der Bogen die Notizen und damit einen neuen
  // key — so flackert er nicht bei jedem Tastendruck.
  const entprellung = useRef<number>()
  useEffect(() => () => window.clearTimeout(entprellung.current), [])
  const aendereNotes = useCallback((next: ReportNotes) => {
    setNotes(next)
    setSaved(false)
    window.clearTimeout(entprellung.current)
    entprellung.current = window.setTimeout(() => setBogenNotes(next), NEU_MESSEN_MS)
  }, [])
  const bogenKey = JSON.stringify([
    sessionId,
    bogenNotes.zielbild,
    bogenNotes.empfehlung,
    bogenNotes.paket,
    bogenNotes.zieleBestaetigt,
    bogenNotes.paketBestaetigt,
  ])

  const setzeAnsicht = useCallback(
    (an: boolean) =>
      setSuche((alt) => {
        const neu = new URLSearchParams(alt)
        if (an) neu.set('ansicht', 'praesentation')
        else neu.delete('ansicht')
        return neu
      }),
    [setSuche],
  )
  const schliessePraesentation = useCallback(() => setzeAnsicht(false), [setzeAnsicht])

  // Nicht auswertbar: keine Präsentation, ein solcher Aufruf landet auf dem Bogen.
  const nichtAuswertbar = data?.auswertbar === false
  useEffect(() => {
    if (!nichtAuswertbar || !praesentation) return
    setSuche(
      (alt) => {
        const neu = new URLSearchParams(alt)
        neu.delete('ansicht')
        return neu
      },
      { replace: true },
    )
  }, [nichtAuswertbar, praesentation, setSuche])

  const handleSave = useCallback(async () => {
    if (!sessionId) return
    setSaving(true)
    setSaved(false)
    const result = await saveReportNotes(sessionId, notes, bestaetigung)
    setSaving(false)
    if (result.error) setError(result.error)
    else {
      setNotesUnavailable(result.unavailable)
      setSaved(true)
    }
  }, [sessionId, notes, bestaetigung])

  // L5 Teil D: Schalter in der Präsentation — sofort übernehmen und speichern.
  const bestaetigeSofort = useCallback((art: 'zieleBestaetigt' | 'paketBestaetigt', an: boolean) => {
    if (!sessionId) return
    const next = { ...notes, [art]: an }
    setNotes(next)
    setBogenNotes(next)
    void saveReportNotes(sessionId, next, true).then((r) => {
      if (r.error) setError(r.error)
    })
  }, [sessionId, notes])

  const name = data?.firstName?.trim() || t('head.childFallback')
  const titel = loading ? t('head.title') : name

  // Ein Titel-Mechanismus für den Knopf und für ?aktion=pdf.
  const drucke = useCallback(
    (danach?: () => void) =>
      druckeMitTitel(
        data
          ? t('actions.druckTitel', {
              name,
              datum: data.analysedAt ? druckDatum(data.analysedAt, i18n.language) : '',
            }).trim()
          : document.title,
        danach,
      ),
    [data, name, t, i18n.language],
  )

  const pdf = suche.get('aktion') === 'pdf'
  const bereitZumDruck = !loading && !error && data !== null && pakete !== 'offen' && pakete !== 'laedt'
  const gedruckt = useRef(false)
  useEffect(() => {
    if (!pdf || !bereitZumDruck || gedruckt.current) return
    gedruckt.current = true
    void bogenBereit().then(() => {
      if (!gemountet.current) return
      drucke(() =>
        setSuche(
          (alt) => {
            const neu = new URLSearchParams(alt)
            neu.delete('aktion')
            return neu
          },
          { replace: true },
        ),
      )
    })
  }, [pdf, bereitZumDruck, drucke, setSuche])

  const aktionen = (
    <>
      {nichtAuswertbar ? (
        <span
          className="inline-flex"
          title={ta('lsaReports.aktion.praesentationGesperrt', {
            grund: durchklickGrund(ta, i18n.language, data?.nichtAuswertbarGrund),
          })}
        >
          <Button type="button" variant="secondary" disabled>
            <Presentation className="mr-2 h-4 w-4" />
            {tp('einstieg.knopf')}
          </Button>
        </span>
      ) : (
        <Button type="button" variant="secondary" onClick={() => setzeAnsicht(true)}>
          <Presentation className="mr-2 h-4 w-4" />
          {tp('einstieg.knopf')}
        </Button>
      )}
      <Button type="button" variant="secondary" onClick={() => drucke()}>
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
      onChange={aendereNotes}
      onSave={() => void handleSave()}
      saving={saving}
      saved={saved}
      unavailable={notesUnavailable}
      nurLesen={role !== 'admin'}
      bestaetigung={bestaetigung}
    />
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

  const ebene = praesentation && sessionId && (loading || data) && !nichtAuswertbar && (
    <Praesentation
      data={data}
      notes={notes}
      tiers={tiers}
      tiersFehler={pakete === 'fehler'}
      sessionId={sessionId}
      laden={loading || pakete === 'offen' || pakete === 'laedt'}
      onSchliessen={schliessePraesentation}
      bestaetigung={role === 'admin' && bestaetigung && !notesUnavailable ? { onWechsel: bestaetigeSofort } : undefined}
    />
  )

  // Am Bildschirm Hinweise, Leiste und Ausblick, auf Papier nur der Bogen.
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
            {data.klassenarbeitAbweichung && <KaAbweichungHinweis abweichung={data.klassenarbeitAbweichung} />}
            {nichtAuswertbar ? (
              <>
                <NichtAuswertbarBalken
                  stand={data.nichtAuswertbarGrund ?? null}
                  leadId={data.leadId ?? null}
                  darfFreigeben={role === 'admin'}
                />
                {/* Eine Seite, ohne Ausblick: es gibt nichts zu empfehlen. */}
                <div className="overflow-x-auto rounded-[var(--radius-lg)] bg-[var(--color-bg-subtle)] p-4 print:overflow-visible print:bg-transparent print:p-0">
                  <div className="mx-auto w-fit">
                    <ElternberichtBogen data={data} notes={null} tiers={[]} />
                  </div>
                </div>
              </>
            ) : (
              <BerichtAnsicht
                data={data}
                notes={bogenNotes}
                tiers={tiers}
                bogenKey={bogenKey}
                ausblick={ausblick}
                preise={preise}
                onPreise={schaltePreise}
              />
            )}
          </>
        )
      )}
      {ebene}
    </div>
  )
}
