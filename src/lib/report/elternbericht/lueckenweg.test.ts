// Bericht v3, Seite 3: jeder Bereich in genau einem Block (erstes kommendes Thema im Plan), „betrifft auch“.
import { describe, expect, it } from 'vitest'

import { LUECKENWEG_STUFEN, baueLueckenweg, duenneLueckenweg, type LueckenwegEingabe } from '@/lib/report/elternbericht/lueckenweg'
import type { EbBereich, EbKommtThema, EbLueckenweg, LernPlan, PlanEintrag, ThemenfeldKey } from '@/types'

const bereich = (skillKey: string, label: string, sicher: boolean, feld: ThemenfeldKey = 'zahlen', klasse = 8): EbBereich => ({
  skillKey,
  label,
  feld,
  klasse,
  sicher,
})
const eintrag = (position: number, themaKey: string | null, titel: string, halbjahr: 1 | 2 | null = 2): PlanEintrag => ({
  position,
  themaKey,
  titel,
  halbjahr,
})
const plan = (eintraege: PlanEintrag[], teil: Partial<LernPlan> = {}): LernPlan => ({
  quelle: 'schule',
  schulname: 'Gymnasium Nord',
  klasse: 9,
  eintraege,
  naechsteKlasse: null,
  ...teil,
})

const eingabe = (teil: Partial<LueckenwegEingabe> = {}): LueckenwegEingabe => ({
  bereiche: [],
  kanten: [],
  heimatThemen: [],
  plan: null,
  kommt: [],
  raum: new Set(),
  thema: null,
  ...teil,
})

// Thema „quad“ (Quadratische Gleichungen) hat den Skill q_loesen; der setzt
// wurzel_ziehen und term_umformen voraus. Thema „kreis“ hat kreis_flaeche, das
// setzt term_umformen voraus.
const GRAPH = {
  kanten: [
    { skillKey: 'q_loesen', voraussetzt: 'wurzel_ziehen' },
    { skillKey: 'q_loesen', voraussetzt: 'term_umformen' },
    { skillKey: 'kreis_flaeche', voraussetzt: 'term_umformen' },
  ],
  heimatThemen: [
    { skillKey: 'q_loesen', themaKey: 'quad' },
    { skillKey: 'kreis_flaeche', themaKey: 'kreis' },
  ],
}
const KOMMT = [eintrag(1, 'quad', 'Quadratische Gleichungen', 1), eintrag(2, 'kreis', 'Kreis', 2)]

const z = (label: string, auch: string[] = []) => ({ label, auch })

