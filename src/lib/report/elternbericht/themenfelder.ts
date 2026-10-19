// Eltern-Bericht R7 — die acht Themenfelder (Entscheidung 5).
//
// Eine Gliederung für Seite 2, 3 und 4, gebildet aus den Inhaltsbereichen in
// src/lib/report/inhaltsbereiche.ts. Die sechs Familien aus R5 (familien.ts)
// bleiben für R6. Anzeige über elternbericht:feld.<key>, nie der Schlüssel.

import { inhaltsbereich, type Inhaltsbereich } from '@/lib/report/inhaltsbereiche'
import type { ThemenfeldKey } from '@/types'

export type Themenfeld = {
  key: ThemenfeldKey
  bereiche: readonly Inhaltsbereich[]
}

/** Reihenfolge wie im Bauauftrag. `weitere` erscheint nur, falls belegt. */
export const THEMENFELDER: readonly Themenfeld[] = [
  { key: 'brueche', bereiche: ['brueche', 'dezimalzahlen'] },
  { key: 'prozent', bereiche: ['prozent', 'zuordnungen'] },
  { key: 'terme', bereiche: ['terme', 'gleichungen'] },
  { key: 'geometrie', bereiche: ['geometrie'] },
  { key: 'groessen', bereiche: ['groessen'] },
  { key: 'zahlen', bereiche: ['zahlen', 'negative_zahlen', 'potenzen', 'wurzeln'] },
  { key: 'funktionen', bereiche: ['funktionen'] },
  { key: 'zufall', bereiche: ['stochastik'] },
  { key: 'weitere', bereiche: ['weitere'] },
]

const FELD_VON_BEREICH = new Map<Inhaltsbereich, ThemenfeldKey>(
  THEMENFELDER.flatMap((f) => f.bereiche.map((b) => [b, f.key] as const)),
)

const POSITION = new Map<ThemenfeldKey, number>(THEMENFELDER.map((f, i) => [f.key, i]))

/** Das Themenfeld eines Skills. Unbekanntes fällt auf `weitere`. */
export function feldVon(skillKey: string): ThemenfeldKey {
  return FELD_VON_BEREICH.get(inhaltsbereich(skillKey)) ?? 'weitere'
}

/** Position eines Felds in THEMENFELDER — zum Sortieren. */
export function feldPosition(feld: ThemenfeldKey): number {
  return POSITION.get(feld) ?? THEMENFELDER.length
}
