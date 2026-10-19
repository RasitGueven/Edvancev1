import { useTranslation } from 'react-i18next'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'

/** Station 02. Hülle aus T2: Kicker und Titel aus Anhang A. Den Inhalt baut T3. */
export function Station2(_props: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  return (
    <div className="tp-szene tp-s2">
      <Kicker nummer={2}>{t('s2.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {t('s2.titel')}
      </h2>
    </div>
  )
}
