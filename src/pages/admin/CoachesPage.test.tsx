// Coach-Liste nach K1: Einladung statt Passwort, Stand je Konto aus
// mitarbeiter_konto_stand, "erneut senden" nur fuer offene Einladungen.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'

vi.mock('@/lib/supabase/profiles', () => ({
  getCoaches: vi.fn(() =>
    Promise.resolve({
      data: [
        { id: 'c-aktiv', full_name: 'ZZ Ada Aktiv' },
        { id: 'c-offen', full_name: 'ZZ Otto Offen' },
      ],
      error: null,
    }),
  ),
}))
vi.mock('@/lib/supabase/coachEinladen', () => ({
  getKontoStand: vi.fn(() =>
    Promise.resolve({
      data: [
        { id: 'c-aktiv', eingeladen_at: null, bestaetigt_at: '2026-03-02T09:00:00Z', zuletzt_angemeldet_at: null },
        { id: 'c-offen', eingeladen_at: '2026-10-14T07:30:00Z', bestaetigt_at: null, zuletzt_angemeldet_at: null },
      ],
      error: null,
    }),
  ),
  coachEinladen: vi.fn(() => Promise.resolve({ data: null, error: 'email_vergeben' })),
  einladungErneut: vi.fn(() => Promise.resolve({ data: { coach_id: 'c-offen' }, error: null })),
}))

import { coachEinladen, einladungErneut } from '@/lib/supabase/coachEinladen'
import { CoachesPage } from './CoachesPage'

function karte(name: string): HTMLElement {
  return screen.getByText(name).closest('div')!.parentElement as HTMLElement
}

beforeEach(() => vi.clearAllMocks())

describe('CoachesPage (K1)', () => {
  it('hat kein Passwortfeld mehr', async () => {
    render(<MemoryRouter><CoachesPage /></MemoryRouter>)
    await screen.findByText('ZZ Ada Aktiv')
    expect(screen.getByLabelText('Vorname *')).toBeInTheDocument()
    expect(screen.getByLabelText('Nachname *')).toBeInTheDocument()
    expect(screen.queryByLabelText(/Passwort/)).not.toBeInTheDocument()
  })

  it('zeigt den Stand je Konto, "erneut" nur bei offener Einladung', async () => {
    render(<MemoryRouter><CoachesPage /></MemoryRouter>)
    await screen.findByText('ZZ Ada Aktiv')
    expect(within(karte('ZZ Ada Aktiv')).getByText('aktiv seit 02.03.2026')).toBeInTheDocument()
    expect(within(karte('ZZ Ada Aktiv')).queryByRole('button')).not.toBeInTheDocument()
    expect(within(karte('ZZ Otto Offen')).getByText('eingeladen am 14.10.2026')).toBeInTheDocument()
    fireEvent.click(within(karte('ZZ Otto Offen')).getByRole('button', { name: 'Einladung erneut senden' }))
    expect(await screen.findByRole('status')).toHaveTextContent('Einladung an ZZ Otto Offen ist erneut unterwegs.')
    expect(einladungErneut).toHaveBeenCalledWith('c-offen')
  })

  it('doppelte Mail: verständliche Meldung', async () => {
    render(<MemoryRouter><CoachesPage /></MemoryRouter>)
    await screen.findByText('ZZ Ada Aktiv')
    fireEvent.change(screen.getByLabelText('Vorname *'), { target: { value: 'ZZ Mia' } })
    fireEvent.change(screen.getByLabelText('Nachname *'), { target: { value: 'Beispiel' } })
    fireEvent.change(screen.getByLabelText('E-Mail *'), { target: { value: 'zz-ada@example.org' } })
    fireEvent.click(screen.getByRole('button', { name: 'Einladung senden' }))
    expect(await screen.findByRole('alert')).toHaveTextContent('Mit dieser Adresse gibt es schon ein Konto.')
    expect(coachEinladen).toHaveBeenCalledWith({ vorname: 'ZZ Mia', nachname: 'Beispiel', email: 'zz-ada@example.org' })
  })
})
