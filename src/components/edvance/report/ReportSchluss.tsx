import { useTranslation } from 'react-i18next'

import type { ReportEmpfehlung } from '@/types'

/**
 * Der Schluss des Eltern-Reports: Fazit und Empfehlung (R3 — Gestaltung).
 *
 * NOCH OHNE DATEN. Die Bausteine für Fazit und Empfehlung entstehen in einem
 * eigenen PR (Tabelle mit Abnahme-Schranke, analog fehlbild_familien). Hier
 * liegt nur die Gestaltung vor — fehlen die Daten, rendert die Komponente
 * nichts.
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
  fazit,
  empfehlung,
}: {
  fazit: string[] | null | undefined
  empfehlung: ReportEmpfehlung | null | undefined
}): JSX.Element | null {
  const { t } = useTranslation('report')

  const hatFazit = Boolean(fazit && fazit.length > 0)
  const hatEmpfehlung = Boolean(empfehlung?.paket)
  if (!hatFazit && !hatEmpfehlung) return null

  return (
    <section className="report-block report-schluss">
      {hatFazit && (
        <div className="report-schluss-fazit">
          <h3 className="report-schluss-titel">{t('schluss.fazitTitel')}</h3>
          {fazit?.map((satz) => (
            <p key={satz} className="report-schluss-text">
              {satz}
            </p>
          ))}
        </div>
      )}

      {hatEmpfehlung && empfehlung && (
        <div className="report-schluss-empfehlung">
          <h3 className="report-schluss-titel">{t('schluss.empfehlungTitel')}</h3>
          <p className="report-schluss-paket">{empfehlung.paket}</p>
          {empfehlung.begruendung.map((satz) => (
            <p key={satz} className="report-schluss-text">
              {satz}
            </p>
          ))}
        </div>
      )}
    </section>
  )
}
