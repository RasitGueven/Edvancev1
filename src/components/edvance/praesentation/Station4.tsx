import { useId, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { Empfehlung } from './Empfehlung'
import { Foerderfokus } from './Foerderfokus'
import { Kicker } from './Kicker'
import { Kurve } from './Kurve'
import type { StationProps } from './stationProps'

/** Höchstens drei Punkte auf der Kurve; der Druckbogen behält alle (PS-1, Entscheidung 16). */
const PUNKTE = 3

/**
 * Station 04 · Förderansatz (Entscheidung 9, PS-1 Entscheidungen 16–18): die
 * ersten drei Schwerpunkte auf der Kurve des Logos, daneben der Förderfokus des
 * gewählten Punkts, darunter die Paketempfehlung und als Caption der Hinweis
 * zum Arbeitsvorschlag. Ohne Schwerpunkt nur Titel, Satz und Empfehlung.
 */
export function Station4({ p }: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const [gewaehlt, setGewaehlt] = useState(0)
  const basis = useId()
  const tabId = (i: number): string => `${basis}-punkt-${i}`
  const panelId = `${basis}-fokus`

  const schwerpunkte = p.schwerpunkte.slice(0, PUNKTE)
  const n = schwerpunkte.length
  const aktiv = schwerpunkte[Math.min(gewaehlt, n - 1)]

  return (
    <div className={n > 0 ? 'tp-szene tp-s4' : 'tp-szene tp-s4 tp-s4-keiner'}>
      <Kicker nummer={4}>{t('s4.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {n > 0 ? t('s4.titel') : tb('s4.titelKeiner')}
      </h2>
      <p className="tp-desc tp-reveal">{n > 0 ? t('s4.desc', { count: n }) : tb('s1.blick.ansatzKeiner')}</p>
      {aktiv && (
        <div className="tp-s4-layout tp-reveal">
          <Kurve schwerpunkte={schwerpunkte} gewaehlt={gewaehlt} onWahl={setGewaehlt} tabId={tabId} panelId={panelId} />
          <Foerderfokus s={aktiv} id={panelId} tabId={tabId(Math.min(gewaehlt, n - 1))} />
        </div>
      )}
      {p.empfehlung && <Empfehlung e={p.empfehlung} name={p.name} />}
      {aktiv && <p className="tp-s4-hinweis tp-reveal">{t('s4.hinweis')}</p>}
    </div>
  )
}