describe('baueLueckenweg — kommende Themen', () => {
  it('jeder Bereich steht nur im ersten Thema des Plans, das auf ihm aufbaut; die anderen stehen in „auch“', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: KOMMT,
        bereiche: [bereich('wurzel_ziehen', 'Wurzel ziehen', false), bereich('term_umformen', 'Terme umformen', false)],
      }),
    )
    // Kreis baut nur auf term_umformen auf, Quadratische Gleichungen kommt zuerst.
    expect(lw.themen).toEqual([
      {
        titel: 'Quadratische Gleichungen',
        halbjahr: 1,
        sitzt: [],
        fehlt: [z('Terme umformen', ['Kreis']), z('Wurzel ziehen')],
      },
    ])
  })

  it('der Block ist das erste Thema im Plan, nicht im Graphen', () => {
    const lw = baueLueckenweg(
      eingabe({ ...GRAPH, kommt: [...KOMMT].reverse(), bereiche: [bereich('term_umformen', 'Terme umformen', false)] }),
    )
    expect(lw.themen).toEqual([{ titel: 'Kreis', halbjahr: 2, sitzt: [], fehlt: [z('Terme umformen', ['Quadratische Gleichungen'])] }])
  })

  it('trennt sichere Bereiche (sitzt) und Lücken (fehlt) je Thema', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: KOMMT,
        bereiche: [bereich('wurzel_ziehen', 'Wurzel ziehen', true), bereich('term_umformen', 'Terme umformen', false)],
      }),
    )
    expect(lw.themen[0]).toMatchObject({ sitzt: [z('Wurzel ziehen')], fehlt: [z('Terme umformen', ['Kreis'])] })
    expect(lw.weitereStaerken).toEqual([])
  })

  it('Themen ohne eigenen Bereich und ohne themaKey fallen weg, die Plan-Reihenfolge bleibt', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: [eintrag(1, null, 'Ohne Schlüssel'), eintrag(2, 'unbekannt', 'Ohne Bezug'), ...KOMMT],
        bereiche: [bereich('wurzel_ziehen', 'Wurzel ziehen', false), bereich('kreis_x', 'Kreis-Kante', false)],
        kanten: [...GRAPH.kanten, { skillKey: 'kreis_flaeche', voraussetzt: 'kreis_x' }],
      }),
    )
    expect(lw.themen.map((t) => t.titel)).toEqual(['Quadratische Gleichungen', 'Kreis'])
  })

  it('ein Thema, das zweimal im Plan steht, nur einmal', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: [eintrag(1, 'kreis', 'Kreis', 1), eintrag(2, 'kreis', 'Kreis', 2)],
        bereiche: [bereich('term_umformen', 'Terme umformen', false)],
      }),
    )
    expect(lw.themen).toEqual([{ titel: 'Kreis', halbjahr: 1, sitzt: [], fehlt: [z('Terme umformen')] }])
  })

  it('Halbjahr null bleibt null', () => {
    const lw = baueLueckenweg(
      eingabe({ ...GRAPH, kommt: [eintrag(1, 'kreis', 'Kreis', null)], bereiche: [bereich('term_umformen', 'T', false)] }),
    )
    expect(lw.themen[0].halbjahr).toBeNull()
  })

  it('Bereiche je Block nach Klasse, dann alphabetisch', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: [KOMMT[0]],
        bereiche: [
          bereich('term_umformen', 'Zebra', false, 'terme', 7),
          bereich('wurzel_ziehen', 'Anton', false, 'zahlen', 8),
        ],
      }),
    )
    expect(lw.themen[0].fehlt.map((x) => x.label)).toEqual(['Zebra', 'Anton'])
  })

  it('nur eine Kante, keine Kette: ein Thema, das erst über einen Zwischenschritt aufbaut, erscheint nicht', () => {
    const lw = baueLueckenweg(
      eingabe({
        kanten: [
          { skillKey: 'q_loesen', voraussetzt: 'zwischen' },
          { skillKey: 'zwischen', voraussetzt: 'wurzel_ziehen' },
        ],
        heimatThemen: [{ skillKey: 'q_loesen', themaKey: 'quad' }],
        kommt: KOMMT,
        bereiche: [bereich('wurzel_ziehen', 'Wurzel ziehen', false)],
      }),
    )
    expect(lw.themen).toEqual([])
    expect(lw.weitere).toHaveLength(1)
  })

  it('Invariante: jeder geprüfte Bereich steht genau einmal (Block, weitere Stärken oder weitere Lücken)', () => {
    const bereiche = [
      bereich('wurzel_ziehen', 'Wurzel ziehen', true),
      bereich('term_umformen', 'Terme umformen', false),
      bereich('s1', 'Frei sicher', true),
      bereich('l1', 'Frei Lücke', false, 'geometrie'),
      bereich('l2', 'Frei Lücke 2', false, 'brueche'),
    ]
    const lw = baueLueckenweg(eingabe({ ...GRAPH, kommt: KOMMT, bereiche }))
    const alle = [
      ...lw.themen.flatMap((t) => [...t.sitzt, ...t.fehlt].map((x) => x.label)),
      ...lw.weitereStaerken,
      ...lw.weitere.flatMap((g) => g.labels),
    ]
    expect([...alle].sort()).toEqual(bereiche.map((b) => b.label).sort())
  })
})

