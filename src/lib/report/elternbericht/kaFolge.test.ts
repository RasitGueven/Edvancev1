// L5 Teil C (docs/report/Bauauftrag-L5.md, Entscheidungen 8–10): Fahrplan mit bekannter und unbekannter Folge.
import { describe, expect, it } from 'vitest'

import { baueFahrplan } from '@/lib/report/elternbericht/fahrplan'
import { bericht } from '@/lib/report/elternbericht/fixtures/berichtV4Hilfe'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { schlechtestes, schuljahrVon } from '@/lib/report/elternbericht/kaFolge'
import type { EbFahrplan, ReportKlassenarbeit } from '@/types'

const fp = (name: string): EbFahrplan => {
  const f = bericht(name).fahrplan
  if (!f) throw new Error(`kein Fahrplan für ${name}`)
  return f
}

const d = FAELLE.batuV4.data
const EINGABE = {
  plan: d.erzaehlung.plan,
  themaKey: d.erzaehlung.raum?.themaKey ?? null,
  datum: d.analysedAt,
  klassenarbeitStatus: null,
  signale: new Map(),
}
const ka = (nr: number | null, themaKeys: string[], extra: Partial<ReportKlassenarbeit> = {}): ReportKlassenarbeit => ({
  nr,
  themaKeys,
  datum: null,
  status: null,
  note: null,
  herkunft: 'eigen',
  ...extra,
})

describe('Schuljahr und Signal', () => {
  it('Schuljahr nach NRW-Zählung wie ka_schuljahr', () => {
    expect(schuljahrVon('2026-10-24')).toBe('2026/27')
    expect(schuljahrVon('2027-07-31')).toBe('2026/27')
    expect(schuljahrVon('2027-08-01')).toBe('2027/28')
    expect(schuljahrVon('2099-03-01')).toBe('2098/99')
  })

  it('schlechtestes Signal: fehlt vor erfuellt vor ohne', () => {
    expect(schlechtestes(['ohne', 'erfuellt', 'fehlt'])).toBe('fehlt')
    expect(schlechtestes(['ohne', 'erfuellt'])).toBe('erfuellt')
    expect(schlechtestes(['ohne'])).toBe('ohne')
  })
})

describe('Folge bekannt (Entscheidung 10)', () => {
  it('eigene Angaben: Stationen = Arbeiten mit echter Nummer und ihren Themen', () => {
    const f = fp('batuEigen')
    expect(f.folge).toBe('eigen')
    expect(f.stationen.slice(0, 4).map((s) => [s.ka, s.stand, s.themen.map((x) => x.themaKey)])).toEqual([
      [1, 'geschrieben', ['reelle_zahlen']],
      [2, 'naechste', ['quadratische_funktionen']],
      [3, 'voraussichtlich', ['kreis', 'potenzen']],
      [4, 'voraussichtlich', ['pythagoras', 'bedingte_wahrscheinlichkeit']],
    ])
    expect(f.stationen[1].datum).toBe('2026-11-26')
    expect(f.weitere).toBe(0)
  })

  it('Signal einer Arbeit = schlechtestes ihrer Themen (Potenzen allein wäre „ohne“)', () => {
    expect(fp('batuV4').stationen.find((s) => s.themaKey === 'potenzen')?.signal).toBe('ohne')
    expect(fp('batuEigen').stationen.find((s) => s.ka === 3)?.signal).toBe('fehlt')
  })

  it('Schulwert: Folge „schule“', () => {
    expect(fp('batuSchule').folge).toBe('schule')
  })

  it('unvollständige Folge: nur die bekannte Arbeit trägt eine Nummer, sonst Themen ohne Nummer', () => {
    const f = baueFahrplan({ ...EINGABE, arbeiten: [ka(3, ['kreis', 'potenzen'])] })!
    expect(f.folge).toBe('eigen')
    expect(f.stationen.map((s) => [s.ka, s.themaKey])).toEqual([
      [null, 'reelle_zahlen'],
      [3, 'kreis'],
      [null, 'quadratische_funktionen'],
      [null, 'pythagoras'],
      [null, 'bedingte_wahrscheinlichkeit'],
    ])
  })

  it('Arbeiten ohne Nummer erfinden keine Folge', () => {
    const f = baueFahrplan({ ...EINGABE, arbeiten: [ka(null, ['quadratische_funktionen'], { datum: '2026-11-26' })] })!
    expect(f.folge).toBe('unbekannt')
    expect(f.stationen.every((s) => s.ka === null)).toBe(true)
  })

  it('Datum vorbei: die Arbeit gilt als geschrieben (berechnet)', () => {
    const f = baueFahrplan({ ...EINGABE, arbeiten: [ka(1, ['reelle_zahlen'], { datum: '2026-10-20' })] })!
    expect(f.stationen[0]).toMatchObject({ ka: 1, stand: 'geschrieben' })
    const g = baueFahrplan({ ...EINGABE, arbeiten: [ka(1, ['reelle_zahlen'], { datum: '2026-10-30' })] })!
    expect(g.stationen[0]).toMatchObject({ ka: 1, stand: 'naechste' })
    expect(g.stationen[1]).toMatchObject({ ka: null, stand: 'unterricht' })
  })

  it('Themen, die nicht im Plan stehen, entfallen; eine Arbeit ganz ohne Plan-Thema auch', () => {
    const f = baueFahrplan({ ...EINGABE, arbeiten: [ka(2, ['gibt_es_nicht'])] })!
    expect(f.folge).toBe('unbekannt')
  })

  it('alle Arbeiten schon vorbei: Folge gilt als unbekannt (keine Nummer zu zeigen)', () => {
    const f = baueFahrplan({ ...EINGABE, arbeiten: [ka(1, ['zahl_unbekannt_vorher'], { status: 'geschrieben' })] })!
    expect(f.folge).toBe('unbekannt')
  })
})
