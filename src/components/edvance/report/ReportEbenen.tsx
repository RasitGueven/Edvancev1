import { useTranslation } from 'react-i18next'

import { Bausteinsatz, alsWort, ebeneAlsZeile, ebeneImSatz, ebenenUntertitel } from '@/lib/report/bausteine'
import { sucheFall } from '@/lib/report/fundament'
import type { Fundament } from '@/types'

/**
 * „Wie wir gesucht haben" — der Abstieg durch die Fundamentebenen (R6).
 *
 * Eine Zeile je geprüfter Ebene, darunter die Bereiche, die dort tatsächlich
 * liegen. „Zwei Ebenen tiefer" allein sagt nichts; erst die Namen machen die
 * Spur nachvollziehbar, statt sie als Balkengrafik hinzunehmen.
 *
 * ----------------------------------------------------------------------------
 * Der Balken ist eine ZUSAMMENSETZUNG, keine Skala (INV-4.4)
 * ----------------------------------------------------------------------------
 * Er zeigt nicht, wie weit das Kind auf einem Weg gekommen ist, sondern wie
 * sich die geprüften Bereiche einer Ebene aufteilen — und die Zahl daneben
 * nennt beide Summanden im Klartext („2 von 3"). Deshalb trägt der gefüllte
 * Teil Navy und der Rest bleibt offen; es gibt kein Rot, kein Grün und keine
 * Ampel. Die Farbe sagt „das steht", nicht „das ist gut".
 *
 * Alle Sätze kommen aus report_bausteine. Fehlt einer, bleibt seine Stelle
 * leer — dieselbe Weglass-Regel wie bei den Fehlbild-Familien.
 */
export function ReportEbenen({
  fundament,
  satz,
  sessionId,
  titleClassName,
}: {
  fundament: Fundament | null
  satz: Bausteinsatz
  sessionId: string
  titleClassName: string
}): JSX.Element | null {
  const { t } = useTranslation('report')
  if (!fundament) return null

  const sucheText = satz.waehle('suche', sucheFall(fundament), sessionId, {
    geprueft: fundament.geprueft,
    ebenen: alsWort(fundament.ebenen.length),
  })
  const einbruchText = fundament.einbruch
    ? satz.waehle('abstieg_einbruch', 'standard', sessionId, {
        ebene: ebeneImSatz(fundament.einbruch.delta),
        traegt: fundament.einbruch.traegt,
        geprueft: fundament.einbruch.geprueft,
      })
    : null
  // Nur sagen, wenn die unterste Ebene wirklich trägt UND es überhaupt einen
  // Abstieg gab — sonst wäre es eine Aussage über das aktuelle Thema.
  const bodenText =
    fundament.bodenTraegt && fundament.fundamentGeprueft
      ? satz.waehle('abstieg_boden', 'vollstaendig', sessionId)
      : null

  return (
    <section className="report-block report-hauptteil flex flex-col gap-2">
      <h3 className={titleClassName}>{t('ebenen.title')}</h3>
      {sucheText && (
        <p className="mb-2 text-base leading-relaxed text-[var(--color-report-navy)]">
          {sucheText}
        </p>
      )}

      <ol className="report-ebenen">
        {fundament.ebenen.map((ebene) => {
          const anteil = Math.round((ebene.traegt / ebene.geprueft) * 100)
          const was = ebenenUntertitel(ebene.labels, ebene.weitere)
          return (
            <li key={ebene.tiefe} className="report-ebene">
              <div className="report-ebene-kopf">
                <span className="report-ebene-name">{ebeneAlsZeile(ebene.delta)}</span>
                <span className="report-ebene-spur" aria-hidden="true">
                  <span
                    className="report-ebene-fuellung"
                    style={{ width: `${anteil}%` }}
                  />
                </span>
                <span className="report-ebene-zahl">
                  {t('ebenen.zaehlung', {
                    traegt: ebene.traegt,
                    geprueft: ebene.geprueft,
                  })}
                </span>
              </div>
              {was && <p className="report-ebene-was">{was}</p>}
            </li>
          )
        })}
      </ol>

      {(einbruchText || bodenText) && (
        <div className="report-ebenen-notiz">
          {einbruchText && <p>{einbruchText}</p>}
          {bodenText && <p>{bodenText}</p>}
        </div>
      )}
    </section>
  )
}
