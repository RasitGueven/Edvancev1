import { useTranslation } from 'react-i18next'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'

/**
 * Station 01 · Überblick (Entscheidung 6). Hülle aus T2: Kicker und Überschrift.
 * Die Überschrift ist der Kopfsatz wie auf Seite 1 des Druckbogens; fehlt er,
 * gilt die neutrale Ersatzüberschrift. Leitsatz und Karten baut T3.
 */
export function Station1({ p, satz, sessionId }: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const name = p.name
  // Wie Seite1.tsx des Druckbogens, damit Tablet und Papier denselben Satz zeigen.
  const kopf =
    satz.waehle('kopf', p.kopfFall, sessionId, { name: name ?? tb('kind') }) ??
    (name ? tb('s1.kopfErsatz', { name }) : tb('s1.kopfErsatzOhneName'))

  return (
    <div className="tp-szene tp-s1">
      <Kicker nummer={1}>{p.wessen ? t('s1.kicker', { wessen: p.wessen }) : t('s1.kickerOhneName')}</Kicker>
      <h1 className="tp-titel tp-reveal" data-tp-pflicht="">
        {kopf}
      </h1>
    </div>
  )
}
