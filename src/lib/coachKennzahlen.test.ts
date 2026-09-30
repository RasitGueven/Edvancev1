import { describe, expect, it } from 'vitest'
import type { CoachingSession } from '@/types'
import { amSelbenBerlinerTag, naechsteSession } from './coachKennzahlen'

const s = (id: string, scheduled_at: string, status: CoachingSession['status'] = 'upcoming'): CoachingSession => ({
  id, scheduled_at, status, created_at: scheduled_at, coach_id: 'ZZ_coach', room: null,
})

describe('naechsteSession', () => {
  const jetzt = Date.parse('2026-09-30T10:00:00Z')

  it('ignoriert vergangene Sessions mit Status upcoming (Prod-Befund)', () => {
    const liste = [s('alt', '2026-09-04T07:00:00Z'), s('neu', '2026-10-02T14:00:00Z')]
    expect(naechsteSession(liste, jetzt)?.id).toBe('neu')
  })

  it('ignoriert erledigte, nimmt laufende ab jetzt', () => {
    const liste = [s('fertig', '2026-09-30T12:00:00Z', 'done'), s('spaeter', '2026-09-30T15:00:00Z', 'active')]
    expect(naechsteSession(liste, jetzt)?.id).toBe('spaeter')
  })

  it('ohne kommende Session: null', () => {
    expect(naechsteSession([s('alt', '2026-09-04T07:00:00Z')], jetzt)).toBeNull()
  })
})

describe('amSelbenBerlinerTag', () => {
  it('rechnet nach Berliner Datum, nicht UTC', () => {
    // 23:30 UTC am 30.09. ist in Berlin schon der 01.10.
    expect(amSelbenBerlinerTag('2026-09-30T23:30:00Z', '2026-10-01T08:00:00Z')).toBe(true)
    expect(amSelbenBerlinerTag('2026-09-30T21:30:00Z', '2026-10-01T08:00:00Z')).toBe(false)
  })
})
