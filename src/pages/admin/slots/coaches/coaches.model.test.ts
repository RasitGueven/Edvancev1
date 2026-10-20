// Slots W4, Entscheidung 1–3: Blockbildung, Zielraum besetzt, Konfliktsätze. Reine Funktionen, erfundene Daten.

import { describe, expect, it } from 'vitest'
import type { SlotZeit, Stammschicht } from '@/types/slotplan'
import {
  bloeckeBilden, endetVorher, ersterWochentagAb, konfliktSatzAnlegen, konfliktSatzWechsel, naechsterMontag, standardAb, zielraumBesetzt,
  type CoachDaten,
} from './coaches.model'

// Pause zwischen 15:00 und 16:30: benachbart heißt Nachbar in der Liste, nicht +60 Minuten.
const ZEITEN: SlotZeit[] = [
  { id: 'z14', beginn: '14:00', ende: '15:00' },
  { id: 'z15', beginn: '15:00', ende: '16:00' },
  { id: 'z16', beginn: '16:30', ende: '17:30' },
  { id: 'z17', beginn: '17:30', ende: '18:30' },
]
const MONTAG = '2026-11-02'

const schicht = (id: string, wochentag: number, zeit: string, raum: string, teil: Partial<Stammschicht> = {}): Stammschicht => ({
  id, wochentag, zeit_id: zeit, beginn: ZEITEN.find((z) => z.id === zeit)!.beginn, raum_id: raum, raum_name: raum.toUpperCase(),
  gueltig_ab: '2026-09-01', gueltig_bis: null, kinder: 1, ...teil,
})

const coach = (id: string, name: string, stammschichten: Stammschicht[]): CoachDaten => ({
  id, name, stammschichten, stunden_pro_woche: stammschichten.length, abweichungen: [],
})

describe('bloeckeBilden', () => {
  it('fasst benachbarte Uhrzeiten im selben Raum zu einem Block, über die Pause hinweg; Kinder als Summe je Stunde', () => {
    const b = bloeckeBilden([
      schicht('s3', 1, 'z16', 'a1', { kinder: 4 }), schicht('s1', 1, 'z14', 'a1', { kinder: 2 }),
      schicht('s2', 1, 'z15', 'a1', { kinder: 3 }), schicht('s4', 1, 'z17', 'a1', { kinder: 0 }),
    ], ZEITEN, MONTAG)
    expect(b).toHaveLength(1)
    expect(b[0]).toMatchObject({ wochentag: 1, raumId: 'a1', ids: ['s1', 's2', 's3', 's4'], beginn: '14:00', ende: '18:30', kinder: 9, ab: null })
  })

  it('eine Lücke trennt Blöcke', () => {
    const b = bloeckeBilden([schicht('s1', 2, 'z14', 'a1'), schicht('s3', 2, 'z16', 'a1'), schicht('s4', 2, 'z17', 'a1')], ZEITEN, MONTAG)
    expect(b.map((x) => [x.beginn, x.ende, x.ids])).toEqual([['14:00', '15:00', ['s1']], ['16:30', '18:30', ['s3', 's4']]])
  })

  it('ein anderer Raum trennt Blöcke, ebenso ein anderer Tag', () => {
    const b = bloeckeBilden([
      schicht('s1', 4, 'z14', 'a1'), schicht('s2', 4, 'z15', 'b1'), schicht('s3', 4, 'z16', 'b1'), schicht('s4', 5, 'z17', 'b1'),
    ], ZEITEN, MONTAG)
    expect(b.map((x) => [x.wochentag, x.raumName, x.ids])).toEqual([[4, 'A1', ['s1']], [4, 'B1', ['s2', 's3']], [5, 'B1', ['s4']]])
  })

  it('nimmt je Wochentag, was am Tag der Woche gilt; künftige Schichten bilden eigene Blöcke mit „ab“', () => {
    // Raumwechsel ab Montag 9.11.: bis 8.11. in A1, ab 9.11. in B1. In der Woche ab 2.11. gilt A1.
    const b = bloeckeBilden([
      schicht('alt1', 1, 'z14', 'a1', { gueltig_bis: '2026-11-08' }), schicht('alt2', 1, 'z15', 'a1', { gueltig_bis: '2026-11-08' }),
      schicht('neu1', 1, 'z14', 'b1', { gueltig_ab: '2026-11-09' }), schicht('neu2', 1, 'z15', 'b1', { gueltig_ab: '2026-11-09' }),
      // am Mittwoch 4.11. schon beendet (bis 3.11.): fällt heraus
      schicht('weg', 3, 'z14', 'a1', { gueltig_bis: '2026-11-03' }),
    ], ZEITEN, MONTAG)
    expect(b.map((x) => [x.raumName, x.ids, x.ab, x.gueltigBis])).toEqual([
      ['A1', ['alt1', 'alt2'], null, '2026-11-08'],
      ['B1', ['neu1', 'neu2'], '2026-11-09', null],
    ])
    expect(bloeckeBilden([schicht('neu1', 1, 'z14', 'b1', { gueltig_ab: '2026-11-09' })], ZEITEN, '2026-11-09')[0].ab).toBeNull()
  })

  it('ein anderes Ende trennt (ein Block hat ein gemeinsames „bis“)', () => {
    const b = bloeckeBilden([schicht('s1', 1, 'z14', 'a1', { gueltig_bis: '2026-12-31' }), schicht('s2', 1, 'z15', 'a1')], ZEITEN, MONTAG)
    expect(b).toHaveLength(2)
  })
})

