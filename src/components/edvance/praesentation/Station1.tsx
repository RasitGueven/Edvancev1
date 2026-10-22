import { useTranslation } from 'react-i18next'

import { baueListe } from '@/components/edvance/elternbericht/liste'
import { anliegenSaetze } from '@/components/edvance/elternbericht/seite1Saetze'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'
import { UeberblickKarten } from './UeberblickKarten'

/** Ab dieser Länge wird die Überschrift kleiner, damit sie in vier Zeilen passt. */
const LANG = 48
const SEHR_LANG = 80

/** Höchstens zwei Sätze aus dem Anliegen (PS-1, Entscheidung 4). */
const ANLIEGEN_SAETZE = 2

/**
 * Station 01 · Überblick (Entscheidung 6, PS-1 Entscheidungen 4–6): Kicker,
 * Überschrift, das Anliegen als Frage und Antwort wie auf Seite 1 (R7-11) und
 * die zwei Karten. Die Überschrift ist der Kopfsatz wie auf Seite 1 des
 * Druckbogens; fehlt er, gilt die neutrale Ersatzüberschrift. Leitsatz, Fach
 * und Klasse und die Fußzeile entfallen: Fach und Klasse stehen im Intro.
 */
export function Station1({ p, satz, sessionId }: StationProps): JSX.Element {
  const { t, i18n } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const name = p.name
  // Wie Seite1.tsx des Druckbogens, damit Tablet und Papier denselben Satz zeigen.
  const kopf =
    satz.waehle('kopf', p.kopfFall, sessionId, { name: name ?? tb('kind') }) ??
    (name ? tb('s1.kopfErsatz', { name }) : tb('s1.kopfErsatzOhneName'))
  const laenge = kopf.length >= SEHR_LANG ? ' tp-s1-sehr-lang' : kopf.length >= LANG ? ' tp-s1-lang' : ''
  // „Ihr Anliegen“ mit denselben Sätzen wie Seite 1 (R7-11, Entscheidung 13).
  const anliegen = p.anliegen
    ? anliegenSaetze(tb, p.anliegen, p.wessen, baueListe(tb, i18n.language), i18n.language)
        .slice(0, ANLIEGEN_SAETZE)
        .join(' ')
    : null
  const thema = p.schwerpunkte[0]?.thema ? p.schwerpunkte[0] : null

  return (
    <div className="tp-szene tp-s1">
      <div className="tp-s1-raster">
        <div className="tp-s1-text">
          <Kicker nummer={1}>{p.wessen ? t('s1.kicker', { wessen: p.wessen }) : t('s1.kickerOhneName')}</Kicker>
          <h1 className={`tp-titel tp-reveal${laenge}`} data-tp-pflicht="">
            {kopf}
          </h1>
          {anliegen && (
            <p className="tp-s1-anliegen tp-reveal" data-testid="tp-s1-anliegen">
              {anliegen}
            </p>
          )}
        </div>
        <UeberblickKarten ueberblick={p.ueberblick} start={thema?.start ?? null} />
      </div>
    </div>
  )
}
