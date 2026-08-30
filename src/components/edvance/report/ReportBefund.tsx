import { useTranslation } from 'react-i18next'

import type { Bausteinsatz } from '@/lib/report/bausteine'
import type { Fundament } from '@/types'

/**
 * „Was wir gefunden haben" — die beiden Listen (R6).
 *
 * Zuerst das, was trägt. Die Reihenfolge ist die Aussage: Ein Report, der mit
 * Lücken beginnt, liest sich als Mängelliste, auch wenn danach Gutes kommt.
 *
 * KEINE AMPEL (INV-4.4): Die tragende Spalte steht auf Creme, die offene trägt
 * einen Goldrand. Rot und Grün wären hier zwei Wertungen in Signalfarbe auf
 * einem Dokument über ein Kind — die Sprache des Reports vermeidet genau das
 * („trägt noch nicht", nicht „Lücke"), und die Farbe darf es nicht
 * zurückholen.
 *
 * Gerendert wird `label` aus `skills.label`, nie der `skill_key` (INV-4.3).
 */
export function ReportBefund({
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

  const traegtText = satz.waehle('befund_traegt', 'standard', sessionId, {
    traegt: fundament.traegt,
    geprueft: fundament.geprueft,
  })

  // Nur behaupten, wenn es stimmt: Liegt eine Lücke AUF der Einstiegsebene,
  // ist sie nicht „unter dem aktuellen Thema", sondern Teil davon.
  const alleDarunter = fundament.luecken.every(
    (l) => l.fundamentTiefe < fundament.einstiegTiefe,
  )

  return (
    <div className="report-befund">
      <div className="report-befund-spalte report-befund-traegt">
        <h4 className={titleClassName}>{t('befund.traegtTitel')}</h4>
        <ul>
          {fundament.tragend.map((skill) => (
            <li key={skill.skillKey}>{skill.label}</li>
          ))}
        </ul>
        {traegtText && <p className="report-befund-fuss">{traegtText}</p>}
      </div>

      {fundament.luecken.length > 0 && (
        <div className="report-befund-spalte report-befund-offen">
          <h4 className={titleClassName}>{t('befund.offenTitel')}</h4>
          <ul>
            {/* Von der Einstiegsebene abwärts — der Weg, den der Report
                erzählt, läuft in der Liste daneben andersherum als im
                Aufklappbereich, wo der Coach von unten nach oben arbeitet. */}
            {[...fundament.luecken].reverse().map((skill) => (
              <li key={skill.skillKey}>{skill.label}</li>
            ))}
          </ul>
          {alleDarunter && (
            <p className="report-befund-fuss">{t('befund.offenFuss')}</p>
          )}
        </div>
      )}
    </div>
  )
}
