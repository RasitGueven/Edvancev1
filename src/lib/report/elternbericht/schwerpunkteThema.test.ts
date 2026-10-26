// Schwerpunkte mit Thema der LSA (R7-11, Entscheidungen 1–5).
import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import {
  MAX_SCHWERPUNKTE,
  planrangVon,
  themaReihenfolge,
  waehleSchwerpunkte,
  type ThemaKontext,
} from '@/lib/report/elternbericht/schwerpunkte'
import type { EbBereich, ReportData, ThemenfeldKey } from '@/types'

const bericht = (d: ReportData, mitQuelle = true) =>
  baueElternbericht({
    kompetenzen: d.erzaehlung.kompetenzen,
    katalog: d.erzaehlung.katalog,
    klasse: d.grade,
    lernweg: mitQuelle ? { erzaehlung: d.erzaehlung, datum: d.analysedAt } : undefined,
  })!

const b = (skillKey: string, feld: ThemenfeldKey, klasse: number, sicher: boolean, label = skillKey): EbBereich => ({
  skillKey,
  label,
  feld,
  klasse,
  sicher,
})

const kontext = (teil: Partial<ThemaKontext> & Pick<ThemaKontext, 'raum'>): ThemaKontext => ({
  thema: 'Thema',
  geprueft: new Set(),
  kanten: [],
  heimatThemen: [],
  kommt: [],
  ...teil,
})

describe('Schwerpunkte mit Thema — Fälle', () => {
  it('abgestuft (Batu): Thema zuerst, Startstelle Wurzelgesetze, Geometrie nicht vorn', () => {
    const { schwerpunkte, danach, uebungListe, sicherListe } = bericht(FAELLE.abgestuft.data)
    expect(schwerpunkte[0]).toEqual({
      feld: null,
      thema: 'Reelle Zahlen',
      gemischt: true,
      sicher: ['Bruch in Dezimalzahl', 'Wurzeln abschätzen und Näherungswerte'],
      uebung: [
        'Wurzelgesetze für Produkt und Quotient',
        'Rationale und irrationale Zahlen',
        'Teilweise die Wurzel ziehen',
      ],
      start: 'Wurzelgesetze für Produkt und Quotient',
      naechster: 'Teilweise die Wurzel ziehen',
    })
    expect(schwerpunkte.map((s) => s.feld)).toEqual([null, 'terme', 'geometrie', 'zufall'])
    expect(danach).toEqual([])
    // Listen auf Seite 1 beginnen mit den Bereichen des Themas.
    expect(uebungListe.slice(0, 3).map((x) => x.label)).toEqual(schwerpunkte[0].uebung)
    expect(sicherListe.slice(0, 2).map((x) => x.label)).toEqual(schwerpunkte[0].sicher)
  })

  it('abgestuftThemaSicher: Thema ohne Übungsbedarf ist kein Schwerpunkt, die Breite beginnt bei 1', () => {
    const r = bericht(FAELLE.abgestuftThemaSicher.data)
    expect(r.schwerpunkte.map((s) => s.feld)).toEqual(['terme', 'geometrie', 'zufall'])
    expect(r.thema).toMatchObject({ titel: 'Reelle Zahlen', uebung: [] })
  })

  it('Thema ohne Übungsbedarf und Breite ohne Übungsbedarf: keine Schwerpunkte', () => {
    const { data } = FAELLE.abgestuftThemaSicher
    const alles = data.erzaehlung.kompetenzen.map((k) => ({ ...k, zustand: 'traegt' }))
    const r = bericht({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: alles } })
    expect(r.schwerpunkte).toEqual([])
    expect(r.danach).toEqual([])
    expect(r.thema?.titel).toBe('Reelle Zahlen')
  })

  it('naechster nur, wenn ein Bereich mit Übungsbedarf direkt auf der Startstelle aufbaut', () => {
    // abgestuftMitOffen: Start „Runden und Überschlag“; darauf baut „Wurzeln abschätzen …“ (Übungsbedarf) auf.
    expect(bericht(FAELLE.abgestuftMitOffen.data).schwerpunkte[0]).toMatchObject({
      start: 'Runden und Überschlag',
      naechster: 'Wurzeln abschätzen und Näherungswerte',
    })
    // abgestuftPlanrang ohne Teilweise die Wurzel ziehen: nichts baut mit Übungsbedarf darauf auf.
    const { data } = FAELLE.abgestuftPlanrang
    const ohne = data.erzaehlung.kompetenzen.filter((k) => k.skillKey !== 'zahl_wurzel_teilweise')
    expect(bericht({ ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: ohne } }).schwerpunkte[0]).toMatchObject({
      start: 'Wurzelgesetze für Produkt und Quotient',
      naechster: null,
    })
  })

  it('abgestuftPlanrang: das Feld für das nächste Plan-Thema vor dem gemischten Feld', () => {
    const { schwerpunkte } = bericht(FAELLE.abgestuftPlanrang.data)
    expect(schwerpunkte.map((s) => s.feld)).toEqual([null, 'geometrie', 'terme'])
    // Nach der alten Regel stünde Terme (gemischt) vorn.
    const ohneThema = bericht(FAELLE.abgestuftPlanrang.data, false).schwerpunkte.map((s) => s.feld)
    expect(ohneThema.indexOf('terme')).toBeLessThan(ohneThema.indexOf('geometrie'))
  })

  it('ilkay: wörtlich wie ohne Thema-Regel (nicht abgestuft)', () => {
    const mit = bericht(FAELLE.ilkay.data)
    const ohne = bericht(FAELLE.ilkay.data, false)
    expect(mit.schwerpunkte).toEqual(ohne.schwerpunkte)
    expect(mit.danach).toEqual(ohne.danach)
    expect(mit.sicherListe).toEqual(ohne.sicherListe)
    expect(mit.uebungListe).toEqual(ohne.uebungListe)
    expect(mit.schwerpunkte.map((s) => s.feld)).toEqual(['geometrie', 'brueche', 'groessen', 'prozent'])
    expect(mit.schwerpunkte.every((s) => s.thema === null && s.start === null && s.naechster === null)).toBe(true)
    expect(mit.thema).toBeNull()
  })

  it('in allen Fällen: höchstens vier, kein Bereich doppelt, abgeleitete zählen nie', () => {
    for (const [name, fall] of Object.entries(FAELLE)) {
      if (name === 'ohneKatalog') continue
      const r = bericht(fall.data)
      expect(r.schwerpunkte.length, name).toBeLessThanOrEqual(MAX_SCHWERPUNKTE)
      expect(r.schwerpunkte.filter((s) => s.thema !== null).length, name).toBeLessThanOrEqual(1)
      const labels = r.schwerpunkte.flatMap((s) => [...s.sicher, ...s.uebung])
      expect(new Set(labels).size, name).toBe(labels.length)
      const direkt = new Set(r.sicherListe.concat(r.uebungListe).map((x) => x.label))
      for (const l of labels) expect(direkt.has(l), `${name}: ${l}`).toBe(true)
    }
  })
})

