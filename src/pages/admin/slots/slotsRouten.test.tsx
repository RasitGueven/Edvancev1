// Slots SL2, Tests 1 und 7: Alle /admin/slots*-Routen nur für Admins; ein Coach landet auch über die direkte
// Adresse in seinen Einsätzen (Abnahmefall 14). /admin/slot-auswahl leitet in die Kinder-Liste um,
// /admin/schedule und /admin/slots/termin/… in den Wochenplan (W2; Verhalten in wochenplan/wochenplan.test.tsx).

import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter, Navigate, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'coach' as string }))
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: { id: 'u1' }, role: auth.rolle, loading: false }) }))
vi.mock('@/lib/supabase/freigabe', () => ({ getDarfPruefen: vi.fn() }))

const { ProtectedRoute } = await import('@/components/edvance/ProtectedRoute')

function Ort(): JSX.Element {
  const l = useLocation()
  return <p data-testid="ort">{l.pathname + l.search}</p>
}

const APP = readFileSync(join(__dirname, '../../../App.tsx'), 'utf8')

describe('Slots-Routen', () => {
  it('jede /admin/slots*-Route und /admin/slot-auswahl: nur Admin, Coach nach /coach/einsaetze', () => {
    const pfade = ['/admin/slots', '/admin/slots/termin/:datum/:zeitId', '/admin/slots/kind/:studentId', '/admin/slot-auswahl']
    for (const pfad of pfade) {
      const block = APP.slice(APP.indexOf(`path="${pfad}"`), APP.indexOf('</Route>', APP.indexOf(`path="${pfad}"`)) + 200)
      expect(block, pfad).toMatch(/allowedRoles=\{\['admin'\]\} umleitungFuer=\{\{ coach: '\/coach\/einsaetze' \}\}/)
    }
  })

  it('ein Coach wird von der direkten Adresse umgeleitet', () => {
    auth.rolle = 'coach'
    render(
      <MemoryRouter initialEntries={['/admin/slots/kind/k1']}>
        <Routes>
          <Route path="/admin/slots/kind/:studentId" element={
            <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/einsaetze' }}><p>Kind</p></ProtectedRoute>
          } />
          <Route path="*" element={<Ort />} />
        </Routes>
      </MemoryRouter>,
    )
    expect(screen.getByTestId('ort').textContent).toBe('/coach/einsaetze')
    expect(screen.queryByText('Kind')).toBeNull()
  })

  it('/admin/slot-auswahl leitet einen Admin in die Kinder-Liste', () => {
    auth.rolle = 'admin'
    render(
      <MemoryRouter initialEntries={['/admin/slot-auswahl']}>
        <Routes>
          <Route path="/admin/slot-auswahl" element={
            <ProtectedRoute allowedRoles={['admin']} umleitungFuer={{ coach: '/coach/einsaetze' }}>
              <Navigate to="/admin/slots?reiter=kinder" replace />
            </ProtectedRoute>
          } />
          <Route path="*" element={<Ort />} />
        </Routes>
      </MemoryRouter>,
    )
    expect(screen.getByTestId('ort').textContent).toBe('/admin/slots?reiter=kinder')
    expect(APP).toContain('<Navigate to="/admin/slots?reiter=kinder" replace />')
  })

  it('/admin/schedule und die Termin-Adresse leiten in den Wochenplan (W2, Entscheidung 1 und 6)', () => {
    const block = (pfad: string): string => APP.slice(APP.indexOf(`path="${pfad}"`), APP.indexOf('</Route>', APP.indexOf(`path="${pfad}"`)) + 300)
    expect(block('/admin/schedule')).toContain('<ScheduleUmleitung />')
    expect(block('/admin/slots/termin/:datum/:zeitId')).toContain('<TerminUmleitung />')
    expect(APP).not.toContain('reiter=stundenplan')
    expect(APP).not.toContain('SchedulePage')
    expect(APP).not.toContain('TerminPage')
  })
})
