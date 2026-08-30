import { useTranslation } from 'react-i18next'

import type { FamilienBefund } from '@/lib/report/familien'

/**
 * „Profil über die Themenfamilien" — das Bild, auf das der Coach zeigt (R6).
 *
 * Es ordnet nach THEMA, die Ebenenspur in Abschnitt 02 nach TIEFE. Zwei Achsen,
 * dieselben Urteile, keine Dopplung.
 *
 * ----------------------------------------------------------------------------
 * Zwei Flächen auf DEMSELBEN Nenner
 * ----------------------------------------------------------------------------
 * Eine einzelne Fläche mit `traegt / geprueft` verzerrt in genau die falsche
 * Richtung: „2 von 2" ergäbe eine volle Achse, obwohl von acht vorhandenen
 * Bereichen sechs nie angesehen wurden. Je weniger geprüft, desto besser sähe
 * die Familie aus.
 *
 * Deshalb zählen beide Flächen gegen den BESTAND — alle Skills der Familie:
 *
 *   außen, gestrichelt   geprueft / vorhanden
 *   innen, gefüllt       traegt   / vorhanden
 *
 * Der Abstand ist die Information: dicht beisammen heißt „das Geprüfte trägt",
 * weit auseinander „gründlich geprüft, trägt wenig", beide klein „hier wurde
 * kaum geprüft". Die innere Fläche kann die äußere nie überragen.
 *
 * KEINE NOTE (INV-4.4): ein Farbton, keine Prozentzahl an den Achsen, keine
 * Skalenbeschriftung, keine Ampelfarben. Die Ringe sind das einzige Maß, und
 * sie tragen bewusst keine Zahl. Der Nenner steht als Text darunter — ohne ihn
 * verschweigt ein Anteilsdiagramm seine Grundlage.
 */

const CX = 130
const CY = 128
const R = 82

const r1 = (n: number): number => Math.round(n * 10) / 10
const winkel = (i: number, n: number): number => ((-90 + (i * 360) / n) * Math.PI) / 180

function flaeche(
  befunde: readonly FamilienBefund[],
  wert: (b: FamilienBefund) => number | null,
): string {
  return befunde
    .map((b, i) => {
      const w = winkel(i, befunde.length)
      const f = wert(b) ?? 0
      return `${r1(Math.cos(w) * R * f)},${r1(Math.sin(w) * R * f)}`
    })
    .join(' ')
}

function ring(n: number, f: number): string {
  return Array.from({ length: n }, (_, i) => {
    const w = winkel(i, n)
    return `${r1(Math.cos(w) * R * f)},${r1(Math.sin(w) * R * f)}`
  }).join(' ')
}

export function ReportProfil({
  profil,
  titleClassName,
}: {
  profil: FamilienBefund[]
  titleClassName: string
}): JSX.Element | null {
  const { t } = useTranslation('report')

  // Ohne einen einzigen geprüften Bereich gäbe es sechs leere Achsen — das ist
  // kein Profil, sondern ein leerer Kasten.
  if (profil.length === 0 || profil.every((b) => b.geprueft === 0)) return null

  const n = profil.length

  return (
    <section className="report-block report-profil">
      <svg
        viewBox="0 0 260 258"
        className="report-profil-bild"
        role="img"
        aria-label={t('profil.ariaLabel')}
      >
        <g transform={`translate(${CX},${CY})`}>
          <polygon points={ring(n, 1)} className="report-profil-netz" />
          <polygon points={ring(n, 2 / 3)} className="report-profil-netz report-profil-netz-innen" />
          <polygon points={ring(n, 1 / 3)} className="report-profil-netz report-profil-netz-innen" />
          <g className="report-profil-speichen">
            {profil.map((b, i) => {
              const w = winkel(i, n)
              return (
                <line
                  key={b.key}
                  x1="0"
                  y1="0"
                  x2={r1(Math.cos(w) * R)}
                  y2={r1(Math.sin(w) * R)}
                />
              )
            })}
          </g>
          <polygon
            points={flaeche(profil, (b) => b.anteilGeprueft)}
            className="report-profil-geprueft"
          />
          <polygon
            points={flaeche(profil, (b) => b.anteilTraegt)}
            className="report-profil-traegt"
          />
          <g className="report-profil-punkte">
            {profil.map((b, i) => {
              if (b.grund !== null) return null
              const w = winkel(i, n)
              const f = b.anteilTraegt ?? 0
              return (
                <circle
                  key={b.key}
                  cx={r1(Math.cos(w) * R * f)}
                  cy={r1(Math.sin(w) * R * f)}
                  r="2.5"
                />
              )
            })}
          </g>
        </g>
        <g className="report-profil-achsen">
          {profil.map((b, i) => {
            const w = winkel(i, n)
            const lx = Math.min(224, Math.max(36, r1(CX + Math.cos(w) * (R + 26))))
            const zeilen = [
              ...b.zeilen,
              ...(b.grund ? [t('profil.nichtGeprueft')] : []),
            ]
            let ly = r1(CY + Math.sin(w) * (R + 26)) + 3
            const hoehe = (zeilen.length - 1) * 10
            if (ly + hoehe > 244) ly = 244 - hoehe
            if (ly < 12) ly = 12
            return zeilen.map((zeile, k) => (
              <text
                key={`${b.key}-${k}`}
                x={lx}
                y={r1(ly + k * 10)}
                className={
                  b.grund !== null ? 'report-profil-achse-grau' : 'report-profil-achse'
                }
              >
                {zeile}
              </text>
            ))
          })}
        </g>
      </svg>

      <div className="report-profil-text">
        <h4 className={titleClassName}>{t('profil.title')}</h4>
        <p className="report-profil-cap">{t('profil.description')}</p>
        <ul className="report-profil-legende">
          <li>
            <span className="report-profil-marke-geprueft" aria-hidden="true" />
            <span>
              <b>{t('profil.legendeGepruefName')}</b> {t('profil.legendeGeprueft')}
            </span>
          </li>
          <li>
            <span className="report-profil-marke-traegt" aria-hidden="true" />
            <span>
              <b>{t('profil.legendeTraegtName')}</b> {t('profil.legendeTraegt')}
            </span>
          </li>
        </ul>
        <p className="report-profil-cap">{t('profil.lesehilfe')}</p>
        <p className="report-profil-nenner">
          {profil
            .map((b) =>
              b.geprueft === 0
                ? t('profil.nennerLeer', { familie: b.label, vorhanden: b.vorhanden })
                : t('profil.nenner', {
                    familie: b.label,
                    geprueft: b.geprueft,
                    vorhanden: b.vorhanden,
                    traegt: b.traegt,
                  }),
            )
            .join(' · ')}
        </p>
      </div>
    </section>
  )
}
