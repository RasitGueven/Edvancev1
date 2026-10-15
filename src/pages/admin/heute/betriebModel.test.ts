// Slots S3: welche Aktion eine Zeile in „Heute im Betrieb“ trägt (erfundene Daten).

import { describe, expect, it } from 'vitest'
import type { TagRaumTermin, TagSessionOhneRaum } from '@/types/slotplan'
import { betriebAktion, type BetriebZeile } from './betriebModel'

const termin: TagRaumTermin = {
  zeit_id: 'z15', beginn: '15:00', ende: '16:00', raum_id: 'r1', raum_name: 'Raum A1', coach_id: 'c1', coach_name: 'ZZ_Coach',
  art: 'stamm', kapazitaet: 5, belegt: 3, session_id: null, gestartet: false, status: null,
}
const ohneRaum: TagSessionOhneRaum = {
  session_id: 'e1', scheduled_at: '2026-10-15T13:00:00Z', room: null, status: 'upcoming', coach_id: 'c1', coach_name: 'ZZ_Coach',
  testlauf: false, gestartet: false, kinder: 1,
}
const raum = (t: Partial<TagRaumTermin>): BetriebZeile => ({ art: 'raum', key: 'r', sortier: 0, t: { ...termin, ...t } })

describe('betriebAktion', () => {
  it('Raum-Termin mit Coach, noch ohne Session: „Session öffnen“ mit Datum, Zeit und Raum', () => {
    expect(betriebAktion(raum({}), '2026-10-15')).toEqual({ art: 'oeffnen', datum: '2026-10-15', zeit_id: 'z15', raum_id: 'r1' })
  })

  it('Raum-Termin ohne Session und ohne Kinder: kein Knopf, auch mit oder ohne Coach (SL013)', () => {
    expect(betriebAktion(raum({ belegt: 0 }), '2026-10-15')).toEqual({ art: 'leer' })
    expect(betriebAktion(raum({ belegt: 0, coach_id: null, coach_name: null }), '2026-10-15')).toEqual({ art: 'leer' })
    expect(betriebAktion(raum({ belegt: 0, session_id: 's9' }), '2026-10-15').art).toBe('live')
  })

  it('Raum-Termin ohne Coach: kein Knopf, Link zur Termin-Seite', () => {
    expect(betriebAktion(raum({ coach_id: null, coach_name: null }), '2026-10-15'))
      .toEqual({ art: 'ohneCoach', ziel: '/admin/slots/termin/2026-10-15/z15' })
  })

  it('Coach fällt aus, noch keine Session: wie ohne Coach', () => {
    expect(betriebAktion(raum({ art: 'faellt_aus' }), '2026-10-15').art).toBe('ohneCoach')
  })

  it('Raum-Termin mit Session (auch ohne Coach): Live-Sicht', () => {
    expect(betriebAktion(raum({ session_id: 's9' }), '2026-10-15')).toEqual({ art: 'live', ziel: '/coach/session/s9/live' })
    expect(betriebAktion(raum({ session_id: 's9', coach_id: null }), '2026-10-15').art).toBe('live')
    expect(betriebAktion(raum({ session_id: 's9', art: 'faellt_aus' }), '2026-10-15').art).toBe('live')
  })

  it('Session ohne Raum: Live-Sicht', () => {
    expect(betriebAktion({ art: 'ohneRaum', key: 's', sortier: 0, s: ohneRaum }, '2026-10-15'))
      .toEqual({ art: 'live', ziel: '/coach/session/e1/live' })
  })
})
