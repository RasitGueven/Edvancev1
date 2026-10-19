import { useTranslation } from 'react-i18next'

import { Kicker } from './Kicker'
import type { StationProps } from './stationProps'

/** Station 03. Hülle aus T2: Kicker und Titel aus Anhang A. Den Inhalt baut T4. */
export function Station3(_props: StationProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  return (
    <div className="tp-szene tp-s3">
      <Kicker nummer={3}>{t('s3.kicker')}</Kicker>
      <h2 className="tp-titel tp-reveal" data-tp-pflicht="">
        {t('s3.titel')}
      </h2>
    </div>
  )
}
