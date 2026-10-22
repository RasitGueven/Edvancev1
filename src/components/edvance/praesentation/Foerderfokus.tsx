import { useTranslation } from 'react-i18next'

import { schwerpunktKey, schwerpunktTitel } from '@/components/edvance/elternbericht/liste'
import type { TpSchwerpunkt } from '@/types'

import { useKlassen } from './useKlassen'

/** Höchstens drei Bereiche je Kasten, danach „+n weitere". */
const SICHTBAR = 3

/** Der Kasten „Hier üben wir": höchstens drei Bereiche, beim Thema die Startstelle zuerst. */
function Kasten({ s }: { s: TpSchwerpunkt }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  const labels = s.start ? [s.start, ...s.uebung.filter((l) => l !== s.start)] : s.uebung
  const rest = labels.length - SICHTBAR
  return (
    <div className="tp-s4-kasten tp-s4-kasten-ueben">
      <small>{t('s4.ueben')}</small>
      <ul>
        {labels.slice(0, SICHTBAR).map((l) => (
          <li key={l}>{l}</li>
        ))}
        {rest > 0 && <li className="tp-s4-weitere">{tb('s1.blick.weitere', { count: rest })}</li>}
      </ul>
    </div>
  )
}

/**
 * Die Karte „Förderfokus" zum gewählten Punkt (Entscheidung 9, PS-1
 * Entscheidung 17): Pille mit der Klassenangabe, Schild am Thema, Titel =
 * Themenfeld und nur der Kasten „Hier üben wir"; „Sicher im Test" steht im
 * Druckbogen. Im Querformat rechts neben der Kurve, im Hochformat darunter.
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
        <Kasten s={s} />
      </div>
    </div>
  )
}
