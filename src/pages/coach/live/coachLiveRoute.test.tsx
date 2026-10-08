// Routentabelle aus App.tsx nach H6: Die Live-Sicht ist eine Fokus-Seite ohne
// Leiste, die übrigen Coach-Seiten stehen in der Coach-Hülle. Der Supabase-Client
// ist durch einen leeren Fake ersetzt (jede Abfrage liefert leere Daten), das
// Coach-Dashboard durch einen Platzhalter.

import { describe, expect, it, vi } from 'vitest'
import { act, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'coach' as string }))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({
    user: { id: 'c1', email: 'coach@edvance.de', user_metadata: {} },
    role: auth.rolle,
    loading: false,
    signOut: vi.fn(),
  }),
}))
vi.mock('@/lib/supabase/client', () => {
  const ergebnis = { data: [], error: null, count: 0 }
  const kette: unknown = new Proxy(() => kette, {
    get: (_z, k) =>
      k === 'then' ? (ok: (v: unknown) => unknown) => Promise.resolve(ergebnis).then(ok) : kette,
    apply: () => kette,
  })
  return { supabase: kette }
})
// C2: Die Live-Sicht liest echte Daten; hier reichen die Beispieldaten aus C1.
vi.mock('@/lib/session/coachLive', () => import('@/lib/session/coachLiveBeispielQuelle'))
// Das Dashboard rendert mit leeren Fake-Daten endlos neu; hier zählt nur die Hülle um die Route.
vi.mock('@/pages/coach/CoachDashboard', () => ({ CoachDashboard: () => <p>Coach-Startseite</p> }))

import App from '@/App'

const zeige = async (pfad: string): Promise<void> => {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <App />
    </MemoryRouter>,
  )
  await act(async () => {})
}

const leiste = (): HTMLElement | null => screen.queryByRole('navigation', { name: 'Hauptnavigation' })

describe('Coach-Live-Sicht in der App-Routentabelle', () => {
  it.each(['coach', 'admin'])('/coach/session/:id/live läuft ohne Leiste (%s)', async (rolle) => {
    auth.rolle = rolle
    await zeige('/coach/session/s1/live')
    expect(await screen.findByText('Session 16:30 · Raum 1')).toBeTruthy()
    expect(leiste()).toBeNull()
  })

  it.each(['/coach', '/coach/pruefen', '/admin/akten'])('%s steht für Coaches in der Hülle', async (pfad) => {
    auth.rolle = 'coach'
    await zeige(pfad)
    expect(leiste()).not.toBeNull()
  })

  it('ein Schülerkonto kommt nicht in die Live-Sicht', async () => {
    auth.rolle = 'student'
    await zeige('/coach/session/s1/live')
    expect(screen.queryByText('Session 16:30 · Raum 1')).toBeNull()
  })
})
