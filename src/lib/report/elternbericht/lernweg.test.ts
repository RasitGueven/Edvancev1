import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { KUERZUNGEN, baueLernweg, kuerzeLernweg, zoneFuer, zonenFuer, type LernwegEingabe } from '@/lib/report/elternbericht/lernweg'
import { GRENZEN } from '@/lib/report/elternbericht/lernwegKanten'
import type { EbBereich, Lernweg, LwEintrag, ThemenfeldKey } from '@/types'

const lernwegVon = (fall: keyof typeof FAELLE): Lernweg => {
  const { data } = FAELLE[fall]
  const e = data.erzaehlung
  return baueElternbericht({
    kompetenzen: e.kompetenzen,
    katalog: e.katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: e, datum: data.analysedAt },
  })!.lernweg!
}

/** Alle Einträge mit Insel und Zone, ↳ eingeschlossen. */
const alle = (lw: Lernweg) =>
  lw.zonen.flatMap((z) =>
    z.inseln.flatMap((i) =>
      i.eintraege.flatMap((e) => [
        { ...e, basen: [] as string[], zone: z.key, insel: i, unterVon: null as LwEintrag | null },
        ...e.unter.map((u) => ({ ...u, klasse: null, spaeter: false, unter: [], zone: z.key, insel: i, unterVon: e as LwEintrag | null })),
      ]),
    ),
  )
const per = (lw: Lernweg, label: string) => alle(lw).find((x) => x.label.startsWith(label))!

const b = (skillKey: string, feld: ThemenfeldKey, klasse: number, sicher: boolean): EbBereich => ({
  skillKey,
  label: skillKey,
  feld,
  klasse,
  sicher,
})
const ein = (aenderung: Partial<LernwegEingabe>): LernwegEingabe => ({
  bereiche: [],
  klasse: 9,
  kanten: [],
  katalog: [],
  heimatThemen: [],
  plan: null,
  themaKey: null,
  thema: null,
  datum: null,
  ...aenderung,
})

describe('Zonen je Klasse (Entscheidung 6)', () => {
  it('9/10: Grundlagen, Weiterführend, Aktuell, Kommt noch', () => {
    expect(zonenFuer(9)).toEqual(['grundlagen', 'weiterfuehrend', 'aktuell', 'kommt'])
    expect(zonenFuer(10)).toEqual(['grundlagen', 'weiterfuehrend', 'aktuell', 'kommt'])
  })
  it('7/8: ohne Weiterführend; 5/6: nur Aktuell und Kommt noch', () => {
    expect(zonenFuer(7)).toEqual(['grundlagen', 'aktuell', 'kommt'])
    expect(zonenFuer(6)).toEqual(['aktuell', 'kommt'])
  })
  it('Stoff späterer Klassen steht in Aktuell, mit seiner Klasse', () => {
    expect(zoneFuer(10, 7)).toBe('aktuell')
    expect(zoneFuer(8, 9)).toBe('weiterfuehrend')
    const lw = lernwegVon('spaeter')
    const wurzel = alle(lw).find((x) => x.spaeter)!
    expect(wurzel.zone).toBe('aktuell')
    expect(wurzel.klasse).toBe(9)
  })
  it('klasse7: Grundlagen, Aktuell, Kommt noch', () => {
    expect(lernwegVon('klasse7').zonen.map((z) => z.key)).toEqual(['grundlagen', 'aktuell', 'kommt'])
  })
  it('eine leere Zone zwischen zwei mit Inhalt bleibt, eine führende leere fällt weg', () => {
    const lw = baueLernweg(ein({ bereiche: [b('bruch_a', 'brueche', 5, true), b('zahl_a', 'zahlen', 9, true)] }))
    expect(lw.zonen.map((z) => [z.key, z.inseln.length])).toEqual([
      ['grundlagen', 1],
      ['weiterfuehrend', 0],
      ['aktuell', 1],
      ['kommt', 0],
    ])
    expect(baueLernweg(ein({ bereiche: [b('zahl_a', 'zahlen', 9, true)] })).zonen.map((z) => z.key)).toEqual([
      'aktuell',
      'kommt',
    ])
  })
})

