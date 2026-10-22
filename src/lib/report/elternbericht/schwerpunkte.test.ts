import { describe, expect, it } from 'vitest'

import { bereicheAus } from '@/lib/report/elternbericht/bereiche'
import { ilkay } from '@/lib/report/elternbericht/fixtures/ilkay'
import {
  alleFelder,
  allesSicher,
  nichtsSicher,
  sechsFelderMitUebung,
} from '@/lib/report/elternbericht/fixtures/synthetisch'
import { MAX_SCHWERPUNKTE, waehleSchwerpunkte } from '@/lib/report/elternbericht/schwerpunkte'
import { feldPosition } from '@/lib/report/elternbericht/themenfelder'
import type { EbBereich, ReportData, ThemenfeldKey } from '@/types'

const w = (d: ReportData) => waehleSchwerpunkte(bereicheAus(d.erzaehlung.kompetenzen))

let n = 0
const b = (feld: ThemenfeldKey, klasse: number, sicher: boolean): EbBereich => ({
  skillKey: `zz_${++n}`,
  label: `ZZ ${n}`,
  feld,
  klasse,
  sicher,
})
const felder = (bereiche: EbBereich[]) => waehleSchwerpunkte(bereiche).schwerpunkte.map((s) => s.feld)

describe('waehleSchwerpunkte — die vier Sortierstufen', () => {
  it('1. gemischt vor reinem Übungsbedarf, auch gegen tiefere Stufe und mehr Übung', () => {
    expect(
      felder([
        b('brueche', 5, false),
        b('brueche', 5, false),
        b('geometrie', 9, true),
        b('geometrie', 9, false),
      ]),
    ).toEqual(['geometrie', 'brueche'])
  })

  it('2. tiefste Stufe unter den Übungsbedarf-Bereichen, auch gegen mehr Übung', () => {
    expect(
      felder([
        b('brueche', 8, false),
        b('brueche', 9, false),
        b('brueche', 9, false),
        b('geometrie', 6, false),
      ]),
    ).toEqual(['geometrie', 'brueche'])
  })

  it('2. zählt nur die Stufe der Übungsbedarf-Bereiche, nicht der sicheren', () => {
    expect(
      felder([
        b('brueche', 5, true),
        b('brueche', 9, false),
        b('geometrie', 7, true),
        b('geometrie', 7, false),
      ]),
    ).toEqual(['geometrie', 'brueche'])
  })

  it('3. mehr Übungsbedarf vor weniger', () => {
    expect(
      felder([b('brueche', 7, false), b('geometrie', 8, false), b('geometrie', 7, false)]),
    ).toEqual(['geometrie', 'brueche'])
  })

  it('4. Gleichstand: Reihenfolge der Themenfelder', () => {
    expect(
      felder([b('zufall', 8, false), b('prozent', 7, false), b('brueche', 8, false)]),
    ).toEqual(['brueche', 'prozent', 'zufall'])
  })
})

describe('waehleSchwerpunkte — Fälle', () => {
  it('ilkay: Geometrie, Brüche, Größen, Prozent; danach Terme, Zahlen', () => {
    const { schwerpunkte, danach } = w(ilkay)
    expect(schwerpunkte.map((s) => s.feld)).toEqual(['geometrie', 'brueche', 'groessen', 'prozent'])
    expect(danach).toEqual(['terme', 'zahlen'])
    expect(schwerpunkte.every((s) => s.gemischt)).toBe(true)
    expect(schwerpunkte[1]).toEqual({
      feld: 'brueche',
      thema: null,
      gemischt: true,
      sicher: ['Bruch in Dezimalzahl', 'Brüche kürzen'],
      uebung: ['Brüche addieren', 'Brüche dividieren', 'Brüche multiplizieren'],
      start: null,
    })
  })

  it('höchstens vier, der Rest in danach in derselben Reihenfolge', () => {
    for (const d of [sechsFelderMitUebung, alleFelder]) {
      const { schwerpunkte, danach } = w(d)
      expect(schwerpunkte).toHaveLength(MAX_SCHWERPUNKTE)
      const mitUebung = new Set(bereicheAus(d.erzaehlung.kompetenzen).filter((x) => !x.sicher).map((x) => x.feld))
      expect(schwerpunkte.length + danach.length).toBe(mitUebung.size)
    }
    expect(w(sechsFelderMitUebung).schwerpunkte.map((s) => s.feld)).toEqual(['brueche', 'geometrie', 'groessen', 'prozent'])
    expect(w(sechsFelderMitUebung).danach).toEqual(['terme', 'zahlen'])
    expect(w(alleFelder).danach).toEqual(['terme', 'zahlen', 'funktionen', 'zufall'])
    // danach: alle ohne Sicheres, gleiche Stufe 7/8, je ein Bereich → Feld-Reihenfolge.
    const pos = w(alleFelder).danach.map(feldPosition)
    expect([...pos].sort((a, c) => a - c)).toEqual(pos)
  })

  it('ohne Übungsbedarf keine Schwerpunkte', () => {
    expect(w(allesSicher)).toEqual({ schwerpunkte: [], danach: [] })
  })

  it('nichts sicher: keiner gemischt, Labels nur im Übungsbedarf', () => {
    const { schwerpunkte } = w(nichtsSicher)
    expect(schwerpunkte.every((s) => !s.gemischt && s.sicher.length === 0)).toBe(true)
  })
})
