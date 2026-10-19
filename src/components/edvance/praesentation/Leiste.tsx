import { useLayoutEffect, useRef, useState, type CSSProperties } from 'react'
import { useTranslation } from 'react-i18next'

import { STATIONEN, stationsNummer } from './stationProps'

/**
 * Stationsleiste links (Entscheidung 5): vier Einträge mit Nummer und Namen.
 * Die Kugel (Eddie) wandert zur aktuellen Station, Tippen springt dorthin.
 * Ohne Pfadlinie.
 */
export function Leiste({ aktuell, onSprung }: { aktuell: number; onSprung: (station: number) => void }): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const knoepfe = useRef<(HTMLButtonElement | null)[]>([])
  const [versatz, setVersatz] = useState(0)

  // Wie alignEddie im Dummy: Abstand der Mitte des aktuellen Eintrags zur Mitte des ersten.
  useLayoutEffect(() => {
    const richte = (): void => {
      const ziel = knoepfe.current[Math.max(aktuell, 1) - 1]
      const erster = knoepfe.current[0]
      if (!ziel || !erster) return
      setVersatz(ziel.offsetTop + ziel.offsetHeight / 2 - (erster.offsetTop + erster.offsetHeight / 2))
    }
    richte()
    window.addEventListener('resize', richte)
    return () => window.removeEventListener('resize', richte)
  }, [aktuell])

  return (
    <nav className="tp-leiste" aria-label={t('leiste.aria')}>
      {STATIONEN.map((n, i) => (
        <button
          key={n}
          ref={(el) => {
            knoepfe.current[i] = el
          }}
          type="button"
          className="tp-leiste-eintrag"
          aria-current={aktuell === n ? 'step' : undefined}
          onClick={() => onSprung(n)}
        >
          <span className="tp-leiste-punkt" aria-hidden="true" />
          <span className="tp-leiste-name">
            <small>{stationsNummer(n, i18n.language)}</small>
            {t(`leiste.station.${n}`)}
          </span>
        </button>
      ))}
      <span
        className="tp-eddie"
        aria-hidden="true"
        style={{ '--tp-eddie': `${versatz}px` } as CSSProperties}
      >
        <b />
      </span>
    </nav>
  )
}
