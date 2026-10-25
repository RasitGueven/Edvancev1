// Feste Props aller vier Stationen der Tablet-Präsentation (T2, Entscheidung 7).
//
// T3 (Station 01, 02) und T4 (03, 04) bauen ihre Stationen gegen genau diese
// Props. Der Rahmen (Praesentation.tsx) reicht sie durch; die Zustände der
// Bewegung (entered, motion-complete) hängen als Klassen an der <section>, die
// der Rahmen um jede Station legt.

import type { Bausteinsatz } from '@/lib/report/bausteine'
import type { PraesentationDaten, TpAnzeige } from '@/types'

import type { PraesentationV4 } from './v4Daten'

export type StationProps = {
  p: PraesentationDaten
  /** Zählweise „übersprungen" — aus UEBERSPRUNGEN_ANZEIGE, als Prop für Tests. */
  anzeige: TpAnzeige
  satz: Bausteinsatz
  sessionId: string
  /** Klassenarbeiten als roter Faden (V4); fehlt ohne Fahrplan, dann gilt die Zuordnung vor V4. */
  v4?: PraesentationV4 | null
}

/** Die vier Stationen, 1 … 4. */
export const STATIONEN = [1, 2, 3, 4] as const
export type StationNummer = (typeof STATIONEN)[number]

/** „01", „02" … — zweistellig über Intl, nie per Hand. */
export function stationsNummer(n: number, sprache: string): string {
  return new Intl.NumberFormat(sprache, { minimumIntegerDigits: 2 }).format(n)
}

/** Name einer Station in Leiste, Kopf und Vorlesetext: mit Fahrplan „Klassenarbeiten“ statt „Lernweg“. */
export const stationsName = (t: (key: string) => string, n: number, v4: boolean): string =>
  t(v4 ? `v4.leiste.${n}` : `leiste.station.${n}`)
