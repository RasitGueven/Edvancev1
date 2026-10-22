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

// Mikro-Navigation: fünf Punkte auf einer Linie (Maßblatt, Kopf).
const NAV_X = [484, 497, 510, 523, 536] as const
const NAV_Y = 39
const NAV_R = 3.4

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
            <rect className="eb-chip" x="381" y="30" width="82" height="21" rx="10.5" />
            <text className="eb-chip-text" x="394" y="43.4">
              {t('rahmen.testdaten')}
            </text>
          </g>
        )}
        {gesamt === SEITEN_GESAMT && NAV_X.slice(1).map((x, i) => (
          <line key={x} className="eb-nav-linie" x1={NAV_X[i]} y1={NAV_Y} x2={x} y2={NAV_Y} />
        ))}
        {gesamt === SEITEN_GESAMT && NAV_X.map((x, i) => (
          <circle
            key={x}
            className={i + 1 === nummer ? 'eb-nav-punkt eb-nav-punkt-aktiv' : 'eb-nav-punkt'}
            data-aktiv={i + 1 === nummer || undefined}
            cx={x}
            cy={NAV_Y}
            r={NAV_R}
          />
        ))}
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
