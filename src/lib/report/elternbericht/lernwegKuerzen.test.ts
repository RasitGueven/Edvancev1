// R7-12 — kuerzeLernweg: Zeilen je Insel, „+ n weitere“, zusammengefasste
// Zonen, und die Fixture sehrViele über alle Stufen.
import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { GRENZEN, KUERZUNGEN, STUFE_BEREICHE } from '@/lib/report/elternbericht/lernwegKanten'
import { kuerzeLernweg } from '@/lib/report/elternbericht/lernwegKuerzen'
import type { Lernweg, LwEintrag, LwInsel, LwStand, LwUnter, LwZoneKey, ThemenfeldKey } from '@/types'

const e = (id: string, stand: LwStand, unter: LwUnter[] = [], label = `L-${id}`): LwEintrag => ({
  id,
  label,
  stand,
  klasse: 8,
  spaeter: false,
  unter,
})
const u = (id: string, stand: LwStand, basis: string, label = `L-${id}`): LwUnter => ({ id, label, stand, basen: [basis] })
const insel = (id: string, zone: LwZoneKey, feld: ThemenfeldKey, eintraege: LwEintrag[]): LwInsel => ({
  id,
  zone,
  feld,
  titel: null,
  eintraege,
  broeckelt: false,
})
const weg = (zonen: { key: LwZoneKey; inseln: LwInsel[] }[], linien: Lernweg['linien'] = []): Lernweg => ({
  klasse: 9,
  zonen,
  linien,
  naechsteKlasse: null,
  quelle: 'klp',
  schulname: null,
  thema: null,
  datum: null,
  weggelassen: { linien: 0, offen: 0, kommt: 0, eintraege: 0, zonen: 0 },
})

/** Sichtbare Zeilen einer Insel (Einträge und ↳), in Reihenfolge. */
const zeilen = (i: LwInsel): string[] => i.eintraege.flatMap((x) => [x.id, ...x.unter.map((v) => v.id)])
const zeilenStand = (i: LwInsel): string[] => i.eintraege.flatMap((x) => [x.stand, ...x.unter.map((v) => v.stand)])
const inselIn = (lw: Lernweg, id: string): LwInsel => lw.zonen.flatMap((z) => z.inseln).find((i) => i.id === id)!

/** Eine Insel in Aktuell mit 12 Einträgen: 1–8 Übungsbedarf, 9–12 sicher. */
const zwoelf = (): Lernweg =>
  weg([
    { key: 'aktuell', inseln: [insel('i1', 'aktuell', 'geometrie', Array.from({ length: 12 }, (_, n) => e(`e${n + 1}`, n < 8 ? 'uebung' : 'sicher')))] },
  ])

describe('Kürzungsstufen (R7-12, Entscheidung 2)', () => {
  it('Stufe 0 hat 8 je Insel, nichts zusammengefasst; 0–3 bleiben, 4–7 kommen dazu', () => {
    expect(GRENZEN).toMatchObject({ eintraegeJeInsel: 8, zusammenfassen: [] })
    expect(KUERZUNGEN).toHaveLength(8)
    expect(KUERZUNGEN.slice(0, 4).map((g) => g.eintraegeJeInsel)).toEqual([8, 8, 8, 8])
    expect(KUERZUNGEN.slice(4).map((g) => [g.eintraegeJeInsel, g.zusammenfassen])).toEqual([
      [6, []],
      [4, []],
      [4, ['grundlagen']],
      [3, ['grundlagen', 'weiterfuehrend']],
    ])
    expect(KUERZUNGEN[3]).toMatchObject({ offenJeInsel: 1, linien: 4, kommt: 4 })
    expect(STUFE_BEREICHE).toBe(4)
  })

  it('Insel mit 12 Einträgen: 8, 6, 4, 3 Zeilen; „+ n weitere“ zählt den Rest', () => {
    for (const [stufe, n] of [[0, 8], [4, 6], [5, 4], [7, 3]] as const) {
      const k = kuerzeLernweg(zwoelf(), KUERZUNGEN[stufe])
      const i = inselIn(k, 'i1')
      expect(zeilen(i), `Stufe ${stufe}`).toHaveLength(n)
      expect(i.weitere!.uebung + i.weitere!.sicher + i.weitere!.offen).toBe(12 - n)
      expect(i.weitere!.labels).toHaveLength(12 - n)
      expect(k.weggelassen.eintraege).toBe(12 - n)
    }
  })

  it('Übungsbedarf vor sicher; sichtbare Einträge behalten ihre Reihenfolge', () => {
    const lw = weg([{ key: 'aktuell', inseln: [insel('i1', 'aktuell', 'geometrie', [
      e('e1', 'sicher'), e('e2', 'offen'), e('e3', 'uebung'), e('e4', 'sicher'), e('e5', 'uebung'), e('e6', 'uebung'),
    ])] }])
    const i = inselIn(kuerzeLernweg(lw, { ...GRENZEN, eintraegeJeInsel: 4 }), 'i1')
    expect(zeilen(i)).toEqual(['e1', 'e3', 'e5', 'e6'])
    expect(i.weitere).toEqual({ uebung: 0, sicher: 1, offen: 1, vorgriff: 0, labels: ['L-e2', 'L-e4'] })
  })
})

