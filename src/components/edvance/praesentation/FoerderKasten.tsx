import { useTranslation } from 'react-i18next'

import type { FoerderPunkt } from './foerderPunkte'

/** Höchstens so viele Bereiche je Spalte, danach „+n weitere“. */
const JE_SPALTE = 4

function Spalte({
  art,
  titel,
  liste,
  rest,
}: {
  art: 'sitzt' | 'angehen'
  titel: string
  liste: string[]
  rest: number
}): JSX.Element {
  const { t: tb } = useTranslation('elternbericht')
  const zeigen = liste.slice(0, JE_SPALTE)
  const weitere = liste.length - zeigen.length + rest
  return (
    <div className={`tp-s4v-spalte tp-s4v-spalte-${art}`} data-testid={`tp-s4v-${art}`}>
      <h4>{titel}</h4>
      <ul>
        {zeigen.map((l) => (
          <li key={l}>{l}</li>
        ))}
        {weitere > 0 && <li className="tp-s4v-weitere">{tb('s1.blick.weitere', { count: weitere })}</li>}
      </ul>
    </div>
  )
}

/**
 * Der feste Kasten rechts neben der Kurve (V4, Station 04): bleibt immer an
 * derselben Stelle und in derselben Größe (Höhe aus dem CSS, nicht aus dem
 * Inhalt); beim Antippen eines Punkts wechselt nur sein Inhalt. Unten
 * „zurück“, „n / m“ und „weiter“, jeweils mindestens 44 px hoch.
 */
export function FoerderKasten({
  punkt,
  index,
  gesamt,
  id,
  tabId,
  onWechsel,
}: {
  punkt: FoerderPunkt
  index: number
  gesamt: number
  id: string
  tabId: string
  onWechsel: (schritt: number) => void
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const sorgfalt = punkt.art === 'sorgfalt'
  return (
    <div
      className="tp-s4v-kasten"
      role="tabpanel"
      id={id}
      aria-labelledby={tabId}
      aria-live="polite"
      tabIndex={0}
      data-testid="tp-s4v-kasten"
      data-tp-beschriftung=""
    >
      {/* key: beim Wechsel blendet der Inhalt neu ein, der Kasten selbst bleibt stehen. */}
      <div key={punkt.key} className="tp-s4v-inhalt" data-testid="tp-s4v-inhalt">
        <div className="tp-s4v-kopf">
          <span className="tp-etikett">{t('v4.s4.fokusVon', { n: index + 1, m: gesamt })}</span>
          <span className={sorgfalt ? 'tp-s4v-pille tp-s4v-pille-sorgfalt' : 'tp-s4v-pille'}>{punkt.pille}</span>
        </div>
        <h3>{punkt.titel}</h3>
        {/* Ein bestätigtes Ziel sagt dasselbe wie der Grund, nur als Ziel — dann steht es an seiner Stelle (Platz im festen
            Kasten). Bei Sorgfalt ist der Text der Inhalt selbst (keine Spalten) und bleibt. */}
        {punkt.grund && (sorgfalt || !punkt.ziel) && <p className="tp-s4v-grund">{punkt.grund}</p>}
        {!sorgfalt && (
          <div className="tp-s4v-spalten">
            {punkt.sitzt.length > 0 && (
              <Spalte art="sitzt" titel={t('v4.s4.sitzt')} liste={punkt.sitzt} rest={0} />
            )}
            <Spalte art="angehen" titel={t('v4.s4.angehen')} liste={punkt.angehen} rest={punkt.rest} />
          </div>
        )}
        {punkt.ziel && (
          <p className="tp-s4v-ziel" data-testid="tp-s4v-ziel">
            {t('v4.s4.ziel', { ziel: punkt.ziel })}
          </p>
        )}
      </div>
      <div className="tp-s4v-bedienung">
        <button type="button" className="tp-s4v-knopf" disabled={index === 0} title={t('v4.s4.zurueck')} onClick={() => onWechsel(-1)}>
          {t('v4.s4.zurueck')}
        </button>
        <span>
          {index + 1} / {gesamt}
        </span>
        <button
          type="button"
          className="tp-s4v-knopf"
          disabled={index === gesamt - 1}
          title={t('v4.s4.weiter')}
          onClick={() => onWechsel(1)}
        >
          {t('v4.s4.weiter')}
        </button>
      </div>
    </div>
  )
}
