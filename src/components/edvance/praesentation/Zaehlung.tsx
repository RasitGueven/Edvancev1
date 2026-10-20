import { Fragment } from 'react'
import { useTranslation } from 'react-i18next'

import { anzeigeZahlen, type TpAnteile } from '@/lib/report/praesentation/praesentation'
import type { TpAnzeige } from '@/types'

type ZaehlungProps = {
  anteile: TpAnteile
  anzeige: TpAnzeige
  /** Klasse der Station (Größe, Lage). */
  className: string
  /** Teile in den Farben der Zustände (Station 03). */
  farbig?: boolean
}

/**
 * Die Zählung je Zeile (02) bzw. Ebene (03): „2 sicher · 3 Übungsbedarf" und je
 * Zählweise „davon 1 übersprungen" bzw. „1 übersprungen". Nur Teile ≠ 0.
 */
export function Zaehlung({ anteile, anzeige, className, farbig = false }: ZaehlungProps): JSX.Element {
  const { t } = useTranslation('praesentation')
  const z = anzeigeZahlen(anteile, anzeige)
  const teile: { art: string; text: string }[] = []
  if (z.sicher > 0) teile.push({ art: 'sicher', text: t('zaehlung.sicher', { count: z.sicher }) })
  if (z.uebung > 0) teile.push({ art: 'uebung', text: t('zaehlung.uebung', { count: z.uebung }) })
  if (z.dritte)
    teile.push({
      art: z.dritte.art,
      text: t(z.dritte.art === 'davon' ? 'zaehlung.davonUebersprungen' : 'zaehlung.uebersprungen', {
        count: z.dritte.wert,
      }),
    })
  return (
    <span className={`tp-zaehlung ${className}${farbig ? ' tp-zaehlung-farbig' : ''}`}>
      {teile.map((teil, i) => (
        <Fragment key={teil.art}>
          {i > 0 && ' '}
          <span className={`tp-zaehlung-${teil.art}`}>{teil.text}</span>
        </Fragment>
      ))}
    </span>
  )
}
