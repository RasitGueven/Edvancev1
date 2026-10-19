// Pakete und Empfehlung im Rahmen (T2, Entscheidung 3): Scheitern die Pakete,
// entfällt nur die Empfehlung — die Präsentation läuft weiter. Station 04 ist
// hier ein Spion, der die gerechnete Empfehlung zeigt.
import { render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'

import { Praesentation } from './Praesentation'
import type { StationProps } from './stationProps'

vi.mock('./Station4', () => ({
  Station4: ({ p, anzeige }: StationProps) => (
    <p data-testid="s4">
      {p.empfehlung ? `${p.empfehlung.paket}/${p.empfehlung.basis ?? '-'}` : 'keine'}·{anzeige}
    </p>
  ),
}))

const { ilkay } = PRAESENTATION_FAELLE

function oeffne(tiersFehler: boolean) {
  return render(
    <Praesentation
      data={ilkay.data}
      notes={ilkay.notes}
      tiers={tiersFehler ? [] : ilkay.tiers}
      tiersFehler={tiersFehler}
      sessionId={ilkay.data.sessionId}
      laden={false}
      onSchliessen={vi.fn()}
    />,
  )
}

describe('Präsentation — Pakete', () => {
  it('reicht die Empfehlung aus Notizen und Paketen an Station 04, Zählweise aus den Einstellungen', () => {
    oeffne(false)
    expect(screen.getByTestId('s4')).toHaveTextContent('Premium/Basic·kombiniert')
  })

  it('ohne Pakete: keine Empfehlung, aber alle Stationen (kein Abbruch)', () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    oeffne(true)
    expect(screen.getByTestId('s4')).toHaveTextContent('keine')
    expect(document.querySelectorAll('.tp-station')).toHaveLength(4)
    expect(warn).toHaveBeenCalled()
    warn.mockRestore()
  })
})
