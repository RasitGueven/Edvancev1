import { describe, expect, it } from 'vitest'

import { baueElternbericht, gezaehlteBereiche } from '@/lib/report/elternbericht/bericht'
import { ABGESTUFT_URTEILE, fall } from '@/lib/report/elternbericht/fixtures/abgestuft'
import { u } from '@/lib/report/elternbericht/fixtures/basis'
import { KUERZUNGEN, kuerzeLernweg } from '@/lib/report/elternbericht/lernweg'
import { gezaehlt, vorgriffe, vorschauRand, type VorgriffEingabe } from '@/lib/report/elternbericht/vorgriff'
import { bauePraesentation, zustandAufTablet } from '@/lib/report/praesentation/praesentation'
import type { EbBereich, PraesentationDaten, ReportData } from '@/types'

const b = (skillKey: string, sicher = false): EbBereich => ({ skillKey, label: skillKey, feld: 'zahlen', klasse: 8, sicher })

// Thema A; Plan danach U1, U2, U3; nächste Klasse N; Z steht in keinem Plan.
// u1 setzt r (ohne Thema) und x (aus U2) voraus, x setzt y voraus.
const GRUND: VorgriffEingabe = {
  bereiche: ['a', 'a2', 'u1', 'u3', 'n', 'z', 'r', 'x', 'y'].map((k) => b(k)),
  raum: new Set(['a']),
  kanten: [
    { skillKey: 'u1', voraussetzt: 'r' },
    { skillKey: 'u1', voraussetzt: 'x' },
    { skillKey: 'x', voraussetzt: 'y' },
  ],
  heimatThemen: [
    { skillKey: 'a', themaKey: 'A' },
    { skillKey: 'a2', themaKey: 'A' },
    { skillKey: 'u1', themaKey: 'U1' },
    { skillKey: 'x', themaKey: 'U2' },
    { skillKey: 'u3', themaKey: 'U3' },
    { skillKey: 'n', themaKey: 'N' },
    { skillKey: 'z', themaKey: 'Z' },
  ],
  kommt: ['U1', null, 'U2', 'A', 'U3'],
  naechsteKlasse: ['N'],
  themaKey: 'A',
}

describe('vorschauRand (wie lsa_select_next_core, LSA-V)', () => {
  it('Voraussetzungen der nächsten zwei Themen; eine aus einem kommenden Thema wird durch ihren Rand ersetzt', () => {
    expect([...vorschauRand(GRUND)].sort()).toEqual(['r', 'y'])
  })

  it('nur die nächsten zwei Themen: U1 an dritter Stelle — r fällt weg, y bleibt als Rand von U2', () => {
    expect([...vorschauRand({ ...GRUND, kommt: ['U2', 'U3', 'U1'] })]).toEqual(['y'])
  })
})

describe('vorgriffe (Entscheidung 11)', () => {
  it('Heimat in Kommt noch (Klasse oder Klasse + 1), nicht im Raum, nicht am Rand', () => {
    expect([...vorgriffe(GRUND)].sort()).toEqual(['n', 'u1', 'u3', 'x'])
  })

  it('das Thema der Sitzung zählt nicht als „kommt noch“, auch wenn es im Plan wiederkommt', () => {
    expect(vorgriffe(GRUND).has('a2')).toBe(false)
  })

  it('ohne kommende Themen keine Vorgriffe', () => {
    expect(vorgriffe({ ...GRUND, kommt: [], naechsteKlasse: [] }).size).toBe(0)
  })

  it('gezaehlt: sichere Vorgriffe zählen, unsichere nicht', () => {
    const bereiche = [b('u1', true), b('u3'), b('z')]
    expect(gezaehlt(bereiche, new Set(['u1', 'u3'])).map((x) => x.skillKey)).toEqual(['u1', 'z'])
  })
})

// Batu (Klasse 9, Reelle Zahlen, FWG): danach kommen Quadratische Funktionen und Kreise.
const NORMALFORM = u('fkt_quadr_normalform', 'Normalform', 8, 9, 'traegt_nicht', 1, false)
const KREIS = u('geo_kreis_umfang', 'Kreisumfang', 6, 9, 'traegt', 1, false)
const MIT: ReportData = fall('91', { urteile: [...ABGESTUFT_URTEILE, NORMALFORM, KREIS] })
const OHNE: ReportData = fall('92', { urteile: ABGESTUFT_URTEILE })

