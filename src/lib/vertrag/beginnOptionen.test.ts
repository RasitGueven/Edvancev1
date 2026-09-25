import { describe, expect, it } from 'vitest'
import { beginnAuswahl, beginnOptionen } from './beginnOptionen'

describe('beginnOptionen', () => {
  it('beginnt mit dem kommenden Monat, nicht mit dem laufenden', () => {
    expect(beginnOptionen('2026-09-25', 3)).toEqual(['2026-10-01', '2026-11-01', '2026-12-01'])
  })

  it('traegt den Jahreswechsel', () => {
    expect(beginnOptionen('2026-11-15', 3)).toEqual(['2026-12-01', '2027-01-01', '2027-02-01'])
  })

  it('liefert achtzehn Monate und endet dort, wo die Rechnung noch traegt', () => {
    const o = beginnOptionen('2026-09-25')
    expect(o).toHaveLength(18)
    expect(o[17]).toBe('2028-03-01')
  })

  it('gibt immer nur Monatserste zurueck', () => {
    expect(beginnOptionen('2026-01-31', 14).every((d) => d.endsWith('-01'))).toBe(true)
  })

  // Der 31.10. ist der Tag der Zeitumstellung. Ueber Millisekunden gerechnet
  // landet der Folgemonat hier eine Stunde zu frueh und damit im Vormonat.
  it('rechnet ueber Jahr und Monat, nicht ueber Millisekunden', () => {
    expect(beginnOptionen('2026-10-31', 2)).toEqual(['2026-11-01', '2026-12-01'])
  })
})

describe('beginnAuswahl', () => {
  it('haelt einen bereits gespeicherten, inzwischen vergangenen Beginn waehlbar', () => {
    const o = beginnAuswahl('2026-09-25', '2026-05-01', 3)
    expect(o[0]).toBe('2026-05-01')
    expect(o).toHaveLength(4)
  })

  it('dupliziert einen Beginn nicht, der ohnehin in der Liste steht', () => {
    expect(beginnAuswahl('2026-09-25', '2026-11-01', 3)).toHaveLength(3)
  })

  it('kommt ohne gespeicherten Wert aus', () => {
    expect(beginnAuswahl('2026-09-25', null, 2)).toEqual(['2026-10-01', '2026-11-01'])
  })
})
