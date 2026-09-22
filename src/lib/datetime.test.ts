import { describe, expect, it } from 'vitest'
import { berlinLocalParts, berlinLocalToIso, berlinToday } from './datetime'

describe('berlinLocalToIso', () => {
  it('rechnet Sommerzeit (UTC+2) um', () => {
    expect(berlinLocalToIso('2026-09-24', '16:30')).toBe('2026-09-24T14:30:00.000Z')
  })

  it('rechnet Winterzeit (UTC+1) um', () => {
    expect(berlinLocalToIso('2026-12-03', '09:00')).toBe('2026-12-03T08:00:00.000Z')
  })

  it('trifft den Tag der Zeitumstellung', () => {
    // 29.03.2026: 02:00 -> 03:00. 10:00 Uhr ist schon Sommerzeit.
    expect(berlinLocalToIso('2026-03-29', '10:00')).toBe('2026-03-29T08:00:00.000Z')
  })
})

describe('berlinLocalParts', () => {
  it('ist die Umkehrung von berlinLocalToIso', () => {
    expect(berlinLocalParts('2026-09-24T14:30:00.000Z')).toEqual({
      date: '2026-09-24',
      time: '16:30',
    })
  })

  it('liefert nach Mitternacht UTC schon den Berliner Folgetag', () => {
    expect(berlinToday(new Date('2026-09-24T22:30:00.000Z'))).toBe('2026-09-25')
  })
})
