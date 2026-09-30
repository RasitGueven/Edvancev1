import { describe, expect, it } from 'vitest'
import type { BoardSchueler } from '@/types'
import { baueSpalten, gesundheitsTreffer, nachname, sortiere, summeJeZustand } from './board'

function k(over: Partial<BoardSchueler> & { student_id: string }): BoardSchueler {
  return {
    name: 'ZZ_Kind',
    klasse: 9,
    schule: 'ZZ_Gymnasium',
    zustand: 'aktiv',
    ruhend_seit: null,
    letzte_session: null,
    art: 'laufend',
    einheiten: 57,
    beginn: '2027-09-01',
    stichtag: '2028-08-31',
    verbraucht: 10,
    offen: 47,
    soll: 12,
    rueckstand: 2,
    ampel: 'leicht_im_rueckstand',
    ...over,
  }
}

const liste = [
  k({ student_id: 'a', name: 'ZZ_Mia Wenzel', klasse: 8, rueckstand: -0.2 }),
  k({ student_id: 'b', name: 'ZZ_Efe Demir', klasse: 9, schule: 'ZZ_Realschule', rueckstand: 3.2 }),
  k({ student_id: 'c', name: 'ZZ_Elif Yilmaz', klasse: 9, rueckstand: 4.6 }),
  k({ student_id: 'd', name: 'ZZ_Lina Brehm', klasse: 9, art: 'vorher', rueckstand: null }),
  k({ student_id: 'e', name: 'ZZ_Ben Lindner', klasse: 10, zustand: 'ruhend', art: 'keiner', rueckstand: null }),
]

const basis = { zustand: 'aktiv' as const, sucheGlobal: '', sucheSpalte: {}, sortierung: 'nachname' as const }

describe('Board — Spalten und Filter', () => {
  it('eine Spalte je vorhandener Klasse; Zustand "aktiv" blendet ruhende aus', () => {
    const { spalten } = baueSpalten(liste, basis)
    expect(spalten.map((s) => s.klasse)).toEqual([8, 9])
    expect(baueSpalten(liste, { ...basis, zustand: 'alle' }).spalten.map((s) => s.klasse)).toEqual([8, 9, 10])
    expect(baueSpalten(liste, { ...basis, zustand: 'ruhend' }).spalten.map((s) => s.klasse)).toEqual([10])
  })

  it('Spaltensuche aendert nur die eigene Spalte und zaehlt "x von y"', () => {
    const { spalten } = baueSpalten(liste, { ...basis, sucheSpalte: { '9': 'demir' } })
    const neun = spalten.find((s) => s.klasse === 9)!
    expect([neun.sichtbar.length, neun.gesamt]).toEqual([1, 3])
    expect(spalten.find((s) => s.klasse === 8)!.sichtbar).toHaveLength(1)
  })

  it('globale Suche (Schule) wirkt ueber alle Spalten und zusammen mit der Spaltensuche', () => {
    const r = baueSpalten(liste, { ...basis, sucheGlobal: 'gymnasium' })
    expect(r.trefferGesamt).toBe(3)
    const zusammen = baueSpalten(liste, { ...basis, sucheGlobal: 'gymnasium', sucheSpalte: { '9': 'brehm' } })
    expect(zusammen.trefferGesamt).toBe(2)
  })
})

describe('Board — Sortierung', () => {
  it('nach Nachname', () => {
    expect(nachname('ZZ_Efe Demir')).toBe('demir')
    expect(sortiere(liste, 'nachname').map((s) => s.student_id)).toEqual(['d', 'b', 'e', 'a', 'c'])
  })

  it('groesster Rueckstand zuerst, ohne Einheiten-Stand ans Ende', () => {
    expect(sortiere(liste, 'rueckstand').map((s) => s.student_id)).toEqual(['c', 'b', 'a', 'd', 'e'])
  })
})

describe('Anwesenheit und Wortliste', () => {
  it('zaehlt je Zustand', () => {
    const s = summeJeZustand(['present', 'present', 'unexcused', 'cancelled_by_us'])
    expect(s).toEqual({ present: 2, cancelled: 0, unexcused: 1, cancelled_by_us: 1, planned: 0 })
  })

  it('prueft wie die Datenbank: Wortteil bzw. ganzes Wort', () => {
    const w = [
      { wort: 'allergi', nur_ganzes_wort: false },
      { wort: 'ads', nur_ganzes_wort: true },
      { wort: 'ärzt', nur_ganzes_wort: false },
    ]
    expect(gesundheitsTreffer('Hat eine Allergie.', w)).toBe('allergi')
    expect(gesundheitsTreffer('Standardaufgaben sitzen', w)).toBeNull()
    expect(gesundheitsTreffer('Verdacht auf ADS.', w)).toBe('ads')
    expect(gesundheitsTreffer('Laut Ärztin', w)).toBe('ärzt')
  })
})