describe('Datum und Zielraum', () => {
  it('nächster Montag; ein künftiger Block frühestens ab seinem Beginn', () => {
    expect(naechsterMontag(new Date('2026-10-20T10:00:00Z'))).toBe('2026-10-26')
    const [b] = bloeckeBilden([schicht('n', 1, 'z14', 'b1', { gueltig_ab: '2026-11-16' })], ZEITEN, MONTAG)
    expect(standardAb(b, '2026-11-09')).toBe('2026-11-16')
    expect(standardAb({ ...b, gueltigAb: '2026-09-01' }, '2026-11-09')).toBe('2026-11-09')
    // Block in einer künftigen Woche: spätestes gueltig_ab der Stunden, nicht das der ersten.
    const [k] = bloeckeBilden([
      schicht('k1', 2, 'z14', 'a1', { gueltig_ab: '2026-11-03' }), schicht('k2', 2, 'z15', 'a1', { gueltig_ab: '2026-11-10' }),
    ], ZEITEN, '2026-11-16')
    expect(k.ids).toEqual(['k1', 'k2'])
    expect(standardAb(k, '2026-10-26')).toBe('2026-11-10')
  })

  it('Zielraum besetzt: andere Schicht im Zielraum zu einer der Zeiten, die ab dem Datum noch gilt', () => {
    const sara = coach('c1', 'Sara Kühn', [schicht('s1', 4, 'z14', 'b1'), schicht('s2', 4, 'z15', 'b1')])
    const jonas = coach('c2', 'Jonas Brandt', [
      schicht('j1', 4, 'z15', 'a1'), schicht('j2', 4, 'z16', 'a1', { gueltig_bis: '2026-11-05' }), schicht('j3', 2, 'z14', 'a1'),
    ])
    const [block] = bloeckeBilden(sara.stammschichten, ZEITEN, MONTAG)
    expect(zielraumBesetzt(block, 'a1', '2026-11-09', [sara, jonas])).toEqual([{ beginn: '15:00', coach: 'Jonas Brandt' }])
    expect(zielraumBesetzt(block, 'c1', '2026-11-09', [sara, jonas])).toEqual([])
  })
})