describe('abgestuft (Batu): wie Entwurf und Prototyp', () => {
  const lw = lernwegVon('abgestuft')

  it('Inseln je Zone und Themenfeld, sicher zuerst', () => {
    expect(lw.zonen.map((z) => [z.key, z.inseln.map((i) => i.feld ?? i.titel)])).toEqual([
      ['grundlagen', ['brueche']],
      ['weiterfuehrend', ['terme', 'geometrie', 'zufall']],
      ['aktuell', ['zahlen']],
      [
        'kommt',
        [
          'Quadratische Funktionen',
          'Kreise, Prismen und Zylinder',
          'Potenzen und Potenzgesetze',
          'Der Satz des Pythagoras und Berechnungen in Körpern',
          'Daten und Wahrscheinlichkeit',
        ],
      ],
    ])
    expect(lw.zonen[1].inseln[0].eintraege.map((e) => e.stand)).toEqual(['sicher', 'sicher', 'uebung'])
  })

  it('Linien von „Bruch in Dezimalzahl“ zu Rationale Zahlen, Laplace, Negative Hochzahlen und Vierfeldertafel', () => {
    const bruch = per(lw, 'Bruch in Dezimalzahl')
    const ziele = lw.linien.map((l) => {
      expect(l.von).toBe(bruch.id)
      return alle(lw).find((x) => x.id === l.zu)!
    })
    expect(ziele.map((z) => z.label).sort()).toEqual([
      'Laplace-Wahrscheinlichkeit',
      'Negative Hochzahlen und Hochzahl null',
      'Rationale und irrationale Zahlen',
      'Vierfeldertafel ergänzen',
    ])
    expect(per(lw, 'Negative Hochzahlen').insel.titel).toBe('Potenzen und Potenzgesetze')
    expect(per(lw, 'Vierfeldertafel').insel.titel).toBe('Daten und Wahrscheinlichkeit')
    expect(per(lw, 'Laplace').insel.feld).toBe('zufall')
    expect(per(lw, 'Laplace').stand).toBe('offen')
  })

  it('↳ unter Additionsverfahren (beide Verfahren), Drachen und Raute, Wurzelgesetze', () => {
    const sach = per(lw, 'Gleichungssysteme aus Sachaufgaben')
    expect(sach.unterVon?.label).toBe('Additionsverfahren')
    expect(sach.stand).toBe('offen')
    expect(sach.basen.map((id) => alle(lw).find((x) => x.id === id)!.label)).toEqual(['Einsetzungsverfahren', 'Additionsverfahren'])
    expect(per(lw, 'Zusammengesetzte Vielecke').unterVon?.label).toBe('Flächeninhalt von Drachen und Raute')
    const teilweise = per(lw, 'Teilweise die Wurzel ziehen')
    expect(teilweise.unterVon?.label).toBe('Wurzelgesetze für Produkt und Quotient')
    expect(teilweise.stand).toBe('uebung')
    expect(teilweise.basen).toEqual([per(lw, 'Wurzelgesetze').id])
  })

  it('ein geprüftes Ziel steht nur unter seiner Basis, nicht doppelt', () => {
    expect(alle(lw).filter((x) => x.label === 'Teilweise die Wurzel ziehen')).toHaveLength(1)
  })

  it('Geometrie und Zahlen & Rechnen gebröckelt, sonst nichts', () => {
    const broeckelt = lw.zonen.flatMap((z) => z.inseln).filter((i) => i.broeckelt)
    expect(broeckelt.map((i) => i.feld)).toEqual(['geometrie', 'zahlen'])
  })

  it('Kommt noch beginnt nach Reelle Zahlen; die nächste Klasse kommt als eigene Liste', () => {
    expect(lw.zonen[3].inseln[0].titel).toBe('Quadratische Funktionen')
    expect(lw.naechsteKlasse?.klasse).toBe(10)
    expect(lw.naechsteKlasse?.inseln.map((i) => i.titel)).toHaveLength(6)
    expect(lw.quelle).toBe('schule')
    expect(lw.schulname).toBe('Friedrich-Wilhelm-Gymnasium')
    expect(lw.datum).toBe(FAELLE.abgestuft.data.analysedAt)
  })

  it('Kennungen sind eigene, nie Skill-Schlüssel', () => {
    for (const x of alle(lw)) expect(x.id).toMatch(/^e\d+$/)
    for (const z of lw.zonen) for (const i of z.inseln) expect(i.id).toMatch(/^i\d+$/)
  })
})

