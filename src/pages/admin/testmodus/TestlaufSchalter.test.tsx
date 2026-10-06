import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import '@/i18n'
import { TestlaufSchalter } from './TestlaufSchalter'
import { TestlaufBanner } from './TestlaufBanner'

describe('Schalter „Testlauf“ (Entscheidung 27)', () => {
  it('erscheint nur für Admins bei Testkonten', () => {
    const { rerender } = render(<TestlaufSchalter istAdmin istTest wert={false} onChange={() => {}} />)
    expect(screen.getByRole('switch', { name: /Testlauf/ })).toBeTruthy()

    rerender(<TestlaufSchalter istAdmin istTest={false} wert={false} onChange={() => {}} />)
    expect(screen.queryByRole('switch')).toBeNull()

    rerender(<TestlaufSchalter istAdmin={false} istTest wert={false} onChange={() => {}} />)
    expect(screen.queryByRole('switch')).toBeNull()
  })

  it('meldet das Umschalten', () => {
    const onChange = vi.fn()
    render(<TestlaufSchalter istAdmin istTest wert={false} onChange={onChange} />)
    fireEvent.click(screen.getByRole('switch', { name: /Testlauf/ }))
    expect(onChange).toHaveBeenCalledWith(true)
  })

  it('das Banner sagt „Testlauf“', () => {
    render(<TestlaufBanner />)
    expect(screen.getByRole('status').textContent).toContain('Testlauf')
  })
})
