import { useId, useState, type KeyboardEvent } from 'react'
import { useTranslation } from 'react-i18next'

import { Empfehlung } from './Empfehlung'
import { baueFoerderPunkte } from './foerderPunkte'
import { FoerderKasten } from './FoerderKasten'
import { FoerderKurve } from './FoerderKurve'
import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'

const VOR = ['ArrowUp', 'ArrowRight']
const ZURUECK = ['ArrowDown', 'ArrowLeft']

/**
 * Station 04 · Förderansatz (V4, Entscheidung 5): links die Kurve mit den
 * Punkten in Lernpfad-Reihenfolge, rechts ein fester Kasten, der beim Antippen
 * nur seinen Inhalt wechselt. Im Hochformat steht er unter der Kurve. Darunter
 * die Empfehlung ohne Preis und der Hinweis zum Arbeitsvorschlag.
 */
export function StationFoerderansatz({ p, v4 }: StationProps): JSX.Element | null {
  const { t: tp } = useTranslation('praesentation')
  const { t: tb, i18n } = useTranslation('elternbericht')
  const [gewaehlt, setGewaehlt] = useState(0)
  const basis = useId()
  const tabId = (i: number): string => `${basis}-punkt-${i}`
  const panelId = `${basis}-fokus`
  if (!v4) return null

  const punkte = baueFoerderPunkte(v4, p.name, { tp, tb, sprache: i18n.language })
  const n = punkte.length
  const aktuell = Math.min(gewaehlt, n - 1)
  const aktiv = punkte[aktuell]

  const wechsle = (schritt: number, fokus = false): void => {
    const ziel = Math.max(0, Math.min(n - 1, aktuell + schritt))
    setGewaehlt(ziel)
    if (fokus) document.getElementById(tabId(ziel))?.focus()
  }
  const taste = (e: KeyboardEvent): void => {
    const schritt = VOR.includes(e.key) ? 1 : ZURUECK.includes(e.key) ? -1 : 0
    if (!schritt) return
    e.preventDefault()
    wechsle(schritt, (e.target as HTMLElement).getAttribute('role') === 'tab')
  }

  return (
    <div className={n > 0 ? 'tp-szene tp-s4 tp-s4v' : 'tp-szene tp-s4 tp-s4v tp-s4-keiner'}>
      <Kicker nummer={4}>{tp('s4.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {n > 0 ? tp('v4.s4.titel') : tb('s4.titelKeiner')}
      </h2>
      <p className="tp-desc tp-reveal">{n > 0 ? tp(v4?.fahrplan.folge === 'unbekannt' ? 'v4.s4.descThema' : 'v4.s4.desc') : tb('s1.blick.ansatzKeiner')}</p>
      {aktiv && (
        // Die Pfeiltasten gelten, solange der Fokus in Kurve oder Kasten liegt.
        <div className="tp-s4-layout tp-s4v-layout tp-reveal" onKeyDown={taste}>
          <FoerderKurve punkte={punkte} gewaehlt={aktuell} onWahl={setGewaehlt} tabId={tabId} panelId={panelId} />
          <FoerderKasten
            punkt={aktiv}
            index={aktuell}
            gesamt={n}
            id={panelId}
            tabId={tabId(aktuell)}
            onWechsel={(schritt) => wechsle(schritt)}
          />
        </div>
      )}
      {p.empfehlung && <Empfehlung e={p.empfehlung} name={p.name} />}
      {aktiv && <p className="tp-s4-hinweis tp-reveal">{tp('s4.hinweis')}</p>}
    </div>
  )
}
