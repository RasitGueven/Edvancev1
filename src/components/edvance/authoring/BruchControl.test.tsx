// Das Feld „Bruch“ der Item-Pflege (LSA-Erlebnis L1): drei Zustaende, „Automatisch“ zeigt den Vorschlag.

import { fireEvent, render, screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import '@/i18n'
import { BruchControl } from './BruchControl'

describe('BruchControl', () => {
  it('zeigt bei „Automatisch“ den Vorschlag aus den Loesungen', () => {
    render(<BruchControl feld="bruch" value={null} answers={['3/4', '6/8']} onChange={() => {}} />)
    expect(screen.getByRole('radio', { name: 'Automatisch' })).toHaveAttribute('aria-checked', 'true')
    expect(screen.getByText(/Automatisch aus den Lösungen: Bruch/)).toBeInTheDocument()
  })

  it('warnt bei gemischten Loesungen, dass die Aufgabe nicht in die LSA kommt', () => {
    render(<BruchControl feld="bruch" value={null} answers={['3/4', '0,75']} onChange={() => {}} />)
    expect(screen.getByText(/Nicht eindeutig/)).toBeInTheDocument()
  })

  it('setzt die Angabe ausdruecklich', () => {
    const onChange = vi.fn()
    render(<BruchControl feld="bruch" value={null} answers={['3/4', '0,75']} onChange={onChange} />)
    fireEvent.click(screen.getByRole('radio', { name: 'Bruch' }))
    expect(onChange).toHaveBeenCalledWith(true)
    fireEvent.click(screen.getByRole('radio', { name: 'Zahl' }))
    expect(onChange).toHaveBeenCalledWith(false)
  })

  it('zeigt bei gesetzter Angabe keinen Vorschlag', () => {
    render(<BruchControl feld="bruch" value={false} answers={['3/4']} onChange={() => {}} />)
    expect(screen.getByRole('radio', { name: 'Zahl' })).toHaveAttribute('aria-checked', 'true')
    expect(screen.queryByText(/Automatisch aus den Lösungen/)).not.toBeInTheDocument()
  })
})
