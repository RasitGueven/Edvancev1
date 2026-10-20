import { Fragment } from 'react'
import { useTranslation } from 'react-i18next'

import { anzeigeZahlen, type TpAnteile } from '@/lib/report/praesentation/praesentation'
import type { TpAnzeige } from '@/types'

/**
 * Die kleine Zählung unter „x von y": „2 sicher · 3 Übungsbedarf" und, je
 * Zählweise, „davon 1 übersprungen" bzw. „1 übersprungen". Nur Teile, die
 * nicht null sind. Umbruch nur zwischen den Teilen, der Punkt bleibt am Teil davor.
 */
export function Zaehlung({ anteile, anzeige }: { anteile: TpAnteile; anzeige: TpAnzeige }): JSX.Element {
  const { t } = useTranslation('praesentation')
  const z = anzeigeZahlen(anteile, anzeige)
  const teile: { key: string; text: string }[] = []
  if (z.sicher > 0) teile.push({ key: 'sicher', text: t('zaehlung.sicher', { count: z.sicher }) })
  if (z.uebung > 0) teile.push({ key: 'uebung', text: t('zaehlung.uebung', { count: z.uebung }) })
  if (z.dritte)
    teile.push({
      key: 'dritte',
      text: t(z.dritte.art === 'davon' ? 'zaehlung.davonUebersprungen' : 'zaehlung.uebersprungen', {
        count: z.dritte.wert,
      }),
    })
  return (
    <span className="tp-s2-zaehlung">
      {teile.map((teil, i) => (
        <Fragment key={teil.key}>
          {i > 0 && ' '}
          <span>{teil.text}</span>
        </Fragment>
      ))}
    </span>
  )
}
