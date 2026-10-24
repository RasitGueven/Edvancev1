import { useTranslation } from 'react-i18next'

import type { TierPlan } from '@/types'

// Maßblatt Seite 5: Karten 161 breit, 12 pt Abstand, Innenkante + 13. Bei mehr
// oder weniger als drei Paketen teilen sich die Karten die Breite von 507 pt.
// Bericht v2: nur Name und Rhythmus, die Karten sind dafür niedriger.
const BREITE = 507
const ABSTAND = 12
const HOEHE = 104

/**
 * „Unsere Mitgliedschaften“: je aktivem Paket eine Karte mit Name und
 * Rhythmus (erstes Merkmal, z. B. „1 Session/Woche“). Kein Preis, keine
 * Laufzeit, keine weiteren Merkmale. Die vorausgewählte Karte ist
 * hervorgehoben, mit Schild „Vorschlag“ bzw. „Empfehlung Ihres Coachs“.
 */
export function Mitgliedschaften({
  pakete,
  vorschlag,
  bestaetigt,
}: {
  pakete: TierPlan[]
  vorschlag: TierPlan | null
  bestaetigt: boolean
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const w = (BREITE - (pakete.length - 1) * ABSTAND) / pakete.length

  return (
    <section className="eb-s5-pakete" data-testid="eb-pakete">
      <h2 className="eb-kicker eb-s5-pakete-kicker">{t('s5.pakete.kicker')}</h2>
      <ul className="eb-s5-karten">
        {pakete.map((p) => {
          const hervor = p.id === vorschlag?.id
          const [rhythmus] = p.features
          return (
            <li key={p.id} data-testid="eb-paket" data-vorschlag={hervor || undefined}>
              <svg
                className={hervor ? 'eb-s5-karte eb-s5-karte-vorschlag' : 'eb-s5-karte'}
                width={`${w}pt`}
                height={`${HOEHE}pt`}
                viewBox={`0 0 ${w} ${HOEHE}`}
              >
                <defs>
                  {/* Merkmale sind Freitext und brechen im SVG nicht um: nichts ragt über den Rand. */}
                  <clipPath id={`eb-karte-${p.id}`}>
                    <rect x="13" y="0" width={w - 26} height={HOEHE} />
                  </clipPath>
                </defs>
                <rect className="eb-s5-karte-flaeche" x="0.5" y="0.5" width={w - 1} height={HOEHE - 1} rx="12" />
                {hervor ? (
                  <g className="eb-s5-chip">
                    <rect x="13" y="10" width={bestaetigt ? 104 : 56} height="15" rx="7.5" />
                    <text x="21" y="20">
                      {t(bestaetigt ? 's5.vorschlag.chipBestaetigt' : 's5.pakete.vorschlagChip')}
                    </text>
                  </g>
                ) : (
                  <text className="eb-s5-karte-kopf" x="13" y="23.1">
                    {t('s5.pakete.karte')}
                  </text>
                )}
                <text className="eb-s5-karte-name" x="13" y="60" clipPath={`url(#eb-karte-${p.id})`}>
                  {p.name}
                </text>
                <line className="eb-s5-karte-linie" x1="13" y1="77" x2={w - 13} y2="77" />
                {rhythmus && (
                  <text
                    className="eb-s5-merkmal eb-s5-merkmal-1"
                    x="13"
                    y="94.5"
                    clipPath={`url(#eb-karte-${p.id})`}
                  >
                    {rhythmus}
                  </text>
                )}
              </svg>
            </li>
          )
        })}
      </ul>
    </section>
  )
}
