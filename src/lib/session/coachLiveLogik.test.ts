// C1 Tests 1 bis 4 (Regeln): Warteschlange mit Mastery-Obergrenze, Zeitleiste aus dem
// Snapshot, Stundenziel-Satz je Fall, Eingriff Stufe 3 ohne Fehlbild und Vertagen
// ohne Grund. Dazu die Datenquelle, die dieselben Regeln durchsetzt.

import { beforeEach, describe, expect, it } from 'vitest'
import i18n from '@/i18n'
import type { LiveSignal, LiveZiel } from '@/types/coachLive'
import {
  beispielZuruecksetzen,
  eingriffNotieren,
  ladeRaumLive,
  masteryEntscheiden,
} from './coachLive'
import {
  eingriffAbsendbar,
  sortiereWarteschlange,
  vertagenAbsendbar,
  zeitleisteAusSnapshot,
  zielSatz,
} from './coachLiveLogik'

const s = (kindId: string, art: LiveSignal['art'], seit: string): LiveSignal => ({
  kindId, art, grund: 'kandidat', seit: `2026-10-06T${seit}:00.000Z`, wert: null, skill: null, aufgabeNr: null,
})

describe('1 Warteschlange', () => {
  const signale = [
    s('a', 'hinweis', '14:01'),
    s('b', 'haengt', '14:05'),
    s('c', 'kandidat', '14:10'),
    s('d', 'entscheidung', '14:09'),
    s('e', 'haengt', '14:02'),
    s('f', 'kandidat', '14:03'),
  ]

  it('Mastery vor Entscheidung vor hängt vor Hinweis, bei gleicher Art das älteste zuerst', () => {
    const q = sortiereWarteschlange(signale, { masteryJeRaum: 3, masteryEntschieden: 0 })
    expect(q.map((x) => x.kindId)).toEqual(['f', 'c', 'd', 'e', 'b', 'a'])
  })

  it('höchstens mastery_kandidaten_je_raum Mastery-Prüfungen, abzüglich der schon entschiedenen', () => {
    expect(sortiereWarteschlange(signale, { masteryJeRaum: 1, masteryEntschieden: 0 }).map((x) => x.kindId))
      .toEqual(['f', 'd', 'e', 'b', 'a'])
    expect(sortiereWarteschlange(signale, { masteryJeRaum: 3, masteryEntschieden: 3 }).some((x) => x.art === 'kandidat'))
      .toBe(false)
  })
})

describe('2 Zeitleiste aus dem Snapshot', () => {
  it('Check-in 5, Warm-up 10, Check-out 5 ergibt Kernarbeit 40', () => {
    expect(zeitleisteAusSnapshot({ phase_checkin_min: 5, phase_warmup_min: 10, phase_checkout_min: 5 })).toEqual([
      { phase: 'checkin', minuten: 5 },
      { phase: 'warmup', minuten: 10 },
      { phase: 'kern', minuten: 40 },
      { phase: 'checkout', minuten: 5 },
    ])
  })

  it('andere Werte verschieben nur die Kernarbeit', () => {
    expect(zeitleisteAusSnapshot({ phase_checkin_min: 8, phase_warmup_min: 15, phase_checkout_min: 10 })[2].minuten).toBe(27)
  })
})

describe('3 Stundenziel-Satz', () => {
  const ziel = (z: Partial<LiveZiel>): LiveZiel => ({
    fallVorschlag: null, fallCoach: null, themaKey: null, themaLabel: null, klassenarbeit: null, lsaLuecke: null, ...z,
  })
  const satz = (z: LiveZiel): string => {
    const { key, werte } = zielSatz(z)
    return i18n.t(key, { ns: 'coachLive', ...werte })
  }

  it('Klassenarbeit', () => {
    expect(satz(ziel({ fallVorschlag: 'klassenarbeit', klassenarbeit: { datum: '2026-10-08', themaLabel: 'Quadratische Gleichungen' } })))
      .toBe('Quadratische Gleichungen für die Klassenarbeit')
    expect(satz(ziel({ fallVorschlag: 'klassenarbeit' }))).toBe('Klassenarbeit: Thema und Datum fehlen')
  })

  it('Schulthema, die Wahl des Coaches geht vor dem Vorschlag', () => {
    expect(satz(ziel({ fallVorschlag: 'klassenarbeit', fallCoach: 'schulthema', themaLabel: 'Terme und Gleichungen' })))
      .toBe('Terme und Gleichungen durchdringen')
    expect(satz(ziel({ fallVorschlag: 'schulthema' }))).toBe('erst Schulthema wählen')
  })

  it('Lernpfad', () => {
    expect(satz(ziel({ fallVorschlag: 'lernpfad', lsaLuecke: 'Prozentrechnung: Grundwert' })))
      .toBe('Prozentrechnung: Grundwert, aus der LSA')
    expect(satz(ziel({ fallVorschlag: 'lernpfad' }))).toBe('nächste Lücke im Lernpfad')
  })
})

describe('4 nicht absendbar', () => {
  beforeEach(() => beispielZuruecksetzen())

  it('Eingriff ab Stufe 3 ohne Fehlbild', async () => {
    expect(eingriffAbsendbar(2, null)).toBe(true)
    expect(eingriffAbsendbar(3, null)).toBe(false)
    expect(eingriffAbsendbar(4, ' ')).toBe(false)
    expect(eingriffAbsendbar(3, 'minus_klammer_erster_summand')).toBe(true)
    expect((await eingriffNotieren('s1', 'mila', 3, null)).error).toBe('fehlbildPflicht')
    const raum = (await ladeRaumLive('s1')).data
    expect(raum?.kinder.find((k) => k.id === 'mila')?.eingreifen.eingriffe).toEqual([])
  })

  it('Vertagen ohne Grund', async () => {
    expect(vertagenAbsendbar(null)).toBe(false)
    expect(vertagenAbsendbar('  ')).toBe(false)
    expect(vertagenAbsendbar('Ging nur mit Hilfe')).toBe(true)
    const res = await masteryEntscheiden({
      sessionId: 's1', studentId: 'mila', skillKey: 'pyth_hypotenuse', entscheidung: 'vertagt', grund: null,
    })
    expect(res.error).toBe('grundPflicht')
    const raum = (await ladeRaumLive('s1')).data
    expect(raum?.kinder.find((k) => k.id === 'mila')?.masteryKandidat?.entscheidung).toBeNull()
  })
})
