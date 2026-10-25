// Bericht v4: der Lernpfad nach Klassenarbeiten (Bauauftrag V4, V4-1, Entscheidung 5).
import { describe, expect, it } from 'vitest'

import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { bericht, berichtVon } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import { TEILE_MAX, gruppiereSchwerpunkte } from '@/lib/report/elternbericht/lernpfadV4'
import type { EbFahrplan, EbSchwerpunkt, EbStation, EbThemaSignal } from '@/types'

const sp = (uebung: string[], teil: Partial<EbSchwerpunkt> = {}): EbSchwerpunkt => ({
  feld: 'terme',
  thema: null,
  gemischt: false,
  sicher: [],
  uebung,
  start: null,
  naechster: null,
  ...teil,
})
const station = (nummer: number, themaKey: string, titel: string): EbStation => ({
  nummer,
  themaKey,
  titel,
  halbjahr: null,
  schuljahr: 'dieses',
  stand: nummer === 1 ? 'geschrieben' : 'voraussichtlich',
  signal: nummer === 1 ? null : 'fehlt',
  note: null,
})
const FAHRPLAN: EbFahrplan = {
  stationen: [station(1, 't0', 'Start'), station(2, 't2', 'Zwei'), station(3, 't3', 'Drei'), station(4, 't4', 'Vier')],
  weitere: 0,
  halbjahrTrenner: false,
  klassenTrenner: null,
  quelle: 'schule',
  schulname: null,
  satz: 'fehlt',
}
const fehlt = (themaKey: string, labels: string[]): EbThemaSignal => ({
  themaKey,
  sitzt: [],
  fehlt: labels.map((label) => ({ skillKey: label, label, feld: 'zahlen', klasse: 8, sicher: false })),
})
const SIGNALE = [fehlt('t2', ['A', 'B']), fehlt('t3', ['B', 'C', 'D']), fehlt('t4', ['E'])]

const punkte = (schwerpunkte: EbSchwerpunkt[], teil: { fahrplan?: EbFahrplan | null; danach?: never[] } = {}) =>
  gruppiereSchwerpunkte({
    schwerpunkte,
    gruende: schwerpunkte.map(() => undefined),
    danach: teil.danach ?? [],
    fahrplan: teil.fahrplan === undefined ? FAHRPLAN : teil.fahrplan,
    signale: SIGNALE,
  })

