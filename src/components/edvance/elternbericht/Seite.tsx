import type { ReactNode } from 'react'
import { useTranslation } from 'react-i18next'

import { SEITEN_GESAMT } from './seitenProps'

/**
 * Eine A4-Seite des Eltern-Berichts R7: Kopf und Fuß fest, der Inhalt im Fluss.
 *
 * Kopf und Fuß sind je ein SVG in pt (viewBox = Seitenkoordinaten aus dem
 * Maßblatt E7, „Alle Seiten“). So liegen Linien, Chip und Navigationspunkte
 * genau dort, wo das Muster sie hat, und Text steht auf seiner Grundlinie —
 * unabhängig von Zeilenhöhen. Der Inhalt läuft in `.eb-inhalt` zwischen der
 * Kopflinie (y 78) und y 800.
 *
 * `gesamt` nur für einen Bogen mit anderer Seitenzahl (die Seite „nicht
 * auswertbar“, LSA-R2): Fuß „1 / 1“, ohne die Navigationspunkte.
 */

// Navigation „Ihr Weg durch diesen Bericht“ (Bericht v2): fünf beschriftete
// Stationen oben rechts, die aktuelle Seite gefüllt. Mitten in pt; die letzte
// Beschriftung endet an der Kopflinie (x 551).
const NAV_X = [256, 322, 388, 454, 520] as const
const NAV_Y = 33
const NAV_R = 6.2
const NAV_TEXT_Y = 53.5

export function Seite({
  nummer,
  gesamt = SEITEN_GESAMT,
  testlauf,
  name,
  children,
}: {
  nummer: number
  gesamt?: number
  testlauf: boolean
  name: string | null
  children: ReactNode
}): JSX.Element {
  const { t } = useTranslation('elternbericht')

  return (
    <section className="eb-seite" data-seite={nummer}>
      <svg
        className="eb-kopf"
        viewBox="0 0 595.28 90"
        aria-hidden={!testlauf}
        data-testid="eb-kopf"
      >
        <polyline className="eb-chevron" points="44,37 50,31 62,42" />
        <text className="eb-wortmarke" x="70" y="43.4">
          edvance
        </text>
        {testlauf && (
          <g data-testid="eb-chip">
            <rect className="eb-chip" x="70" y="52" width="50" height="13" rx="6.5" />
            <text className="eb-chip-text" x="95" y="61">
              {t('rahmen.testdaten')}
            </text>
          </g>
        )}
        {gesamt === SEITEN_GESAMT && (
          <g className="eb-nav" data-testid="eb-nav" role="list" aria-label={t('rahmen.nav')}>
            <line className="eb-nav-linie" x1={NAV_X[0]} y1={NAV_Y} x2={NAV_X[4]} y2={NAV_Y} />
            {NAV_X.map((x, i) => {
              const aktiv = i + 1 === nummer
              return (
                <g
                  key={x}
                  role="listitem"
                  className={aktiv ? 'eb-nav-station eb-nav-aktiv' : 'eb-nav-station'}
                  data-aktiv={aktiv || undefined}
                  aria-current={aktiv ? 'page' : undefined}
                >
                  <circle className="eb-nav-punkt" cx={x} cy={NAV_Y} r={NAV_R} />
                  <text className="eb-nav-nummer" x={x} y={NAV_Y + 2.2}>
                    {i + 1}
                  </text>
                  <text className="eb-nav-name" x={x} y={NAV_TEXT_Y}>
                    {t(`s1.weg.station.${i + 1}`)}
                  </text>
                </g>
              )
            })}
          </g>
        )}
        <line className="eb-kopflinie" x1="44" y1="78" x2="551" y2="78" />
      </svg>

      <div className="eb-inhalt">{children}</div>

      <svg className="eb-fuss" viewBox="0 800 595.28 41.89" data-testid="eb-fuss">
        <line className="eb-fusslinie" x1="44" y1="810" x2="551" y2="810" />
        <text className="eb-fuss-text" x="44" y="828.1">
          {name ? t('rahmen.fuss', { name }) : t('rahmen.fussOhneName')}
        </text>
        <text className="eb-fuss-text eb-fuss-seite" x="551" y="828.1">
          {t('rahmen.seite', { seite: nummer, gesamt })}
        </text>
      </svg>
    </section>
  )
}