describe('Vorrang in der Insel (R7-12, Entscheidung 3)', () => {
  // e1–e3 sicher, e4 sicher mit Linie, e5 Startstelle (sicher), e6 nächster (offen), e7–e9 Übungsbedarf.
  const vorrang = (): Lernweg =>
    weg(
      [
        { key: 'weiterfuehrend', inseln: [insel('i1', 'weiterfuehrend', 'terme', [e('b1', 'sicher')])] },
        {
          key: 'aktuell',
          inseln: [insel('i2', 'aktuell', 'zahlen', [
            e('e1', 'sicher'), e('e2', 'sicher'), e('e3', 'sicher'), e('e4', 'sicher'),
            e('e5', 'sicher', [], 'Start'), e('e6', 'offen', [], 'Danach'),
            e('e7', 'uebung'), e('e8', 'uebung'), e('e9', 'uebung'),
          ])],
        },
      ],
      [{ von: 'b1', zu: 'e4' }],
    )

  it('a Linienende, b Startstelle und nächster, c Übungsbedarf vor sicher vor offen', () => {
    const k = kuerzeLernweg(vorrang(), { ...GRENZEN, eintraegeJeInsel: 4 }, { start: 'Start', naechster: 'Danach' })
    expect(zeilen(inselIn(k, 'i2'))).toEqual(['e4', 'e5', 'e6', 'e7'])
    const ohneThema = kuerzeLernweg(vorrang(), { ...GRENZEN, eintraegeJeInsel: 4 })
    expect(zeilen(inselIn(ohneThema, 'i2'))).toEqual(['e4', 'e7', 'e8', 'e9'])
  })

  it('d sonst die Reihenfolge der Insel', () => {
    const k = kuerzeLernweg(vorrang(), { ...GRENZEN, eintraegeJeInsel: 6 })
    expect(zeilen(inselIn(k, 'i2'))).toEqual(['e1', 'e2', 'e4', 'e7', 'e8', 'e9'])
  })

  it('doppeltes Label: der erste Treffer gilt als Startstelle', () => {
    const lw = weg([{ key: 'aktuell', inseln: [insel('i1', 'aktuell', 'zahlen', [
      e('e1', 'uebung'), e('e2', 'sicher', [], 'Start'), e('e3', 'uebung'), e('e4', 'sicher', [], 'Start'),
    ])] }])
    const k = kuerzeLernweg(lw, { ...GRENZEN, eintraegeJeInsel: 2 }, { start: 'Start', naechster: null })
    expect(zeilen(inselIn(k, 'i1'))).toEqual(['e1', 'e2'])
  })

  it('Linienenden bleiben immer, auch über die Grenze; ein ↳-Ende bringt seine Basis mit', () => {
    const lw = weg(
      [
        { key: 'weiterfuehrend', inseln: [insel('i1', 'weiterfuehrend', 'terme', [e('b1', 'sicher'), e('b2', 'sicher')])] },
        {
          key: 'aktuell',
          inseln: [insel('i2', 'aktuell', 'zahlen', [
            e('e1', 'uebung'), e('e2', 'uebung'), e('e3', 'sicher', [u('u1', 'uebung', 'e3')]), e('e4', 'sicher'),
          ])],
        },
      ],
      [{ von: 'b1', zu: 'u1' }, { von: 'b2', zu: 'e4' }],
    )
    const k = kuerzeLernweg(lw, { ...GRENZEN, eintraegeJeInsel: 1 })
    expect(zeilen(inselIn(k, 'i2'))).toEqual(['e3', 'u1', 'e4'])
    expect(zeilen(inselIn(k, 'i1'))).toEqual(['b1', 'b2'])
    expect(k.linien).toEqual(lw.linien)
  })

  it('↳ ohne Basis fällt mit und zählt in „+ n weitere“', () => {
    const lw = weg([{ key: 'aktuell', inseln: [insel('i1', 'aktuell', 'zahlen', [
      e('e1', 'uebung'), e('e2', 'uebung'), e('e3', 'sicher', [u('u1', 'uebung', 'e3'), u('u2', 'offen', 'e3')]),
    ])] }])
    const i = inselIn(kuerzeLernweg(lw, { ...GRENZEN, eintraegeJeInsel: 2 }), 'i1')
    expect(zeilen(i)).toEqual(['e1', 'e2'])
    expect(i.weitere).toEqual({ uebung: 1, sicher: 1, offen: 1, vorgriff: 0, labels: ['L-e3', 'L-u1', 'L-u2'] })
  })

  it('↳ mit Übungsbedarf holt seine sichere Basis nach, wenn Platz ist', () => {
    const lw = weg([{ key: 'aktuell', inseln: [insel('i1', 'aktuell', 'zahlen', [
      e('e1', 'sicher', [u('u1', 'uebung', 'e1')]), e('e2', 'sicher'), e('e3', 'sicher'),
    ])] }])
    expect(zeilen(inselIn(kuerzeLernweg(lw, { ...GRENZEN, eintraegeJeInsel: 3 }), 'i1'))).toEqual(['e1', 'u1', 'e2'])
  })
})