const bericht = (d: ReportData) =>
  baueElternbericht({
    kompetenzen: d.erzaehlung.kompetenzen,
    katalog: d.erzaehlung.katalog,
    klasse: d.grade,
    lernweg: { erzaehlung: d.erzaehlung, datum: d.analysedAt },
  })!

const praesentation = (d: ReportData): PraesentationDaten => {
  const p = bauePraesentation({ data: d, notes: null, tiers: [] })
  if ('fehlt' in p) throw new Error(p.fehlt)
  return p
}

describe('Bericht: Vorgriffe sind nie Übungsbedarf (Entscheidungen 12–14)', () => {
  const mit = bericht(MIT)
  const ohne = bericht(OHNE)

  it('beide Ausblick-Bereiche sind Vorgriffe', () => {
    const { vorgriff } = gezaehlteBereiche(MIT.erzaehlung.kompetenzen, { erzaehlung: MIT.erzaehlung, datum: MIT.analysedAt })
    expect([...vorgriff].sort()).toEqual(['fkt_quadr_normalform', 'geo_kreis_umfang'])
  })

  it('Zahlen: der unsichere Vorgriff zählt nicht, der sichere als sicher', () => {
    expect(mit.zaehlung.uebung).toBe(ohne.zaehlung.uebung)
    expect(mit.zaehlung.sicher).toBe(ohne.zaehlung.sicher + 1)
    expect(mit.zaehlung.untersucht).toBe(ohne.zaehlung.untersucht + 1)
  })

  it('Listen und Schwerpunkte: Normalform nirgends als Übungsbedarf, Kreisumfang bei „Schon gelungen“', () => {
    expect(mit.uebungListe.map((x) => x.label)).not.toContain('Normalform')
    expect(mit.schwerpunkte.flatMap((s) => s.uebung)).not.toContain('Normalform')
    // Der sichere Vorgriff darf als sicher in einem Schwerpunkt stehen (das Feld wird dann „gemischt“ und
    // rückt nach vorn); der Übungsbedarf bleibt derselbe.
    const uebung = (r: typeof mit) => [...r.schwerpunkte.flatMap((s) => s.uebung), ...r.danach].sort()
    expect(uebung(mit)).toEqual(uebung(ohne))
    expect(mit.sicherListe.map((x) => x.label)).toContain('Kreisumfang')
  })

  it('Lernweg: beide in Kommt noch — Kreisumfang sicher, Normalform „noch nicht behandelt“', () => {
    const kommt = mit.lernweg!.zonen.find((z) => z.key === 'kommt')!
    const eintraege = kommt.inseln.flatMap((i) => i.eintraege)
    expect(eintraege.find((e) => e.label === 'Normalform')?.stand).toBe('vorgriff')
    expect(eintraege.find((e) => e.label === 'Kreisumfang')?.stand).toBe('sicher')
    const anderswo = mit.lernweg!.zonen.filter((z) => z.key !== 'kommt').flatMap((z) => z.inseln.flatMap((i) => i.eintraege))
    expect(anderswo.map((e) => e.label)).not.toContain('Normalform')
  })

  it('Präsentation: dieselben Zahlen, Zeilen und Kette ohne den unsicheren Vorgriff', () => {
    const p = praesentation(MIT)
    const q = praesentation(OHNE)
    expect(p.zahlen.uebung).toBe(q.zahlen.uebung)
    expect(p.zahlen.sicher).toBe(q.zahlen.sicher + 1)
    expect(p.zeilen.flatMap((z) => [...z.uebung, ...z.uebersprungen]).map((x) => x.label)).not.toContain('Normalform')
    expect(p.schwerpunkte.flatMap((s) => s.uebung).sort()).toEqual(q.schwerpunkte.flatMap((s) => s.uebung).sort())
    expect(p.themaWeg).toEqual(q.themaWeg)
  })
})

