// Pfadrechnung der Kurve auf Seite 4 (Maßblatt E7, Teil 1 „Seite 4“).
import { describe, expect, it } from 'vitest'

import { kurvenPfade } from './kurve'

// Knoten des Musters: Titel-Grundlinien 380,2 / 459,8 / 539,2 / 618,8 − 3,4.
const MUSTER = [376.8, 456.4, 535.8, 615.4]
// Lernziel-Kasten bei y 695: Mitte der Kicker-Zeile 695 + 16,3.
const ZIEL = 711.3

/** Alle Zahlen eines d-Attributs, paarweise als Punkte. */
function punkte(d: string): [number, number][] {
  const z = d.match(/-?\d+(\.\d+)?/g)!.map(Number)
  return Array.from({ length: z.length / 2 }, (_, i) => [z[2 * i], z[2 * i + 1]])
}

describe('kurvenPfade', () => {
  it('ohne Knoten: nichts', () => {
    expect(kurvenPfade([], ZIEL)).toEqual({ pfad: null, auslauf: null, spitze: null })
  })

  it('ein Knoten ohne Lernziel: weder Kurve noch Auslauf', () => {
    expect(kurvenPfade([376.8], null)).toEqual({ pfad: null, auslauf: null, spitze: null })
  })

  it('ein Knoten mit Lernziel: nur der Auslauf mit Spitze', () => {
    const k = kurvenPfade([376.8], ZIEL)
    expect(k.pfad).toBeNull()
    expect(k.auslauf).toBe('M 61 376.8 C 46 560.78 59 718.3 84.5 711.3')
    expect(k.spitze).not.toBeNull()
  })

  it('zwei Knoten: ein Stück, nach rechts ausschwingend', () => {
    const k = kurvenPfade(MUSTER.slice(0, 2), null)
    expect(k.pfad).toBe('M 61 376.8 C 73 396.7 73 436.5 61 456.4')
    expect(k.auslauf).toBeNull()
    expect(k.spitze).toBeNull()
  })

  it('drei Knoten: rechts, dann links', () => {
    const p = punkte(kurvenPfade(MUSTER.slice(0, 3), null).pfad!)
    expect(p).toHaveLength(7)
    expect(p[1][0]).toBe(73)
    expect(p[4][0]).toBe(49)
    expect(p[6]).toEqual([61, 535.8])
  })

  it('vier Knoten mit Lernziel: Kurve des Musters', () => {
    const k = kurvenPfade(MUSTER, ZIEL)
    const p = punkte(k.pfad!)
    expect(p).toHaveLength(10)
    // Stücke enden je in der nächsten Knotenmitte.
    expect([p[3], p[6], p[9]]).toEqual([
      [61, 456.4],
      [61, 535.8],
      [61, 615.4],
    ])
    expect([p[1][0], p[4][0], p[7][0]]).toEqual([73, 49, 73])
    expect(k.auslauf).toBe('M 61 615.4 C 46 668.15 59 718.3 84.5 711.3')
  })

  it('vier Knoten ohne Lernziel: endet am letzten Knoten, ohne Spitze', () => {
    const k = kurvenPfade(MUSTER, null)
    expect(punkte(k.pfad!).at(-1)).toEqual([61, 615.4])
    expect(k.auslauf).toBeNull()
    expect(k.spitze).toBeNull()
  })

  it('die Spitze zeigt in Richtung vom Kontrollpunkt (59 | yk + 7) zum Ziel', () => {
    const [a1, spitze, a2] = punkte(kurvenPfade(MUSTER, ZIEL).spitze!)
    expect(spitze).toEqual([84.5, ZIEL])
    // Beide Arme liegen hinter der Spitze und sind 7,2 lang.
    for (const a of [a1, a2]) {
      expect(a[0]).toBeLessThan(84.5)
      expect(Math.hypot(a[0] - 84.5, a[1] - ZIEL)).toBeCloseTo(7.2, 1)
    }
    // Die Winkelhalbierende der Arme zeigt zurück zum Kontrollpunkt.
    const halbierende = Math.atan2((a1[1] + a2[1]) / 2 - ZIEL, (a1[0] + a2[0]) / 2 - 84.5)
    expect(halbierende).toBeCloseTo(Math.atan2(7, 59 - 84.5), 2)
    // Wie im Muster: Arme bei x 77,7 und y 708,9 … 716,8.
    expect(Math.min(a1[0], a2[0])).toBeCloseTo(77.7, 1)
    expect(Math.min(a1[1], a2[1])).toBeCloseTo(708.95, 1)
    expect(Math.max(a1[1], a2[1])).toBeCloseTo(716.8, 1)
  })
})