describe('Was worauf aufbaut (Entscheidung 8)', () => {
  const katalog = [
    { skillKey: 'zahl_ziel', klasse: 9, label: 'Ziel' },
    { skillKey: 'zahl_ziel2', klasse: 9, label: 'Ziel 2' },
    { skillKey: 'bruch_ziel', klasse: 6, label: 'Bruchziel' },
  ]
  it('Linien nur von sicheren Basen; von Übungsbedarf nur ↳ in der Insel', () => {
    const lw = baueLernweg(
      ein({
        bereiche: [b('bruch_s', 'brueche', 6, true), b('bruch_u', 'brueche', 6, false)],
        katalog,
        kanten: [
          { skillKey: 'zahl_ziel', voraussetzt: 'bruch_s' },
          { skillKey: 'zahl_ziel2', voraussetzt: 'bruch_u' },
          { skillKey: 'bruch_ziel', voraussetzt: 'bruch_u' },
        ],
      }),
    )
    expect(lw.linien).toHaveLength(1)
    expect(per(lw, 'Ziel').stand).toBe('offen')
    expect(alle(lw).some((x) => x.label === 'Ziel 2')).toBe(false)
    expect(per(lw, 'Bruchziel').unterVon?.label).toBe('bruch_u')
  })

  it('Ziel unter dem Plan-Thema über heimatThemen, sonst in der Insel seiner Zone', () => {
    const plan = {
      quelle: 'schule' as const,
      schulname: 'S',
      klasse: 9,
      eintraege: [
        { position: 1, themaKey: 'jetzt', titel: 'Jetzt', halbjahr: null },
        { position: 2, themaKey: 'spaeter', titel: 'Später', halbjahr: null },
      ],
      naechsteKlasse: null,
    }
    const basis = ein({ bereiche: [b('bruch_s', 'brueche', 6, true)], katalog, plan, themaKey: 'jetzt', kanten: [{ skillKey: 'zahl_ziel', voraussetzt: 'bruch_s' }] })
    expect(per(baueLernweg({ ...basis, heimatThemen: [{ skillKey: 'zahl_ziel', themaKey: 'spaeter' }] }), 'Ziel').insel.titel).toBe('Später')
    const ohne = per(baueLernweg(basis), 'Ziel')
    expect(ohne.zone).toBe('aktuell')
    expect(ohne.insel.feld).toBe('zahlen')
  })

  it('Grenzen: höchstens 6 Linien, 2 nicht geprüfte je Insel, 8 insgesamt (vieleKanten)', () => {
    const lw = lernwegVon('vieleKanten')
    expect(lw.linien.length).toBeLessThanOrEqual(GRENZEN.linien)
    const offen = alle(lw).filter((x) => x.stand === 'offen')
    expect(offen.length).toBeLessThanOrEqual(8)
    for (const z of lw.zonen) for (const i of z.inseln) {
      const n = alle(lw).filter((x) => x.insel.id === i.id && x.stand === 'offen').length
      expect(n, i.feld ?? i.titel ?? '').toBeLessThanOrEqual(2)
    }
    // Es gab mehr: gezählt, nicht gezeigt.
    expect(lw.weggelassen.linien).toBeGreaterThan(0)
    expect(lw.weggelassen.offen).toBeGreaterThan(0)
  })

  it('Vorrang: Ziel in Kommt noch vor geprüftem Ziel vor dem Rest', () => {
    const lw = baueLernweg(
      ein({
        bereiche: [b('bruch_s', 'brueche', 6, true), b('zahl_g', 'zahlen', 9, false)],
        katalog,
        plan: { quelle: 'klp', schulname: null, klasse: 9, eintraege: [{ position: 1, themaKey: 't', titel: 'T', halbjahr: null }], naechsteKlasse: null },
        heimatThemen: [{ skillKey: 'zahl_ziel2', themaKey: 't' }],
        kanten: [
          { skillKey: 'zahl_ziel', voraussetzt: 'bruch_s' },
          { skillKey: 'zahl_g', voraussetzt: 'bruch_s' },
          { skillKey: 'zahl_ziel2', voraussetzt: 'bruch_s' },
        ],
      }),
      { ...GRENZEN, linien: 2 },
    )
    expect(lw.linien.map((l) => alle(lw).find((x) => x.id === l.zu)!.label)).toEqual(['Ziel 2', 'zahl_g'])
    expect(lw.weggelassen.linien).toBe(1)
  })

  it('ohneKanten: keine Linien, kein ↳, aber alle Inseln', () => {
    const lw = lernwegVon('ohneKanten')
    expect(lw.linien).toEqual([])
    expect(alle(lw).every((x) => x.unterVon === null)).toBe(true)
    expect(lw.zonen.flatMap((z) => z.inseln).length).toBeGreaterThan(5)
  })
})

