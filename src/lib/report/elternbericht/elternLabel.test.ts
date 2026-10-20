import { describe, expect, it } from 'vitest'

import { ELTERN_WOERTER, elternLabel } from '@/lib/report/elternbericht/elternLabel'
import { KATALOG } from '@/lib/report/elternbericht/fixtures/katalog'

describe('elternLabel (Entscheidung 4)', () => {
  it('löst LGS und Sachsituationen auf', () => {
    expect(elternLabel('LGS aus Sachsituationen aufstellen und lösen')).toBe(
      'Gleichungssysteme aus Sachaufgaben aufstellen und lösen',
    )
    expect(elternLabel('LGS grafisch lösen (Schnittpunkt)')).toBe('Gleichungssysteme grafisch lösen (Schnittpunkt)')
    expect(elternLabel('Sachsituation modellieren')).toBe('Sachaufgabe modellieren')
  })
  it('nur ganze Wörter, sonst unverändert', () => {
    expect(elternLabel('LGSX und XLGS')).toBe('LGSX und XLGS')
    expect(elternLabel('Bruch in Dezimalzahl')).toBe('Bruch in Dezimalzahl')
  })
  it('kein Katalog-Label behält ein bekanntes Kürzel', () => {
    for (const k of KATALOG) {
      for (const [kurz] of ELTERN_WOERTER) expect(elternLabel(k.label), k.label).not.toMatch(new RegExp(`\\b${kurz}\\b`))
    }
  })
})
