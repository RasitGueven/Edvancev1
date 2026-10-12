// F2 Tests 1 und 3 (Regeln, Trockenlauf 10.10.): Der Kopf folgt den Kindern, nicht der Uhr; die Restzeit haengt
// nur an der Uhr; Hinweis „kein Testlauf“ nur ohne Testlauf und nur mit Testkonten.

import { describe, expect, it } from 'vitest'
import type { SessionPhase } from '@/types/sessionLive'
import { imCheckin, phaseDerKinder, restMinuten, testlaufHinweis } from './coachLiveLogik'
import { zeitpunktAus } from './coachLiveTeile'

const am = (...p: (SessionPhase | null)[]) => p.map((phase, i) => ({ tablet: i + 1, phase }))
/** coach_raum_live-Form fuer zeitpunktAus */
const roh = (...p: (SessionPhase | null)[]) => p.map((phase, i) => ({ tablet_nr: i + 1, phase }))
const START = '2026-10-10T12:00:00Z'
const minute = (m: number) => new Date(Date.parse(START) + m * 60_000).toISOString()
const aktiv = { status: 'active', gestartet_am: START }

describe('F2 1 Phase des Kopfs', () => {
  it('Mehrheit der Kinder', () => {
    expect(phaseDerKinder(am('kern', 'kern', 'warmup'))).toBe('kern')
    expect(phaseDerKinder(am('checkin', 'warmup', 'warmup', 'kern'))).toBe('warmup')
  })

  it('Gleichstand: die fruehere Phase', () => {
    expect(phaseDerKinder(am('kern', 'warmup'))).toBe('warmup')
    expect(phaseDerKinder(am('checkout', 'kern', 'kern', 'checkout'))).toBe('kern')
  })

  it('kein Kind mit Tablet: Check-in', () => {
    expect(phaseDerKinder([])).toBe('checkin')
    expect(phaseDerKinder([{ tablet: null, phase: null }, { tablet: null, phase: 'kern' }])).toBe('checkin')
  })

  it('ein Kind voraus: der Kopf bleibt bei den anderen', () => {
    expect(phaseDerKinder(am('checkin', 'checkin', 'kern'))).toBe('checkin')
  })

  it('Kinder ohne Tablet zaehlen nicht mit', () => {
    expect(phaseDerKinder([{ tablet: 1, phase: 'kern' }, { tablet: null, phase: null }, { tablet: null, phase: null }])).toBe('kern')
  })

  it('zeitpunktAus: Uhr zeigt Check-in (Minute 1), das Kind ist in der Kernarbeit -> Kernarbeit', () => {
    expect(zeitpunktAus(aktiv, minute(1), [{ tablet_nr: 1, phase: 'kern' }])).toBe('kern')
  })

  it('zeitpunktAus: Uhr zeigt Kernarbeit (Minute 20), ohne Kind mit Tablet -> Check-in', () => {
    expect(zeitpunktAus(aktiv, minute(20), [{ tablet_nr: null, phase: null }])).toBe('checkin')
  })

  it('zeitpunktAus: vorher, danach und nach 60 Minuten wie bisher', () => {
    expect(zeitpunktAus({ status: 'upcoming', gestartet_am: null }, minute(0), [])).toBe('vorher')
    expect(zeitpunktAus({ status: 'done', gestartet_am: START }, minute(30), roh('kern'))).toBe('danach')
    expect(zeitpunktAus(aktiv, minute(61), roh('checkout'))).toBe('danach')
  })

  it('zeitpunktAus: Check-out folgt der Uhr, auch wenn die Kinder noch in der Kernarbeit sind', () => {
    expect(zeitpunktAus(aktiv, minute(54), roh('kern', 'kern'))).toBe('kern')
    expect(zeitpunktAus(aktiv, minute(55), roh('kern', 'kern'))).toBe('checkout')
    expect(zeitpunktAus(aktiv, minute(59), roh('warmup'))).toBe('checkout')
    // phase_checkout_min aus dem Snapshot
    const zehn = { ...aktiv, einstellungen: { phase_checkout_min: 10 } }
    expect(zeitpunktAus(zehn, minute(50), roh('kern'))).toBe('checkout')
    expect(zeitpunktAus(zehn, minute(49), roh('kern'))).toBe('kern')
  })

  it('Restzeit haengt nur an der Uhr', () => {
    expect(restMinuten(START, minute(0))).toBe(60)
    expect(restMinuten(START, minute(18))).toBe(42)
    expect(restMinuten(START, minute(75))).toBe(0)
    // dieselbe Uhr, ganz andere Phasen der Kinder: der Kopf wechselt, die Restzeit nicht
    expect(zeitpunktAus(aktiv, minute(3), roh('checkin'))).toBe('checkin')
    expect(zeitpunktAus(aktiv, minute(3), roh('kern'))).toBe('kern')
    expect(restMinuten(START, minute(3))).toBe(57)
  })
})

describe('F2 2 Kind im Check-in', () => {
  it('ohne Tablet (nicht als „nicht erschienen“ bestaetigt) oder am Tablet im Check-in', () => {
    expect(imCheckin({ tablet: null, phase: null, nichtErschienen: false })).toBe(true)
    expect(imCheckin({ tablet: null, phase: null, nichtErschienen: true })).toBe(false)
    expect(imCheckin({ tablet: 2, phase: 'checkin', nichtErschienen: false })).toBe(true)
    expect(imCheckin({ tablet: 2, phase: null, nichtErschienen: false })).toBe(true)
    expect(imCheckin({ tablet: 2, phase: 'warmup', nichtErschienen: false })).toBe(false)
  })
})

describe('F2 3 Hinweis „kein Testlauf“', () => {
  const kinder = [
    { id: 'a', wartet: 'pool_leer' as const },
    { id: 'b', wartet: null },
  ]
  const alleTest = () => true

  it('kein Testlauf, alle Testkonten, ein Kind wartet: Hinweis', () => {
    expect(testlaufHinweis({ session: { testlauf: false }, kinder }, alleTest)).toBe(true)
    expect(testlaufHinweis({ session: { testlauf: false }, kinder: [{ id: 'a', wartet: 'kein_ziel' as const }] }, alleTest)).toBe(true)
  })

  it('im Testlauf: kein Hinweis', () => {
    expect(testlaufHinweis({ session: { testlauf: true }, kinder }, alleTest)).toBe(false)
  })

  it('ein Echtkind dabei oder Testkonto noch nicht geladen: kein Hinweis', () => {
    expect(testlaufHinweis({ session: { testlauf: false }, kinder }, (id) => id === 'a')).toBe(false)
    expect(testlaufHinweis({ session: { testlauf: false }, kinder }, (id) => (id === 'a' ? true : undefined))).toBe(false)
  })

  it('niemand wartet: kein Hinweis', () => {
    expect(testlaufHinweis({ session: { testlauf: false }, kinder: [{ id: 'a', wartet: null }] }, alleTest)).toBe(false)
  })
})
