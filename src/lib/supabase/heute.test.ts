import { describe, expect, it, vi } from 'vitest'

vi.mock('@/lib/supabase/client', () => ({ supabase: {} }))

import { berlinTagesGrenzen } from './heute'

describe('berlinTagesGrenzen', () => {
  it('Sommerzeit: Berliner Mitternacht ist 22:00 UTC', () => {
    expect(berlinTagesGrenzen(new Date('2026-10-05T10:00:00Z'))).toEqual({
      von: '2026-10-04T22:00:00.000Z',
      bis: '2026-10-05T22:00:00.000Z',
    })
  })

  it('kurz nach Mitternacht zählt schon der neue Tag', () => {
    expect(berlinTagesGrenzen(new Date('2026-10-04T22:30:00Z')).von).toBe('2026-10-04T22:00:00.000Z')
  })

  it('Tag der Zeitumstellung hat 25 Stunden', () => {
    const { von, bis } = berlinTagesGrenzen(new Date('2026-10-25T12:00:00Z'))
    expect(von).toBe('2026-10-24T22:00:00.000Z')
    expect(bis).toBe('2026-10-25T23:00:00.000Z')
  })
})