describe('Konfliktsätze', () => {
  const sara = coach('c1', 'Sara Kühn', [schicht('s1', 4, 'z16', 'a1')])
  const jonas = coach('c2', 'Jonas Brandt', [schicht('j1', 4, 'z16', 'b1')])

  it('SL009 raum: wer den Raum zu der Uhrzeit hat', () => {
    expect(konfliktSatzAnlegen({ code: 'SL009', hint: 'raum:16:30' }, { coachId: 'c1', wochentag: 4, raumId: 'b1', ab: '2026-11-05' }, [sara, jonas], { raum: 'B1', coach: 'Sara Kühn' }))
      .toEqual({ schluessel: 'coaches2.konflikt.raum', werte: { raum: 'B1', beginn: '16:30', coach: 'Jonas Brandt' } })
  })

  it('SL009 coach: in welchem Raum der Coach dann schon ist; ohne Treffer nur mit Uhrzeit', () => {
    expect(konfliktSatzAnlegen({ code: 'SL009', hint: 'coach:16:30' }, { coachId: 'c1', wochentag: 4, raumId: 'b1', ab: '2026-11-05' }, [sara, jonas], { raum: 'B1', coach: 'Sara Kühn' }))
      .toEqual({ schluessel: 'coaches2.konflikt.coach', werte: { coach: 'Sara Kühn', beginn: '16:30', raum: 'A1' } })
    expect(konfliktSatzAnlegen({ code: 'SL009', hint: 'coach:14:00' }, { coachId: 'c1', wochentag: 4, raumId: 'b1', ab: '2026-11-05' }, [sara, jonas], { raum: 'B1', coach: 'Sara Kühn' }))
      .toEqual({ schluessel: 'coaches2.konflikt.coachOhneRaum', werte: { coach: 'Sara Kühn', beginn: '14:00' } })
  })

  it('andere Fehler sind kein Konfliktsatz', () => {
    expect(konfliktSatzAnlegen({ code: '22023', hint: 'von_bis' }, { coachId: 'c1', wochentag: 4, raumId: 'b1', ab: '2026-11-05' }, [sara], { raum: 'B1', coach: 'S' })).toBeNull()
  })

  it('Raumwechsel: SL009 und SL001 mit Uhrzeit, „doppelt“ ohne', () => {
    const [block] = bloeckeBilden(sara.stammschichten, ZEITEN, MONTAG)
    expect(konfliktSatzWechsel({ code: 'SL009', hint: 'raum:16:30' }, block, { id: 'b1', name: 'B1', ab: '2026-11-09' }, [sara, jonas]))
      .toEqual({ schluessel: 'coaches2.konflikt.raum', werte: { raum: 'B1', beginn: '16:30', coach: 'Jonas Brandt' } })
    expect(konfliktSatzWechsel({ code: 'SL001', hint: 'raum:16:30' }, block, { id: 'b1', name: 'B1', ab: '2026-11-09' }, [sara, jonas]))
      .toEqual({ schluessel: 'coaches2.konflikt.voll', werte: { raum: 'B1', beginn: '16:30' } })
    expect(konfliktSatzWechsel({ code: 'SL009', hint: 'doppelt' }, block, { id: 'b1', name: 'B1', ab: '2026-11-09' }, [sara, jonas])).toBeNull()
  })
})

describe('Zweitprüfung', () => {
  it('„ab“ ist der erste Termin an diesem Wochentag, nicht der Beginn mitten in der Woche', () => {
    expect(ersterWochentagAb('2026-10-20', 1)).toBe('2026-10-26')
    expect(ersterWochentagAb('2026-10-20', 2)).toBe('2026-10-20')
    // Montag-Schicht ab Dienstag 20.10.: in der Woche ab 19.10. ein Block „ab 26.10.“
    const [b] = bloeckeBilden([schicht('m', 1, 'z14', 'a1', { gueltig_ab: '2026-10-20' })], ZEITEN, '2026-10-19')
    expect(b.ab).toBe('2026-10-26')
  })

  it('Uhrzeit außerhalb der aktiven Liste: Ende = Beginn plus eine Stunde', () => {
    const fremd = { ...schicht('x', 1, 'z14', 'a1'), zeit_id: 'alt', beginn: '19:00' }
    const [b] = bloeckeBilden([fremd], ZEITEN, MONTAG)
    expect([b.beginn, b.ende]).toEqual(['19:00', '20:00'])
  })

  it('ein Block, der vor dem Standarddatum endet, hat nichts mehr zu ändern', () => {
    const [b] = bloeckeBilden([schicht('s', 1, 'z14', 'a1', { gueltig_bis: '2026-11-08' })], ZEITEN, MONTAG)
    expect(endetVorher(b, standardAb(b, '2026-11-09'))).toBe(true)
    expect(endetVorher(b, '2026-11-05')).toBe(false)
    expect(endetVorher({ ...b, gueltigBis: null }, '2026-11-09')).toBe(false)
  })

  it('Konfliktsatz nimmt die am Prüfdatum gültige Schicht', () => {
    // B1 Do 16:30: bis 08.11. Jonas, ab 09.11. Lea. Geprüft ab 12.11. → Lea.
    const jonas = coach('c2', 'Jonas Brandt', [schicht('j', 4, 'z16', 'b1', { gueltig_bis: '2026-11-08' })])
    const lea = coach('c3', 'Lea Wolf', [schicht('l', 4, 'z16', 'b1', { gueltig_ab: '2026-11-09' })])
    expect(konfliktSatzAnlegen({ code: 'SL009', hint: 'raum:16:30' }, { coachId: 'c1', wochentag: 4, raumId: 'b1', ab: '2026-11-12' },
      [jonas, lea], { raum: 'B1', coach: 'Sara Kühn' })?.werte.coach).toBe('Lea Wolf')
    expect(konfliktSatzAnlegen({ code: 'SL009', hint: 'raum:16:30' }, { coachId: 'c1', wochentag: 4, raumId: 'b1', ab: '2026-11-05' },
      [jonas, lea], { raum: 'B1', coach: 'Sara Kühn' })?.werte.coach).toBe('Jonas Brandt')
  })
})
