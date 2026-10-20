import { useTranslation } from 'react-i18next'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'
import { UeberblickKarten } from './UeberblickKarten'

/** Ab dieser Länge wird die Überschrift kleiner, damit sie in vier Zeilen passt. */
const LANG = 48
const SEHR_LANG = 80

/**
 * Station 01 · Überblick (Entscheidung 6): Überschrift, Leitsatz, Fach und
 * Klasse, die zwei Karten und die Fußzeile. Die Überschrift ist der Kopfsatz
 * wie auf Seite 1 des Druckbogens; fehlt er, gilt die neutrale
 * Ersatzüberschrift. Keine farbige Teilhervorhebung.
 */
export function Station1({ p, satz, sessionId }: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const name = p.name
  // Wie Seite1.tsx des Druckbogens, damit Tablet und Papier denselben Satz zeigen.
  const kopf =
    satz.waehle('kopf', p.kopfFall, sessionId, { name: name ?? tb('kind') }) ??
    (name ? tb('s1.kopfErsatz', { name }) : tb('s1.kopfErsatzOhneName'))
  const laenge = kopf.length >= SEHR_LANG ? ' tp-s1-sehr-lang' : kopf.length >= LANG ? ' tp-s1-lang' : ''

  return (
    <div className="tp-szene tp-s1">
      <div className="tp-s1-raster">
        <div className="tp-s1-text">
          <Kicker nummer={1}>{p.wessen ? t('s1.kicker', { wessen: p.wessen }) : t('s1.kickerOhneName')}</Kicker>
          <h1 className={`tp-titel tp-reveal${laenge}`} data-tp-pflicht="">
            {kopf}
          </h1>
          <p className="tp-s1-lead tp-reveal">{t(`s1.lead.${p.kopfFall}`)}</p>
          <p className="tp-s1-notiz tp-reveal">
            <i aria-hidden="true" />
            <span>{t('s1.fachKlasse', { fach: p.fach, klasse: p.klasse })}</span>
            {p.naechstesThema && <span>{t('s1.imBlick', { thema: p.naechstesThema })}</span>}
          </p>
        </div>
        <UeberblickKarten ueberblick={p.ueberblick} />
      </div>
      <p className="tp-fusszeile tp-s1-fuss tp-reveal">
        {p.wessen ? t('s1.weiter', { wessen: p.wessen }) : t('s1.weiterOhneName')}{' '}
        <span aria-hidden="true">↓</span>
      </p>
    </div>
  )
}
