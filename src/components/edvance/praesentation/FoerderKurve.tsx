import type { CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import { KURVE_PFAD, KURVE_PFEIL, KURVE_START, VIEWBOX } from '@/lib/report/praesentation/kurve'

import { lagen, type FoerderPunkt } from './foerderPunkte'

/**
 * Die Kurve in der Form des Logos (V4, Station 04): Startpunkt navy, Pfeilspitze
 * gold, darauf ein Punkt je Förderfokus in Lernpfad-Reihenfolge von links unten
 * nach rechts oben; der letzte kann die blaue Kugel „Sorgfalt“ sein. Jeder
 * Punkt ist ein Tab des Kastens rechts. Beschriftung: der erste Punkt darunter,
 * alle weiteren links davon. Die Pfeiltasten behandelt die Station.
 */
export function FoerderKurve({
  punkte,
  gewaehlt,
  onWahl,
  tabId,
  panelId,
}: {
  punkte: FoerderPunkt[]
  gewaehlt: number
  onWahl: (i: number) => void
  tabId: (i: number) => string
  panelId: string
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const stellen = lagen(punkte.length)

  return (
    <div className="tp-s4-kurve">
      <svg className="tp-s4-svg" viewBox={`0 0 ${VIEWBOX.w} ${VIEWBOX.h}`} aria-hidden="true" focusable="false">
        <path className="tp-s4-linie" d={KURVE_PFAD} pathLength={100} data-tp-kurve="" />
        <circle className="tp-s4-start" cx={KURVE_START[0]} cy={KURVE_START[1]} r={5.5} />
        <path className="tp-s4-pfeil" d={KURVE_PFEIL} />
      </svg>
      <div className="tp-s4-punkte" role="tablist" aria-label={t('s4.punkteAria')}>
        {punkte.map((pt, i) => {
          const lage = stellen[i]
          const an = i === gewaehlt
          return (
            <button
              key={pt.key}
              type="button"
              role="tab"
              id={tabId(i)}
              className={`tp-s4-punkt tp-s4-seite-${lage.seite}${pt.art === 'sorgfalt' ? ' tp-s4-punkt-sorgfalt' : ''}`}
              style={{ '--x': lage.x, '--y': lage.y, '--anteil': lage.anteil } as CSSProperties}
              aria-selected={an}
              aria-controls={panelId}
              tabIndex={an ? 0 : -1}
              onClick={() => onWahl(i)}
            >
              <span className="tp-s4-kugel" aria-hidden="true" />
              <span className="tp-s4-label" data-tp-beschriftung="">
                <b>{pt.titel}</b>
                <small>{pt.zeile}</small>
              </span>
            </button>
          )
        })}
      </div>
    </div>
  )
}