describe('baueLueckenweg — weitere Lücken und Stärken', () => {
  it('Lücken ohne Bezug zu einem kommenden Thema stehen je Themenfeld in „weitere“, in Feld-Reihenfolge', () => {
    const lw = baueLueckenweg(
      eingabe({
        bereiche: [
          bereich('a', 'Geometrie-Lücke', false, 'geometrie'),
          bereich('b', 'Bruch-Lücke', false, 'brueche'),
          bereich('c', 'Bruch-Lücke 2', false, 'brueche'),
        ],
      }),
    )
    expect(lw.themen).toEqual([])
    expect(lw.weitere).toEqual([
      { feld: 'brueche', thema: null, labels: ['Bruch-Lücke', 'Bruch-Lücke 2'] },
      { feld: 'geometrie', thema: null, labels: ['Geometrie-Lücke'] },
    ])
  })

  it('Lücken im Themenraum der LSA stehen zuerst, unter dem Thema statt unter dem Feld', () => {
    const lw = baueLueckenweg(
      eingabe({
        raum: new Set(['a']),
        thema: 'Reelle Zahlen',
        bereiche: [bereich('b', 'Bruch-Lücke', false, 'brueche'), bereich('a', 'Im Thema', false, 'zahlen')],
      }),
    )
    expect(lw.weitere).toEqual([
      { feld: null, thema: 'Reelle Zahlen', labels: ['Im Thema'] },
      { feld: 'brueche', thema: null, labels: ['Bruch-Lücke'] },
    ])
  })

  it('Raum ohne Thema-Label: die Lücken stehen unter ihrem Feld', () => {
    const lw = baueLueckenweg(eingabe({ raum: new Set(['a']), thema: null, bereiche: [bereich('a', 'Im Raum', false, 'zahlen')] }))
    expect(lw.weitere).toEqual([{ feld: 'zahlen', thema: null, labels: ['Im Raum'] }])
  })

  it('eine Lücke mit Bezug zu einem kommenden Thema steht nicht zusätzlich in „weitere“', () => {
    const lw = baueLueckenweg(
      eingabe({ ...GRAPH, kommt: KOMMT, bereiche: [bereich('term_umformen', 'Terme umformen', false)] }),
    )
    expect(lw.weitere).toEqual([])
  })

  it('sichere Bereiche ohne kommendes Thema stehen in weitereStaerken, nicht in einem Block', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: KOMMT,
        bereiche: [bereich('term_umformen', 'Terme umformen', true), bereich('x', 'Anderes', true)],
      }),
    )
    expect(lw.themen[0].sitzt.map((x) => x.label)).toEqual(['Terme umformen'])
    expect(lw.weitereStaerken).toEqual(['Anderes'])
  })

  it('ohne Bereiche und ohne Plan: leer', () => {
    expect(baueLueckenweg(eingabe())).toEqual({
      themen: [],
      weitereStaerken: [],
      weitere: [],
      quelle: 'klp',
      schulname: null,
    })
  })
})

describe('baueLueckenweg — Quelle', () => {
  it('übernimmt Quelle und Schulname aus dem Plan', () => {
    const lw = baueLueckenweg(eingabe({ plan: plan([]) }))
    expect(lw).toMatchObject({ quelle: 'schule', schulname: 'Gymnasium Nord' })
  })

  it('Kernlehrplan ohne Schulnamen', () => {
    const lw = baueLueckenweg(eingabe({ plan: plan([], { quelle: 'klp', schulname: null }) }))
    expect(lw).toMatchObject({ quelle: 'klp', schulname: null })
  })
})

