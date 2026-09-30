// P5b: Platz in einer regulaeren Session nur mit laufendem Vertrag am
// Session-Datum. Die Regel setzt die Datenbank durch (Trigger, SQLSTATE
// ZG001); die Seite bietet nur Kinder aus session_platz_kandidaten an und
// zeigt die Ablehnung der Datenbank verstaendlich an. Supabase ist gemockt.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'

vi.mock('@/lib/supabase/sessions', () => ({
  KEIN_PLATZ_ZUGANG: 'ZG001',
  createSession: vi.fn(),
  listSessionsForCoach: vi.fn(() =>
    Promise.resolve({
      data: [
        {
          id: 'ZZ_session',
          created_at: '2026-09-30T08:00:00Z',
          coach_id: 'ZZ_coach',
          room: null,
          scheduled_at: '2026-10-05T14:00:00Z',
          status: 'upcoming',
        },
      ],
      error: null,
    }),
  ),
  getSessionStudents: vi.fn(() => Promise.resolve({ data: [], error: null })),
  listPlatzKandidaten: vi.fn(() => Promise.resolve({ data: ['ZZ_mit'], error: null })),
  addStudentToSession: vi.fn(),
}))
vi.mock('@/lib/supabase/profiles', () => ({
  getCoaches: vi.fn(() =>
    Promise.resolve({ data: [{ id: 'ZZ_coach', full_name: 'ZZ Coach' }], error: null }),
  ),
}))
vi.mock('@/lib/supabase/students', () => ({
  listStudentsWithName: vi.fn(() =>
    Promise.resolve({
      data: [
        { id: 'ZZ_mit', full_name: 'ZZ Mit Vertrag', class_level: 9 },
        { id: 'ZZ_ohne', full_name: 'ZZ Ohne Vertrag', class_level: 9 },
      ],
      error: null,
    }),
  ),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))

import { addStudentToSession, listPlatzKandidaten } from '@/lib/supabase/sessions'
import { SchedulePage } from './SchedulePage'

async function sessionOeffnen(): Promise<HTMLSelectElement> {
  render(
    <MemoryRouter>
      <SchedulePage />
    </MemoryRouter>,
  )
  const coachWahl = await screen.findByLabelText('Sessions eines Coaches verwalten')
  await waitFor(() => expect(within(coachWahl).getByText('ZZ Coach')).toBeTruthy())
  fireEvent.change(coachWahl, { target: { value: 'ZZ_coach' } })
  return (await screen.findByLabelText('Schüler auswählen')) as HTMLSelectElement
}

beforeEach(() => {
  vi.mocked(addStudentToSession).mockReset()
  vi.mocked(listPlatzKandidaten).mockClear()
})

describe('SchedulePage — Platz nur mit laufendem Vertrag', () => {
  it('bietet nur Kinder aus session_platz_kandidaten an', async () => {
    const auswahl = await sessionOeffnen()
    expect(listPlatzKandidaten).toHaveBeenCalledWith('ZZ_session')
    expect(within(auswahl).queryByText(/ZZ Mit Vertrag/)).toBeTruthy()
    expect(within(auswahl).queryByText(/ZZ Ohne Vertrag/)).toBeNull()
  })

  it('zeigt die Ablehnung der Datenbank (ZG001) mit dem Datum der Session', async () => {
    vi.mocked(addStudentToSession).mockResolvedValue({
      data: null,
      error: 'Kein laufender Vertrag am 05.10.2026 — Platz kann nicht vergeben werden.',
      code: 'ZG001',
    })
    const auswahl = await sessionOeffnen()
    fireEvent.change(auswahl, { target: { value: 'ZZ_mit' } })
    fireEvent.click(screen.getByRole('button', { name: 'Zuweisen' }))
    expect(
      await screen.findByText('Kein laufender Vertrag am 05.10.2026 — Platz kann nicht vergeben werden.'),
    ).toBeTruthy()
  })

  it('zeigt einen Hinweis, wenn kein Kind an diesem Datum einen Vertrag hat', async () => {
    vi.mocked(listPlatzKandidaten).mockResolvedValueOnce({ data: [], error: null })
    render(
      <MemoryRouter>
        <SchedulePage />
      </MemoryRouter>,
    )
    const coachWahl = await screen.findByLabelText('Sessions eines Coaches verwalten')
    await waitFor(() => expect(within(coachWahl).getByText('ZZ Coach')).toBeTruthy())
    fireEvent.change(coachWahl, { target: { value: 'ZZ_coach' } })
    expect(
      await screen.findByText('Kein weiteres Kind hat an diesem Datum einen laufenden Vertrag.'),
    ).toBeTruthy()
    expect(screen.queryByLabelText('Schüler auswählen')).toBeNull()
  })
})
