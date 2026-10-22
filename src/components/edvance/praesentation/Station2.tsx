import { useEffect, useId, useRef, useState } from 'react'
import { useTranslation } from 'react-i18next'

import { anzeigeZahlen, PROFIL_SOFORT, profilReihenfolge } from '@/lib/report/praesentation/praesentation'

import { Kicker } from './Kicker'
import { Profilzeile } from './Profilzeile'
import type { StationProps } from './stationProps'

/** So lange öffnet sich ein Detail (station2.css), danach wird die Zeile geholt. */
const OEFFNEN_MS = 400

/**
 * Station 02 · Lernstand (Entscheidung 7, PS-1 Entscheidungen 7–9): zwei große
 * Zahlen, sicher und Übungsbedarf. Übersprungen steht nur als kleine Zeile
 * darunter; der Erklärsatz öffnet sich erst beim Antippen. Das Profil zeigt
 * höchstens vier Themenfelder, die übrigen hinter „Alle Themenfelder zeigen".
 * Höchstens ein Detail ist offen; beim Öffnen wird die Zeile in den sichtbaren
 * Bereich der Liste geholt. Die Liste darf dann in sich scrollen, die Station nicht.
 */
export function Station2({ p, anzeige }: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const [offen, setOffen] = useState<number | null>(null)
  const [alle, setAlle] = useState(false)
  const [erklaert, setErklaert] = useState(false)
  const erklaerId = useId()
  const listeRef = useRef<HTMLDivElement>(null)
  const zahlen = anzeigeZahlen(p.zahlen, anzeige)
  const uebersprungen = p.zahlen.uebersprungen > 0
  const zeilen = profilReihenfolge(p)
  const sichtbar = alle ? zeilen : zeilen.slice(0, PROFIL_SOFORT)

  useEffect(() => {
    if (offen === null) return
    const ruhig = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false
    const id = window.setTimeout(() => holeInSicht(listeRef.current, offen, ruhig), ruhig ? 0 : OEFFNEN_MS)
    return () => window.clearTimeout(id)
  }, [offen])

  const umschaltenAlle = (): void => {
    if (alle && offen !== null && offen >= PROFIL_SOFORT) setOffen(null)
    setAlle((a) => !a)
  }

  return (
    <div className={anzeige === 'getrennt' ? 'tp-szene tp-s2 tp-s2-getrennt' : 'tp-szene tp-s2'}>
      <div className="tp-s2-kopf">
        <Kicker nummer={2}>{t('s2.kicker')}</Kicker>
        <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
          {t('s2.titel')}
        </h2>
      </div>

      <div className="tp-s2-tafel">
        <div className="tp-s2-zahlen">
          <p className="tp-s2-zahl tp-s2-zahl-sicher tp-reveal" data-testid="tp-s2-zahl-sicher">
            <strong>{zahlen.sicher}</strong>
            <span>{tb('s2.zahl.sicher')}</span>
          </p>
          <div className="tp-s2-zahl tp-s2-zahl-uebung tp-reveal" data-testid="tp-s2-zahl-uebung">
            <strong>{zahlen.uebung}</strong>
            <span>{tb('s2.zahl.uebung')}</span>
            {zahlen.dritte && (
              <button
                type="button"
                className="tp-s2-ueber-zeile"
                data-testid="tp-s2-zahl-ueber"
                aria-expanded={erklaert}
                aria-controls={erklaerId}
                onClick={() => setErklaert((e) => !e)}
              >
                <i className="tp-muster-ueber" aria-hidden="true" />
                {t(zahlen.dritte.art === 'davon' ? 'zaehlung.davonUebersprungen' : 'zaehlung.uebersprungen', {
                  count: zahlen.dritte.wert,
                })}
              </button>
            )}
          </div>
        </div>
        {uebersprungen && (
          <p id={erklaerId} className="tp-s2-erklaer" data-testid="tp-s2-erklaer" hidden={!erklaert}>
            {p.name ? t('s2.uebersprungenHeisst', { name: p.name }) : t('s2.uebersprungenHeisstOhneName')}
          </p>
        )}
      </div>

      <section className="tp-s2-profil tp-reveal">
        <div className="tp-s2-profil-kopf">
          <h3>{p.wessen ? tb('s2.profil.titel', { wessen: p.wessen }) : tb('s2.profil.titelOhneName')}</h3>
        </div>
        <div ref={listeRef} className="tp-s2-liste" data-tp-liste="">
          {sichtbar.map((zeile, i) => (
            <Profilzeile
              key={zeile.feld}
              zeile={zeile}
              index={i}
              anzeige={anzeige}
              offen={offen === i}
              onUmschalten={() => setOffen((o) => (o === i ? null : i))}
            />
          ))}
          {zeilen.length > PROFIL_SOFORT && (
            <button
              type="button"
              className="tp-s2-alle"
              data-testid="tp-s2-alle"
              aria-expanded={alle}
              onClick={umschaltenAlle}
            >
              {t(alle ? 's2.wenigerFelder' : 's2.alleFelder')}
            </button>
          )}
        </div>
        <div className="tp-s2-fuss tp-reveal">
          <ul className="tp-s2-legende">
            <li>
              <i className="tp-s2-anteil-sicher" aria-hidden="true" />
              {tb('s2.profil.legende.sicher')}
            </li>
            <li>
              <i className="tp-s2-anteil-uebung" aria-hidden="true" />
              {tb('s2.profil.legende.uebung')}
            </li>
            {uebersprungen && (
              <li data-testid="tp-s2-legende-ueber">
                <i className="tp-muster-ueber" aria-hidden="true" />
                {t('s2.legende.uebersprungen')}
              </li>
            )}
          </ul>
          <p className="tp-s2-tippen">{t('s2.tippen')}</p>
        </div>
      </section>
    </div>
  )
}

/** Holt die offene Zeile ganz in den sichtbaren Bereich der Liste, nur die Liste scrollt. */
function holeInSicht(liste: HTMLElement | null, index: number, ruhig: boolean): void {
  const zeile = liste?.querySelectorAll<HTMLElement>('[data-tp-zeile]')[index]
  if (!liste || !zeile) return
  const l = liste.getBoundingClientRect()
  const r = zeile.getBoundingClientRect()
  let delta = 0
  if (r.top < l.top) delta = r.top - l.top
  else if (r.bottom > l.bottom - 10) delta = Math.min(r.bottom - l.bottom + 10, r.top - l.top)
  if (delta !== 0) liste.scrollBy?.({ top: delta, behavior: ruhig ? 'auto' : 'smooth' })
}
