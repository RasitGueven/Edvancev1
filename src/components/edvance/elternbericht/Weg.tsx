import { useTranslation } from 'react-i18next'

// Pfad und Stationen wörtlich aus dem Maßblatt E7 (Seite 1, „Weg durch den
// Bericht“), in Seitenkoordinaten (pt). Die viewBox schneidet den Ausschnitt
// x 44–551, y 698–757 heraus; das SVG steht im Fluss unter dem Kicker.
const PFAD =
  'M 69,720 C 117.3,720 135.7,712 184,712 C 232.3,712 250.7,723 299,723 ' +
  'C 347.3,723 365.7,713 414,713 C 454.7,713 470.3,720 511,720'

const STATIONEN = [
  { n: 1, x: 69, y: 720 },
  { n: 2, x: 184, y: 712 },
  { n: 3, x: 299, y: 723 },
  { n: 4, x: 414, y: 713 },
  { n: 5, x: 511, y: 720 },
] as const

/** Abstand Stationsmitte → Grundlinie der Beschriftung bzw. der Nummer. */
const BESCHRIFTUNG_DY = 26.4
const NUMMER_DY = 2.2

/**
 * „Ihr Weg durch diesen Bericht“: fünf Stationen auf einer Kurve, die erste
 * ist diese Seite. Ein SVG, damit Pfad, Kreise und Beschriftung zueinander
 * stehen wie im Muster.
 */
export function Weg(): JSX.Element {
  const { t } = useTranslation('elternbericht')

  return (
    <section className="eb-s1-weg" data-testid="eb-weg">
      <h2 className="eb-kicker eb-s1-weg-kicker">{t('s1.weg.kicker')}</h2>
      <svg className="eb-s1-weg-bild" viewBox="44 698 507 59" role="img" aria-label={t('s1.weg.kicker')}>
        <path className="eb-weg-pfad" d={PFAD} />
        {STATIONEN.map((s) => {
          const hier = s.n === 1
          return (
            <g key={s.n} className={hier ? 'eb-weg-station eb-weg-hier' : 'eb-weg-station'}>
              <circle cx={s.x} cy={s.y} r="11.4" />
              <text className="eb-weg-nummer" x={s.x} y={s.y + NUMMER_DY}>
                {String(s.n).padStart(2, '0')}
              </text>
              <text className="eb-weg-name" x={s.x} y={s.y + BESCHRIFTUNG_DY}>
                {t(`s1.weg.station.${s.n}`)}
              </text>
            </g>
          )
        })}
        <text className="eb-weg-sie" x="44" y="754">
          {t('s1.weg.hier')}
        </text>
      </svg>
    </section>
  )
}
