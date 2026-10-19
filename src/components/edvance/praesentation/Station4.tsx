import { useTranslation } from 'react-i18next'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'

/** Station 04. Hülle aus T2: Kicker und Titel aus Anhang A. Den Inhalt baut T4. */
export function Station4(_props: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  return (
    <div className="tp-szene tp-s4">
      <Kicker nummer={4}>{t('s4.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {t('s4.titel')}
      </h2>
    </div>
  )
}
