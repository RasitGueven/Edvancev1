// Reihe 1 A5: „Aufgabe stimmt nicht“ in der Coach-Live-Sicht.
import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'

vi.mock('@/lib/supabase/bauformPruefung', () => ({ aufgabeMelden: vi.fn(async () => ({ data: null, error: null })) }))
import { aufgabeMelden } from '@/lib/supabase/bauformPruefung'
import { AufgabeMelden } from './AufgabeMelden'

describe('AufgabeMelden', () => {
  it('meldet mit Grund und bestätigt', async () => {
    render(<AufgabeMelden taskId="t1" />)
    fireEvent.click(screen.getByRole('button', { name: 'Aufgabe stimmt nicht' }))
    const melden = screen.getByRole('button', { name: 'Melden' })
    expect(melden).toBeDisabled()
    fireEvent.change(screen.getByPlaceholderText('z. B. Lösung falsch, Text unklar'), { target: { value: 'Lösung falsch' } })
    fireEvent.click(melden)
    await waitFor(() => expect(screen.getByRole('status')).toHaveTextContent('Gemeldet.'))
    expect(aufgabeMelden).toHaveBeenCalledWith('t1', 'Lösung falsch')
  })
})