describe('Gebröckelt (Entscheidung 10)', () => {
  it('mindestens 2 mit Übungsbedarf und mehr Übungsbedarf als sicher', () => {
    const insel = (sicher: number, uebung: number) =>
      baueLernweg(
        ein({
          bereiche: [
            ...Array.from({ length: sicher }, (_, i) => b(`zahl_s${i}`, 'zahlen', 9, true)),
            ...Array.from({ length: uebung }, (_, i) => b(`zahl_u${i}`, 'zahlen', 9, false)),
          ],
        }),
      ).zonen[0].inseln[0].broeckelt
    expect(insel(0, 2)).toBe(true)
    expect(insel(1, 3)).toBe(true)
    expect(insel(0, 1)).toBe(false)
    expect(insel(2, 2)).toBe(false)
  })
})

describe('Kommt noch (Entscheidung 9)', () => {
  it('planOhneThema: Position nach Datum (März → zweites Halbjahr)', () => {
    const lw = lernwegVon('planOhneThema')
    expect(lw.zonen.at(-1)!.inseln.map((i) => i.titel)).toEqual([
      'Der Satz des Pythagoras und Berechnungen in Körpern',
      'Daten und Wahrscheinlichkeit',
    ])
  })
  it('ilkay: keine Schule → Kernlehrplan NRW 9/10, keine nächste Klasse, höchstens 6', () => {
    const lw = lernwegVon('ilkay')
    expect(lw.quelle).toBe('klp')
    expect(lw.naechsteKlasse).toBeNull()
    expect(lw.zonen.at(-1)!.inseln.length).toBeLessThanOrEqual(6)
    expect(lw.weggelassen.kommt).toBeGreaterThan(0)
  })
  it('ein Plan-Thema, auf das nichts aufbaut, steht trotzdem, nur mit Titel', () => {
    const lw = lernwegVon('abgestuft')
    expect(lw.zonen[3].inseln[0].eintraege).toEqual([])
  })
})

describe('kuerzeLernweg (Entscheidung 18)', () => {
  const lw = lernwegVon('vieleKanten')
  const offen = (x: Lernweg) => alle(x).filter((e) => e.stand === 'offen')

  it('Stufe 1: nicht geprüfte Einträge auf 1 je Insel', () => {
    const k = kuerzeLernweg(lw, KUERZUNGEN[1])
    for (const z of k.zonen) for (const i of z.inseln) {
      expect(alle(k).filter((x) => x.insel.id === i.id && x.stand === 'offen').length).toBeLessThanOrEqual(1)
    }
    expect(offen(k).length).toBeLessThan(offen(lw).length)
    expect(k.weggelassen.offen).toBeGreaterThan(lw.weggelassen.offen)
  })

  it('Stufe 2: Linien auf 4; jede Linie hat Anfang und Ende', () => {
    const k = kuerzeLernweg(lw, KUERZUNGEN[2])
    expect(k.linien.length).toBeLessThanOrEqual(4)
    const ids = new Set(alle(k).map((x) => x.id))
    for (const l of k.linien) {
      expect(ids.has(l.von)).toBe(true)
      expect(ids.has(l.zu)).toBe(true)
    }
    // Kein eigenständiger nicht geprüfter Eintrag ohne Linie.
    const ziele = new Set(k.linien.map((l) => l.zu))
    for (const x of alle(k)) if (x.stand === 'offen' && !x.unterVon) expect(ziele.has(x.id), x.label).toBe(true)
  })

  it('Stufe 3: Kommt noch auf 4 Themen; geprüfte Ziele bleiben', () => {
    const batu = lernwegVon('abgestuft')
    const k = kuerzeLernweg(batu, KUERZUNGEN[3])
    expect(k.zonen.at(-1)!.inseln).toHaveLength(4)
    expect(per(k, 'Teilweise die Wurzel ziehen').unterVon?.label).toBe('Wurzelgesetze für Produkt und Quotient')
    expect(per(k, 'Rationale und irrationale Zahlen')).toBeDefined()
    expect(k.weggelassen.kommt).toBe(1)
  })

  it('Stufe 0 ändert nichts', () => {
    expect(kuerzeLernweg(lw, KUERZUNGEN[0])).toEqual(lw)
  })
})
