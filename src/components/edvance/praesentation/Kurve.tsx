import { useRef, type CSSProperties, type KeyboardEvent } from 'react'
import { useTranslation } from 'react-i18next'

import { KURVE_PFAD, KURVE_PFEIL, KURVE_START, VIEWBOX, kurvenPunkte } from '@/lib/report/praesentation/kurve'
import type { TpSchwerpunkt } from '@/types'

import { useKlassen } from './useKlassen'

type KurveProps = {
  schwerpunkte: TpSchwerpunkt[]
  gewaehlt: number
  onWahl: (i: number) => void
  /** Ids der Punkte (role tab) und der Karte (tabpanel). */
  tabId: (i: number) => string
  panelId: string
}

const VOR = ['ArrowUp', 'ArrowRight']
const ZURUECK = ['ArrowDown', 'ArrowLeft']

/**
 * Die Kurve in der Form des Logos (Entscheidung 9): Startpunkt navy, Pfeilspitze
 * gold, darauf ein Punkt je Schwerpunkt ohne Zahl. Jeder Punkt ist ein Tab der
 * Förderfokus-Karte; Pfeiltasten wechseln. Lage aus kurvenPunkte() als Zahl in
 * --x/--y, im CSS calc(var(--x) * 1%).
 */
export function Kurve({ schwerpunkte, gewaehlt, onWahl, tabId, panelId }: KurveProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const klassen = useKlassen()
  const punkte = kurvenPunkte(schwerpunkte.length)
  const knoepfe = useRef<(HTMLButtonElement | null)[]>([])

  const taste = (e: KeyboardEvent, i: number): void => {
    const schritt = VOR.includes(e.key) ? 1 : ZURUECK.includes(e.key) ? -1 : 0
    if (!schritt) return
    e.preventDefault()
    const n = (i + schritt + punkte.length) % punkte.length
    onWahl(n)
    knoepfe.current[n]?.focus()
  }

  return (
    <div className="tp-s4-kurve">
      <svg
        className="tp-s4-svg"
        viewBox={`0 0 ${VIEWBOX.w} ${VIEWBOX.h}`}
        aria-hidden="true"
        focusable="false"
      >
        <path className="tp-s4-linie" d={KURVE_PFAD} pathLength={100} data-tp-kurve="" />
        <circle className="tp-s4-start" cx={KURVE_START[0]} cy={KURVE_START[1]} r={5.5} />
        <path className="tp-s4-pfeil" d={KURVE_PFEIL} />
      </svg>
      <div className="tp-s4-punkte" role="tablist" aria-label={t('s4.punkteAria')}>
        {punkte.map((pt, i) => {
          const s = schwerpunkte[i]
          const feldKey = s.feld
          const feld = tb(`feld.${feldKey}`)
          const angabe = klassen(s.stufen)
          const an = i === gewaehlt
          return (
            <button
              key={s.feld}
              ref={(el) => {
                knoepfe.current[i] = el
              }}
              type="button"
              role="tab"
              id={tabId(i)}
              className={`tp-s4-punkt tp-s4-seite-${pt.seite}`}
              style={{ '--x': pt.x, '--y': pt.y, '--anteil': pt.anteil } as CSSProperties}
              aria-selected={an}
              aria-controls={panelId}
              aria-label={t('s4.punktAria', { feld, klassen: angabe })}
              tabIndex={an ? 0 : -1}
              onClick={() => onWahl(i)}
              onKeyDown={(e) => taste(e, i)}
            >
              <span className="tp-s4-kugel" aria-hidden="true" />
              <span className="tp-s4-label" aria-hidden="true" data-tp-beschriftung="">
                <b>{feld}</b>
                <small>{angabe}</small>
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}