describe('duenneLueckenweg — Seite 3 dünnt stufenweise aus', () => {
  const namen = (n: number, p: string): string[] => Array.from({ length: n }, (_, i) => `${p}${i + 1}`)
  const thema = (i: number, fehlt: string[], sitzt: string[] = []): EbKommtThema => ({
    titel: `Thema ${i}`,
    halbjahr: 1,
    sitzt: sitzt.map((l) => z(l)),
    fehlt: fehlt.map((l) => z(l)),
  })
  const voll: EbLueckenweg = {
    themen: [thema(1, namen(5, 'L'), namen(4, 'S'))],
    weitereStaerken: namen(8, 'W'),
    weitere: [
      { feld: 'brueche', thema: null, labels: namen(5, 'B') },
      { feld: 'terme', thema: null, labels: namen(2, 'T') },
    ],
    quelle: 'klp',
    schulname: null,
  }
  /** Acht Blöcke mit je einer eigenen Lücke Z1 … Z8 und einer Stärke S1 … S8. */
  const acht: EbLueckenweg = {
    ...voll,
    themen: Array.from({ length: 8 }, (_, i) => thema(i + 1, [`Z${i + 1}`], [`S${i + 1}`])),
    weitereStaerken: [],
    weitere: [],
  }
  const gesamt = (lw: EbLueckenweg): number =>
    lw.themen.reduce((n, k) => n + k.sitzt.length + (k.restSitzt ?? 0) + k.fehlt.length + (k.restFehlt ?? 0), 0) +
    lw.weitereStaerken.length +
    (lw.weitereStaerkenRest ?? 0) +
    lw.weitere.reduce((n, g) => n + g.labels.length + (g.rest ?? 0), 0)

  it('hat fünf Stufen; Stufe 0 ändert nichts', () => {
    expect(LUECKENWEG_STUFEN).toBe(5)
    expect(duenneLueckenweg(voll, 0)).toBe(voll)
  })

  it('Stufe 1: je Kasten höchstens drei Bereiche, Gruppen drei Namen, weitere Stärken sechs; Blöcke unberührt', () => {
    const lw = duenneLueckenweg(voll, 1)
    expect(lw.themen[0]).toMatchObject({ restFehlt: 2, restSitzt: 1 })
    expect(lw.themen[0].fehlt).toHaveLength(3)
    expect(lw.themen[0].sitzt).toHaveLength(3)
    expect(lw.weitere.map((g) => [g.labels.length, g.rest])).toEqual([[3, 2], [2, 0]])
    expect(lw.weitereStaerken).toHaveLength(6)
    expect(lw.weitereStaerkenRest).toBe(2)
    expect(duenneLueckenweg(acht, 1).themen).toHaveLength(8)
  })

  it('Stufe 2: höchstens vier Blöcke; Lücken der übrigen in „spätere Themen“, deren Stärken zu weitere Stärken', () => {
    const lw = duenneLueckenweg(acht, 2)
    expect(lw.themen.map((k) => k.titel)).toEqual(['Thema 1', 'Thema 2', 'Thema 3', 'Thema 4'])
    expect(lw.weitere[0]).toMatchObject({ feld: null, thema: null, spaeter: true, labels: ['Z5', 'Z6', 'Z7'], rest: 1 })
    expect(lw.weitereStaerken).toEqual(['S5', 'S6', 'S7', 'S8'])
    expect(gesamt(lw)).toBe(gesamt(acht))
  })

  it('Stufe 2: ohne Lücken in den übrigen Blöcken keine Gruppe „spätere Themen“', () => {
    const ohne = { ...acht, themen: acht.themen.map((k, i) => (i < 4 ? k : { ...k, fehlt: [] })) }
    expect(duenneLueckenweg(ohne, 2).weitere.some((g) => g.spaeter)).toBe(false)
  })

  it('Stufe 3: übrige Lücken und weitere Stärken nur noch als Zahl; Blöcke bleiben vier', () => {
    const lw = duenneLueckenweg(voll, 3)
    expect(lw.weitere.map((g) => [g.labels, g.rest])).toEqual([[[], 5], [[], 2]])
    expect(lw.weitereStaerken).toEqual([])
    expect(lw.weitereStaerkenRest).toBe(8)
    expect(duenneLueckenweg(acht, 3).themen).toHaveLength(4)
  })

  it('Stufe 4: höchstens drei Blöcke, nichts verschwindet still', () => {
    const lw = duenneLueckenweg(acht, 4)
    expect(lw.themen).toHaveLength(3)
    expect(lw.weitere[0]).toMatchObject({ spaeter: true, labels: [], rest: 5 })
    expect(lw.weitereStaerkenRest).toBe(5)
    expect(gesamt(duenneLueckenweg(voll, 4))).toBe(gesamt(voll))
  })

  it('jede Stufe behält alle Bereiche (als Name oder Zahl)', () => {
    for (let s = 0; s <= LUECKENWEG_STUFEN; s++) expect(gesamt(duenneLueckenweg(acht, s))).toBe(gesamt(acht))
  })

  it('verändert die Eingabe nicht', () => {
    const kopie = structuredClone(acht)
    duenneLueckenweg(acht, 4)
    expect(acht).toEqual(kopie)
  })
})
