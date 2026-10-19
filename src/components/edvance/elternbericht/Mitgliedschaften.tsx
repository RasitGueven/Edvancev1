import { useTranslation } from 'react-i18next'

import type { TierPlan } from '@/types'

// Maßblatt Seite 5: Karten 161 × 152, 12 pt Abstand, Innenkante + 13. Bei mehr
// oder weniger als drei Paketen teilen sich die Karten die Breite von 507 pt.
const BREITE = 507
const ABSTAND = 12
const HOEHE = 152

/**
 * „Unsere Mitgliedschaften“: je aktivem Paket eine Karte mit Name, den ersten
 * zwei Merkmalen und „Konditionen im Gespräch“. Kein Preis, keine Laufzeit.
 * Die Karte zum Coach-Vorschlag ist hervorgehoben.
 */
export function Mitgliedschaften({
  pakete,
  vorschlag,
}: {
  pakete: TierPlan[]
  vorschlag: TierPlan | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const w = (BREITE - (pakete.length - 1) * ABSTAND) / pakete.length

  return (
    <section className="eb-s5-pakete" data-testid="eb-pakete">
      <h2 className="eb-kicker eb-s5-pakete-kicker">{t('s5.pakete.kicker')}</h2>
      <ul className="eb-s5-karten">
        {pakete.map((p) => {
          const hervor = p.id === vorschlag?.id
          const [m1, m2] = p.features
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
                    <rect x="13" y="10" width="87" height="15" rx="7.5" />
                    <text x="21" y="20">
                      {t('s5.pakete.vorschlag')}
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
                <g clipPath={`url(#eb-karte-${p.id})`}>
                  {m1 && (
                    <text className="eb-s5-merkmal eb-s5-merkmal-1" x="13" y="94.5">
                      {m1}
                    </text>
                  )}
                  {m2 && (
                    <text className="eb-s5-merkmal" x="13" y="114.5">
                      {m2}
                    </text>
                  )}
                </g>
                <text className="eb-s5-konditionen" x="13" y="139.4">
                  {t('s5.pakete.konditionen')}
                </text>
              </svg>
            </li>
          )
        })}
      </ul>
      <p className="eb-s5-pakete-hinweis">{t('s5.pakete.hinweis')}</p>
    </section>
  )
}
