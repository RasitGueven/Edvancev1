import type { ComponentType } from 'react'

import { Endkarte } from './Endkarte'
import { Merksatz } from './Merksatz'
import { Raster } from './Raster'
import { TermZeile } from './TermZeile'
import { Titelkarte } from './Titelkarte'
import type { BausteinProps } from './typen'

/** Remotion-Komponente je Baustein-Name (Namen und Parameter: src/studio/skript/bausteine.ts). */
export const BAUSTEIN_KOMPONENTEN: Record<string, ComponentType<BausteinProps>> = {
  titelkarte: Titelkarte,
  raster: Raster,
  term_zeile: TermZeile,
  merksatz: Merksatz,
  endkarte: Endkarte,
}
