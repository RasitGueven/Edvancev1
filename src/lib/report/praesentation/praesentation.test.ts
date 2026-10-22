import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { klassenAngabe } from '@/lib/report/elternbericht/einordnung'
import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { kurvenPunkte } from '@/lib/report/praesentation/kurve'
import {
  anteileZeile,
  anzeigeZahlen,
  bauePraesentation,
  PROFIL_SOFORT,
  profilReihenfolge,
  uebersprungeneSchluessel,
  zustandAufTablet,
  type PraesentationFehlt,
} from '@/lib/report/praesentation/praesentation'
import type { PraesentationDaten, ReportData } from '@/types'

function baue(name: string): PraesentationDaten {
  const p = bauePraesentation(PRAESENTATION_FAELLE[name])
  if ('fehlt' in p) throw new Error(`${name}: fehlt ${p.fehlt}`)
  return p
}

const r7 = (data: ReportData) => {
  const b = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
    lernweg: { erzaehlung: data.erzaehlung, datum: data.analysedAt },
  })
  if (!b) throw new Error('kein R7-Bericht')
  return b
}

/** Zeile als [sicher, Übungsbedarf ohne übersprungen, übersprungen, vorhanden]. */
const zeilen = (p: PraesentationDaten) =>
  Object.fromEntries(p.zeilen.map((z) => [z.feld, [z.sicher.length, z.uebung.length, z.uebersprungen.length, z.vorhanden]]))

describe('Zustände auf dem Tablet', () => {
  it('traegt sicher, nicht_angesetzt übersprungen, traegt_teilweise/traegt_nicht Übungsbedarf', () => {
    expect(zustandAufTablet('traegt')).toBe('sicher')
    expect(zustandAufTablet('nicht_angesetzt')).toBe('uebersprungen')
    expect(zustandAufTablet('traegt_teilweise')).toBe('uebung')
    expect(zustandAufTablet('traegt_nicht')).toBe('uebung')
  })

  it('gilt auch bei offen = true (vorläufig)', () => {
    const basis = PRAESENTATION_FAELLE.ilkay.data
    const k = basis.erzaehlung.kompetenzen.slice(0, 2)
    const vorlaeufig = [
      { ...k[0], zustand: 'traegt', offen: true },
      { ...k[1], zustand: 'nicht_angesetzt', offen: true },
    ]
    expect([...uebersprungeneSchluessel(vorlaeufig)]).toEqual([k[1].skillKey])
    const p = bauePraesentation({
      data: { ...basis, erzaehlung: { ...basis.erzaehlung, kompetenzen: vorlaeufig } },
      notes: null,
      tiers: [],
    }) as PraesentationDaten
    expect(p.zahlen).toMatchObject({ sicher: 1, uebung: 0, uebersprungen: 1, untersucht: 2 })
  })
})

describe('Doppelte Schlüssel in den Kompetenzen', () => {
  it('der letzte Eintrag gilt, wie in bereicheAus', () => {
    const k = PRAESENTATION_FAELLE.ilkay.data.erzaehlung.kompetenzen[0]
    expect([...uebersprungeneSchluessel([{ ...k, zustand: 'nicht_angesetzt' }, { ...k, zustand: 'traegt' }])]).toEqual([])
    expect([...uebersprungeneSchluessel([{ ...k, zustand: 'traegt_nicht' }, { ...k, zustand: 'nicht_angesetzt' }])]).toEqual([
      k.skillKey,
    ])
  })
})

