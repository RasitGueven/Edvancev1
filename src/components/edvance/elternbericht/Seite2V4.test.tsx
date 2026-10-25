// Bericht v4, V4-2: Seite 2 mit „Wichtig für“ je Themenfeld.
import { within } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import de from '@/i18n/locales/de/elternbericht.json'
import { bogenV4, MIT_FAHRPLAN } from '@/test/elternberichtV4'
import type { EbBereich, EbFahrplan, EbStation, EbThemaSignal } from '@/types'

import { wichtigFuer } from './wichtigFuer'

const station = (nummer: number, titel: string, stand: EbStation['stand'] = 'voraussichtlich'): EbStation => ({
  nummer,
  themaKey: `t${nummer}`,
  titel,
  halbjahr: null,
  schuljahr: 'dieses',
  stand,
  signal: nummer > 1 ? 'fehlt' : null,
  note: null,
})
const fahrplan = (stationen: EbStation[]): EbFahrplan => ({
  stationen,
  weitere: 0,
  halbjahrTrenner: false,
  klassenTrenner: null,
  quelle: 'klp',
  schulname: null,
  satz: 'fehlt',
})
const bereich = (feld: EbBereich['feld']): EbBereich => ({ skillKey: `s-${feld}`, label: feld, feld, klasse: 7, sicher: false })

describe('wichtigFuer', () => {
  const signale: EbThemaSignal[] = [
    { themaKey: 't2', sitzt: [], fehlt: [bereich('terme')] },
    { themaKey: 't3', sitzt: [bereich('terme')], fehlt: [] },
    { themaKey: 't4', sitzt: [], fehlt: [bereich('terme'), bereich('geometrie')] },
  ]
  const f = fahrplan([station(1, 'A', 'geschrieben'), station(2, 'B', 'naechste'), station(3, 'C'), station(4, 'D')])

  it('die kommenden Stationen, die das Feld betreffen, höchstens zwei in Plan-Reihenfolge', () => {
    expect(wichtigFuer('terme', f, signale)).toEqual([
      { nummer: 2, titel: 'B', naechste: true },
      { nummer: 3, titel: 'C', naechste: false },
    ])
    expect(wichtigFuer('geometrie', f, signale)).toEqual([{ nummer: 4, titel: 'D', naechste: false }])
  })

  it('ein Feld ohne Thema bekommt keine Marke', () => {
    expect(wichtigFuer('zufall', f, signale)).toEqual([])
  })

  it('die aktuelle Station zählt nicht', () => {
    const nur = [{ themaKey: 't1', sitzt: [], fehlt: [bereich('terme')] }]
    expect(wichtigFuer('terme', f, nur)).toEqual([])
  })
})

describe('Seite 2 mit Fahrplan', () => {
  it('batuV4: je Zeile „Wichtig für“ mit Nummer und Titel, die nächste Arbeit navy mit Zusatz', () => {
    const b = bogenV4('batuV4')
    const s2 = within(b.seite(2))
    const zeilen = s2.getAllByTestId('eb-profil-zeile')
    const mit = zeilen.filter((z) => z.querySelector('[data-testid="eb-wichtig"]'))
    expect(mit.length).toBeGreaterThan(0)
    for (const z of mit) {
      const marken = [...z.querySelectorAll('[data-testid="eb-marke"]')]
      expect(marken.length).toBeLessThanOrEqual(2)
      const nummern = marken.map((m) => Number(m.querySelector('b')!.textContent))
      expect(nummern).toEqual([...nummern].sort((x, y) => x - y))
    }
    const naechste = s2.getAllByTestId('eb-marke').filter((m) => m.classList.contains('eb-s2-marke-naechste'))
    expect(naechste.length).toBeGreaterThan(0)
    for (const m of naechste) {
      expect(m.textContent).toContain('Quadratische Funktionen')
      expect(m.textContent).toContain(de.v4.s2.naechste)
    }
    expect(s2.getAllByText(de.v4.s2.wichtig).length).toBe(s2.getAllByTestId('eb-wichtig').filter((p) => p.querySelector('[data-testid="eb-marke"]')).length)
  })

  it('batuV4: Daten & Zufall hat Übungsbedarf, aber kein Thema: „wird in späteren Schuljahren wichtig“', () => {
    const b = bogenV4('batuV4')
    const zeile = within(b.seite(2))
      .getAllByTestId('eb-profil-zeile')
      .find((z) => z.textContent?.includes('Daten & Zufall'))!
    expect(zeile.querySelector('[data-testid="eb-wichtig"]')).toHaveTextContent(de.v4.s2.spaeter)
    expect(zeile.querySelectorAll('[data-testid="eb-marke"]')).toHaveLength(0)
  })

  it('ein Feld ohne Thema und ohne Übungsbedarf bekommt keine Zeile', () => {
    for (const fall of MIT_FAHRPLAN) {
      const b = bogenV4(fall)
      for (const z of within(b.seite(2)).getAllByTestId('eb-profil-zeile')) {
        const w = z.querySelector('[data-testid="eb-wichtig"]')
        if (w) continue
        // keine Zeile: dann nichts Rotes in der Spur
        expect(z.querySelectorAll('.eb-s2-segment-uebung'), fall).toHaveLength(0)
      }
    }
  })

  it('die Legende nennt die Nummer der Klassenarbeit', () => {
    const b = bogenV4('batuV4')
    expect(within(b.seite(2)).getByTestId('eb-legende-nummer')).toHaveTextContent(de.v4.s2.legendeNummer)
  })

  it('„Was die Grafik zeigt“ steht im mint Kasten', () => {
    const b = bogenV4('batuV4')
    expect(within(b.seite(2)).getByTestId('eb-deutung')).toHaveClass('eb-s2-deutung-v4')
  })

  it('Felder aufsteigend nach frühester Klassenstufe', () => {
    const b = bogenV4('batuV4')
    const klassen = within(b.seite(2))
      .getAllByTestId('eb-profil-klasse')
      .map((k) => Number(k.textContent?.match(/\d+/)?.[0]))
    expect(klassen).toEqual([...klassen].sort((x, y) => x - y))
  })

  it('ohnePlan: wie v3, keine „Wichtig für“-Zeilen, keine Legende dazu', () => {
    const b = bogenV4('ohnePlan')
    expect(within(b.seite(2)).queryAllByTestId('eb-wichtig')).toHaveLength(0)
    expect(within(b.seite(2)).queryByTestId('eb-legende-nummer')).toBeNull()
    expect(within(b.seite(2)).getByTestId('eb-deutung')).not.toHaveClass('eb-s2-deutung-v4')
  })
})
