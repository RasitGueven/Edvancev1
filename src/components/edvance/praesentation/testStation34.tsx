// Nur für Tests der Stationen 03 und 04: rechnet einen Fall aus
// PRAESENTATION_FAELLE und rendert eine Station ohne Rahmen.
import { render } from '@testing-library/react'
import type { ComponentType } from 'react'

import { Bausteinsatz } from '@/lib/report/bausteine'
import type { ElternberichtFall } from '@/lib/report/elternbericht/fixtures'
import { bauePraesentation } from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, TpAnzeige } from '@/types'

import type { StationProps } from './stationProps'

export function daten(fall: ElternberichtFall): PraesentationDaten {
  const p = bauePraesentation(fall)
  if ('fehlt' in p) throw new Error(`fixture without data: ${p.fehlt}`)
  return p
}

export function zeige(
  Station: ComponentType<StationProps>,
  fall: ElternberichtFall,
  anzeige: TpAnzeige = 'kombiniert',
): ReturnType<typeof render> {
  return render(
    <Station p={daten(fall)} anzeige={anzeige} satz={new Bausteinsatz([])} sessionId={fall.data.sessionId} />,
  )
}
