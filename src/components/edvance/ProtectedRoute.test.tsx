// Der Rollen-Guard der Vertragsrouten.
//
// Die Daten schuetzt ohnehin die RLS — ein Coach saehe auch bei offener Route
// keine Zeile. Der Guard soll verhindern, dass er ueberhaupt auf einer Seite
// landet, die ihn nichts angeht, und dort eine leere Liste fuer einen Fehler
// haelt.

import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'admin' as string | null, angemeldet: true }))

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({
    user: auth.angemeldet ? { email: 'wer@edvance.de' } : null,
    role: auth.rolle,
    loading: false,
    signOut: vi.fn(),
  }),
}))

vi.mock('@/lib/supabase/freigabe', () => ({
  getDarfPruefen: vi.fn(),
}))

import { getDarfPruefen } from '@/lib/supabase/freigabe'
import { ProtectedRoute } from './ProtectedRoute'

function zeige(): void {
  render(
    <MemoryRouter initialEntries={['/admin/vertraege']}>
      <ProtectedRoute allowedRoles={['admin']}>
        <p>Vertragsmenue</p>
      </ProtectedRoute>
    </MemoryRouter>,
  )
}

describe('ProtectedRoute auf den Vertragsrouten', () => {
  it('laesst den Admin durch', () => {
    auth.rolle = 'admin'
    auth.angemeldet = true
    zeige()
    expect(screen.getByText('Vertragsmenue')).toBeTruthy()
  })

  it('weist den Coach ab, auch ueber die direkte Adresse', () => {
    auth.rolle = 'coach'
    auth.angemeldet = true
    zeige()
    expect(screen.queryByText('Vertragsmenue')).toBeNull()
    expect(screen.getByText('Kein Zugriff')).toBeTruthy()
  })

  it('leitet eine Rolle mit Umleitung weiter statt "Kein Zugriff" zu zeigen', () => {
    auth.rolle = 'coach'
    auth.angemeldet = true
    render(
      <MemoryRouter initialEntries={['/admin/leads']}>
        <Routes>
          <Route
            path="/admin/leads"
            element={
              <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach' }}>
                <p>Leads</p>
              </ProtectedRoute>
            }
          />
          <Route path="/coach" element={<p>Coach-Dashboard</p>} />
        </Routes>
      </MemoryRouter>,
    )
    expect(screen.queryByText('Leads')).toBeNull()
    expect(screen.queryByText('Kein Zugriff')).toBeNull()
    expect(screen.getByText('Coach-Dashboard')).toBeTruthy()
  })

  it('weist auch Eltern und Schueler ab', () => {
    for (const rolle of ['parent', 'student']) {
      auth.rolle = rolle
      auth.angemeldet = true
      const { unmount } = render(
        <MemoryRouter initialEntries={['/admin/vertraege']}>
          <ProtectedRoute allowedRoles={['admin']}>
            <p>Vertragsmenue</p>
          </ProtectedRoute>
        </MemoryRouter>,
      )
      expect(screen.queryByText('Vertragsmenue')).toBeNull()
      unmount()
    }
  })
})

describe('ProtectedRoute mit Pruefrecht (Lena-Board)', () => {
  function pruefen(): void {
    render(
      <MemoryRouter initialEntries={['/coach/pruefen']}>
        <Routes>
          <Route path="/coach" element={<p>Coach-Dashboard</p>} />
          <Route
            path="/coach/pruefen"
            element={
              <ProtectedRoute allowedRoles={['admin', 'coach']} pruefrecht>
                <p>Aufgaben pruefen</p>
              </ProtectedRoute>
            }
          />
        </Routes>
      </MemoryRouter>,
    )
  }

  it('laesst einen Coach mit Pruefrecht durch', async () => {
    auth.rolle = 'coach'
    auth.angemeldet = true
    vi.mocked(getDarfPruefen).mockResolvedValue({ data: true, error: null })
    pruefen()
    expect(await screen.findByText('Aufgaben pruefen')).toBeTruthy()
  })

  it('schickt einen Coach ohne Pruefrecht zurueck auf /coach', async () => {
    auth.rolle = 'coach'
    auth.angemeldet = true
    vi.mocked(getDarfPruefen).mockResolvedValue({ data: false, error: null })
    pruefen()
    expect(await screen.findByText('Coach-Dashboard')).toBeTruthy()
    expect(screen.queryByText('Aufgaben pruefen')).toBeNull()
  })
})