describe('Gleichheit mit dem Druckbogen R7', () => {
  const faelle = Object.entries(PRAESENTATION_FAELLE).filter(([n]) => n !== 'ohneKatalog')

  it.each(faelle)('%s', (name, fall) => {
    const p = baue(name)
    const b = r7(fall.data)

    expect(p.zahlen.sicher).toBe(b.zaehlung.sicher)
    expect(p.zahlen.uebung + p.zahlen.uebersprungen).toBe(b.zaehlung.uebung)
    expect(p.zahlen.untersucht).toBe(b.zaehlung.untersucht)
    expect(p.zahlen.katalog).toBe(b.zaehlung.katalog)
    expect(p.zahlen.bisKlasse).toBe(b.zaehlung.bisKlasse)

    const mitUntersuchtem = b.profil.filter((z) => z.sicher + z.uebung > 0)
    expect(p.zeilen.map((z) => z.feld)).toEqual(mitUntersuchtem.map((z) => z.feld))
    p.zeilen.forEach((z, i) => {
      const r = mitUntersuchtem[i]
      expect(z.vorhanden).toBe(r.vorhanden)
      expect(z.sicher.length).toBe(r.sicher)
      expect(z.uebung.length + z.uebersprungen.length).toBe(r.uebung)
      for (const liste of [z.sicher, z.uebung, z.uebersprungen]) {
        const sortiert = [...liste].sort(
          (a, c) => a.klasse - c.klasse || a.label.localeCompare(c.label, 'de'),
        )
        expect(liste).toEqual(sortiert)
      }
    })

    expect(p.pyramide.map((e) => [e.ebene, e.stufen])).toEqual(b.pyramide.map((e) => [e.ebene, e.stufen]))
    p.pyramide.forEach((e, i) => {
      expect(e.sicher).toBe(b.pyramide[i].sicher)
      expect(e.uebung + e.uebersprungen).toBe(b.pyramide[i].uebung)
    })

    // Dieselbe Rechnung (R7-11, Entscheidung 6): schwerpunkte.ts, nur um die Stufen ergänzt.
    expect(p.schwerpunkte.map(({ stufen: _stufen, ...s }) => s)).toEqual(b.schwerpunkte)
    expect(p.danach).toEqual(b.danach)
    expect(p.kopfFall).toBe(b.kopfFall)
  })
})

describe('bauePraesentation — Ränder', () => {
  it('ohneKatalog → fehlt katalog', () => {
    expect(bauePraesentation(PRAESENTATION_FAELLE.ohneKatalog)).toEqual<PraesentationFehlt>({ fehlt: 'katalog' })
  })

  it('ohne Kompetenzen → fehlt kompetenzen', () => {
    const { data, notes, tiers } = PRAESENTATION_FAELLE.ilkay
    const leer = { ...data, erzaehlung: { ...data.erzaehlung, kompetenzen: [] } }
    expect(bauePraesentation({ data: leer, notes, tiers })).toEqual({ fehlt: 'kompetenzen' })
  })

  it('laeuftNoch nur bei status in_progress', () => {
    expect(baue('laeuftNoch').laeuftNoch).toBe(true)
    expect(baue('ilkay').laeuftNoch).toBe(false)
  })

  it('Name, Genitiv, Fach, Testlauf', () => {
    const p = baue('ilkay')
    expect([p.name, p.wessen, p.fach, p.klasse, p.testlauf]).toEqual(['Ilkay', 'Ilkays', 'Mathematik', 10, false])
    expect(p.naechstesThema).toBe('Algebra & Funktionen')
    expect(baue('testlauf').testlauf).toBe(true)
    const ohne = baue('ohneName')
    expect([ohne.name, ohne.wessen]).toEqual([null, null])
  })

  it('Rufname wird getrimmt, leer zählt als ohne Namen', () => {
    const { data, notes, tiers } = PRAESENTATION_FAELLE.ilkay
    const p = bauePraesentation({ data: { ...data, firstName: '  Max ' }, notes, tiers }) as PraesentationDaten
    expect([p.name, p.wessen]).toEqual(['Max', 'Max’'])
    const leer = bauePraesentation({ data: { ...data, firstName: '  ' }, notes, tiers }) as PraesentationDaten
    expect(leer.name).toBeNull()
  })

  it('Empfehlung aus den Notizen, ohne Notizen keine', () => {
    expect(baue('ilkay').empfehlung).toEqual({ paket: 'Premium', basis: 'Basic' })
    expect(baue('ohneNotizen').empfehlung).toBeNull()
  })
})

