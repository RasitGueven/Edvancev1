// Bericht v2, Seite 3: Lücken und die kommenden Themen, die direkt darauf aufbauen.
import { describe, expect, it } from 'vitest'

import { LUECKENWEG_STUFEN, baueLueckenweg, duenneLueckenweg, type LueckenwegEingabe } from '@/lib/report/elternbericht/lueckenweg'
import type { EbBereich, EbLueckenweg, LernPlan, PlanEintrag, ThemenfeldKey } from '@/types'

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

describe('baueLueckenweg — kommende Themen', () => {
  it('ordnet jede Lücke den kommenden Themen zu, die direkt auf ihr aufbauen', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: KOMMT,
        bereiche: [bereich('wurzel_ziehen', 'Wurzel ziehen', false), bereich('term_umformen', 'Terme umformen', false)],
      }),
    )
    expect(lw.themen).toEqual([
      { titel: 'Quadratische Gleichungen', halbjahr: 1, luecken: ['Terme umformen', 'Wurzel ziehen'], staerken: [] },
      { titel: 'Kreis', halbjahr: 2, luecken: ['Terme umformen'], staerken: [] },
    ])
  })

  it('trennt Lücken und sichere Bereiche je Thema', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: KOMMT,
        bereiche: [bereich('wurzel_ziehen', 'Wurzel ziehen', true), bereich('term_umformen', 'Terme umformen', false)],
      }),
    )
    expect(lw.themen[0]).toMatchObject({ luecken: ['Terme umformen'], staerken: ['Wurzel ziehen'] })
    expect(lw.staerken).toEqual(['Wurzel ziehen'])
  })

  it('bleibt in der Reihenfolge des Plans, nicht des Graphen', () => {
    const lw = baueLueckenweg(
      eingabe({ ...GRAPH, kommt: [...KOMMT].reverse(), bereiche: [bereich('term_umformen', 'Terme umformen', false)] }),
    )
    expect(lw.themen.map((t) => t.titel)).toEqual(['Kreis', 'Quadratische Gleichungen'])
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

  it('Themen ohne Bezug zu einem geprüften Bereich und ohne themaKey fallen weg', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: [eintrag(1, null, 'Ohne Schlüssel'), eintrag(2, 'unbekannt', 'Ohne Bezug'), ...KOMMT],
        bereiche: [bereich('term_umformen', 'Terme umformen', false)],
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
    expect(lw.themen).toEqual([{ titel: 'Kreis', halbjahr: 1, luecken: ['Terme umformen'], staerken: [] }])
  })

  it('Labels je Thema nach Klasse, dann alphabetisch', () => {
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
    expect(lw.themen[0].luecken).toEqual(['Zebra', 'Anton'])
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

  it('sichere Bereiche ohne Bezug zählen nur in sicherGesamt, nicht in staerken', () => {
    const lw = baueLueckenweg(
      eingabe({
        ...GRAPH,
        kommt: KOMMT,
        bereiche: [bereich('term_umformen', 'Terme umformen', true), bereich('x', 'Anderes', true)],
      }),
    )
    expect(lw.staerken).toEqual(['Terme umformen'])
    expect(lw.sicherGesamt).toBe(2)
  })

  it('ohne Bereiche und ohne Plan: leer', () => {
    expect(baueLueckenweg(eingabe())).toEqual({
      themen: [],
      weitere: [],
      staerken: [],
      sicherGesamt: 0,
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
  const thema = (i: number, luecken: string[], staerken: string[] = []) => ({
    titel: `Thema ${i}`,
    halbjahr: 1 as const,
    luecken,
    staerken,
  })
  const voll: EbLueckenweg = {
    themen: [thema(1, namen(5, 'L'), ['S1'])],
    weitere: [
      { feld: 'brueche', thema: null, labels: namen(5, 'B') },
      { feld: 'terme', thema: null, labels: namen(2, 'T') },
    ],
    staerken: ['S1'],
    sicherGesamt: 4,
    quelle: 'klp',
    schulname: null,
  }
  /** Acht Zeilen mit je einer eigenen Lücke Z1 … Z8. */
  const acht: EbLueckenweg = {
    ...voll,
    themen: Array.from({ length: 8 }, (_, i) => thema(i + 1, [`Z${i + 1}`], [`S${i + 1}`])),
    weitere: [],
    staerken: namen(8, 'S'),
  }
  const mitLuecken = (lw: EbLueckenweg): number => lw.themen.filter((k) => k.luecken.length > 0).length

  it('hat sechs Stufen; Stufe 0 ändert nichts', () => {
    expect(LUECKENWEG_STUFEN).toBe(6)
    expect(duenneLueckenweg(voll, 0)).toBe(voll)
  })

  it('Stufe 1: je Gruppe höchstens drei Namen, der Rest als Zahl; Zeilen unberührt', () => {
    const lw = duenneLueckenweg(voll, 1)
    expect(lw.weitere.map((g) => [g.labels.length, g.rest])).toEqual([[3, 2], [2, 0]])
    expect(lw.themen).toEqual(voll.themen)
    expect(lw.staerken).toEqual(['S1'])
  })

  it('Stufe 1: höchstens sechs Zeilen; die Lücken der übrigen Themen stehen in der Gruppe „spätere Themen“', () => {
    const lw = duenneLueckenweg(acht, 1)
    expect(mitLuecken(lw)).toBe(6)
    expect(lw.weitere[0]).toMatchObject({ feld: null, thema: null, spaeter: true, labels: ['Z7', 'Z8'] })
    // Die gekappten Themen bleiben für den Stärken-Satz in themen, ohne Lücken.
    expect(lw.themen).toHaveLength(8)
    expect(lw.themen[7]).toMatchObject({ titel: 'Thema 8', luecken: [], staerken: ['S8'] })
  })

  it('eine Lücke, die in einer gezeigten Zeile steht, kommt nicht in „spätere Themen“', () => {
    const lw = duenneLueckenweg(
      { ...acht, themen: [...acht.themen.slice(0, 6), thema(7, ['Z1', 'Z7'])] },
      1,
    )
    expect(lw.weitere.find((g) => g.spaeter)?.labels).toEqual(['Z7'])
    const keine = duenneLueckenweg({ ...acht, themen: [...acht.themen.slice(0, 6), thema(7, ['Z1'])] }, 1)
    expect(keine.weitere.some((g) => g.spaeter)).toBe(false)
  })

  it('Stufe 2: höchstens vier Zeilen, je Zeile drei Lücken mit Rest, ohne „Sitzt schon“; Stärken-Liste bleibt', () => {
    const lw = duenneLueckenweg(voll, 2)
    expect(lw.themen[0]).toMatchObject({ luecken: ['L1', 'L2', 'L3'], rest: 2, zeileOhneStaerken: true, staerken: ['S1'] })
    expect(lw.staerken).toEqual(['S1'])
    expect(mitLuecken(duenneLueckenweg(acht, 2))).toBe(4)
  })

  it('Stufe 3: übrige Lücken nur noch als Zahl', () => {
    const lw = duenneLueckenweg(voll, 3)
    expect(lw.weitere.map((g) => [g.labels, g.rest])).toEqual([[[], 5], [[], 2]])
  })

  it('Stufe 4: Stärken nur noch als Zahl (sicherGesamt bleibt), nichts verschwindet still', () => {
    const lw = duenneLueckenweg(voll, 4)
    expect(lw.staerken).toEqual([])
    expect(lw.sicherGesamt).toBe(4)
    expect(lw.themen[0].luecken.length + (lw.themen[0].rest ?? 0)).toBe(5)
  })

  it('Stufe 5: höchstens drei Zeilen', () => {
    const lw = duenneLueckenweg(acht, 5)
    expect(mitLuecken(lw)).toBe(3)
    expect(lw.weitere[0]).toMatchObject({ spaeter: true, labels: [], rest: 5 })
  })

  it('verändert die Eingabe nicht', () => {
    const kopie = structuredClone(acht)
    duenneLueckenweg(acht, 5)
    expect(acht).toEqual(kopie)
  })
})
