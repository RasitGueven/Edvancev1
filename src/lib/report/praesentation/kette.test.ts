import { describe, expect, it } from 'vitest'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { basisFuer, kette, MAX_GLIEDER } from '@/lib/report/praesentation/kette'
import { bauePraesentation } from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, TpKette, TpSchwerpunkt, TpThemaWeg } from '@/types'

const sp = (s: Partial<TpSchwerpunkt>): TpSchwerpunkt => ({
  feld: null,
  thema: null,
  gemischt: false,
  stufen: [],
  sicher: [],
  uebung: [],
  start: null,
  naechster: null,
  ...s,
})

const THEMA = sp({
  thema: 'Reelle Zahlen',
  gemischt: true,
  sicher: ['Quadratwurzel', 'Brüche'],
  uebung: ['Wurzelgesetze', 'Teilweise Wurzel ziehen'],
  start: 'Wurzelgesetze',
  naechster: 'Teilweise Wurzel ziehen',
})

const WEG: TpThemaWeg = {
  reihe: [
    { label: 'Brüche', sicher: true },
    { label: 'Quadratwurzel', sicher: true },
    { label: 'Wurzelgesetze', sicher: false },
    { label: 'Teilweise Wurzel ziehen', sicher: false },
  ],
  kanten: [
    { von: 'Brüche', zu: 'Wurzelgesetze' },
    { von: 'Wurzelgesetze', zu: 'Teilweise Wurzel ziehen' },
  ],
}

const eingabe = (p: Partial<Parameters<typeof kette>[0]>): Parameters<typeof kette>[0] => ({
  schwerpunkte: [],
  thema: null,
  themaWeg: null,
  naechstesThema: null,
  ...p,
})

const kurz = (k: TpKette | null): string[] | null =>
  k && k.glieder.map((g) => `${g.art}:${'label' in g ? g.label : g.feld}`)

describe('kette — mit Thema-Schwerpunkt', () => {
  it('volle Kette: Startstelle, Basis über Kante, naechster, Thema, nächstes Thema', () => {
    const k = kette(eingabe({ schwerpunkte: [THEMA], thema: 'Reelle Zahlen', themaWeg: WEG, naechstesThema: 'Quadratische Funktionen' }))
    expect(k?.fall).toBe('thema')
    expect(kurz(k)).toEqual([
      'basis:Brüche',
      'start:Wurzelgesetze',
      'naechster:Teilweise Wurzel ziehen',
      'thema:Reelle Zahlen',
      'kommt:Quadratische Funktionen',
    ])
    expect(k!.glieder[0]).toMatchObject({ kante: true })
  })

  it('Basis über Kante geht vor Basis über Reihenfolge (Quadratwurzel stünde näher)', () => {
    expect(basisFuer('Wurzelgesetze', WEG)).toEqual({ label: 'Brüche', kante: true })
  })

  it('ohne Kante: der letzte sichere Bereich vor der Startstelle in der Thema-Reihenfolge', () => {
    expect(basisFuer('Wurzelgesetze', { ...WEG, kanten: [] })).toEqual({ label: 'Quadratwurzel', kante: false })
  })

  it('mehrere Kanten: der späteste sichere in der Thema-Reihenfolge', () => {
    const weg = { ...WEG, kanten: [...WEG.kanten, { von: 'Quadratwurzel', zu: 'Wurzelgesetze' }] }
    expect(basisFuer('Wurzelgesetze', weg)).toEqual({ label: 'Quadratwurzel', kante: true })
  })

  it('eine Kante von einem Bereich mit Übungsbedarf zählt nicht als Basis', () => {
    const weg: TpThemaWeg = {
      reihe: [
        { label: 'A', sicher: false },
        { label: 'B', sicher: false },
      ],
      kanten: [{ von: 'A', zu: 'B' }],
    }
    expect(basisFuer('B', weg)).toBeNull()
  })

  it('ohne Basis entfällt der Kasten; ohne naechster und ohne nächstes Thema ebenso', () => {
    const k = kette(
      eingabe({ schwerpunkte: [{ ...THEMA, naechster: null }], thema: 'Reelle Zahlen', themaWeg: { reihe: WEG.reihe.slice(2), kanten: [] } }),
    )
    expect(kurz(k)).toEqual(['start:Wurzelgesetze', 'thema:Reelle Zahlen'])
  })

  it('ohne naechster: Basis, Startstelle, Thema, nächstes Thema', () => {
    const k = kette(
      eingabe({ schwerpunkte: [{ ...THEMA, naechster: null }], thema: 'Reelle Zahlen', themaWeg: WEG, naechstesThema: 'Funktionen' }),
    )
    expect(kurz(k)).toEqual(['basis:Brüche', 'start:Wurzelgesetze', 'thema:Reelle Zahlen', 'kommt:Funktionen'])
  })
})

