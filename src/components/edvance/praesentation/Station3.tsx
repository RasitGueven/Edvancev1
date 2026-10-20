import { useTranslation } from 'react-i18next'

import { Kicker } from './Kicker'
import { Pyramide } from './Pyramide'
import type { StationProps } from './stationProps'

/**
 * Station 03 · Einordnung (Entscheidung 8): die untersuchten Bereiche als
 * Pyramide nach Lehrplanstufe, daneben (im Hochformat darunter) die Lesehilfe.
 * Kein Satz sagt, dass eine Ebene auf einer anderen aufbaut.
 */
export function Station3({ p, anzeige }: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const { t: tb } = useTranslation('elternbericht')
  return (
    <div className="tp-szene tp-s3">
      <Kicker nummer={3}>{t('s3.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {t('s3.titel')}
      </h2>
      <p className="tp-desc tp-reveal">{t('s3.desc')}</p>
      <div className="tp-s3-layout tp-reveal">
        <Pyramide ebenen={p.pyramide} anzeige={anzeige} />
        <aside className="tp-s3-lesen">
          <span className="tp-etikett">{t('s3.lesen.label')}</span>
          <h3>{t('s3.lesen.titel')}</h3>
          <p>{p.wessen ? t('s3.lesen.text', { wessen: p.wessen }) : t('s3.lesen.textOhneName')}</p>
          <p className="tp-s3-hinweis">{tb('s3.lesen.hinweisEineEbene')}</p>
        </aside>
      </div>
    </div>
  )
}
