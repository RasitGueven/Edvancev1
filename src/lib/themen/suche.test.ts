import { describe, expect, it } from 'vitest'
import { TEST_KATALOG } from './katalog.fixture'
import {
  falten,
  nachStufe,
  stufeDarunter,
  stufeFuerKlasse,
  sucheSchulen,
  sucheThemen,
} from './suche'

const keys = (eingabe: string): string[] => sucheThemen(TEST_KATALOG, eingabe).map((t) => t.thema_key)

describe('sucheThemen', () => {
  it('findet "irrationale zahlen" ueber das Schlagwort', () => {
    expect(keys('irrationale zahlen')).toEqual(['reelle_zahlen'])
  })

  it('findet "Wurzel" im Label (Praefix von "Wurzeln"), Gross-/Kleinschreibung egal', () => {
    expect(keys('Wurzel')[0]).toBe('reelle_zahlen')
  })

  it('"pi": ganze Schlagworte vor Praefix-Treffern wie "pizza"', () => {
    expect(keys('pi')).toEqual(['reelle_zahlen', 'kreis', 'brueche'])
  })

  it('"Zinsen" trifft die Zinsrechnung, nicht "zinseszins"', () => {
    expect(keys('Zinsen')).toEqual(['zinsrechnung'])
  })

  it('"steigung": ganzes Schlagwort vor Praefix ("steigungswinkel")', () => {
    expect(keys('steigung')).toEqual(['lineare_funktionen', 'trigonometrie'])
  })

  it('"binomisch" trifft das Label per Praefix', () => {
    expect(keys('binomisch')).toEqual(['terme_binomische_formeln'])
  })

  it('"baumdiagramm" liefert beide Stufen in Katalog-Reihenfolge', () => {
    expect(keys('baumdiagramm')).toEqual(['zufallsexperimente', 'bedingte_wahrscheinlichkeit'])
  })

  it('"parabel" trifft die quadratischen Funktionen', () => {
    expect(keys('parabel')).toEqual(['quadratische_funktionen'])
  })

  it('"thales": Label vor allem anderen', () => {
    expect(keys('thales')).toEqual(['thales_konstruktionen'])
  })

  it('"Ähnlichkeit" und "aehnlichkeit" finden dasselbe', () => {
    expect(keys('Ähnlichkeit')).toEqual(['aehnlichkeit'])
    expect(keys('aehnlichkeit')).toEqual(['aehnlichkeit'])
  })

  it('Label-Treffer stehen vor Schlagwort-Treffern', () => {
    // "zahlen": Label bei natuerlichen, rationalen und reellen Zahlen.
    const r = keys('zahlen')
    expect(r.slice(0, 3)).toEqual(['rechnen_natuerliche_zahlen', 'rationale_zahlen', 'reelle_zahlen'])
  })

  it('liefert hoechstens 6 Vorschlaege', () => {
    expect(sucheThemen(TEST_KATALOG, 'e').length).toBeLessThanOrEqual(6)
  })

  it('leere Eingabe und kein Treffer liefern nichts', () => {
    expect(keys('   ')).toEqual([])
    expect(keys('photosynthese')).toEqual([])
  })
})

describe('sucheSchulen', () => {
  const SCHULEN = [
    { name: 'Heinrich-Heine-Gymnasium', stadtteil: 'Ostheim' },
    { name: 'Gymnasium Kreuzgasse', stadtteil: 'Altstadt-Nord' },
    { name: 'Erich Kästner-Gymnasium', stadtteil: 'Köln-Riehl' },
  ]

  it('findet nach Name und Stadtteil, Umlaute gefaltet', () => {
    expect(sucheSchulen(SCHULEN, 'heine').map((s) => s.stadtteil)).toEqual(['Ostheim'])
    expect(sucheSchulen(SCHULEN, 'ostheim').map((s) => s.name)).toEqual(['Heinrich-Heine-Gymnasium'])
    expect(sucheSchulen(SCHULEN, 'kaestner riehl')).toHaveLength(1)
    expect(sucheSchulen(SCHULEN, 'gym')).toHaveLength(3)
    expect(sucheSchulen(SCHULEN, '')).toEqual([])
  })
})

describe('falten', () => {
  it('faltet Umlaute und ß', () => {
    expect(falten('Größe Übung Ärger Öl')).toBe('groesse uebung aerger oel')
  })
})

describe('Stufen', () => {
  it('ordnet Klassen ihrer Stufe zu', () => {
    expect([5, 6, 7, 8, 9, 10, 12].map(stufeFuerKlasse)).toEqual([
      'erprobung',
      'erprobung',
      'erste',
      'erste',
      'zweite',
      'zweite',
      'zweite',
    ])
    expect(stufeFuerKlasse(null)).toBeNull()
  })

  it('kennt die Stufe darunter', () => {
    expect(stufeDarunter('zweite')).toBe('erste')
    expect(stufeDarunter('erprobung')).toBeNull()
  })

  it('stellt die Stufe des Kindes vor die anderen', () => {
    const { eigene, andere } = nachStufe(sucheThemen(TEST_KATALOG, 'baumdiagramm'), 'zweite')
    expect(eigene.map((t) => t.thema_key)).toEqual(['bedingte_wahrscheinlichkeit'])
    expect(andere.map((t) => t.thema_key)).toEqual(['zufallsexperimente'])
  })
})
