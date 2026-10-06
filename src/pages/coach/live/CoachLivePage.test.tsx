// C1 Tests 5 und 6: Die Route weist Schuelerkonten ab (dieselben Rollen wie in
// App.tsx), und Musterloesung und Fehlbild erscheinen nur in der Schublade.
// Die Datenquelle liefert Beispieldaten ohne Supabase; useAuth ist gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'coach' as string }))

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'coach@edvance.de' }, role: auth.rolle, loading: false, signOut: vi.fn() }),
}))
vi.mock('@/lib/supabase/freigabe', () => ({ getDarfPruefen: vi.fn() }))

import { ProtectedRoute } from '@/components/edvance/ProtectedRoute'
import { beispielZuruecksetzen } from '@/lib/session/coachLive'
import { COACH_LIVE_ROLLEN, CoachLivePage } from './CoachLivePage'

function zeige(): void {
  render(
    <MemoryRouter initialEntries={['/coach/session/s1/live']}>
      <Routes>
        <Route
          path="/coach/session/:id/live"
          element={
            <ProtectedRoute allowedRoles={COACH_LIVE_ROLLEN}>
              <CoachLivePage />
            </ProtectedRoute>
          }
        />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  beispielZuruecksetzen()
  auth.rolle = 'coach'
})

describe('5 Route der Live-Sicht', () => {
  it('weist ein Schülerkonto ab', () => {
    auth.rolle = 'student'
    zeige()
    expect(screen.getByText('Kein Zugriff')).toBeTruthy()
    expect(screen.queryByText(/Session 16:30/)).toBeNull()
  })

  it('lässt Coach und Admin hinein', async () => {
    for (const rolle of ['coach', 'admin']) {
      auth.rolle = rolle
      const { unmount } = render(
        <MemoryRouter initialEntries={['/coach/session/s1/live']}>
          <Routes>
            <Route
              path="/coach/session/:id/live"
              element={
                <ProtectedRoute allowedRoles={COACH_LIVE_ROLLEN}>
                  <CoachLivePage />
                </ProtectedRoute>
              }
            />
          </Routes>
        </MemoryRouter>,
      )
      expect(await screen.findByText('Session 16:30 · Raum 1')).toBeTruthy()
      unmount()
    }
    expect(COACH_LIVE_ROLLEN).not.toContain('student')
  })
})

describe('6 Musterlösung und Fehlbild nur in der Schublade', () => {
  it('Kacheln und Warteschlange zeigen beides nicht, die Schublade schon', async () => {
    zeige()
    await screen.findByText('Session 16:30 · Raum 1')
    // Kernarbeit: Emir hängt bei Aufgabe 5.
    expect(screen.queryByText('Ergebnis: −6x + 15')).toBeNull()
    expect(screen.queryByText(/Minus nur auf den ersten Summanden/)).toBeNull()
    expect(screen.queryByText(/Musterlösung/)).toBeNull()
    expect(screen.queryByTestId('musterloesung')).toBeNull()

    fireEvent.click(screen.getByRole('button', { name: 'Emir Şahin öffnen' }))
    const schublade = await screen.findByRole('dialog', { name: 'Kind im Detail' })
    expect(within(schublade).getByTestId('musterloesung').textContent).toContain('Ergebnis: −6x + 15')
    expect(within(schublade).getByText('Fehlbild: Minus nur auf den ersten Summanden angewendet')).toBeTruthy()

    fireEvent.click(within(schublade).getByRole('button', { name: 'Schließen' }))
    expect(screen.queryByTestId('musterloesung')).toBeNull()
  })
})
