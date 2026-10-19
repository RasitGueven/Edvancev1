import { describe, expect, it } from 'vitest'

import { bereicheAus } from '@/lib/report/elternbericht/bereiche'
import { EBENEN, bauePyramide, ebeneFuer, klassenAngabe } from '@/lib/report/elternbericht/einordnung'
import { ilkay } from '@/lib/report/elternbericht/fixtures/ilkay'
import { klasse10neu, klasse7, spaeter } from '@/lib/report/elternbericht/fixtures/synthetisch'
import type { EbEbene, ReportData } from '@/types'

const pyramide = (d: ReportData): EbEbene[] =>
  bauePyramide(bereicheAus(d.erzaehlung.kompetenzen), d.grade)

describe('ebeneFuer — Stufe des Skills gegen Stufe des Kindes', () => {
  // Skills aus 5/6, 7/8, 9/10 (je eine Klasse beider Jahrgänge).
  it.each([
    [5, ['aktuell', 'aktuell', 'spaeter', 'spaeter', 'spaeter', 'spaeter']],
    [6, ['aktuell', 'aktuell', 'spaeter', 'spaeter', 'spaeter', 'spaeter']],
    [7, ['grundlagen', 'grundlagen', 'aktuell', 'aktuell', 'spaeter', 'spaeter']],
    [8, ['grundlagen', 'grundlagen', 'aktuell', 'aktuell', 'spaeter', 'spaeter']],
    [9, ['grundlagen', 'grundlagen', 'weiterfuehrend', 'weiterfuehrend', 'aktuell', 'aktuell']],
    [10, ['grundlagen', 'grundlagen', 'weiterfuehrend', 'weiterfuehrend', 'aktuell', 'aktuell']],
    // Ab Klasse 11 keine eigene Stufe: 7–10 weiterführend, nichts aktuell.
    [11, ['grundlagen', 'grundlagen', 'weiterfuehrend', 'weiterfuehrend', 'weiterfuehrend', 'weiterfuehrend']],
  ])('Kind in Klasse %i', (kind, erwartet) => {
    expect([5, 6, 7, 8, 9, 10].map((skill) => ebeneFuer(skill, kind))).toEqual(erwartet)
  })
})

describe('bauePyramide', () => {
  it('ilkay: Ebenen aus den Daten, von oben nach unten, nur nicht leere', () => {
    const p = pyramide(ilkay)
    const klassen = ilkay.erzaehlung.kompetenzen.map((k) => k.klasseHerkunft)
    const erwartet = EBENEN.filter((e) => klassen.some((k) => ebeneFuer(k, ilkay.grade) === e))
    expect(p.map((e) => e.ebene)).toEqual(erwartet)
    // Jeder Bereich steht genau einmal in der Pyramide.
    const alle = p.flatMap((e) => e.gruppen.flatMap((g) => g.eintraege))
    expect(alle).toHaveLength(ilkay.erzaehlung.kompetenzen.length)
    for (const e of p) {
      expect(e.sicher + e.uebung).toBe(e.gruppen.reduce((n, g) => n + g.eintraege.length, 0))
      for (const g of e.gruppen) for (const x of g.eintraege) expect(ebeneFuer(x.klasse, 10)).toBe(e.ebene)
    }
  })

  it('ilkay: Analyse vor dem Katalogausbau — weiterführend 7/8 und Grundlagen 5/6', () => {
    const p = pyramide(ilkay)
    expect(p.map((e) => [e.ebene, e.stufen])).toEqual([
      ['weiterfuehrend', ['erste']],
      ['grundlagen', ['erprobung']],
    ])
    expect(p.map((e) => [e.sicher, e.uebung])).toEqual([
      [4, 8],
      [7, 8],
    ])
  })

  it('klasse10neu: drei Ebenen mit Klassenangabe', () => {
    const p = pyramide(klasse10neu)
    expect(p.map((e) => [e.ebene, e.stufen])).toEqual([
      ['aktuell', ['zweite']],
      ['weiterfuehrend', ['erste']],
      ['grundlagen', ['erprobung']],
    ])
  })

  it('klasse7: zwei Ebenen', () => {
    expect(pyramide(klasse7).map((e) => [e.ebene, e.stufen])).toEqual([
      ['aktuell', ['erste']],
      ['grundlagen', ['erprobung']],
    ])
  })

  it('spaeter: oberste Ebene „Stoff späterer Klassen"', () => {
    const p = pyramide(spaeter)
    expect(p[0].ebene).toBe('spaeter')
    expect(p[0].stufen).toEqual(['zweite'])
    expect(p[0].gruppen.map((g) => g.feld)).toEqual(['zahlen'])
    expect(p.map((e) => e.ebene)).toEqual(['spaeter', 'aktuell', 'grundlagen'])
  })

  it('Klasse 11: eine Ebene über mehrere Stufen nennt alle enthaltenen', () => {
    const p = bauePyramide(bereicheAus(klasse10neu.erzaehlung.kompetenzen), 11)
    expect(p.map((e) => [e.ebene, e.stufen])).toEqual([
      ['weiterfuehrend', ['erste', 'zweite']],
      ['grundlagen', ['erprobung']],
    ])
  })

  it('Gruppen in Feld-Reihenfolge, darin erst sicher, dann Übungsbedarf, je nach Label', () => {
    const grundlagen = pyramide(ilkay).find((e) => e.ebene === 'grundlagen')!
    expect(grundlagen.gruppen.map((g) => g.feld)).toEqual(['brueche', 'geometrie', 'groessen', 'zahlen'])
    expect(grundlagen.gruppen[0].eintraege.map((x) => [x.sicher, x.label])).toEqual([
      [true, 'Bruch in Dezimalzahl'],
      [true, 'Brüche kürzen'],
      [false, 'Brüche addieren'],
      [false, 'Brüche dividieren'],
      [false, 'Brüche multiplizieren'],
    ])
  })

  it('nutzt nie fundament_tiefe', () => {
    const verdreht = ilkay.erzaehlung.kompetenzen.map((k) => ({ ...k, fundamentTiefe: 99 - k.fundamentTiefe }))
    expect(bauePyramide(bereicheAus(verdreht), 10)).toEqual(pyramide(ilkay))
  })
})

describe('klassenAngabe', () => {
  it('eine Stufe nennt die Stufe, mehrere die Spanne', () => {
    expect(klassenAngabe(['zweite'])).toEqual({ stufe: 'zweite' })
    expect(klassenAngabe(['erste', 'zweite'])).toEqual({ von: 7, bis: 10 })
    expect(klassenAngabe(['erprobung', 'erste'])).toEqual({ von: 5, bis: 8 })
    expect(klassenAngabe([])).toBeNull()
  })
})