describe('Kontrollwerte aus Anhang C', () => {
  it('ilkay', () => {
    const p = baue('ilkay')
    expect(p.zahlen).toEqual({ sicher: 11, uebung: 16, uebersprungen: 0, untersucht: 27, katalog: 130, bisKlasse: 10 })
    expect(zeilen(p)).toEqual({
      brueche: [2, 3, 0, 8],
      prozent: [1, 3, 0, 9],
      terme: [2, 2, 0, 23],
      geometrie: [1, 5, 0, 40],
      groessen: [3, 2, 0, 6],
      zahlen: [2, 1, 0, 14],
    })
    expect(p.pyramide.map((e) => [e.ebene, klassenAngabe(e.stufen), e.sicher, e.uebung, e.uebersprungen])).toEqual([
      ['weiterfuehrend', { stufe: 'erste' }, 4, 8, 0],
      ['grundlagen', { stufe: 'erprobung' }, 7, 8, 0],
    ])
    expect(p.schwerpunkte.map((s) => [s.feld, klassenAngabe(s.stufen), s.sicher, s.uebung])).toEqual([
      [
        'geometrie',
        { von: 5, bis: 8 },
        ['Fläche von Rechteck und Quadrat'],
        [
          'Umfang von Rechteck und Dreieck',
          'Maßstab',
          'Volumen und Oberfläche des Quaders',
          'Fläche von Dreieck und Parallelogramm',
          'Winkelsummen im Dreieck und Viereck',
        ],
      ],
      ['brueche', { stufe: 'erprobung' }, ['Bruch in Dezimalzahl', 'Brüche kürzen'], ['Brüche addieren', 'Brüche dividieren', 'Brüche multiplizieren']],
      ['groessen', { stufe: 'erprobung' }, ['Längen umrechnen', 'Massen umrechnen', 'Gemischte Schreibweise'], ['Flächeneinheiten', 'Volumeneinheiten']],
      ['prozent', { stufe: 'erste' }, ['Prozentwert berechnen'], ['Grundwert berechnen', 'Prozentsatz berechnen', 'Prozentuale Veränderung']],
    ])
    expect(p.danach).toEqual(['terme', 'zahlen'])
    expect(p.ueberblick.gelungen).toEqual(['groessen', 'zahlen'])
    expect(p.ueberblick.ueben).toEqual(['geometrie', 'brueche', 'prozent', 'terme'])
  })

  it('uebersprungen', () => {
    const p = baue('uebersprungen')
    const ilkay = baue('ilkay')
    expect(p.zahlen).toMatchObject({ sicher: 11, uebung: 13, uebersprungen: 3, untersucht: 27, katalog: 130 })
    expect(anzeigeZahlen(p.zahlen, 'kombiniert')).toEqual({ sicher: 11, uebung: 16, dritte: { wert: 3, art: 'davon' } })
    expect(anzeigeZahlen(p.zahlen, 'getrennt')).toEqual({ sicher: 11, uebung: 13, dritte: { wert: 3, art: 'eigen' } })
    expect(zeilen(p)).toEqual({
      ...zeilen(ilkay),
      prozent: [1, 2, 1, 9],
      terme: [2, 1, 1, 23],
      geometrie: [1, 4, 1, 40],
    })
    expect(p.zeilen.flatMap((z) => z.uebersprungen.map((b) => b.label))).toEqual([
      'Prozentsatz berechnen',
      'Ausklammern',
      'Winkelsummen im Dreieck und Viereck',
    ])
    expect(p.pyramide.map((e) => [e.ebene, e.sicher, e.uebung, e.uebersprungen])).toEqual([
      ['weiterfuehrend', 4, 5, 3],
      ['grundlagen', 7, 8, 0],
    ])
    expect(anzeigeZahlen(p.pyramide[0], 'kombiniert')).toEqual({ sicher: 4, uebung: 8, dritte: { wert: 3, art: 'davon' } })
    expect(p.ueberblick).toEqual(ilkay.ueberblick)
    expect(p.schwerpunkte).toEqual(ilkay.schwerpunkte)
    expect(p.danach).toEqual(ilkay.danach)
  })

  it('alleFelder: acht Zeilen', () => {
    expect(baue('alleFelder').zeilen).toHaveLength(8)
  })

  it('klasse10neu: drei Ebenen, Terme mit Klasse 7–10', () => {
    // Ohne Plan: Mit Plan ist gleichung_quadr_formel (Quadratische Gleichungen kommt noch) ein Vorgriff (LSA-V2)
    // und zählt nicht als Übungsbedarf; hier geht es um die Klassenangabe über drei Stufen.
    const f = PRAESENTATION_FAELLE.klasse10neu
    const ohnePlan = { ...f, data: { ...f.data, erzaehlung: { ...f.data.erzaehlung, plan: null } } }
    const roh = bauePraesentation(ohnePlan)
    if ('fehlt' in roh) throw new Error('klasse10neu: fehlt')
    const p = roh
    expect(p.pyramide.map((e) => [e.ebene, klassenAngabe(e.stufen)])).toEqual([
      ['aktuell', { stufe: 'zweite' }],
      ['weiterfuehrend', { stufe: 'erste' }],
      ['grundlagen', { stufe: 'erprobung' }],
    ])
    const terme = p.schwerpunkte.find((s) => s.feld === 'terme')
    expect(terme && klassenAngabe(terme.stufen)).toEqual({ von: 7, bis: 10 })
  })
})

