// T2: Schalter "Testlauf" je Session. Die Datenbank ist gemockt; geprueft wird,
// was die Oberflaeche aus ihren Antworten macht.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'

vi.mock('@/lib/supabase/sessions', () => ({
  TESTLAUF_GESTARTET: '55000',
  TESTLAUF_NUR_TESTKONTEN: '22023',
  setSessionTestlauf: vi.fn(),
}))

import { setSessionTestlauf } from '@/lib/supabase/sessions'
import { SessionTestlaufSchalter, sessionGestartet } from './SessionTestlaufSchalter'

const GEPLANT = { id: 'ZZ_s', status: 'upcoming' as const, gestartet_am: null }

function schalter(): HTMLInputElement {
  return screen.getByRole('switch', { name: /Testlauf/ }) as HTMLInputElement
}

beforeEach(() => {
  vi.mocked(setSessionTestlauf).mockReset()
})

describe('SessionTestlaufSchalter', () => {
  it('setzt und nimmt den Testlauf vor dem Start', async () => {
    vi.mocked(setSessionTestlauf).mockResolvedValue({ data: null, error: null })
    const onGeaendert = vi.fn()
    const { rerender } = render(<SessionTestlaufSchalter session={GEPLANT} wert={false} onGeaendert={onGeaendert} />)
    fireEvent.click(schalter())
    await waitFor(() => expect(onGeaendert).toHaveBeenCalledWith(true))
    expect(setSessionTestlauf).toHaveBeenCalledWith('ZZ_s', true)
    rerender(<SessionTestlaufSchalter session={GEPLANT} wert onGeaendert={onGeaendert} />)
    fireEvent.click(schalter())
    await waitFor(() => expect(onGeaendert).toHaveBeenCalledWith(false))
    expect(setSessionTestlauf).toHaveBeenLastCalledWith('ZZ_s', false)
  })

  it('ist nach dem Start gesperrt und sagt, warum', () => {
    render(
      <SessionTestlaufSchalter
        session={{ id: 'ZZ_s', status: 'active', gestartet_am: '2026-10-12T14:00:00Z' }}
        wert
        onGeaendert={() => {}}
      />,
    )
    expect(schalter().disabled).toBe(true)
    expect(screen.getByText('Die Session ist gestartet. Der Testlauf bleibt, wie er ist.')).toBeTruthy()
    expect(screen.getByTitle('Die Session ist gestartet. Der Testlauf bleibt, wie er ist.')).toBeTruthy()
  })

  it.each([
    ['22023', 'Ein gebuchtes Kind ist kein Testkonto. Ein Testlauf geht nur mit Testkonten.'],
    ['55000', 'Die Session ist schon gestartet. Der Testlauf bleibt, wie er ist.'],
    ['42501', 'Einen Testlauf setzt nur ein Admin.'],
    ['XX000', 'Der Testlauf konnte nicht geändert werden. Bitte die Seite neu laden.'],
  ])('zeigt die Ablehnung %s ruhig an und laesst den Wert stehen', async (code, text) => {
    vi.mocked(setSessionTestlauf).mockResolvedValue({ data: null, error: 'ZZ_roh', code })
    const onGeaendert = vi.fn()
    render(<SessionTestlaufSchalter session={GEPLANT} wert={false} onGeaendert={onGeaendert} />)
    fireEvent.click(schalter())
    expect(await screen.findByRole('status')).toHaveProperty('textContent', text)
    expect(screen.queryByText('ZZ_roh')).toBeNull()
    expect(onGeaendert).not.toHaveBeenCalled()
  })

  it('erkennt eine gestartete Session an Status oder Startzeit', () => {
    expect(sessionGestartet({ status: 'upcoming', gestartet_am: null })).toBe(false)
    expect(sessionGestartet({ status: 'upcoming', gestartet_am: '2026-10-12T14:00:00Z' })).toBe(true)
    expect(sessionGestartet({ status: 'done', gestartet_am: null })).toBe(true)
  })
})
