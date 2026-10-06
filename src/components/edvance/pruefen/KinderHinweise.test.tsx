// „Hinweise für das Kind“ (L5): Stufenreihenfolge mit Statuspille, Bearbeiten im Entwurf, lesend ohne Felder.

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import '@/i18n'
import type { Bearbeitung } from '@/lib/pruefung/entwurf'
import type { KinderHinweis } from '@/types'
import { KinderHinweise } from './KinderHinweise'

const geladen: KinderHinweis[] = [
  { stufe: 1, text: 'Was ist der Radius?', status: 'geprueft' },
  { stufe: 2, text: 'U = 2 · π · r', status: 'entwurf' },
]
const b: Bearbeitung = {
  werte: [], mc: null, regel: null, fehler: [], skill_key: null, afb: null, hinweise: geladen.map((h) => h.text),
}

describe('KinderHinweise', () => {
  it('zeigt die Stufen in Reihenfolge mit Status (lesend, ohne Eingabefelder)', () => {
    render(<KinderHinweise geladen={geladen} b={b} geaendert={false} lesend onChange={vi.fn()} onZurueck={vi.fn()} />)
    const stufen = screen.getAllByRole('listitem')
    expect(stufen).toHaveLength(2)
    expect(stufen[0]).toHaveTextContent('Stufe 1')
    expect(stufen[0]).toHaveTextContent('Geprüft')
    expect(stufen[0]).toHaveTextContent('Was ist der Radius?')
    expect(stufen[1]).toHaveTextContent('Stufe 2')
    expect(stufen[1]).toHaveTextContent('Entwurf')
    expect(screen.queryByRole('textbox')).toBeNull()
    expect(screen.queryByText(/Hinweis Stufe 3 ergänzen/)).toBeNull()
  })

  it('Lena aendert eine Stufe: neuer Entwurf, die Pille faellt auf Entwurf', () => {
    const onChange = vi.fn()
    const { rerender } = render(
      <KinderHinweise geladen={geladen} b={b} geaendert={false} lesend={false} onChange={onChange} onZurueck={vi.fn()} />)
    fireEvent.change(screen.getByLabelText('Hinweis Stufe 1'), { target: { value: 'Was ist r?' } })
    const neu = onChange.mock.calls[0][0] as Bearbeitung
    expect(neu.hinweise).toEqual(['Was ist r?', 'U = 2 · π · r'])
    rerender(<KinderHinweise geladen={geladen} b={neu} geaendert lesend={false} onChange={onChange} onZurueck={vi.fn()} />)
    expect(screen.getAllByRole('listitem')[0]).toHaveTextContent('Entwurf')
    expect(screen.getByText('geändert')).toBeInTheDocument()
  })

  it('ergaenzt Stufe 3 und entfernt eine Stufe', () => {
    const onChange = vi.fn()
    render(<KinderHinweise geladen={geladen} b={b} geaendert={false} lesend={false} onChange={onChange} onZurueck={vi.fn()} />)
    fireEvent.click(screen.getByText('+ Hinweis Stufe 3 ergänzen'))
    expect((onChange.mock.calls[0][0] as Bearbeitung).hinweise).toEqual([...b.hinweise, ''])
    fireEvent.click(screen.getByLabelText('Hinweis Stufe 1 entfernen'))
    expect((onChange.mock.calls[1][0] as Bearbeitung).hinweise).toEqual(['U = 2 · π · r'])
  })

  it('ohne Hinweise: einladender Satz', () => {
    render(<KinderHinweise geladen={[]} b={{ ...b, hinweise: [] }} geaendert={false} lesend={false} onChange={vi.fn()} onZurueck={vi.fn()} />)
    expect(screen.getByText('Für diese Aufgabe gibt es noch keine Hinweise.')).toBeInTheDocument()
    expect(screen.getByText('+ Hinweis Stufe 1 ergänzen')).toBeInTheDocument()
  })
})
