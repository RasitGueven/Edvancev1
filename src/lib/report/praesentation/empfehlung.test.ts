import { afterEach, describe, expect, it, vi } from 'vitest'

import { TIERS } from '@/lib/report/elternbericht/fixtures'
import { empfehlungAus } from '@/lib/report/praesentation/empfehlung'
import type { TierPlan } from '@/types'

const tier = (n: number, name: string, active = true): TierPlan => ({
  id: `t${n}`,
  name,
  price_cents: 12345,
  features: [],
  sort_order: n,
  active,
})

describe('empfehlungAus', () => {
  afterEach(() => vi.restoreAllMocks())

  it('premium → drittes Paket, Basic ebenfalls möglich', () => {
    expect(empfehlungAus('premium', TIERS)).toEqual({ paket: 'Premium', basis: 'Basic' })
  })

  it('standard → zweites Paket, Basic ebenfalls möglich', () => {
    expect(empfehlungAus('standard', TIERS)).toEqual({ paket: 'Standard', basis: 'Basic' })
  })

  it('basis → erstes Paket, ohne Zusatz', () => {
    expect(empfehlungAus('basis', TIERS)).toEqual({ paket: 'Basic', basis: null })
  })

  it('ohne Paket keine Zeile und keine Warnung', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    expect(empfehlungAus(null, TIERS)).toBeNull()
    expect(empfehlungAus(undefined, TIERS)).toBeNull()
    expect(warn).not.toHaveBeenCalled()
  })

  it('zwei aktive Pakete → keine Zeile, mit Warnung', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    expect(empfehlungAus('premium', [tier(1, 'A'), tier(2, 'B')])).toBeNull()
    expect(warn).toHaveBeenCalledTimes(1)
  })

  it('unsortiert → nach sort_order', () => {
    const tiers = [tier(3, 'Drei'), tier(1, 'Eins'), tier(2, 'Zwei')]
    expect(empfehlungAus('standard', tiers)).toEqual({ paket: 'Zwei', basis: 'Eins' })
  })

  it('inaktive dazwischen zählen nicht', () => {
    const tiers = [tier(1, 'Eins'), tier(2, 'Alt', false), tier(3, 'Zwei'), tier(4, 'Drei'), tier(5, 'Weg', false)]
    expect(empfehlungAus('premium', tiers)).toEqual({ paket: 'Drei', basis: 'Eins' })
  })

  it('enthält nie einen Preis', () => {
    const e = empfehlungAus('premium', [tier(1, 'A'), tier(2, 'B'), tier(3, 'C')])
    expect(JSON.stringify(e)).not.toMatch(/12345|price/)
  })
})
