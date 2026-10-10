// F1 Test 2 (Trockenlauf 08.10., Befund A2/A3): Eingaben lesbar je Aufgabentyp; falsche Versuche nur zur aktuellen Aufgabe.

import { describe, expect, it } from 'vitest'
import type { KindVersuch } from '@/types/sessionLive'
import { eingabeDerAufgabe, eingabeWert, falscheZurAufgabe } from './coachLiveEingabe'

const v = (x: Partial<KindVersuch>): KindVersuch => ({
  task_id: 't1', teil: null, versuch_nr: 1, eingabe: null, ergebnis: 'falsch', fehlbild_slug: null, fehlbild_klartext: null,
  hinweisstufe_max: 0, phase: 'kern', dauer_ms: null, zeit: '2026-10-08T13:00:00Z', ...x,
})

const MC = { kind: 'mc', prompt: 'Welche Zahl ist irrational?', options: [{ id: 'a', label: '√4' }, { id: 'b', label: '√2' }] }
const MP = {
  kind: 'multi_part', stem: 'Wurzeln',
  parts: [{ nr: 1, kind: 'short_input', prompt: '√9' }, { nr: 2, kind: 'mc', prompt: 'irrational?', options: [{ id: 'j', label: 'ja' }, { id: 'n', label: 'nein' }] }],
}

describe('F1 A2 Eingabe lesbar', () => {
  it('Text und Zahl ohne JSON-Huelle', () => {
    expect(eingabeWert({ text: '9' })).toBe('9')
    expect(eingabeWert('9')).toBe('9')
    expect(eingabeWert(9)).toBe('9')
    expect(eingabeWert({ text: '1,5' })).toBe('1,5')
  })

  it('Auswahl: das Label der gewaehlten Option', () => {
    expect(eingabeWert({ selected: ['b'] }, MC)).toBe('√2')
    expect(eingabeWert(['a', 'b'], MC)).toBe('√4, √2')
    expect(eingabeWert('b', MC)).toBe('√2')
    // unbekannte Option: die id selbst statt JSON
    expect(eingabeWert({ selected: ['x'] }, MC)).toBe('x')
  })

  it('mehrere Teile: „a) … · b) …“ mit den Optionen des Teils', () => {
    const e = eingabeDerAufgabe(
      [v({ teil: 1, eingabe: { text: '3' }, ergebnis: 'richtig' }), v({ teil: 2, eingabe: { selected: ['n'] }, ergebnis: 'falsch' })],
      MP,
    )
    expect(e).toEqual({ eingabe: 'a) 3 · b) nein', ergebnis: 'teilweise', hinweisstufe: 0 })
  })

  it('ein Teil: Ergebnis und Hinweisstufe der Antwort', () => {
    expect(eingabeDerAufgabe([v({ eingabe: { text: '9' }, ergebnis: 'richtig', hinweisstufe_max: 2 })])).toEqual({
      eingabe: '9', ergebnis: 'richtig', hinweisstufe: 2,
    })
    expect(eingabeDerAufgabe([])).toBeNull()
  })

  it('Unbekanntes Format bleibt sichtbar statt leer', () => {
    expect(eingabeWert({ punkte: [1, 2] })).toBe('{"punkte":[1,2]}')
  })
})

describe('F1 A3 falsche Versuche nur zur aktuellen Aufgabe', () => {
  const versuche = [
    v({ task_id: 'alt', eingabe: { text: '2' }, fehlbild_klartext: 'Betrag' }),
    v({ task_id: 't1', eingabe: { text: '25' } }),
    v({ task_id: 't1', teil: 2, eingabe: { selected: ['j'] }, fehlbild_klartext: 'Wurzel aus Quadratzahl' }),
    v({ task_id: 't1', teil: 1, eingabe: { text: '3' }, ergebnis: 'richtig' }),
  ]
  it('nur die aktuelle Aufgabe, nur falsch, lesbar', () => {
    expect(falscheZurAufgabe(versuche, 't1', MP)).toEqual([
      { eingabe: '25', fehlbild: null },
      { eingabe: 'b) ja', fehlbild: 'Wurzel aus Quadratzahl' },
    ])
  })
  it('ohne aktuelle Aufgabe nichts', () => {
    expect(falscheZurAufgabe(versuche, null)).toEqual([])
  })
})
