import { useTranslation } from 'react-i18next'

import { anzeigeZahlen } from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, TpAnzeige } from '@/types'

/**
 * Die vier Eckdaten über dem Kompetenzprofil (V4, Station 02): Aufgaben,
 * Bereiche, sicher, Übungsbedarf. Sie beschreiben genau diese Station. Die
 * Zahlen sind dieselben wie in „Auf einen Blick“ (Zählweise wie das Profil).
 */
export function Eckdaten({
  aufgaben,
  p,
  anzeige,
}: {
  aufgaben: number
  p: PraesentationDaten
  anzeige: TpAnzeige
}): JSX.Element {
  const { t } = useTranslation('praesentation')
  const zahlen = anzeigeZahlen(p.zahlen, anzeige)
  const daten = [
    { art: 'aufgaben', wert: aufgaben },
    { art: 'bereiche', wert: p.zahlen.untersucht },
    { art: 'sicher', wert: zahlen.sicher },
    { art: 'uebung', wert: zahlen.uebung },
  ]
  return (
    <div className="tp-s2v-eck tp-reveal" data-testid="tp-s2-eckdaten">
      {daten.map((d) => (
        <div key={d.art} className={`tp-s2v-eck-${d.art}`} data-testid={`tp-s2-eck-${d.art}`}>
          <strong>{d.wert}</strong>
          <span>{t(`v4.s1.eckdaten.${d.art}`)}</span>
        </div>
      ))}
    </div>
  )
}
