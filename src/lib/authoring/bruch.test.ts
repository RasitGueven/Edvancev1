import { describe, expect, it } from 'vitest'
import { eingabeFormat, formatVorschlag } from './bruch'

describe('formatVorschlag', () => {
  it('nur Brueche → Bruch', () => {
    expect(formatVorschlag(['3/4', '-6/8'])).toBe('fraction')
  })
  it('nur Zahlen → Zahl (auch „+“, „−“, Tausender)', () => {
    expect(formatVorschlag(['12', '12,5', '+12', '−12'])).toBe('number')
    expect(formatVorschlag(['500000', '500 000'])).toBe('number')
  })
  it('gemischt → kein Hinweis', () => {
    expect(formatVorschlag(['3/4', '0,75'])).toBeNull()
  })
  it('die Regel ist woertlich: „+1/3“ ist kein Bruch', () => {
    expect(formatVorschlag(['1/3', '+1/3'])).toBeNull()
    expect(formatVorschlag(['+1/3'])).toBeNull()
  })
  it('Textloesungen → kein Hinweis', () => {
    expect(formatVorschlag(['x = 9'])).toBeNull()
    expect(formatVorschlag(['A UND B'])).toBeNull()
  })
  it('Einheit nur, wenn das Feld sie zeigt', () => {
    expect(formatVorschlag(['12', '12 cm', '12cm'], 'cm')).toBe('number')
    expect(formatVorschlag(['6', '6 €'])).toBeNull()
    expect(formatVorschlag(['6', '6 m'], 'cm')).toBeNull()
  })
  it('leer → kein Hinweis', () => {
    expect(formatVorschlag([])).toBeNull()
  })
})

describe('eingabeFormat', () => {
  it('die Angabe gilt vor dem Vorschlag', () => {
    expect(eingabeFormat(false, ['3/4'])).toBe('number')
    expect(eingabeFormat(true, ['0,75'])).toBe('fraction')
  })
  it('ohne Angabe der Vorschlag', () => {
    expect(eingabeFormat(null, ['3/4'])).toBe('fraction')
    expect(eingabeFormat(undefined, ['7'])).toBe('number')
    expect(eingabeFormat(null, ['3/4', '0,75'])).toBeNull()
  })
  it('Term bleibt Term', () => {
    expect(eingabeFormat(true, ['3/4'], null, true)).toBe('term')
  })
})
