// Kinder-Hinweise in der Pruefansicht (L5): Entwurf ohne Luecken, Aenderungsliste wie pruef_aenderungen,
// Status je Stufe, Zusammenspiel mit der Bearbeitung (geaendert-Marke, ↺, Entwurf).

import { describe, expect, it } from 'vitest'
import { feldZuruecksetzen, geaenderteFelder, lokaleAenderungen, zuEntwurf, type Bearbeitung } from './entwurf'
import {
  hinweisAenderungen, hinweisEntfernen, hinweiseFuerEntwurf, hinweiseOffen, hinweisSetzen, hinweisStatus, MAX_STUFEN,
} from './hinweise'
import type { KinderHinweis } from '@/types'

const geladen: KinderHinweis[] = [
  { stufe: 1, text: 'Was ist der Radius?', status: 'geprueft' },
  { stufe: 2, text: 'U = 2 · π · r', status: 'entwurf' },
]
const basis: Bearbeitung = {
  werte: [{ teil: null, werte: ['22,62'] }], mc: null, regel: null, fehler: [], skill_key: 'k', afb: 'II',
  hinweise: geladen.map((h) => h.text),
}

describe('hinweiseFuerEntwurf', () => {
  it('trimmt, laesst leere weg und nummeriert ohne Luecke', () => {
    expect(hinweiseFuerEntwurf(['  a ', '', 'c'])).toEqual([{ stufe: 1, text: 'a' }, { stufe: 2, text: 'c' }])
  })
})

describe('hinweisAenderungen', () => {
  it('meldet geaenderte, neue und entfernte Stufen', () => {
    expect(hinweisAenderungen(['a', 'b'], ['a2', 'b', 'c'])).toEqual([
      { feld: 'hinweis', teil: 1, vorher: 'a', nachher: 'a2' },
      { feld: 'hinweis', teil: 3, vorher: null, nachher: 'c' },
    ])
    expect(hinweisAenderungen(['a', 'b'], ['a'])).toEqual([{ feld: 'hinweis', teil: 2, vorher: 'b', nachher: null }])
  })
  it('Leerraum allein ist keine Aenderung', () => {
    expect(hinweisAenderungen(['a'], [' a '])).toEqual([])
  })
})

describe('hinweisStatus', () => {
  it('unveraendert behaelt den Status, geaendert ist entwurf', () => {
    expect(hinweisStatus(geladen, 1, 'Was ist der Radius? ')).toBe('geprueft')
    expect(hinweisStatus(geladen, 1, 'Was ist r?')).toBe('entwurf')
    expect(hinweisStatus(geladen, 3, 'neu')).toBe('entwurf')
  })
  it('zaehlt ungepruefte', () => {
    expect(hinweiseOffen(geladen)).toBe(1)
  })
})

describe('hinweisSetzen / hinweisEntfernen', () => {
  it('haengt hinten an, hoechstens drei Stufen', () => {
    expect(hinweisSetzen(['a'], 1, 'b')).toEqual(['a', 'b'])
    expect(hinweisSetzen(['a', 'b', 'c'], MAX_STUFEN, 'd')).toEqual(['a', 'b', 'c'])
  })
  it('entfernen laesst die folgenden nachruecken', () => {
    expect(hinweisEntfernen(['a', 'b', 'c'], 0)).toEqual(['b', 'c'])
  })
})

describe('Bearbeitung mit Hinweisen', () => {
  it('Entwurf traegt die Hinweise, Marke und ↺ wirken auf das Feld hinweise', () => {
    const neu = { ...basis, hinweise: ['Was ist der Durchmesser?', basis.hinweise[1]] }
    expect(zuEntwurf(neu).hinweise).toEqual([
      { stufe: 1, text: 'Was ist der Durchmesser?' }, { stufe: 2, text: 'U = 2 · π · r' },
    ])
    expect([...geaenderteFelder(basis, neu)]).toEqual(['hinweise'])
    expect(lokaleAenderungen(basis, neu)).toEqual([
      { feld: 'hinweis', teil: 1, vorher: 'Was ist der Radius?', nachher: 'Was ist der Durchmesser?' },
    ])
    expect(feldZuruecksetzen(neu, basis, 'hinweise').hinweise).toEqual(basis.hinweise)
  })
})
