import { useTranslation } from 'react-i18next'

import type { Bausteinsatz } from '@/lib/report/bausteine'
import type { Rueckbezug } from '@/types'

/**
 * Der Aufgriff der Eltern-Einschätzung im Schluss (R6).
 *
 * Bis R4 nannte der Report wörtlich, was die Eltern angegeben hatten, und kam
 * nie darauf zurück. Bei einem Kind standen vier Punkte im Kopf und zwei im
 * Schluss — ein unbeantworteter Punkt liest sich wie ein stillschweigendes
 * „unauffällig".
 *
 * Seit R5 bekommt jeder genannte Punkt eine von vier Antworten. Die Markierung
 * unterscheidet DREI Zustände, nicht vier: „offen" und „nicht messbar" teilen
 * sich eine neutrale Marke, weil beide dasselbe sagen — diese Analyse gibt dazu
 * nichts her. Eine eigene Signalfarbe daneben läse sich als Befund.
 *
 * KEINE AMPEL (INV-4.4): die drei Marken sind Gold (Befund), Navy (entlastet)
 * und offen (keine Aussage). Sie tragen zusätzlich ein Zeichen und eine
 * Vorlesehilfe, damit die Unterscheidung nicht allein an der Farbe hängt.
 */
export function ReportRueckbezug({
  rueckbezuege,
  satz,
  sessionId,
}: {
  rueckbezuege: Rueckbezug[]
  satz: Bausteinsatz
  sessionId: string
}): JSX.Element | null {
  const { t } = useTranslation('report')

  const zeilen = rueckbezuege
    .map((r) => {
      const text = satz.waehle('rueckbezug', r.fall, `${sessionId} ${r.thema}`, {
        belege: r.belege,
      })
      return text ? { ...r, text } : null
    })
    .filter((x): x is Rueckbezug & { text: string } => x !== null)

  if (zeilen.length === 0) return null

  return (
    <ul className="report-rueckbezug">
      {zeilen.map((r) => {
        const art =
          r.richtung === 'entlastend'
            ? 'entlastet'
            : r.richtung === 'bestaetigend'
              ? 'befund'
              : 'offen'
        return (
          <li key={r.thema} className={`report-rueckbezug-zeile report-rueckbezug-${art}`}>
            <span className="report-rueckbezug-marke">
              <span className="sr-only">{t(`rueckbezug.art.${art}`)}</span>
              <span aria-hidden="true">
                {art === 'entlastet' ? '✓' : art === 'befund' ? '!' : '?'}
              </span>
            </span>
            <p>{r.text}</p>
          </li>
        )
      })}
    </ul>
  )
}
