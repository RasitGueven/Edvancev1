// Nur für Tests: eine Station der Präsentation allein rendern, mit den Daten
// eines Falls aus PRAESENTATION_FAELLE — ohne Rahmen, Intro und Bewegung.
import { render } from '@testing-library/react'
import type { ComponentType } from 'react'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { bauePraesentation } from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, ReportData, TpAnzeige } from '@/types'

import type { StationProps } from './stationProps'

export function datenAus(fall: string, data?: ReportData): PraesentationDaten {
  const f = PRAESENTATION_FAELLE[fall]
  const p = bauePraesentation({ data: data ?? f.data, notes: f.notes, tiers: f.tiers })
  if ('fehlt' in p) throw new Error(`fixture ${fall} has no presentation data`)
  return p
}

export function zeigeStation(
  Station: ComponentType<StationProps>,
  fall: string,
  { anzeige = 'kombiniert', data }: { anzeige?: TpAnzeige; data?: ReportData } = {},
): ReturnType<typeof render> {
  const d = data ?? PRAESENTATION_FAELLE[fall].data
  return render(
    <section className="tp-station entered">
      <Station
        p={datenAus(fall, d)}
        anzeige={anzeige}
        satz={new Bausteinsatz(d.erzaehlung.bausteine)}
        sessionId={d.sessionId}
      />
    </section>,
  )
}
