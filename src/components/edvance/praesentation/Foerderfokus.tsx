import { useTranslation } from 'react-i18next'

import type { TpSchwerpunkt } from '@/types'

import { useKlassen } from './useKlassen'

/** Höchstens drei Bereiche je Kasten, danach „+n weitere". */
const SICHTBAR = 3

function Kasten({ art, titel, labels, leer }: { art: 'sicher' | 'ueben'; titel: string; labels: string[]; leer: string }): JSX.Element {
  const { t: tb } = useTranslation('elternbericht')
  const rest = labels.length - SICHTBAR
  return (
    <div className={`tp-s4-kasten tp-s4-kasten-${art}`}>
      <small>{titel}</small>
      {labels.length === 0 ? (
        <p className="tp-s4-leer">{leer}</p>
      ) : (
        <ul>
          {labels.slice(0, SICHTBAR).map((l) => (
            <li key={l}>{l}</li>
          ))}
          {rest > 0 && <li className="tp-s4-weitere">{tb('s1.blick.weitere', { count: rest })}</li>}
        </ul>
      )}
    </div>
  )
}

/**
 * Die Karte „Förderfokus" zum gewählten Punkt (Entscheidung 9): Pille mit der
 * Klassenangabe, Titel = Themenfeld, zwei Kästen „Sicher im Test" und „Hier üben
 * wir". Im Querformat rechts neben der Kurve, im Hochformat darunter.
 */
export function Foerderfokus({ s, id, tabId }: { s: TpSchwerpunkt; id: string; tabId: string }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const klassen = useKlassen()
  const feldKey = s.feld
  return (
    <div
      className="tp-s4-fokus"
      role="tabpanel"
      id={id}
      aria-labelledby={tabId}
      tabIndex={0}
      data-tp-beschriftung=""
    >
      {/* key: beim Wechsel blendet der Inhalt neu ein wie im Dummy. */}
      <div key={s.feld} className="tp-s4-fokus-inhalt">
        <div className="tp-s4-fokus-kopf">
          <span className="tp-etikett">{t('s4.fokus')}</span>
          <span className="tp-s4-pille">{t('s4.stoffAus', { klassen: klassen(s.stufen) })}</span>
        </div>
        <h3>{tb(`feld.${feldKey}`)}</h3>
        <div className="tp-s4-kaesten">
          <Kasten art="sicher" titel={t('s4.sicher')} labels={s.sicher} leer={t('s4.keinSicher')} />
          <Kasten art="ueben" titel={t('s4.ueben')} labels={s.uebung} leer="" />
        </div>
      </div>
    </div>
  )
}
