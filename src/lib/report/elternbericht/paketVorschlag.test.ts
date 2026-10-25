// Bericht v2, Seite 5: der Paketvorschlag des Systems.
import { describe, expect, it } from 'vitest'

import { PAKET_POSITION, PAKET_REGEL } from '@/lib/report/elternbericht/berichtKonfig'
import { paketVorschlag } from '@/lib/report/elternbericht/paketVorschlag'

describe('paketVorschlag', () => {
  it('Schwellen aus berichtKonfig', () => {
    expect(PAKET_REGEL).toEqual({
      premium: { minAnteil: 0.5, minSchwerpunkte: 3 },
      basic: { maxAnteil: 0.15, maxSchwerpunkte: 1 },
    })
    expect(PAKET_POSITION).toEqual({ basis: 0, standard: 1, premium: 2 })
  })

  it('Premium: Hälfte Übungsbedarf und mindestens drei Schwerpunkte', () => {
    expect(paketVorschlag(3, 10, 20)).toMatchObject({ paket: 'premium', grund: 'breit', schwerpunkte: 3, anteil: 0.5 })
    expect(paketVorschlag(4, 16, 27).paket).toBe('premium')
  })

  it('knapp unter den Premium-Schwellen: Standard', () => {
    expect(paketVorschlag(2, 20, 20).paket).toBe('standard') // zu wenige Schwerpunkte
    expect(paketVorschlag(3, 9, 20).paket).toBe('standard') // Anteil 45 %
  })

  it('Standard nennt den Grund nach der Zahl der Schwerpunkte', () => {
    expect(paketVorschlag(2, 6, 20).grund).toBe('mehrere')
    expect(paketVorschlag(3, 6, 20).grund).toBe('mehrere')
    expect(paketVorschlag(1, 6, 20).grund).toBe('einer')
  })

  it('Basic nur in Ausnahmefällen: höchstens 15 % und höchstens ein Schwerpunkt', () => {
    expect(paketVorschlag(0, 0, 20)).toMatchObject({ paket: 'basis', grund: 'wenig' })
    expect(paketVorschlag(1, 3, 20).paket).toBe('basis') // genau 15 %
    expect(paketVorschlag(1, 4, 20).paket).toBe('standard') // 20 %
    expect(paketVorschlag(2, 1, 20).paket).toBe('standard') // zwei Schwerpunkte
  })

  it('ein Schwerpunkt mit viel Übungsbedarf ist nie Basic und nie Premium', () => {
    expect(paketVorschlag(1, 18, 20)).toMatchObject({ paket: 'standard', grund: 'einer' })
  })

  it('nichts untersucht: Anteil 0 statt NaN', () => {
    const v = paketVorschlag(0, 0, 0)
    expect(v.anteil).toBe(0)
    expect(v.paket).toBe('basis')
  })

  it('gibt Schwerpunkte und Anteil für den Begründungssatz mit', () => {
    expect(paketVorschlag(2, 5, 10)).toMatchObject({ schwerpunkte: 2, anteil: 0.5 })
  })
})
