import { useTranslation } from 'react-i18next'

import { ReportRueckbezug } from '@/components/edvance/report/ReportRueckbezug'
import type { Bausteinsatz } from '@/lib/report/bausteine'
import type { Rueckbezug } from '@/types'

/**
 * Der Schluss des Eltern-Reports: Fazit und Empfehlung (R3 — Gestaltung).
 *
 * Fazit und Empfehlung kommen seit R5 aus report_bausteine und haengen an der
 * VERTEILUNG der Luecken, nicht am Paket: Ein Text, der „dicht beieinander"
 * sagt, existiert nur fuer den Fall, in dem das stimmt. Fehlt ein Baustein,
 * bleibt seine Stelle leer.
 *
 * Dazwischen steht der Aufgriff der Eltern-Einschaetzung — die staerkste
 * Aussage, die der Report machen kann, und bis R4 die einzige, die fehlte.
 *
 * WARUM EINE EIGENE GRUPPE UND KEINE ZWEI WEITEREN ABSCHNITTE:
 * Der Report ist eine Aufzählung von Beobachtungen. Fazit und Empfehlung sind
 * das Gegenteil davon — sie ziehen zusammen und sagen, was folgt. Stünden sie
 * als Kästen sechs und sieben in derselben Reihe, läsen sie sich wie zwei
 * weitere Befunde. Deshalb tragen sie eine gemeinsame Fläche in Navy, abgesetzt
 * durch einen breiten Abstand: das Dokument endet hier sichtbar, es hört nicht
 * einfach auf.
 *
 * Die Empfehlung ist eine EMPFEHLUNG, keine Bedingung — der abschließende Satz
 * gehört zum Baustein und wird nicht weggelassen.
 */
export function ReportSchluss({
  verteilung,
  rueckbezuege,
  satz,
  sessionId,
}: {
  verteilung: string | null
  rueckbezuege: Rueckbezug[]
  satz: Bausteinsatz
  sessionId: string
}): JSX.Element | null {
  const { t } = useTranslation('report')

  const fazit = satz.waehle('fazit', verteilung, sessionId)
  const empfehlung = satz.waehle('empfehlung', verteilung, sessionId)
  const hatRueckbezug = rueckbezuege.length > 0
  if (!fazit && !empfehlung && !hatRueckbezug) return null

  return (
    <section className="report-block report-schluss">
      {fazit && (
        <div className="report-schluss-fazit">
          <h3 className="report-schluss-titel">{t('schluss.fazitTitel')}</h3>
          <p className="report-schluss-text">{fazit}</p>
          <p className="report-schluss-vorbehalt">{t('schluss.vorbehalt')}</p>
        </div>
      )}

      <ReportRueckbezug
        rueckbezuege={rueckbezuege}
        satz={satz}
        sessionId={sessionId}
      />

      {empfehlung && (
        <div className="report-schluss-empfehlung">
          <h3 className="report-schluss-titel">{t('schluss.empfehlungTitel')}</h3>
          <p className="report-schluss-text">{empfehlung}</p>
          <p className="report-schluss-vorbehalt">{t('schluss.offenheit')}</p>
        </div>
      )}
    </section>
  )
}