describe('Zonen zusammenfassen (R7-12, Entscheidung 5)', () => {
  const lw = (): Lernweg =>
    weg(
      [
        {
          key: 'grundlagen',
          inseln: [
            insel('i1', 'grundlagen', 'brueche', [e('g1', 'sicher'), e('g2', 'uebung', [u('g3', 'uebung', 'g2')]), e('g4', 'offen')]),
            insel('i2', 'grundlagen', 'groessen', [e('g5', 'uebung')]),
            insel('i3', 'grundlagen', 'geometrie', [e('g6', 'offen')]),
          ],
        },
        { key: 'aktuell', inseln: [insel('i4', 'aktuell', 'zahlen', [e('a1', 'uebung'), e('a2', 'sicher')])] },
      ],
      [{ von: 'g1', zu: 'a1' }, { von: 'a2', zu: 'g5' }],
    )

  it('je Themenfeld eine Zählzeile, nur Zahlen > 0; keine Inseln mehr', () => {
    const k = kuerzeLernweg(lw(), { ...GRENZEN, zusammenfassen: ['grundlagen'] })
    const z = k.zonen.find((x) => x.key === 'grundlagen')!
    expect(z.inseln).toEqual([])
    expect(z.zusammen).toEqual({
      id: 'zs-grundlagen',
      zeilen: [
        { feld: 'brueche', sicher: 1, uebung: 2 },
        { feld: 'groessen', sicher: 0, uebung: 1 },
      ],
    })
    expect(k.weggelassen.zonen).toBe(1)
  })

  it('Linien aus der Zone beginnen an der Zählung, Linien in die Zone fallen weg', () => {
    const k = kuerzeLernweg(lw(), { ...GRENZEN, zusammenfassen: ['grundlagen'] })
    expect(k.linien).toEqual([{ von: 'zs-grundlagen', zu: 'a1' }])
    expect(k.weggelassen.linien).toBe(1)
  })

  it('zwei Linien aus der Zone zum selben Ziel werden eine', () => {
    const doppelt = { ...lw(), linien: [{ von: 'g1', zu: 'a1' }, { von: 'g5', zu: 'a1' }] }
    expect(kuerzeLernweg(doppelt, { ...GRENZEN, zusammenfassen: ['grundlagen'] }).linien).toEqual([{ von: 'zs-grundlagen', zu: 'a1' }])
  })

  it('eine leere Zone bleibt, wie sie ist', () => {
    const leer = weg([{ key: 'grundlagen', inseln: [] }, { key: 'aktuell', inseln: [] }])
    const k = kuerzeLernweg(leer, { ...GRENZEN, zusammenfassen: ['grundlagen'] })
    expect(k.zonen[0]).toEqual({ key: 'grundlagen', inseln: [] })
    expect(k.weggelassen.zonen).toBe(0)
  })
})

