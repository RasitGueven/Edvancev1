import { describe, expect, it } from 'vitest'
import { abbildung, mischen, nullstellen, parabelY, scheitel, schnitt, zahlText } from './parabel'

describe('Parabel-Mathematik (B7)', () => {
  it('Scheitelpunktform', () => {
    expect(parabelY([2, 1, -3], 3)).toBe(5)
    expect(scheitel([2, 1, -3])).toEqual([1, -3])
  })
  it('Nullstellen: zwei, eine, keine', () => {
    expect(nullstellen([1, 0, -9])).toEqual([-3, 3])
    expect(nullstellen([1, 2, 0])).toEqual([2])
    expect(nullstellen([1, 0, 4])).toEqual([])
    expect(nullstellen([-1, 1, 4])).toEqual([-1, 3])
  })
  it('x² = c als Schnitt mit y = c (V5)', () => {
    expect(schnitt([1, 0, 0], 9)).toEqual([-3, 3])
    expect(schnitt([1, 0, 0], 0)).toEqual([0])
    expect(schnitt([1, 0, 0], -4)).toEqual([])
  })
  it('Übergang zwischen zwei Parametersätzen', () => {
    expect(mischen([1, 0, 0], [2, 3, -1], 0.5)).toEqual([1.5, 1.5, -0.5])
    expect(mischen([1, 0, 0], [2, 3, -1], 2)).toEqual([2, 3, -1])
  })
  it('Koordinaten → Pixel (y nach oben)', () => {
    const m = abbildung([-5, 5], [-2, 8], 1000, 1000)
    expect(m.x(0)).toBe(500)
    expect(m.y(-2)).toBe(1000)
    expect(m.y(8)).toBe(0)
  })
  it('Zahlen im Bild', () => {
    expect(zahlText(3)).toBe('3')
    expect(zahlText(-1.5)).toBe('−1,5')
    expect(zahlText(-0.0001)).toBe('0')
  })
})