describe('gruppiereSchwerpunkte', () => {
  it('zwei Schwerpunkte mit gleicher erster Ziel-Station werden eine Gruppe mit Titel der Station', () => {
    const p = punkte([sp(['A']), sp(['B'], { feld: 'groessen' })])
    expect(p).toHaveLength(1)
    expect(p[0]).toMatchObject({ art: 'gruppe', titelFeld: null, titelThema: 'Zwei', ziele: [2, 3], teile: ['A', 'B'] })
  })

  it('unterschiedliche erste Ziel-Station: einzeln', () => {
    const p = punkte([sp(['A']), sp(['E'], { feld: 'geometrie' })])
    expect(p.map((x) => [x.art, x.titelFeld, x.ziele])).toEqual([
      ['feld', 'terme', [2]],
      ['feld', 'geometrie', [4]],
    ])
  })

  it('nur aufeinanderfolgende Schwerpunkte werden gruppiert', () => {
    const p = punkte([sp(['A']), sp(['E'], { feld: 'geometrie' }), sp(['B'], { feld: 'groessen' })])
    expect(p.map((x) => x.art)).toEqual(['feld', 'feld', 'feld'])
  })

  it('ein Punkt, der zwei Klassenarbeiten vorbereitet, hat beide Ziele aufsteigend', () => {
    const p = punkte([sp(['C', 'B'])])
    expect(p[0]).toMatchObject({ art: 'feld', ziele: [2, 3] })
  })

  it('Thema-Schwerpunkt ohne kommende Station wird „luecke“ mit Titel des Themas', () => {
    const p = punkte([sp(['Z'], { feld: null, thema: 'Reelle Zahlen' })])
    expect(p[0]).toMatchObject({ art: 'luecke', titelFeld: null, titelThema: 'Reelle Zahlen', ziele: [] })
  })

  it('Thema-Schwerpunkt mit kommender Station bleibt „luecke“ mit Ziel', () => {
    const p = punkte([sp(['D'], { feld: null, thema: 'Reelle Zahlen' })])
    expect(p[0]).toMatchObject({ art: 'luecke', ziele: [3] })
  })

  it('Station 1 ist kein Ziel, wenn ihre Arbeit geschrieben oder ihr Stand unbekannt ist', () => {
    for (const stand of ['geschrieben', 'aktuell'] as const) {
      const p = gruppiereSchwerpunkte({
        schwerpunkte: [sp(['A'])],
        gruende: [undefined],
        danach: [],
        fahrplan: { ...FAHRPLAN, stationen: [{ ...FAHRPLAN.stationen[0], stand }, ...FAHRPLAN.stationen.slice(1)] },
        signale: [fehlt('t0', ['A'])],
      })
      expect(p[0].ziele, stand).toEqual([])
    }
  })

  it('Lücke im aktuellen Thema: Station 1 ist erstes Ziel, wenn ihre Arbeit noch ansteht', () => {
    const naechste: EbFahrplan = {
      ...FAHRPLAN,
      stationen: [{ ...FAHRPLAN.stationen[0], stand: 'naechste' }, ...FAHRPLAN.stationen.slice(1)],
    }
    const p = gruppiereSchwerpunkte({
      schwerpunkte: [sp(['A'], { feld: null, thema: 'Start' }), sp(['B'])],
      gruende: [undefined, undefined],
      danach: [],
      fahrplan: naechste,
      signale: [fehlt('t3', ['A']), fehlt('t2', ['B'])],
    })
    expect(p[0].ziele).toEqual([1, 3])
    // Ein Feld-Schwerpunkt bekommt Station 1 nicht.
    expect(p[1].ziele).toEqual([2])
  })

  it('„später“ ist der letzte Punkt, mit den Feldern aus danach', () => {
    const p = punkte([sp(['A']), sp(['E'], { feld: 'geometrie' })], { danach: ['zufall'] as never[] })
    expect(p.at(-1)).toMatchObject({ art: 'spaeter', ziele: [], teile: [], rest: 0, grund: null, felder: ['zufall'] })
    expect(p.filter((x) => x.art === 'spaeter')).toHaveLength(1)
    expect(punkte([sp(['A'])]).some((x) => x.art === 'spaeter')).toBe(false)
  })

  it('ohne Fahrplan: keine Ziele, jeder Schwerpunkt einzeln', () => {
    const p = punkte([sp(['A']), sp(['B'], { feld: 'groessen' })], { fahrplan: null })
    expect(p.map((x) => [x.art, x.ziele])).toEqual([['feld', []], ['feld', []]])
  })

  it('höchstens vier Teile, der Rest als Zahl', () => {
    const p = punkte([sp(['A', 'B', 'C', 'D', 'E', 'F'])])
    expect(p[0].teile).toHaveLength(TEILE_MAX)
    expect(p[0].rest).toBe(2)
  })
})

describe('Lernpfad der Fälle', () => {
  it('Reihenfolge der Punkte = Reihenfolge der Schwerpunkte aus schwerpunkte.ts', () => {
    for (const [name, { data }] of Object.entries(FAELLE)) {
      const b = berichtVon(data)
      if (!b?.lueckenwegV4) continue
      const ohneSpaeter = b.lernpfad.filter((p) => p.art !== 'spaeter')
      const reihenfolge = b.schwerpunkte.map((s) => s.feld ?? s.thema)
      // Gruppen fassen Nachbarn zusammen; ihre Teile bleiben die der Schwerpunkte in dieser Reihenfolge.
      const teile = ohneSpaeter.flatMap((p) => p.teile)
      const erwartet = b.schwerpunkte.flatMap((s) => s.uebung)
      expect(erwartet.filter((l) => teile.includes(l)), name).toEqual(teile)
      expect(ohneSpaeter.length, name).toBeLessThanOrEqual(reihenfolge.length)
      expect(b.lernpfad.at(-1)?.art === 'spaeter', name).toBe(b.danach.length > 0)
    }
  })

  it('batuBevorstehend: die Lücke im aktuellen Thema bereitet auch Klassenarbeit 1 vor', () => {
    const b = bericht('batuBevorstehend')
    const luecke = (b.lernpfad ?? []).find((p) => p.art === 'luecke')
    expect(luecke?.ziele).toEqual([1, 5])
    expect(bericht('batuV4').lernpfad?.some((p) => p.ziele.includes(1))).toBe(false)
  })

  it('ohne Plan: gleich viele Punkte wie Schwerpunkte (+ später), alle ohne Ziel', () => {
    const b = bericht('ohnePlan')
    expect(b.lernpfad.filter((p) => p.art !== 'spaeter')).toHaveLength(b.schwerpunkte.length)
    expect(b.lernpfad.every((p) => p.ziele.length === 0)).toBe(true)
  })
})
