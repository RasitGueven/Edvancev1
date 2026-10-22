import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { u } from '@/lib/report/elternbericht/fixtures/basis'
import { KATALOG } from '@/lib/report/elternbericht/fixtures/katalog'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { ueberblick } from '@/lib/report/praesentation/ueberblick'
import type { Elternbericht, SucheSkill } from '@/types'

function bericht(name: string): Elternbericht {
  const { data } = PRAESENTATION_FAELLE[name]
  const b = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
  })
  if (!b) throw new Error(name)
  return b
}

const aus = (kompetenzen: SucheSkill[]): Elternbericht =>
  baueElternbericht({ kompetenzen, katalog: KATALOG, klasse: 10 })!

describe('ueberblick', () => {
  it('ilkay: gelungen Größen, Zahlen · üben Geometrie, Brüche, Prozent, Terme (alle, die Karte kürzt)', () => {
    expect(ueberblick(bericht('ilkay'))).toEqual({
      gelungen: ['groessen', 'zahlen'],
      ueben: ['geometrie', 'brueche', 'prozent', 'terme'],
      beispielSicher: null,
      beispielUebung: null,
    })
  })

  it('allesSicher: üben leer, kein Beispiel', () => {
    const b = ueberblick(bericht('allesSicher'))
    expect(b.gelungen.length).toBeGreaterThan(0)
    expect(b.ueben).toEqual([])
    expect([b.beispielSicher, b.beispielUebung]).toEqual([null, null])
  })

  it('nichtsSicher: gelungen leer, kein Beispiel', () => {
    const b = ueberblick(bericht('nichtsSicher'))
    expect(b.gelungen).toEqual([])
    expect(b.ueben.length).toBeGreaterThan(0)
    expect([b.beispielSicher, b.beispielUebung]).toEqual([null, null])
  })

  it('alleFelder: gelungen leer, Beispiel „Brüche kürzen", üben alle acht, Brüche und Prozent zuerst', () => {
    expect(ueberblick(bericht('alleFelder'))).toEqual({
      gelungen: [],
      ueben: ['brueche', 'prozent', 'terme', 'geometrie', 'groessen', 'zahlen', 'funktionen', 'zufall'],
      beispielSicher: { label: 'Brüche kürzen', anzahl: 1 },
      beispielUebung: null,
    })
  })

  it('jedes Feld mit Übungsbedarf überwiegend sicher: üben leer, Beispiel gesetzt', () => {
    const b = ueberblick(
      aus([
        u('groessen_laengen', 'Längen umrechnen', 3, 5, 'traegt', 1, false),
        u('groessen_massen', 'Massen umrechnen', 3, 5, 'traegt', 1, false),
        u('groessen_flaechen', 'Flächeneinheiten', 5, 6, 'traegt_nicht', 2, false),
        u('bruch_kuerzen', 'Brüche kürzen', 1, 6, 'traegt', 1, false),
      ]),
    )
    expect(b).toEqual({
      // Größen 2 sicher vor Brüche 1 sicher — nach Anzahl, nicht nach Themenfeld.
      gelungen: ['groessen', 'brueche'],
      ueben: [],
      beispielSicher: null,
      beispielUebung: { label: 'Flächeneinheiten', anzahl: 1 },
    })
  })

  it('Gleichstand: Reihenfolge der Themenfelder', () => {
    const b = ueberblick(
      aus([
        u('groessen_laengen', 'Längen umrechnen', 3, 5, 'traegt', 1, false),
        u('bruch_kuerzen', 'Brüche kürzen', 1, 6, 'traegt', 1, false),
        u('runden_ueberschlag', 'Runden und Überschlag', 2, 5, 'traegt', 1, false),
        u('geo_umfang', 'Umfang von Rechteck und Dreieck', 3, 5, 'traegt_nicht', 2, false),
        u('prozent_grundwert', 'Grundwert berechnen', 7, 7, 'traegt_nicht', 2, false),
      ]),
    )
    expect(b.gelungen).toEqual(['brueche', 'groessen', 'zahlen'])
    expect(b.ueben).toEqual(['prozent', 'geometrie'])
  })

  it('Gleichstand sicher = Übungsbedarf zählt für üben, nicht für gelungen', () => {
    const b = ueberblick(bericht('ilkay'))
    expect(b.gelungen).not.toContain('terme')
  })

  it('kein Feld in beiden Karten', () => {
    for (const [name, { data }] of Object.entries(PRAESENTATION_FAELLE)) {
      if (data.erzaehlung.katalog.length === 0) continue
      const b = ueberblick(bericht(name))
      expect(b.gelungen.filter((f) => b.ueben.includes(f)), name).toEqual([])
    }
  })
})
