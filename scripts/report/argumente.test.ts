import { describe, expect, it } from 'vitest'

import { zerlegeArgumente } from './build-eltern-report'

/**
 * Regression: `--ohne-nachstellen` wurde erkannt, aber nicht aus den
 * Positionsargumenten entfernt. Der Schalter landete damit als vierte
 * Sitzungs-ID im SQL und der Lauf brach ab:
 *
 *   ERROR: invalid input syntax for type uuid: "--ohne-nachstellen"
 *
 * Aufgefallen ist es erst, als die Migration eingespielt war und der Schalter
 * zum ersten Mal wirklich gebraucht wurde — vorher lief immer der Standardpfad.
 */
describe('zerlegeArgumente', () => {
  const ID_A = 'd8b0d885-b72d-4b68-a17b-6b35db301103'
  const ID_B = '920d00ae-22ed-4eac-88a4-2f7ea719d45d'

  it('liest Ziel und Sitzungen ohne Schalter', () => {
    const r = zerlegeArgumente(['/ziel', ID_A, ID_B])
    expect(r.ziel).toBe('/ziel')
    expect(r.ids).toEqual([ID_A, ID_B])
    expect(r.nachstellen).toBe(true)
  })

  it('haelt den Schalter aus der Sitzungsliste heraus — egal wo er steht', () => {
    for (const argv of [
      ['/ziel', ID_A, ID_B, '--ohne-nachstellen'],
      ['/ziel', '--ohne-nachstellen', ID_A, ID_B],
      ['--ohne-nachstellen', '/ziel', ID_A, ID_B],
    ]) {
      const r = zerlegeArgumente(argv)
      expect(r.ziel, argv.join(' ')).toBe('/ziel')
      expect(r.ids, argv.join(' ')).toEqual([ID_A, ID_B])
      expect(r.nachstellen, argv.join(' ')).toBe(false)
    }
  })

  it('laesst einen unbekannten Schalter nicht als Sitzung durchgehen', () => {
    const r = zerlegeArgumente(['/ziel', ID_A, '--tippfehler'])
    expect(r.ids).toEqual([ID_A])
    // Unbekannt heisst nicht "nachstellen aus" — der Standardpfad bleibt.
    expect(r.nachstellen).toBe(true)
  })

  it('meldet fehlende Argumente als leer, statt etwas zu erfinden', () => {
    expect(zerlegeArgumente([])).toEqual({
      ziel: undefined,
      ids: [],
      nachstellen: true,
    })
    expect(zerlegeArgumente(['--ohne-nachstellen'])).toEqual({
      ziel: undefined,
      ids: [],
      nachstellen: false,
    })
  })
})
