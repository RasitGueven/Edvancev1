import { useTranslation } from 'react-i18next'

import { schwerpunktKey, schwerpunktTitel } from '@/components/edvance/elternbericht/liste'
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
      <div key={schwerpunktKey(s)} className="tp-s4-fokus-inhalt">
        <div className="tp-s4-fokus-kopf">
          <span className="tp-etikett">{t('s4.fokus')}</span>
          {/* Schild am Thema-Schwerpunkt wie auf Seite 4 (R7-11). */}
          {s.thema && (
            <span className="tp-s4-chip" data-testid="tp-s4-chip-thema">
              {tb('s4.chip.thema')}
            </span>
          )}
          <span className="tp-s4-pille">{t('s4.stoffAus', { klassen: klassen(s.stufen) })}</span>
        </div>
        <h3>{schwerpunktTitel(tb, s)}</h3>
        <div className="tp-s4-kaesten">
          <Kasten art="sicher" titel={t('s4.sicher')} labels={s.sicher} leer={t('s4.keinSicher')} />
          <Kasten
            art="ueben"
            titel={t('s4.ueben')}
            labels={s.uebung}
            leer={s.thema ? tb('s1.blick.ansatzThemaSicher', { thema: s.thema }) : ''}
          />
        </div>
      </div>
    </div>
  )
}
