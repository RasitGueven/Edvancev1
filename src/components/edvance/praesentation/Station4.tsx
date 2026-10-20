import { useId, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { Empfehlung } from './Empfehlung'
import { Foerderfokus } from './Foerderfokus'
import { Kicker } from './Kicker'
import { Kurve } from './Kurve'
import type { StationProps } from './stationProps'

/**
 * Station 04 · Förderansatz (Entscheidung 9): die Schwerpunkte auf der Kurve des
 * Logos, daneben der Förderfokus des gewählten Punkts, darunter „danach", der
 * Hinweis zum Arbeitsvorschlag und die Paketempfehlung. Ohne Schwerpunkt nur
 * Titel, Satz und Empfehlung.
 */
export function Station4({ p }: StationProps): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const [gewaehlt, setGewaehlt] = useState(0)
  const basis = useId()
  const tabId = (i: number): string => `${basis}-punkt-${i}`
  const panelId = `${basis}-fokus`

  const n = p.schwerpunkte.length
  const aktiv = p.schwerpunkte[Math.min(gewaehlt, n - 1)]
  const danach = new Intl.ListFormat(i18n.language, { style: 'long', type: 'conjunction' }).format(
    p.danach.map((f) => tb(`feld.${f}`)),
  )

  return (
    <div className={n > 0 ? 'tp-szene tp-s4' : 'tp-szene tp-s4 tp-s4-keiner'}>
      <Kicker nummer={4}>{t('s4.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {n > 0 ? t('s4.titel') : tb('s4.titelKeiner')}
      </h2>
      <p className="tp-desc tp-reveal">{n > 0 ? t('s4.desc', { count: n }) : tb('s1.blick.ansatzKeiner')}</p>
      {aktiv && (
        <>
          <div className="tp-s4-layout tp-reveal">
            <Kurve
              schwerpunkte={p.schwerpunkte}
              gewaehlt={gewaehlt}
              onWahl={setGewaehlt}
              tabId={tabId}
              panelId={panelId}
            />
            <Foerderfokus s={aktiv} id={panelId} tabId={tabId(Math.min(gewaehlt, n - 1))} />
          </div>
          {p.danach.length > 0 && <p className="tp-s4-danach tp-reveal">{tb('s4.danach', { liste: danach })}</p>}
          <p className="tp-s4-hinweis tp-reveal">{t('s4.hinweis')}</p>
        </>
      )}
      {p.empfehlung && <Empfehlung e={p.empfehlung} name={p.name} />}
    </div>
  )
}
