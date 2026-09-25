import { describe, expect, it } from 'vitest'
import { abweichendeFelder, vermerkFehlt, type AbgleichStand } from './abgleich'

const versendet: AbgleichStand = {
  tier_id: 'premium',
  laufzeit_monate: 6,
  vertragsbeginn: '2027-11-01',
}

describe('abweichendeFelder', () => {
  it('meldet nichts, wenn das Papier dem Versendeten entspricht', () => {
    expect(abweichendeFelder(versendet, { ...versendet })).toEqual([])
  })

  it('meldet das geaenderte Paket', () => {
    expect(abweichendeFelder(versendet, { ...versendet, tier_id: 'standard' })).toEqual(['tier_id'])
  })

  it('meldet mehrere Abweichungen in fester Reihenfolge', () => {
    expect(
      abweichendeFelder(versendet, {
        tier_id: 'basic',
        laufzeit_monate: 12,
        vertragsbeginn: '2027-12-01',
      }),
    ).toEqual(['tier_id', 'laufzeit_monate', 'vertragsbeginn'])
  })

  // Ein leeres Ist-Feld ist eine Luecke, keine Abweichung — sonst verlangte das
  // Formular einen Vermerk, bevor ueberhaupt etwas eingetragen ist.
  it('haelt ein noch leeres Ist-Feld nicht fuer eine Abweichung', () => {
    expect(abweichendeFelder(versendet, { ...versendet, tier_id: null })).toEqual([])
    expect(abweichendeFelder(versendet, { ...versendet, vertragsbeginn: '' })).toEqual([])
  })
})

describe('vermerkFehlt', () => {
  it('verlangt ohne Abweichung keinen Vermerk', () => {
    expect(vermerkFehlt(versendet, { ...versendet }, '')).toBe(false)
  })

  it('verlangt bei Abweichung einen Vermerk', () => {
    expect(vermerkFehlt(versendet, { ...versendet, laufzeit_monate: 12 }, '')).toBe(true)
  })

  it('gibt sich mit Leerzeichen nicht zufrieden', () => {
    expect(vermerkFehlt(versendet, { ...versendet, laufzeit_monate: 12 }, '   ')).toBe(true)
  })

  it('ist zufrieden, sobald etwas dasteht', () => {
    expect(
      vermerkFehlt(versendet, { ...versendet, laufzeit_monate: 12 }, 'Eltern wollten das Jahrespaket'),
    ).toBe(false)
  })
})