describe('Schwerpunkt-Fälle', () => {
  it.each([
    ['einSchwerpunkt', 1],
    ['zweiSchwerpunkte', 2],
    ['dreiSchwerpunkte', 3],
    ['ilkay', 4],
  ])('%s → %i Schwerpunkte und ebenso viele Kurvenpunkte', (name, n) => {
    const p = baue(name)
    expect(p.schwerpunkte).toHaveLength(n)
    expect(kurvenPunkte(p.schwerpunkte.length)).toHaveLength(n)
  })

  it('allesSicher: keine Schwerpunkte, keine Kurvenpunkte', () => {
    expect(baue('allesSicher').schwerpunkte).toEqual([])
    expect(kurvenPunkte(0)).toEqual([])
  })
})

describe('anzeigeZahlen', () => {
  it('ohne übersprungen: beide Zählweisen gleich, keine dritte Zahl', () => {
    const a = { sicher: 11, uebung: 16, uebersprungen: 0 }
    expect(anzeigeZahlen(a, 'kombiniert')).toEqual({ sicher: 11, uebung: 16, dritte: null })
    expect(anzeigeZahlen(a, 'getrennt')).toEqual({ sicher: 11, uebung: 16, dritte: null })
  })

  it('mit 3 übersprungen: kombiniert davon, getrennt eigen', () => {
    const a = { sicher: 2, uebung: 1, uebersprungen: 3 }
    expect(anzeigeZahlen(a, 'kombiniert')).toEqual({ sicher: 2, uebung: 4, dritte: { wert: 3, art: 'davon' } })
    expect(anzeigeZahlen(a, 'getrennt')).toEqual({ sicher: 2, uebung: 1, dritte: { wert: 3, art: 'eigen' } })
  })

  it('je Zeile über anteileZeile', () => {
    const geo = baue('uebersprungen').zeilen.find((z) => z.feld === 'geometrie')!
    expect(anzeigeZahlen(anteileZeile(geo), 'kombiniert')).toEqual({ sicher: 1, uebung: 5, dritte: { wert: 1, art: 'davon' } })
    expect(anzeigeZahlen(anteileZeile(geo), 'getrennt')).toEqual({ sicher: 1, uebung: 4, dritte: { wert: 1, art: 'eigen' } })
  })
})

describe('Lernweg (R7-9, Entscheidung 5): eine Rechnung, zwei Darstellungen', () => {
  it('abgestuft: PraesentationDaten.lernweg ist bericht.lernweg', () => {
    const fall = PRAESENTATION_FAELLE.abgestuft
    const e = fall.data.erzaehlung
    const bericht = baueElternbericht({
      kompetenzen: e.kompetenzen,
      katalog: e.katalog,
      klasse: fall.data.grade,
      lernweg: { erzaehlung: e, datum: fall.data.analysedAt },
    })!
    const p = bauePraesentation(fall)
    if ('fehlt' in p) throw new Error('abgestuft ohne Daten')
    expect(bericht.lernweg).not.toBeNull()
    expect(p.lernweg).toEqual(bericht.lernweg)
  })
})

describe('profilReihenfolge (PS-1, Entscheidung 9)', () => {
  const felder = (name: string): string[] => profilReihenfolge(baue(name)).map((z) => z.feld)

  it('ohne Thema: Felder mit Übungsbedarf nach schwerpunkte und danach, dann die sicheren (ilkay)', () => {
    expect(felder('ilkay')).toEqual(['geometrie', 'brueche', 'groessen', 'prozent', 'terme', 'zahlen'])
  })

  it('mit Thema: zuerst das Feld der Startstelle (abgestuft)', () => {
    expect(felder('abgestuft')).toEqual(['zahlen', 'terme', 'geometrie', 'zufall', 'brueche'])
  })

  it('alles sicher: Reihenfolge des Profils', () => {
    const p = baue('allesSicher')
    expect(felder('allesSicher')).toEqual(p.zeilen.map((z) => z.feld))
  })

  it('verliert und verdoppelt keine Zeile; sofort sichtbar sind höchstens vier', () => {
    expect(PROFIL_SOFORT).toBe(4)
    for (const [name] of Object.entries(PRAESENTATION_FAELLE).filter(([n]) => n !== 'ohneKatalog')) {
      const p = baue(name)
      expect([...felder(name)].sort(), name).toEqual(p.zeilen.map((z) => z.feld).sort())
    }
  })
})
