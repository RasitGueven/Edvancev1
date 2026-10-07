// Kinderansicht eines Erklaerschritts (L6): Formeln als SVG, ohne SVG der Quelltext mit Hinweis.

import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'
import type { ErklaerSchritt } from '@/types/erklaerPruefung'
import { ErklaerKindSchritt } from './ErklaerKindSchritt'

function schritt(formeln: string[], teil: Partial<ErklaerSchritt> = {}): ErklaerSchritt {
  const inhalt = 'Bei $y = mx + b$ ist **b** der Achsenabschnitt, also $b = 3$.'
  return {
    id: 's1', variante: 'A', art: 'erklaerung', inhalt, bild: null, fehlbild_slugs: [], status: 'entwurf',
    formeln_soll: 2, formeln_ist: formeln.length, geaendert_am: '2026-10-07T10:00:00Z',
    kind: { art: 'erklaerung', inhalt, formeln }, ...teil,
  }
}

describe('ErklaerKindSchritt', () => {
  it('zeigt Formeln nur als SVG, wenn sie erzeugt sind', () => {
    render(<ErklaerKindSchritt schritt={schritt(['https://cdn.test/f1.svg', 'https://cdn.test/f2.svg'])} kernideeNr={1} kernideen={3} />)
    const svgs = screen.getAllByTestId('formel-svg')
    expect(svgs.map((i) => i.getAttribute('src'))).toEqual(['https://cdn.test/f1.svg', 'https://cdn.test/f2.svg'])
    expect(svgs[0]).toHaveAttribute('alt', 'y = mx + b')
    expect(screen.queryByTestId('formel-quelltext')).toBeNull()
    expect(screen.queryByRole('note')).toBeNull()
    expect(screen.getByText('Neu für dich')).toBeInTheDocument()
    expect(screen.getByText('Kernidee 1 von 3 · Erklärschritt')).toBeInTheDocument()
  })

  it('faellt ohne SVG auf den Quelltext mit Hinweis zurueck', () => {
    render(<ErklaerKindSchritt schritt={schritt(['https://cdn.test/f1.svg'])} kernideeNr={2} kernideen={3} />)
    expect(screen.getAllByTestId('formel-svg')).toHaveLength(1)
    const quelle = screen.getByTestId('formel-quelltext')
    expect(quelle).toHaveTextContent('$b = 3$')
    expect(screen.getByRole('note')).toHaveTextContent('Eine Formel ist noch nicht als Bild erzeugt')
  })

  it('Variante B heisst fuer das Kind „Anders erklärt“, das Beispiel „So geht\'s“', () => {
    const { rerender } = render(<ErklaerKindSchritt schritt={schritt([], { variante: 'B' })} kernideeNr={1} kernideen={2} />)
    expect(screen.getByText('Anders erklärt')).toBeInTheDocument()
    rerender(<ErklaerKindSchritt schritt={schritt([], { art: 'beispiel' })} kernideeNr={1} kernideen={2} />)
    expect(screen.getByText("So geht's")).toBeInTheDocument()
  })
})
