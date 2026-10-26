// LSA-L4 Teil D (Entscheidung 13): Hinweis in der Admin-Ansicht, wenn der Lead vom Stand der Sitzung abweicht.
import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import '@/i18n'

import { KaAbweichungHinweis } from './KaAbweichungHinweis'

describe('KaAbweichungHinweis', () => {
  it('nennt den Stand beim Start und den heutigen, nur am Bildschirm', () => {
    render(
      <KaAbweichungHinweis
        abweichung={{ sitzung: { status: 'geschrieben', note: null }, lead: { status: 'geschrieben', note: 3 } }}
      />,
    )
    const h = screen.getByTestId('ka-abweichung')
    expect(h).toHaveClass('print-hide')
    expect(h).toHaveTextContent('beim Start: geschrieben, Note offen')
    expect(h).toHaveTextContent('Heute steht im Erstgespräch: geschrieben, Note 3')
  })
})
