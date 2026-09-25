import { describe, expect, it } from 'vitest'
import type { TierPlan } from '@/types'
import { gesamtCents, kondition, paketOptionen } from './konditionen'

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

const premium: TierPlan = {
  id: 't3',
  name: 'Premium',
  price_cents: 34990,
  features: [],
  sort_order: 3,
  active: true,
  laufzeiten: [
    { laufzeit_monate: 12, preis_cents: 34990, einheiten: 76 },
    { laufzeit_monate: 6, preis_cents: 38990, einheiten: 38 },
  ],
}

describe('paketOptionen', () => {
  // Der Fehler aus dem Klicktest: die Paketauswahl zeigte tiers.price_cents,
  // also immer den Jahrespreis. Ein Wechsel auf Halbjahr aenderte Beitrag und
  // Einheiten darunter, die Auswahl darueber blieb stehen.
  it('wechselt mit der Laufzeit — 12 Monate', () => {
    expect(paketOptionen([standard, premium], 12)).toEqual([
      { id: 't2', name: 'Standard', kondition: kondition(standard, 12) },
      { id: 't3', name: 'Premium', kondition: kondition(premium, 12) },
    ])
  })

  it('wechselt mit der Laufzeit — 6 Monate zeigt andere Zahlen', () => {
    const jahr = paketOptionen([standard, premium], 12)
    const halb = paketOptionen([standard, premium], 6)

    expect(jahr.map((o) => o.kondition?.preis_cents)).toEqual([26990, 34990])
    expect(halb.map((o) => o.kondition?.preis_cents)).toEqual([29990, 38990])
    expect(jahr.map((o) => o.kondition?.einheiten)).toEqual([57, 76])
    expect(halb.map((o) => o.kondition?.einheiten)).toEqual([29, 38])
  })

  it('zeigt Premium im Halbjahr mit 389,90 EUR', () => {
    const premiumHalb = paketOptionen([premium], 6)[0]
    expect(premiumHalb.kondition?.preis_cents).toBe(38990)
    expect(premiumHalb.kondition?.beitraege).toBe(6)
    expect(premiumHalb.kondition?.gesamt_cents).toBe(233940)
  })

  it('ohne Laufzeit steht das Paket ohne Zahlen da', () => {
    expect(paketOptionen([standard, premium], null)).toEqual([
      { id: 't2', name: 'Standard', kondition: null },
      { id: 't3', name: 'Premium', kondition: null },
    ])
  })

  it('behaelt Reihenfolge und Laenge der Tarifliste', () => {
    expect(paketOptionen([], 6)).toEqual([])
    expect(paketOptionen([premium, standard], 6).map((o) => o.name)).toEqual([
      'Premium',
      'Standard',
    ])
  })
})

describe('gesamtCents', () => {
  it('rechnet in Cent ohne Rundungsfehler', () => {
    expect(gesamtCents(38990, 6)).toBe(233940)
    expect(gesamtCents(19990, 12)).toBe(239880)
  })
})