describe('themaReihenfolge — Voraussetzungen zuerst', () => {
  const raum = new Set(['a', 'x', 'c', 'd', 'e'])

  it('folgt Kanten auch über einen nicht geprüften Zwischenschritt', () => {
    // a → x (nicht geprüft) → c; d ohne Kante
    const kanten = [
      { skillKey: 'x', voraussetzt: 'a' },
      { skillKey: 'c', voraussetzt: 'x' },
    ]
    const bereiche = [b('c', 'zahlen', 5, false), b('d', 'zahlen', 9, false), b('a', 'zahlen', 9, false)]
    expect(themaReihenfolge(bereiche, raum, kanten).map((x) => x.skillKey)).toEqual(['a', 'd', 'c'])
  })

  it('Gleichstand nach Klasse, dann Label', () => {
    const bereiche = [b('d', 'zahlen', 9, false, 'B'), b('e', 'zahlen', 9, false, 'A'), b('a', 'zahlen', 7, false, 'Z')]
    expect(themaReihenfolge(bereiche, raum, []).map((x) => x.label)).toEqual(['Z', 'A', 'B'])
  })

  it('Kanten außerhalb des Raums zählen nicht; ein Kreis hängt die Rechnung nicht auf', () => {
    const kanten = [
      { skillKey: 'a', voraussetzt: 'aussen' },
      { skillKey: 'c', voraussetzt: 'd' },
      { skillKey: 'd', voraussetzt: 'c' },
    ]
    const bereiche = [b('a', 'zahlen', 9, false), b('c', 'zahlen', 9, false), b('d', 'zahlen', 9, false)]
    expect(themaReihenfolge(bereiche, raum, kanten)).toHaveLength(3)
    expect(themaReihenfolge(bereiche, raum, kanten)[0].skillKey).toBe('a')
  })
})

describe('Planrang und Breite', () => {
  const kommt = [
    { position: 2, themaKey: 'eins', titel: 'Eins', halbjahr: null },
    { position: 3, themaKey: 'zwei', titel: 'Zwei', halbjahr: null },
  ]

  it('Heimat-Thema des Bereichs oder eines direkten Nachfolgers; sonst Infinity', () => {
    const rang = planrangVon(
      kontext({
        raum: new Set(),
        kommt,
        heimatThemen: [
          { skillKey: 'p', themaKey: 'zwei' },
          { skillKey: 'nach', themaKey: 'eins' },
        ],
        kanten: [{ skillKey: 'nach', voraussetzt: 'q' }],
      }),
    )
    expect(rang(b('p', 'geometrie', 7, false))).toBe(1)
    expect(rang(b('q', 'geometrie', 7, false))).toBe(0)
    expect(rang(b('r', 'geometrie', 7, false))).toBe(Infinity)
  })

  it('Thema + vier Felder in der Breite: drei Felder, das vierte in danach', () => {
    const bereiche = [
      b('t', 'zahlen', 9, false),
      b('f1', 'brueche', 6, false),
      b('f2', 'prozent', 7, false),
      b('f3', 'geometrie', 8, false),
      b('f4', 'zufall', 8, false),
    ]
    const { schwerpunkte, danach } = waehleSchwerpunkte(bereiche, kontext({ raum: new Set(['t']) }))
    expect(schwerpunkte.map((s) => s.feld)).toEqual([null, 'brueche', 'prozent', 'geometrie'])
    expect(danach).toEqual(['zufall'])
    // Der Bereich des Themas steht nicht noch einmal im Feld „Zahlen & Rechnen“.
    expect(schwerpunkte.some((s) => s.feld === 'zahlen')).toBe(false)
  })

  it('ohne Planrang die alte Regel in der Breite: gemischt vor tiefer Stufe', () => {
    const bereiche = [
      b('t', 'zahlen', 9, false),
      b('f1', 'brueche', 5, false),
      b('f2', 'terme', 8, false),
      b('f3', 'terme', 8, true),
    ]
    const { schwerpunkte } = waehleSchwerpunkte(bereiche, kontext({ raum: new Set(['t']) }))
    expect(schwerpunkte.map((s) => s.feld)).toEqual([null, 'terme', 'brueche'])
  })
})
