import type { RefObject } from 'react'
import { useTranslation } from 'react-i18next'

import { Logo } from './Logo'

/**
 * Intro (Entscheidung 5): Logo gleitet ein, dann Kicker, Name, Unterzeile und
 * „Gemeinsam ansehen" — Ablauf und Zeiten wie im Dummy (intro.css). Wischen
 * geht jederzeit. Einmal je Öffnen: hat es den Fluss verlassen, bleibt es weg.
 */
export function Intro({
  name,
  fach,
  weg,
  introRef,
  onLos,
}: {
  name: string | null
  fach: string
  weg: boolean
  introRef: RefObject<HTMLElement>
  onLos: () => void
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')

  return (
    <section ref={introRef} className="tp-intro" aria-label={t('intro.aria')} hidden={weg}>
      <div className="tp-intro-innen">
        <div className="tp-intro-logo" aria-hidden="true">
          <Logo gross />
        </div>
        <p className="tp-intro-kicker">{t('intro.kicker', { fach })}</p>
        <h1 className="tp-intro-name">{name ?? tb('kind')}</h1>
        <p className="tp-intro-unterzeile">{t('intro.unterzeile')}</p>
      </div>
      <button type="button" className="tp-intro-los" onClick={onLos}>
        <span>{t('intro.los')}</span>
        <span className="tp-intro-pfeil" aria-hidden="true">
          ↓
        </span>
      </button>
    </section>
  )
}
