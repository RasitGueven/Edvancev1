import { useTranslation } from 'react-i18next'

import { Lesehilfe } from './Lesehilfe'
import { Pyramide } from './Pyramide'
import type { SeitenProps } from './seitenProps'

/** Das lange Intro beschreibt genau diese drei Ebenen (unten, darüber, oben). */
const DREI_EBENEN = ['aktuell', 'weiterfuehrend', 'grundlagen'].join()

/**
 * Seite 3 des Eltern-Berichts R7: Einordnung als Pyramide (Maßblatt E7, „Seite 3“).
 *
 * Im Fluss: Kicker, Titel, Intro, Zwischenzeile mit Legende, die Pyramide nach
 * Lehrplanstufe und die Lesehilfe. Styles in src/styles/elternbericht/seite3.css.
 */
export function Seite3({ bericht, name, wessen }: SeitenProps): JSX.Element {
  const { t } = useTranslation('elternbericht')
  const { pyramide, zaehlung } = bericht
  const ebenen = pyramide.map((e) => e.ebene).join()

  return (
    <div className="eb-s3">
      <p className="eb-kicker eb-s3-kicker">{t('s3.kicker')}</p>
      <h1 className="eb-titel eb-s3-titel">
        {t(zaehlung.sicher > 0 ? 's3.titel' : 's3.titelOhneSicher')}
      </h1>
      <p className="eb-s3-intro">{t(ebenen === DREI_EBENEN ? 's3.intro' : 's3.introKurz')}</p>

      <div className="eb-s3-zwischen">
        <h2 className="eb-s3-zwischenzeile">{t('s3.zwischenzeile')}</h2>
        <ul className="eb-s3-legende">
          <li className="eb-s3-legende-sicher">{t('s3.legende.sicher')}</li>
          <li className="eb-s3-legende-uebung">{t('s3.legende.uebung')}</li>
        </ul>
      </div>

      <Pyramide ebenen={pyramide} />
      <Lesehilfe ebenen={pyramide} name={name} wessen={wessen} />
    </div>
  )
}
