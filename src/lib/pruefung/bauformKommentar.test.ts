// SP-1 S4: Kommentare, Zeit je Stufe, Entwurf und Fehlbild-Antworten der Prüfansicht.
import { beforeEach, describe, expect, it } from 'vitest'
import {
  aendern, entfernen, entwurfLaden, entwurfSpeichern, fehlerAntworten, grundUmschalten, hinzufuegen, LEER, sendbar,
  zeitSchritt, zumSenden,
} from './bauformKommentar'

describe('Kommentare', () => {
  it('je Anker einer, beim Beispiel je Instanz', () => {
    let e = hinzufuegen(LEER, 'grundgeruest')
    e = hinzufuegen(e, 'grundgeruest')
    e = hinzufuegen(e, 'beispiel', 't1')
    e = hinzufuegen(e, 'beispiel', 't2')
    expect(e.kommentare.map((k) => k.anker + (k.task_id ?? ''))).toEqual(['grundgeruest', 'beispielt1', 'beispielt2'])
  })
  it('ohne Grund und Text nicht sendbar; Grund oder Text reicht', () => {
    let e = hinzufuegen(LEER, 'beispiel', 't1')
    expect(sendbar(e)).toBe(false)
    e = grundUmschalten(e, 'beispiel:t1', 'rechnung_falsch')
    expect(sendbar(e)).toBe(true)
    e = grundUmschalten(e, 'beispiel:t1', 'rechnung_falsch')
    expect(sendbar(e)).toBe(false)
    e = aendern(e, 'beispiel:t1', { text: '  zu lang ' })
    expect(sendbar(e)).toBe(true)
    expect(zumSenden(e).kommentare).toEqual([{ anker: 'beispiel', task_id: 't1', gruende: [], text: 'zu lang' }])
  })
  it('entfernen', () => {
    expect(entfernen(hinzufuegen(LEER, 'stufen'), 'stufen').kommentare).toEqual([])
  })
})

describe('Zeit je Stufe', () => {
  it('Schritte 0,5, Grenzen 0,5 und 10, zurück auf den alten Wert heißt unverändert', () => {
    let e = zeitSchritt(LEER, 3, 1, 0.5)
    expect(e.zeiten).toEqual({ '3': 1.5 })
    e = zeitSchritt(e, 3, 1, -0.5)
    expect(e.zeiten).toEqual({})
    expect(zeitSchritt(LEER, 1, 0.5, -0.5).zeiten).toEqual({})
    expect(zeitSchritt(LEER, 1, 10, 0.5).zeiten).toEqual({})
  })
})

describe('Entwurf im Browser', () => {
  beforeEach(() => window.localStorage.clear())
  it('je Bauform und Version, leer wird entfernt', () => {
    const e = hinzufuegen(LEER, 'stufen')
    entwurfSpeichern('b1', 2, e)
    expect(entwurfLaden('b1', 2)).toEqual(e)
    expect(entwurfLaden('b1', 3)).toEqual(LEER)
    entwurfSpeichern('b1', 2, LEER)
    expect(window.localStorage.length).toBe(0)
  })
})

describe('fehlerAntworten', () => {
  it('neue Formate aus loesung.fehlbilder', () => {
    expect(fehlerAntworten({ loesung: { menge: ['0', '5'], fehlbilder: [{ key: 'qf_null_vergessen', menge: ['5'] }] }, known_errors: null, payload: { kind: 'format' } as never }))
      .toEqual([{ key: 'qf_null_vergessen', antwort: { menge: ['5'] } }])
  })
  it('Zahl: je Fehlbild eine Antwort, typografisches Minus bevorzugt', () => {
    expect(fehlerAntworten({ loesung: null, known_errors: { '-78': 'qf_a', '177': 'qf_b', '−78': 'qf_a' }, payload: { kind: 'short_input' } as never }))
      .toEqual(expect.arrayContaining([{ key: 'qf_a', antwort: { wert: '−78' } }, { key: 'qf_b', antwort: { wert: '177' } }]))
  })
  it('Auswahl: Option', () => {
    expect(fehlerAntworten({ loesung: null, known_errors: { b: 'qf_x' }, payload: { kind: 'mc', options: [] } as never }))
      .toEqual([{ key: 'qf_x', antwort: { option: 'b' } }])
  })
})
