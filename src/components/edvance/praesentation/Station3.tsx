import { useTranslation } from 'react-i18next'

import { legendeFuer, useLernwegTexte } from '@/components/edvance/elternbericht/lernwegTexte'
import type { Lernweg } from '@/types'

import { Kicker } from './Kicker'
import { LernwegBuehne } from './LernwegBuehne'
import type { StationProps } from './stationProps'
import { useLernwegFahrt } from './useLernwegFahrt'

/**
 * Station 03 · Lernweg (R7-9, Entscheidung 19): derselbe Lernweg wie Seite 3
 * des Berichts (p.lernweg), als waagrechte Bühne, die sich beim ersten
 * Betreten Bereich für Bereich aufbaut. Kopf und Legende wie im Prototyp
 * Version 7; die Legende mit denselben Texten wie der Druck.
 */
export function Station3({ p }: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  return (
    <div className="tp-szene tp-s3">
      <Kicker nummer={3}>{t('s3.kicker')}</Kicker>
      <div className="tp-s3-kopfzeile">
        <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
          {tb('s3.titel')}
        </h2>
      </div>
      {p.lernweg && <Weg lw={p.lernweg} />}
    </div>
  )
}

function Weg({ lw }: { lw: Lernweg }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const tx = useLernwegTexte(lw)
  const f = useLernwegFahrt(lw)
  const quelle =
    lw.quelle === 'klp'
      ? t('s3.weg.quelle.klp')
      : lw.schulname
        ? t('s3.weg.quelle.schule', { schulname: lw.schulname })
        : t('s3.weg.quelle.schuleOhneName')
  return (
    <>
      <div className="tp-s3-unterkopf tp-reveal">
        <p className="tp-desc">{t('s3.weg.desc', { quelle })}</p>
        <button
          type="button"
          className="tp-s3-abspielen"
          aria-label={t('s3.weg.abspielenAria')}
          data-testid="tp-s3-abspielen"
          onClick={f.abspielen}
        >
          <svg viewBox="0 0 14 14" aria-hidden="true" focusable="false">
            <path d="M3 2 L12 7 L3 12 Z" />
          </svg>
          {t('s3.weg.abspielen')}
        </button>
      </div>
      <ul className="tp-s3-legende tp-reveal" data-testid="tp-s3-legende">
        {legendeFuer(lw, true).map((a) => (
          <li key={a} className={`tp-s3-leg tp-s3-leg-${a}`} data-legende={a}>
            {a === 'unter' && (
              <span className="tp-s3-pfeil" aria-hidden="true">
                ↳
              </span>
            )}
            {tx.legende(a)}
          </li>
        ))}
      </ul>
      <LernwegBuehne lw={lw} f={f} />
    </>
  )
}