describe('Lernweg: jeder Vorgriff steht in Kommt noch (Zweitprüfung, Befund 1)', () => {
  // Lösungsformel: Quadratische Gleichungen kommt erst in Klasse 10. Umkehrung: Bedingte Wahrscheinlichkeit ist das
  // fünfte kommende Thema, hinter der Grenze von Kürzungsstufe 3 (vier Themen).
  const FORMEL = u('gleichung_quadr_formel', 'Lösungsformel', 8, 9, 'traegt_nicht', 1, false)
  const UMKEHR = u('stoch_bedingt_umkehr', 'Umkehrung', 7, 9, 'traegt', 1, false)
  const lw = bericht(fall('94', { urteile: [...ABGESTUFT_URTEILE, FORMEL, UMKEHR] })).lernweg!
  const inKommt = (l: typeof lw) =>
    l.zonen.find((z) => z.key === 'kommt')!.inseln.flatMap((i) => i.eintraege.map((e) => `${i.titel}: ${e.label} ${e.stand}`))

  it('Klasse + 1: eigene Insel in Kommt noch, „noch nicht behandelt“', () => {
    expect(inKommt(lw).filter((x) => x.includes('Lösungsformel'))).toHaveLength(1)
    expect(inKommt(lw).find((x) => x.includes('Lösungsformel'))).toMatch(/vorgriff$/)
  })

  it('hinter der Kommt-Grenze: die Insel bleibt, in jeder Kürzungsstufe', () => {
    KUERZUNGEN.forEach((g, stufe) => {
      const k = inKommt(kuerzeLernweg(lw, g))
      expect(k.some((x) => x.includes('Umkehrung sicher')), `Stufe ${stufe}`).toBe(true)
      expect(k.some((x) => x.includes('Lösungsformel vorgriff')), `Stufe ${stufe}`).toBe(true)
    })
  })
})

describe('Vorgriffe nur mit Thema (Rasit, 22.10.2026)', () => {
  const quelle = (d: ReportData) => ({ erzaehlung: d.erzaehlung, datum: d.analysedAt })

  it('mit Thema: ein Bereich aus einem späteren Thema ist Vorgriff, kein Übungsbedarf', () => {
    const { vorgriff, bereiche } = gezaehlteBereiche(MIT.erzaehlung.kompetenzen, quelle(MIT))
    expect(vorgriff.has('fkt_quadr_normalform')).toBe(true)
    expect(bereiche.map((x) => x.skillKey)).not.toContain('fkt_quadr_normalform')
  })

  it('ohne Thema: derselbe Bereich behält seinen Übungsbedarf, wie vor LSA-V2', () => {
    const ohneThema = fall('95', { urteile: [...ABGESTUFT_URTEILE, NORMALFORM, KREIS], raum: null, themaLabel: null })
    const { vorgriff, bereiche } = gezaehlteBereiche(ohneThema.erzaehlung.kompetenzen, quelle(ohneThema))
    expect(vorgriff.size).toBe(0)
    expect(bereiche.find((x) => x.skillKey === 'fkt_quadr_normalform')?.sicher).toBe(false)
    const b = bericht(ohneThema)
    expect(b.uebungListe.map((x) => x.label)).toContain('Normalform')
    expect(b.zaehlung.uebung).toBe(bericht(MIT).zaehlung.uebung + 1)
    const lw = b.lernweg!.zonen.flatMap((z) => z.inseln.flatMap((i) => i.eintraege))
    expect(lw.find((x) => x.label === 'Normalform')?.stand).toBe('uebung')
  })
})

describe('„Weiß ich nicht“ mit einer Probe (LSA-V2, Entscheidung 9): der Report bleibt, wie er ist', () => {
  const WN = u('geo_winkel_dreieck', 'Winkelsumme', 4, 7, 'nicht_angesetzt', 1, false)
  const mit = fall('93', { urteile: [...ABGESTUFT_URTEILE, WN] })

  it('auf dem Tablet „übersprungen“, im Druckbogen Übungsbedarf', () => {
    expect(zustandAufTablet(WN.zustand)).toBe('uebersprungen')
    expect(praesentation(mit).zahlen.uebersprungen).toBe(praesentation(OHNE).zahlen.uebersprungen + 1)
    expect(bericht(mit).zaehlung.uebung).toBe(bericht(OHNE).zaehlung.uebung + 1)
  })
})
