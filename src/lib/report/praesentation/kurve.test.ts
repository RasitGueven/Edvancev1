import { describe, expect, it } from 'vitest'

import {
  KURVE_PFAD,
  KURVE_PFEIL,
  KURVE_START,
  kurvenPunkte,
} from '@/lib/report/praesentation/kurve'

// Mit dem Skript des Dummys V7 (dummy-v7.html, STOPS) nachgerechnet, in % der viewBox.
const DUMMY: readonly [number, number][] = [
  [33.44, 79.832],
  [54.32, 61.611],
  [68.753, 37.019],
  [83.32, 16.834],
]

describe('Kurve in der Form des Logos', () => {
  it('Pfad, Startpunkt und Pfeil wie im Dummy', () => {
    expect(KURVE_PFAD).toBe('M30 180 C128 320 196 282 272 182 C348 82 386 46 430 32')
    expect(KURVE_START).toEqual([30, 180])
    expect(KURVE_PFEIL).toBe('M405 32 L430 32 L422 57')
  })

  it('n = 4 deckt sich mit den Punkten des Dummys (±0,2 Prozentpunkte)', () => {
    const punkte = kurvenPunkte(4)
    expect(punkte.map((p) => p.anteil)).toEqual([0.3, 0.52, 0.72, 0.9])
    punkte.forEach((p, i) => {
      expect(Math.abs(p.x - DUMMY[i][0])).toBeLessThanOrEqual(0.2)
      expect(Math.abs(p.y - DUMMY[i][1])).toBeLessThanOrEqual(0.2)
    })
  })

  it('Seiten und Lagen nach der Tabelle in Entscheidung 9', () => {
    const tabelle = (n: number) => kurvenPunkte(n).map((p) => [p.anteil, p.seite])
    expect(tabelle(4)).toEqual([[0.3, 'unten'], [0.52, 'links'], [0.72, 'linksOben'], [0.9, 'linksOben']])
    expect(tabelle(3)).toEqual([[0.3, 'unten'], [0.6, 'links'], [0.9, 'linksOben']])
    expect(tabelle(2)).toEqual([[0.3, 'unten'], [0.85, 'linksOben']])
    expect(tabelle(1)).toEqual([[0.3, 'unten']])
  })

  it('n = 0 ist leer', () => {
    expect(kurvenPunkte(0)).toEqual([])
  })

  it('Punkte liegen in Laufrichtung: nach rechts und nach oben (ab dem Tiefpunkt)', () => {
    for (const n of [2, 3, 4]) {
      const punkte = kurvenPunkte(n)
      for (let i = 1; i < punkte.length; i++) {
        expect(punkte[i].x, `n=${n}`).toBeGreaterThan(punkte[i - 1].x)
        expect(punkte[i].y, `n=${n}`).toBeLessThan(punkte[i - 1].y)
      }
    }
  })

  it('alle Punkte liegen in der viewBox', () => {
    for (const n of [1, 2, 3, 4]) {
      for (const p of kurvenPunkte(n)) {
        expect(p.x).toBeGreaterThan(0)
        expect(p.x).toBeLessThan(100)
        expect(p.y).toBeGreaterThan(0)
        expect(p.y).toBeLessThan(100)
      }
    }
  })
})
