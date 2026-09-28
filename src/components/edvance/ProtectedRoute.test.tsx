// Der Rollen-Guard der Vertragsrouten.
//
// Die Daten schuetzt ohnehin die RLS — ein Coach saehe auch bei offener Route
// keine Zeile. Der Guard soll verhindern, dass er ueberhaupt auf einer Seite
// landet, die ihn nichts angeht, und dort eine leere Liste fuer einen Fehler
// haelt.

import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'

const auth = vi.hoisted(() => ({ rolle: 'admin' as string | null, angemeldet: true }))

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({
    user: auth.angemeldet ? { email: 'wer@edvance.de' } : null,
    role: auth.rolle,
    loading: false,
    signOut: vi.fn(),
  }),
}))

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
