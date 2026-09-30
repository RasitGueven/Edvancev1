// Kachel Fortschritt (S3): Anzeige dessen, was fortschritt() liefert —
// ohne eigene Rechnung, "gemeistert" nur bei Coach-Bestaetigung.

import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'
import type { FachFortschritt } from '@/types'
import { FortschrittKachel } from './FortschrittKachel'

const k = (n: number, am: string) => ({ kompetenz: `ZZ_Kompetenz ${n}`, prozess: 'Operieren', coach: 'ZZ Coach', am })

describe('FortschrittKachel', () => {
  it('zeigt Thema, Station x von y und hoechstens vier bestaetigte Kompetenzen, dann "und n weitere"', () => {
    const faecher: FachFortschritt[] = [
      {
        fach_id: 'm', fach: 'Mathematik', thema: 'Daten & Zufall', station: 4, stationen: 5,
        kompetenzen: [1, 2, 3, 4, 5].map((n) => k(n, `2026-09-${10 + n}T10:00:00Z`)),
      },
      { fach_id: 'd', fach: 'Deutsch', thema: null, station: null, stationen: null, kompetenzen: [] },
    ]
    render(<FortschrittKachel faecher={faecher} />)
    expect(screen.getByText('Daten & Zufall')).toBeTruthy()
    expect(screen.getAllByText('Station 4 von 5').length).toBeGreaterThan(0)
    expect(screen.getAllByText('gemeistert')).toHaveLength(4)
    expect(screen.getByText('und 1 weitere')).toBeTruthy()
    expect(screen.getByText('ZZ_Kompetenz 1')).toBeTruthy()
    expect(screen.queryByText('ZZ_Kompetenz 5')).toBeNull()
    expect(screen.getAllByText(/bestätigt von ZZ Coach am/)).toHaveLength(4)
    expect(screen.getByText('Noch kein Lernpfad.')).toBeTruthy()
  })

  it('ohne Fach: "Noch kein Lernpfad." und nirgends "gemeistert"', () => {
    render(<FortschrittKachel faecher={[]} />)
    expect(screen.getByText('Noch kein Lernpfad.')).toBeTruthy()
    expect(screen.queryByText('gemeistert')).toBeNull()
  })

  it('Kompetenzen ohne Lernpfad-Stand: Liste ja, Station nein', () => {
    render(
      <FortschrittKachel
        faecher={[{ fach_id: 'm', fach: 'Mathematik', thema: null, station: null, stationen: 5, kompetenzen: [k(1, '2026-09-20T10:00:00Z')] }]}
      />,
    )
    expect(screen.getByText('Noch kein Lernpfad.')).toBeTruthy()
    expect(screen.getAllByText('gemeistert')).toHaveLength(1)
    expect(screen.queryByText(/Station/)).toBeNull()
  })
})
