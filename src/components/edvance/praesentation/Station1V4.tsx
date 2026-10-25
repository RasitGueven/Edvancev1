import { useTranslation } from 'react-i18next'

import { baueListe } from '@/components/edvance/elternbericht/liste'
import { anliegenSaetze } from '@/components/edvance/elternbericht/seite1Saetze'

import { FahrplanBahn } from './FahrplanBahn'
import { Kicker } from './Kicker'
import { Pyramide } from './Pyramide'
import type { StationProps } from './stationProps'
import type { PraesentationV4 } from './v4Daten'

/** Ab dieser Länge wird die Überschrift kleiner, damit sie in vier Zeilen passt. */
const LANG = 48
const SEHR_LANG = 80

/** Höchstens zwei Sätze aus dem Anliegen, wenn es keinen Sorgfalt-Satz gibt. */
const ANLIEGEN_SAETZE = 2

/**
 * Station 01 · Überblick (V4, Entscheidung 2): Überschrift und Leitsatz links,
 * rechts die Stufen-Pyramide, darunter über die volle Breite der Fahrplan der
 * Klassenarbeiten mit dem Satz im mint Kasten. Die Eckdaten stehen in Station 02.
 */
export function Station1V4(props: StationProps): JSX.Element | null {
  return props.v4 ? <Ueberblick {...props} v4={props.v4} /> : null
}

function Ueberblick({ p, satz, sessionId, v4 }: StationProps & { v4: PraesentationV4 }): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const name = p.name
  const { fahrplan, bericht, muster } = v4

  const kopf =
    satz.waehle('kopf', p.kopfFall, sessionId, { name: name ?? tb('kind') }) ??
    (name ? tb('s1.kopfErsatz', { name }) : tb('s1.kopfErsatzOhneName'))
  const laenge = kopf.length >= SEHR_LANG ? ' tp-s1-sehr-lang' : kopf.length >= LANG ? ' tp-s1-lang' : ''

  const anliegen = p.anliegen
    ? anliegenSaetze(tb, p.anliegen, p.wessen, baueListe(tb, i18n.language), i18n.language)
        .slice(0, ANLIEGEN_SAETZE)
        .join(' ')
    : null
  const leit = muster?.sorgfalt ? t(name ? 'v4.s1.lead' : 'v4.s1.leadOhneName', { name }) : anliegen

  return (
    <div className="tp-szene tp-s1v">
      <div className="tp-s1v-oben">
        <div className="tp-s1v-text">
          <Kicker nummer={1}>{p.wessen ? t('s1.kicker', { wessen: p.wessen }) : t('s1.kickerOhneName')}</Kicker>
          <h1 className={`tp-titel tp-reveal${laenge}`} data-tp-pflicht="">
            {kopf}
          </h1>
          {leit && (
            <p className="tp-s1v-lead tp-reveal" data-testid="tp-s1-leitsatz">
              {leit}
            </p>
          )}
        </div>
        <Pyramide stufen={bericht.stufen ?? []} />
      </div>

      <section className="tp-fp tp-reveal" data-testid="tp-fahrplan" data-tp-pflicht="">
        <h2 className="tp-fp-kicker">
          {p.wessen ? t('v4.s1.fahrplanKicker', { wessen: p.wessen }) : t('v4.s1.fahrplanKickerOhneName')}
        </h2>
        <FahrplanBahn fahrplan={fahrplan} />
        {fahrplan.satz && (
          <p className="tp-fp-satz" data-testid="tp-fp-satz">
            {tb(fahrplan.satz === 'fehlt' ? 'v4.s1.satzFehlt' : 'v4.s1.satzErfuellt')}
          </p>
        )}
      </section>

      <p className="tp-s1v-weiter tp-reveal">
        {p.wessen ? t('v4.s1.weiter', { wessen: p.wessen }) : t('v4.s1.weiterOhneName')}
      </p>
    </div>
  )
}
