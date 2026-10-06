// Coach-Hülle H6 — Rollenweiche auf geteilten Routen, Prüfrecht in der
// Leiste, Fokus-Seiten ohne Leiste, AltRahmen ist weg.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'coach' as string, darfPruefen: false }))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({
    user: { id: 'c1', email: 'coach@edvance.de', user_metadata: {} },
    role: auth.rolle,
    loading: false,
    signOut: vi.fn(),
  }),
}))
vi.mock('@/lib/supabase/freigabe', () => ({
  getDarfPruefen: vi.fn(() => Promise.resolve({ data: auth.darfPruefen, error: null })),
}))
vi.mock('@/lib/supabase/sessions', () => ({
  listSessionsForCoach: vi.fn(() =>
    Promise.resolve({
      data: [{ scheduled_at: new Date().toISOString() }, { scheduled_at: '2020-01-01T10:00:00.000Z' }],
      error: null,
    }),
  ),
}))
vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefBoard: vi.fn(() =>
    Promise.resolve({ data: [{ lena_status: 'offen' }, { lena_status: 'offen' }, { lena_status: 'passt' }], error: null }),
  ),
}))
vi.mock('@/lib/supabase/adminStats', () => ({
  getAdminStats: vi.fn(() => Promise.resolve({ data: { leadsNew: 0 }, error: null })),
}))
vi.mock('@/lib/supabase/vertraege', () => ({ listVertraege: vi.fn(() => Promise.resolve({ data: [], error: null })) }))
vi.mock('@/lib/supabase/heute', () => ({ countAufgabenFuerAdmin: vi.fn(() => Promise.resolve({ data: 0, error: null })) }))
vi.mock('@/lib/supabase/akte', () => ({ profilNamen: vi.fn(() => Promise.resolve(new Map())) }))

import { AdminLayout } from '@/components/edvance/admin/AdminLayout'
import { istFokusSeite } from './coachNav'

const zeige = async (pfad: string): Promise<void> => {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route element={<AdminLayout />}>
          <Route path="/admin/akten/:id" element={<p>Seite</p>} />
          <Route path="/coach/pruefen" element={<p>Seite</p>} />
          <Route path="/coach" element={<p>Seite</p>} />
          <Route path="/coach/session/:id" element={<p>Seite</p>} />
        </Route>
      </Routes>
    </MemoryRouter>,
  )
  await act(async () => {})
}

const leiste = (): HTMLElement => screen.getByRole('navigation', { name: 'Hauptnavigation' })

beforeEach(() => {
  auth.rolle = 'coach'
  auth.darfPruefen = false
})

describe('Rollenweiche auf geteilten Routen', () => {
  it.each(['/admin/akten/s1', '/coach/pruefen'])('%s: Admin sieht die Admin-Hülle', async (pfad) => {
    auth.rolle = 'admin'
    await zeige(pfad)
    expect(within(leiste()).getByText('Admin')).toBeTruthy()
    expect(within(leiste()).getByRole('link', { name: /Leads/ })).toBeTruthy()
  })

  it.each(['/admin/akten/s1', '/coach/pruefen'])('%s: Coach sieht die Coach-Hülle', async (pfad) => {
    await zeige(pfad)
    expect(within(leiste()).getByText('Coach')).toBeTruthy()
    expect(within(leiste()).queryByRole('link', { name: /Leads/ })).toBeNull()
    expect(within(leiste()).getByRole('link', { name: /Schüler/ })).toBeTruthy()
    expect(screen.getByText('Seite')).toBeTruthy()
  })

  it('Coach-Leiste: Reihenfolge, „Schüler“ aktiv auf der Akte, Sessions heute gezählt', async () => {
    auth.darfPruefen = true
    await zeige('/admin/akten/s1')
    const namen = within(leiste()).getAllByRole('link').map((a) => a.getAttribute('href'))
    expect(namen).toEqual(['/coach', '/admin/akten', '/coach/pruefen', '/admin/content-gesundheit'])
    expect(within(leiste()).getByRole('link', { name: /Schüler/ }).getAttribute('aria-current')).toBe('page')
    expect(within(leiste()).getByRole('link', { name: /Heute/ }).textContent).toContain('1')
    expect(within(leiste()).getByRole('link', { name: /Aufgaben prüfen/ }).textContent).toContain('2')
  })
})

describe('Prüfrecht', () => {
  it('ohne Prüfrecht fehlt „Aufgaben prüfen“', async () => {
    await zeige('/coach')
    expect(within(leiste()).queryByRole('link', { name: /Aufgaben prüfen/ })).toBeNull()
  })

  it('mit Prüfrecht ist „Aufgaben prüfen“ da', async () => {
    auth.darfPruefen = true
    await zeige('/coach')
    expect(within(leiste()).getByRole('link', { name: /Aufgaben prüfen/ })).toBeTruthy()
  })
})

describe('Fokus-Seiten', () => {
  it.each(['coach', 'admin'])('Live-Sicht einer Session hat keine Leiste (%s)', async (rolle) => {
    auth.rolle = rolle
    await zeige('/coach/session/abc')
    expect(screen.queryByRole('navigation', { name: 'Hauptnavigation' })).toBeNull()
    expect(screen.getByText('Seite')).toBeTruthy()
  })

  it('Druckbild des Eltern-Reports: die Leiste ist im Druck ausgeblendet', async () => {
    await zeige('/admin/akten/s1')
    expect(leiste().className).toContain('print-hide')
    expect(istFokusSeite('/coach/sessionen')).toBe(false)
  })
})

describe('AltRahmen', () => {
  it('keine Datei importiert noch AltRahmen, die Datei ist gelöscht', () => {
    const dateien = import.meta.glob('/src/**/*.{ts,tsx}', { query: '?raw', import: 'default', eager: true }) as Record<
      string,
      string
    >
    const pfade = Object.keys(dateien)
    expect(pfade.length).toBeGreaterThan(100)
    expect(pfade.some((p) => p.endsWith('/AltRahmen.tsx'))).toBe(false)
    const importeure = pfade.filter((p) => /from\s+['"][^'"]*AltRahmen['"]/.test(dateien[p]))
    expect(importeure).toEqual([])
  })
})
