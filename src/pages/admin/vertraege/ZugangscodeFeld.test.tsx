import { describe, expect, it } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import '@/i18n'
import { maskIban } from '@/lib/vertrag/iban'
import { ZugangscodeFeld } from './ZugangscodeFeld'

describe('Zugangscode maskiert wie die IBAN (Entscheidung 25)', () => {
  it('nutzt dieselbe Maskierung wie die IBAN', () => {
    expect(maskIban('EDV-ABCD-EFG2')).toBe('ED** **** EFG2')
    expect(maskIban('DE89370400440532013000')).toBe('DE** **** 3000')
  })

  it('zeigt den Code zuerst maskiert', () => {
    render(<ZugangscodeFeld code="EDV-ABCD-EFG2" />)
    expect(screen.getByTestId('zugangscode-wert').textContent).toBe('ED** **** EFG2')
    expect(screen.queryByText('EDV-ABCD-EFG2')).toBeNull()
  })

  it('deckt auf Klick auf und verbirgt wieder', () => {
    render(<ZugangscodeFeld code="EDV-ABCD-EFG2" />)
    fireEvent.click(screen.getByRole('button', { name: /Code anzeigen/ }))
    expect(screen.getByTestId('zugangscode-wert').textContent).toBe('EDV-ABCD-EFG2')
    fireEvent.click(screen.getByRole('button', { name: /Code verbergen/ }))
    expect(screen.getByTestId('zugangscode-wert').textContent).toBe('ED** **** EFG2')
  })

  it('ohne Code: Strich, kein Knopf', () => {
    render(<ZugangscodeFeld code={null} />)
    expect(screen.getByText('—')).toBeTruthy()
    expect(screen.queryByRole('button')).toBeNull()
  })
})
