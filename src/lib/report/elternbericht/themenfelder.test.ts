import { describe, expect, it } from 'vitest'

import { THEMENFELDER, feldPosition, feldVon } from '@/lib/report/elternbericht/themenfelder'
import { INHALTSBEREICHE } from '@/lib/report/inhaltsbereiche'
import { SKILL_BESTAND } from '@/lib/report/skillBestand'

const ACHT = ['brueche', 'prozent', 'terme', 'geometrie', 'groessen', 'zahlen', 'funktionen', 'zufall']

describe('THEMENFELDER — Gliederung aus Entscheidung 5', () => {
  it('acht Felder in fester Reihenfolge, dann weitere', () => {
    expect(THEMENFELDER.map((f) => f.key)).toEqual([...ACHT, 'weitere'])
    expect(feldPosition('brueche')).toBe(0)
    expect(feldPosition('weitere')).toBe(8)
  })

  it('jeder Inhaltsbereich liegt in genau einem Feld', () => {
    const zugeordnet = THEMENFELDER.flatMap((f) => f.bereiche)
    expect([...zugeordnet].sort()).toEqual([...INHALTSBEREICHE].sort())
  })
})

describe('feldVon', () => {
  it('jeder Skill des Bestands landet in einem der acht Felder, keiner in weitere', () => {
    for (const key of SKILL_BESTAND) expect(ACHT, key).toContain(feldVon(key))
  })

  it('ordnet auch die Skills ohne Familie zu', () => {
    expect(feldVon('potenzen')).toBe('zahlen')
    expect(feldVon('runden_ueberschlag')).toBe('zahlen')
    expect(feldVon('zahl_wurzel_quadrat')).toBe('zahlen')
    expect(feldVon('vorzeichen_vorrang')).toBe('zahlen')
    expect(feldVon('proportionalitaet')).toBe('prozent')
    expect(feldVon('dezimal_div')).toBe('brueche')
    expect(feldVon('gleichung_modellieren')).toBe('terme')
    expect(feldVon('fkt_exp_term')).toBe('funktionen')
    expect(feldVon('stoch_laplace')).toBe('zufall')
  })

  it('Unbekanntes fällt auf weitere', () => {
    expect(feldVon('zz_unbekannt')).toBe('weitere')
  })
})
