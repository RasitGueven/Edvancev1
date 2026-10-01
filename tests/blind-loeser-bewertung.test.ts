// Das JS-Gegenstück zur Schülerpfad-Bewertung (tools/blind-loeser/bewertung.mjs).
// Die Fälle spiegeln die SQL-Funktionen lsa_normalize_answer, lsa_is_correct und
// lsa_values_equal — wo sie sich eigenwillig verhalten, hält der Test genau das fest.

import { describe, expect, it } from 'vitest'
// @ts-expect-error — reines ESM-Werkzeug ohne Typdeklaration
import { bewerteAufgabe, istRichtig, normalisiere, werteGleich } from '../tools/blind-loeser/bewertung.mjs'

describe('normalisiere (lsa_normalize_answer)', () => {
  it('trimmt, fasst Leerraum zusammen, ersetzt nur das ERSTE Komma, senkt die Schreibung', () => {
    expect(normalisiere('  3,5  ')).toBe('3.5')
    expect(normalisiere('1,2,3')).toBe('1.2,3')
    expect(normalisiere('X  =  4')).toBe('x = 4')
  })
})

describe('istRichtig (lsa_is_correct)', () => {
  it('vergleicht Strings, nicht Zahlen: 0.5 und 1/2 sind verschieden', () => {
    expect(istRichtig('NUMERIC', ['0,5'], '0.5')).toBe(true)
    expect(istRichtig('NUMERIC', ['0,5'], '1/2')).toBe(false)
  })
  it('kennt das Unicode-Minus nur als eigene Variante', () => {
    expect(istRichtig('NUMERIC', ['-3'], '−3')).toBe(false)
    expect(istRichtig('NUMERIC', ['-3', '−3'], '−3')).toBe(true)
  })
  it('MC: Mengengleichheit der Options-IDs', () => {
    expect(istRichtig('MC', ['b'], 'B')).toBe(true)
    expect(istRichtig('MC', ['b'], 'a,b')).toBe(false)
    expect(istRichtig('MC', ['a', 'c'], 'c; a')).toBe(true)
  })
  it('TERM: Leerraum zählt nicht', () => {
    expect(istRichtig('TERM', ['x^2+6x+9'], 'x^2 + 6x + 9')).toBe(true)
  })
})

describe('werteGleich (lsa_values_equal)', () => {
  it('exact vergleicht exakt über Brüche', () => {
    expect(werteGleich('1/2', '0.5', { mode: 'exact' })).toBe(true)
    expect(werteGleich('0.33', '1/3', undefined)).toBe(false)
  })
  it('absolute: |a − b| ≤ value', () => {
    expect(werteGleich('3.334', '3.33', { mode: 'absolute', value: 0.01 })).toBe(true)
    expect(werteGleich('3.35', '3.33', { mode: 'absolute', value: 0.01 })).toBe(false)
  })
  it('decimals: gleich nach Runden (halbe Stelle weg von 0), nicht Abschneiden', () => {
    expect(werteGleich('2.345', '2.35', { mode: 'decimals', value: 2 })).toBe(true)
    expect(werteGleich('2.344', '2.35', { mode: 'decimals', value: 2 })).toBe(false)
  })
})

describe('bewerteAufgabe', () => {
  it('Teilaufgaben je Teil, MC-Teil über Options-ID', () => {
    const task = { input_type: 'MULTI_PART', teilArten: { '1': 'mc', '2': 'short_input' } }
    const loesung = { correct_answers: { '1': ['a'], '2': ['14'] } }
    expect(bewerteAufgabe(task, loesung, [{ part: '1', antwort: 'A' }, { part: '2', antwort: '14' }]).ok).toBe(true)
    const halb = bewerteAufgabe(task, loesung, [{ part: '1', antwort: 'a' }])
    expect(halb.ok).toBe(false)
    expect(halb.fehlt).toEqual(['2'])
  })
  it('Toleranz nur flach und nicht bei MC, und als nurToleranz gemeldet', () => {
    const loesung = { correct_answers: ['3.33'], acceptance: { canonical: '3.33', tolerance: { mode: 'absolute', value: 0.01 } } }
    const w = bewerteAufgabe({ input_type: 'NUMERIC' }, loesung, [{ part: null, antwort: '3.335' }])
    expect(w.ok).toBe(true)
    expect(w.nurToleranz).toBe(true)
  })
})
