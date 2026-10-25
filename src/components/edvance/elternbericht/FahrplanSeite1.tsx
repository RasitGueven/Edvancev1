import { useTranslation } from 'react-i18next'

import type { EbFahrplan } from '@/types'

import { schuleGenitiv } from './berichtSaetze'
import { signalText, standZeile, stationAria, tonVon, trennerText, trennerVor } from './fahrplanText'

// Die Bahn: ein SVG in pt, 1 Einheit = 1 pt, so breit wie der Innenraum des
// Kastens (507 − Rand − Innenabstand). Die Punkte sitzen über gleich breiten
// Spalten; die Linie schwingt durch ihre Mitten, weil die Zukunft nicht fest ist.
const BREITE = 477
const HOEHE = 34
const RADIUS = 10
const LAGE_Y = [19, 13, 21, 14, 19] as const

/** Sanfte S-Kurve durch die Mittelpunkte, am Anfang und Ende ein Stück verlängert. */
function bahn(xs: readonly number[], ys: readonly number[]): string {
  const punkte = [
    [4, ys[0]],
    ...xs.map((x, i) => [x, ys[i]]),
    [BREITE - 4, ys[ys.length - 1]],
  ]
  return punkte
    .map(([x, y], i) => {
      if (i === 0) return `M${x} ${y}`
      const [vx, vy] = punkte[i - 1]
      const m = (vx + x) / 2
      return `C${m} ${vy} ${m} ${y} ${x} ${y}`
    })
    .join(' ')
}

/**
 * Der Fahrplan auf Seite 1 (Bauauftrag V4, V4-2 Entscheidung 2): ein weißer
 * Kasten mit der Bahn der Klassenarbeiten, darunter je Spalte Titel und Stand
 * mit Signal, der Satz nach fahrplan.satz im mint Kasten und die Quelle.
 * Keine einzelnen Voraussetzungen: die stehen nur auf Seite 3.
 */
export function FahrplanSeite1({
  fahrplan,
  wessen,
}: {
  fahrplan: EbFahrplan
  wessen: string | null
}): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const n = fahrplan.stationen.length
  const spalte = BREITE / n
  const xs = fahrplan.stationen.map((_, i) => (i + 0.5) * spalte)
  const ys = fahrplan.stationen.map((_, i) => LAGE_Y[i % LAGE_Y.length])

  const quelle =
    fahrplan.quelle === 'klp'
      ? t('v4.quelle.klp')
      : fahrplan.schulname
        ? t('v4.quelle.schuleGenitiv', { schule: schuleGenitiv(t, fahrplan.schulname) })
        : t('s3.v2.hinweis', { quelle: t('s3.v2.quelleSchuleOhneName') })

  return (
    <section className="eb-fp" data-testid="eb-fahrplan">
      <h2 className="eb-kicker">
        {wessen ? t('v4.s1.fahrplanKicker', { wessen }) : t('v4.s1.fahrplanKickerOhneName')}
      </h2>

      <div className="eb-fp-raster">
        <svg className="eb-fp-bahn" viewBox={`0 0 ${BREITE} ${HOEHE}`} aria-hidden="true">
          <path className="eb-fp-linie" d={bahn(xs, ys)} />
          {fahrplan.stationen.map((s, i) => {
            const art = trennerVor(fahrplan, i)
            return (
              <g key={s.nummer}>
                {art && (
                  <g className="eb-fp-trenner" data-testid="eb-fp-trenner" data-art={art}>
                    <line x1={i * spalte} y1="9" x2={i * spalte} y2={HOEHE} />
                    <text x={i * spalte} y="6">
                      {trennerText(t, fahrplan, art)}
                    </text>
                  </g>
                )}
                <g className={`eb-fp-punkt eb-ton-${tonVon(s)}`} transform={`translate(${xs[i]} ${ys[i]})`}>
                  <circle r={RADIUS} />
                  {s.stand === 'geschrieben' ? (
                    <path className="eb-fp-haken" d="M-3.6 0.4 L-1.1 3 L3.7 -2.8" />
                  ) : (
                    <text className="eb-fp-nr" y="3">
                      {s.nummer}
                    </text>
                  )}
                </g>
              </g>
            )
          })}
        </svg>

        <ol className="eb-fp-spalten">
          {fahrplan.stationen.map((s, i) => {
            const art = trennerVor(fahrplan, i)
            const signal = signalText(t, s)
            return (
              <li key={s.nummer} className={`eb-fp-spalte eb-ton-${tonVon(s)}`} data-testid="eb-fp-station">
                <span className="sr-only">
                  {art && `${trennerText(t, fahrplan, art)}. `}
                  {stationAria(t, s)}
                  {signal && `, ${signal}`}
                </span>
                <b className="eb-fp-titel" aria-hidden="true">
                  {s.titel}
                </b>
                <span className="eb-fp-stand" aria-hidden="true">
                  {standZeile(t, s)}
                </span>
                {signal && (
                  <span className="eb-fp-signal" aria-hidden="true">
                    {signal}
                  </span>
                )}
              </li>
            )
          })}
        </ol>
      </div>

      {fahrplan.weitere > 0 && (
        <p className="eb-fp-weitere" data-testid="eb-fp-weitere">
          {t('v4.stand.weitere', { count: fahrplan.weitere })}
        </p>
      )}

      {fahrplan.satz && (
        <p className="eb-fp-satz" data-testid="eb-fp-satz">
          {t(fahrplan.satz === 'fehlt' ? 'v4.s1.satzFehlt' : 'v4.s1.satzErfuellt')}
        </p>
      )}

      <p className="eb-fp-quelle" data-testid="eb-fp-quelle">
        <svg viewBox="0 0 10 10" aria-hidden="true">
          <circle cx="5" cy="5" r="4.3" />
          <path d="M5 4.4 V7.2 M5 2.9 V3.1" />
        </svg>
        <span>{quelle}</span>
      </p>
    </section>
  )
}
