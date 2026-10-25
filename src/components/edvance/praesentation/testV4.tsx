// Nur für Tests der Stationen nach V4: eine Station mit Fahrplan allein rendern.
import { render } from '@testing-library/react'
import type { ComponentType } from 'react'

import { Bausteinsatz } from '@/lib/report/bausteine'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { bauePraesentation } from '@/lib/report/praesentation/praesentation'
import type { ReportNotes, TpAnzeige } from '@/types'

import type { StationProps } from './stationProps'
import { baueV4, type PraesentationV4 } from './v4Daten'

export function datenV4(
  fall: string,
  notes?: Partial<ReportNotes>,
): { props: StationProps; v4: PraesentationV4 } {
  const f = PRAESENTATION_FAELLE[fall]
  const n = f.notes ? { ...f.notes, ...notes } : null
  const p = bauePraesentation({ data: f.data, notes: n, tiers: f.tiers })
  if ('fehlt' in p) throw new Error(`fixture ${fall} has no presentation data`)
  const v4 = baueV4(f.data, n)
  if (!v4) throw new Error(`fixture ${fall} has no fahrplan`)
  return {
    v4,
    props: { p, anzeige: 'kombiniert' as TpAnzeige, satz: new Bausteinsatz(f.data.erzaehlung.bausteine), sessionId: f.data.sessionId, v4 },
  }
}

export function zeigeV4(
  Station: ComponentType<StationProps>,
  fall: string,
  notes?: Partial<ReportNotes>,
): ReturnType<typeof render> & { v4: PraesentationV4 } {
  const { props, v4 } = datenV4(fall, notes)
  const r = render(
    <section className="tp-station entered">
      <Station {...props} />
    </section>,
  )
  return { ...r, v4 }
}
