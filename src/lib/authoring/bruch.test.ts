import { describe, expect, it } from 'vitest'
import { bruchVorschlag, eingabeFormat } from './bruch'

describe('bruchVorschlag', () => {
  it('nur Brueche → Bruch', () => {
    expect(bruchVorschlag(['3/4', '-6/8'])).toBe(true)
  })
  it('keine Brueche → Zahl', () => {
    expect(bruchVorschlag(['12', '12,5'])).toBe(false)
  })
  it('gemischt → kein Hinweis', () => {
    expect(bruchVorschlag(['3/4', '0,75'])).toBeNull()
  })
  it('die Regel ist woertlich: „+1/3“ ist kein Bruch', () => {
    expect(bruchVorschlag(['1/3', '+1/3'])).toBeNull()
  })
  it('nur Brueche ausserhalb der Regel → kein Hinweis, nicht Zahl', () => {
    expect(bruchVorschlag(['+1/3'])).toBeNull()
    expect(bruchVorschlag(['−3/4'])).toBeNull()
  })
  it('leer → kein Hinweis', () => {
    expect(bruchVorschlag([])).toBeNull()
    expect(bruchVorschlag(['  '])).toBeNull()
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
    expect(eingabeFormat(true, ['3/4'], true)).toBe('term')
  })
})