describe('sehrViele (60 geprüfte Bereiche)', () => {
  const { data } = FAELLE.sehrViele
  const bericht = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
  })!
  const voll = bericht.lernweg!
  const thema = bericht.schwerpunkte.find((s) => s.feld === null) ?? null

  it('60 direkt geprüft, fast alle mit Übungsbedarf, in Grundlagen, Weiterführend und Aktuell', () => {
    expect(data.erzaehlung.kompetenzen).toHaveLength(60)
    // LSA-V2: 17 Bereiche aus Themen, die noch kommen, sitzen nicht und sind Vorgriffe, kein Übungsbedarf.
    const vorgriffe = voll.zonen.flatMap((z) => z.inseln.flatMap(zeilenStand)).filter((s) => s === 'vorgriff').length
    expect(vorgriffe).toBe(17)
    expect(bericht.zaehlung.uebung + vorgriffe).toBeGreaterThanOrEqual(50)
    for (const z of ['grundlagen', 'weiterfuehrend', 'aktuell'] as const) {
      expect(voll.zonen.find((x) => x.key === z)!.inseln.length, z).toBeGreaterThan(0)
    }
    expect(Math.max(...voll.zonen.flatMap((z) => z.inseln.map((i) => zeilen(i).length)))).toBeGreaterThan(8)
  })

  it('jede Stufe hält ihre Grenze, bis auf Linienenden', () => {
    KUERZUNGEN.forEach((g, stufe) => {
      const k = kuerzeLernweg(voll, g, thema)
      const enden = new Set(k.linien.flatMap((l) => [l.von, l.zu]))
      for (const i of k.zonen.flatMap((z) => z.inseln)) {
        const frei = zeilen(i).filter((id) => !enden.has(id))
        expect(frei.length, `Stufe ${stufe}, ${i.id}`).toBeLessThanOrEqual(g.eintraegeJeInsel)
      }
      for (const l of k.linien) {
        const da = new Set([...k.zonen.flatMap((z) => z.inseln.flatMap(zeilen)), ...k.zonen.flatMap((z) => (z.zusammen ? [z.zusammen.id] : []))])
        expect(da.has(l.von) && da.has(l.zu), `Stufe ${stufe}: Linie ${l.von}→${l.zu}`).toBe(true)
      }
      expect(k.weggelassen.zonen).toBe(g.zusammenfassen.length)
    })
  })

  it('kein geprüfter Bereich geht stumm verloren: sichtbar, in „+ n weitere“ oder gezählt', () => {
    const geprueft = (l: Lernweg): LwEintrag[] =>
      l.zonen.flatMap((z) => z.inseln.flatMap((i) => i.eintraege.flatMap((x) => [x, ...x.unter.map((v) => ({ ...x, ...v }))])))
        .filter((x) => x.stand !== 'offen')
    KUERZUNGEN.forEach((g, stufe) => {
      const k = kuerzeLernweg(voll, g, thema)
      const inseln = k.zonen.flatMap((z) => z.inseln)
      const weitere = inseln.reduce((a, i) => a + (i.weitere ? i.weitere.sicher + i.weitere.uebung + i.weitere.vorgriff : 0), 0)
      const gezaehlt = k.zonen.flatMap((z) => z.zusammen?.zeilen ?? []).reduce((a, z) => a + z.sicher + z.uebung, 0)
      expect(geprueft(k).length + weitere + gezaehlt, `Stufe ${stufe}`).toBe(geprueft(voll).length)
      expect(k.weggelassen.eintraege, `Stufe ${stufe}`).toBe(inseln.reduce((a, i) => a + (i.weitere?.labels.length ?? 0), 0))
    })
  })
})
