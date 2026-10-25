import type { EbBereich, TpZeile } from '@/types'

const bereiche = (z: TpZeile): EbBereich[] => [...z.sicher, ...z.uebung, ...z.uebersprungen]

/** Die kleinste Herkunftsklasse der geprüften Bereiche einer Zeile. */
export const fruehesteKlasse = (z: TpZeile): number => Math.min(...bereiche(z).map((b) => b.klasse))

/** Felder aufsteigend nach der frühesten Klassenstufe; bei Gleichstand bleibt die Reihenfolge des Profils. */
export function nachKlassenstufe(zeilen: readonly TpZeile[]): TpZeile[] {
  return zeilen
    .map((z, i) => ({ z, i, k: fruehesteKlasse(z) }))
    .sort((a, b) => a.k - b.k || a.i - b.i)
    .map(({ z }) => z)
}
