import { Maximize2, X } from 'lucide-react'
import { useTranslation } from 'react-i18next'

import { Logo } from './Logo'
import { STATIONEN, stationsName, stationsNummer } from './stationProps'

type KopfProps = {
  /** 1 … 4; 0 (Intro) zeigt die Stationsanzeige der ersten Station. */
  aktuell: number
  testlauf: boolean
  laeuftNoch: boolean
  onLogo: () => void
  onSchliessen: () => void
  /** TP-L1: Knopf „Vollbild“ neben dem X; ohne Handler kein Knopf. */
  onVollbild?: () => void
  /** Klassenarbeiten als roter Faden: Stationsnamen nach V4. */
  v4?: boolean
}

/**
 * Kopf der Präsentation (Entscheidung 5): Logo (führt zu 01), Chips für
 * Testlauf und laufende Analyse, Stationsanzeige „02 / 04 · Lernstand" und
 * rechts „Schließen" an der Stelle des Einstellungsknopfs aus dem Dummy. Davor
 * auf großen Bildschirmen „Vollbild“ (TP-L1, Entscheidung 4).
 */
export function Kopf({ aktuell, testlauf, laeuftNoch, onLogo, onSchliessen, onVollbild, v4 = false }: KopfProps): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const station = Math.max(aktuell, 1)

  return (
    <header className="tp-kopf">
      <button type="button" className="tp-marke" onClick={onLogo} aria-label={t('kopf.zumUeberblick')}>
        <Logo />
        <span aria-hidden="true">edvance</span>
      </button>
      <div className="tp-kopf-rechts">
        {testlauf && <span className="tp-chip">{t('kopf.testdaten')}</span>}
        {laeuftNoch && <span className="tp-chip tp-chip-laeuft">{t('kopf.laeuftNoch')}</span>}
        <span className="tp-stationsanzeige" aria-live="polite">
          {t('kopf.station', {
            nummer: stationsNummer(station, i18n.language),
            gesamt: stationsNummer(STATIONEN.length, i18n.language),
            name: stationsName(t, station, v4),
          })}
        </span>
        {onVollbild && (
          <button
            type="button"
            className="tp-vollbild"
            onClick={onVollbild}
            aria-label={t('kopf.vollbild')}
            title={t('kopf.vollbildTooltip')}
            data-testid="tp-vollbild"
          >
            <Maximize2 aria-hidden="true" />
          </button>
        )}
        <button type="button" className="tp-schliessen" onClick={onSchliessen} aria-label={t('kopf.schliessen')}>
          <X aria-hidden="true" />
        </button>
      </div>
    </header>
  )
}
