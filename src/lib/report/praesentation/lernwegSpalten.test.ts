import { describe, expect, it } from 'vitest'

import { packeSpalten } from '@/lib/report/praesentation/lernwegSpalten'

// Platz wie in der Präsentation: Spur 510, oben 40 für das Schild, Kopf der Zone
// und Abstände abgezogen; Lücke 16 zwischen zwei Inseln (Nachbesserung R7-9, Entscheidung 2).
const PLATZ = 380
const LUECKE = 16

describe('packeSpalten', () => {
  it('eine Insel: eine Spalte', () => {
    expect(packeSpalten([200], PLATZ, LUECKE)).toEqual({ spalten: [[0]], hoehe: 200, zuHoch: false })
  })

  it('drei Inseln: so viele Spalten wie nötig, keine höher als der Platz', () => {
    const p = packeSpalten([180, 150, 140], PLATZ, LUECKE)
    expect(p.spalten).toEqual([[0, 1], [2]])
    expect(p.hoehe).toBeLessThanOrEqual(PLATZ)
  })

  it('fünf Inseln: Reihenfolge bleibt, Spalte für Spalte', () => {
    const p = packeSpalten([120, 90, 200, 60, 160], PLATZ, LUECKE)
    expect(p.spalten.flat()).toEqual([0, 1, 2, 3, 4])
    expect(p.spalten).toEqual([[0, 1], [2, 3], [4]])
    for (const sp of p.spalten) {
      const h = sp.reduce((n, i, k) => n + [120, 90, 200, 60, 160][i] + (k ? LUECKE : 0), 0)
      expect(h).toBeLessThanOrEqual(PLATZ)
    }
    // Die Spur bleibt bei höchstens 510: Platz + oben + Kopf.
    expect(p.hoehe + 130).toBeLessThanOrEqual(510)
  })

  it('kleine Inseln passen in eine Spalte', () => {
    expect(packeSpalten([60, 60, 60, 60, 60], PLATZ, LUECKE).spalten).toEqual([[0, 1, 2, 3, 4]])
  })

  it('eine Insel höher als der Platz steht allein und meldet die Ausnahme', () => {
    const p = packeSpalten([100, 420, 80], PLATZ, LUECKE)
    expect(p.spalten).toEqual([[0], [1], [2]])
    expect(p.zuHoch).toBe(true)
  })
})
