import { describe, expect, it } from 'vitest'

import {
  Bausteinsatz,
  ebeneAlsZeile,
  ebeneImSatz,
  ebenenUntertitel,
  setzePlatzhalter,
  streuwert,
} from '@/lib/report/bausteine'
import type { ReportBaustein } from '@/types'

const b = (fall: string, variante: string, text: string): ReportBaustein => ({
  schluessel: `suche.${fall}.${variante}`,
  slot: 'suche',
  fall,
  variante,
  text,
})

const SATZ = new Bausteinsatz([
  b('einstieg_traegt_fundament_luecken', 'a', 'Fassung A.'),
  b('einstieg_traegt_fundament_luecken', 'b', 'Fassung B.'),
  {
    schluessel: 'abstieg_einbruch.standard.a',
    slot: 'abstieg_einbruch',
    fall: 'standard',
    variante: 'a',
    text: 'Dort trugen {traegt} von {geprueft}.',
  },
])

describe('Bausteinsatz — Auswahl und Weglassen', () => {
  it('liefert null, wenn es zum Fall keinen Baustein gibt', () => {
    expect(SATZ.waehle('suche', 'alles_traegt', 'x')).toBeNull()
  })

  it('liefert null, wenn gar kein Fall bestimmt werden konnte', () => {
    expect(SATZ.waehle('suche', null, 'x')).toBeNull()
  })

  it('wählt für dieselbe Sitzung immer dieselbe Variante', () => {
    const id = 'd8b0d885-b72d-4b68-a17b-6b35db301103'
    const erste = SATZ.waehle('suche', 'einstieg_traegt_fundament_luecken', id)
    for (let i = 0; i < 20; i++) {
      expect(SATZ.waehle('suche', 'einstieg_traegt_fundament_luecken', id)).toBe(erste)
    }
  })

  it('streut über verschiedene Sitzungen', () => {
    const ids = Array.from({ length: 40 }, (_, i) => `sitzung-${i}`)
    const gewaehlt = new Set(
      ids.map((id) => SATZ.waehle('suche', 'einstieg_traegt_fundament_luecken', id)),
    )
    expect(gewaehlt.size).toBe(2)
  })

  it('setzt Platzhalter ein', () => {
    expect(SATZ.waehle('abstieg_einbruch', 'standard', 'x', { traegt: 0, geprueft: 2 })).toBe(
      'Dort trugen 0 von 2.',
    )
  })

  it('hängt nicht von der Zeilenreihenfolge der Datenbank ab', () => {
    const rueckwaerts = new Bausteinsatz([
      b('f', 'b', 'B'),
      b('f', 'a', 'A'),
    ])
    const vorwaerts = new Bausteinsatz([b('f', 'a', 'A'), b('f', 'b', 'B')])
    for (const id of ['s1', 's2', 's3', 's4']) {
      expect(rueckwaerts.waehle('suche', 'f', id)).toBe(vorwaerts.waehle('suche', 'f', id))
    }
  })
})

describe('setzePlatzhalter', () => {
  it('lässt einen Platzhalter ohne Wert sichtbar stehen', () => {
    // Besser eine sichtbare Lücke im Review als ein Satz wie
    // „Dort trugen  von  Bereichen."
    expect(setzePlatzhalter('a {fehlt} b', {})).toBe('a {fehlt} b')
  })

  it('ersetzt mehrfach vorkommende Platzhalter', () => {
    expect(setzePlatzhalter('{n} und {n}', { n: 3 })).toBe('3 und 3')
  })
})

describe('streuwert', () => {
  it('ist stabil und unterscheidet ähnliche Eingaben', () => {
    expect(streuwert('abc')).toBe(streuwert('abc'))
    expect(streuwert('abc')).not.toBe(streuwert('abd'))
  })
})

describe('Ebenenbeschriftung', () => {
  it('formuliert die Ebene für den Fließtext', () => {
    expect(ebeneImSatz(0)).toBe('beim aktuellen Thema selbst')
    expect(ebeneImSatz(1)).toBe('eine Ebene unter dem aktuellen Thema')
    expect(ebeneImSatz(2)).toBe('zwei Ebenen unter dem aktuellen Thema')
  })

  it('formuliert die Ebene als Zeilenkopf', () => {
    expect(ebeneAlsZeile(0)).toBe('Aktuelles Thema')
    expect(ebeneAlsZeile(1)).toBe('Eine Ebene tiefer')
    expect(ebeneAlsZeile(5)).toBe('Fünf Ebenen tiefer')
  })

  it('nennt nie eine Klassenstufe', () => {
    // fundament_tiefe ist die Position im Voraussetzungsgraphen, nicht der
    // Lehrplan. „Stoff aus Klasse 6" an einer Ebene wäre schlicht falsch.
    for (let d = 0; d <= 10; d++) {
      expect(ebeneImSatz(d)).not.toMatch(/Klasse/i)
      expect(ebeneAlsZeile(d)).not.toMatch(/Klasse/i)
    }
  })
})

describe('ebenenUntertitel', () => {
  it('zählt die Bereiche auf', () => {
    expect(ebenenUntertitel(['Maßstab', 'Flächeneinheiten'], 0)).toBe(
      'Maßstab, Flächeneinheiten',
    )
  })

  it('kürzt mit "u. a." ab', () => {
    expect(ebenenUntertitel(['A', 'B', 'C'], 1)).toBe('A, B, C u. a.')
  })

  it('bleibt leer, wenn nichts auf der Ebene liegt', () => {
    expect(ebenenUntertitel([], 0)).toBe('')
  })
})
