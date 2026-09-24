import { describe, expect, it } from 'vitest'
import type { TierPlan } from '@/types'
import { gesamtCents, kondition } from './konditionen'

const standard: TierPlan = {
  id: 't2',
  name: 'Standard',
  price_cents: 26990,
  features: [],
  sort_order: 2,
  active: true,
  laufzeiten: [
    { laufzeit_monate: 12, preis_cents: 26990, einheiten: 57 },
    { laufzeit_monate: 6, preis_cents: 29990, einheiten: 29 },
  ],
}

describe('kondition', () => {
  it('Jahrespaket: 12 Beitraege, Gesamtpreis nach PAngV', () => {
    expect(kondition(standard, 12)).toEqual({
      laufzeit_monate: 12,
      preis_cents: 26990,
      einheiten: 57,
      beitraege: 12,
      gesamt_cents: 323880,
    })
  })

  it('Halbjahrespaket: hoeherer Beitrag, halbe Einheiten, 6 Beitraege', () => {
    expect(kondition(standard, 6)).toEqual({
      laufzeit_monate: 6,
      preis_cents: 29990,
      einheiten: 29,
      beitraege: 6,
      gesamt_cents: 179940,
    })
  })

  it('ohne Paket, Laufzeit oder passende Zeile: null', () => {
    expect(kondition(null, 12)).toBeNull()
    expect(kondition(standard, null)).toBeNull()
    expect(kondition({ ...standard, laufzeiten: undefined }, 12)).toBeNull()
  })
})

describe('gesamtCents', () => {
  it('rechnet in Cent ohne Rundungsfehler', () => {
    expect(gesamtCents(38990, 6)).toBe(233940)
    expect(gesamtCents(19990, 12)).toBe(239880)
  })
})