describe('kette — Thema ohne Übungsbedarf', () => {
  it('„Ihr Thema · sitzt", dann das nächste Thema — auch wenn andere Felder Übungsbedarf haben', () => {
    const feld = sp({ feld: 'geometrie', uebung: ['Maßstab'] })
    const k = kette(eingabe({ schwerpunkte: [feld], thema: 'Reelle Zahlen', naechstesThema: 'Funktionen' }))
    expect(k?.fall).toBe('themaSitzt')
    expect(kurz(k)).toEqual(['themaSitzt:Reelle Zahlen', 'kommt:Funktionen'])
  })

  it('ohne nächstes Thema bleibt ein Kasten', () => {
    expect(kurz(kette(eingabe({ thema: 'Reelle Zahlen' })))).toEqual(['themaSitzt:Reelle Zahlen'])
  })
})

describe('kette — ohne Thema', () => {
  it('der erste Schwerpunkt: erster sicherer Bereich, erster mit Übungsbedarf, Themenfeld, nächstes Thema', () => {
    const feld = sp({ feld: 'geometrie', sicher: ['Fläche', 'Winkel'], uebung: ['Umfang', 'Maßstab'] })
    const k = kette(eingabe({ schwerpunkte: [feld, sp({ feld: 'brueche', uebung: ['x'] })], naechstesThema: 'Funktionen' }))
    expect(k?.fall).toBe('feld')
    expect(kurz(k)).toEqual(['basis:Fläche', 'start:Umfang', 'feld:geometrie', 'kommt:Funktionen'])
  })

  it('ohne Sicheres im Feld entfällt der erste Kasten', () => {
    const k = kette(eingabe({ schwerpunkte: [sp({ feld: 'geometrie', uebung: ['Umfang'] })] }))
    expect(kurz(k)).toEqual(['start:Umfang', 'feld:geometrie'])
  })

  it('ohne Schwerpunkt und ohne Thema: keine Kette (volle Karte)', () => {
    expect(kette(eingabe({ naechstesThema: 'Funktionen' }))).toBeNull()
  })
})

describe('kette — Fixtures', () => {
  const faelle = Object.entries(PRAESENTATION_FAELLE).filter(([n]) => n !== 'ohneKatalog')
  const daten = (name: string): PraesentationDaten => {
    const p = bauePraesentation(PRAESENTATION_FAELLE[name])
    if ('fehlt' in p) throw new Error(name)
    return p
  }

  it.each(faelle)('%s: höchstens fünf Glieder, Startstelle aus Schwerpunkt 1', (name) => {
    const p = daten(name)
    const k = kette(p)
    if (!k) {
      expect(p.schwerpunkte).toHaveLength(0)
      expect(p.thema).toBeNull()
      return
    }
    expect(k.glieder.length).toBeLessThanOrEqual(MAX_GLIEDER)
    expect(k.glieder.length).toBeGreaterThan(0)
    const start = k.glieder.find((g) => g.art === 'start')
    if (p.schwerpunkte[0]?.start) expect(start).toMatchObject({ label: p.schwerpunkte[0].start })
  })

  it('abgestuft: Bruch in Dezimalzahl (Reihenfolge) → Wurzelgesetze → Teilweise die Wurzel ziehen → Reelle Zahlen', () => {
    expect(kurz(kette(daten('abgestuft')))).toEqual([
      'basis:Bruch in Dezimalzahl',
      'start:Wurzelgesetze für Produkt und Quotient',
      'naechster:Teilweise die Wurzel ziehen',
      'thema:Reelle Zahlen',
    ])
  })

  it('abgestuftThemaSicher: nur „Ihr Thema · sitzt"', () => {
    expect(kette(daten('abgestuftThemaSicher'))?.fall).toBe('themaSitzt')
  })

  it('allesSicher (ohne Thema): keine Kette', () => {
    expect(kette(daten('allesSicher'))).toBeNull()
  })

  it('themaWeg nur mit Thema; dieselbe Reihenfolge wie die Listen des Thema-Schwerpunkts', () => {
    expect(daten('ilkay').themaWeg).toBeNull()
    const p = daten('abgestuft')
    const s = p.schwerpunkte[0]
    const reihe = p.themaWeg!.reihe
    expect(reihe.filter((r) => r.sicher).map((r) => r.label)).toEqual(s.sicher)
    expect(reihe.filter((r) => !r.sicher).map((r) => r.label)).toEqual(s.uebung)
  })
})
