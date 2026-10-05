// Admin-Hülle H2 — Hülle (rollenneutral) und Admin-Layout. Geprüft wird das
// Verhalten, nicht das Aussehen: aktiv-Muster, Zähler, „bald“, Rollenweiche,
// Schublade (Escape, Tippen daneben, Seitenwechsel).

import { afterEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen } from '@testing-library/react'
import { Link, MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import { ADMIN_NAV } from '@/components/edvance/admin/adminNav'
import { istAktiv, type NavEintrag } from './navTypes'
import { AppShell } from './AppShell'
import { ShellSidebar } from './ShellSidebar'

const auth = vi.hoisted(() => ({ rolle: 'admin' as string }))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'zz@edvance.de', user_metadata: {} }, role: auth.rolle, loading: false, signOut: vi.fn() }),
}))
vi.mock('@/lib/supabase/adminStats', () => ({
  getAdminStats: vi.fn(() => Promise.resolve({ data: { leadsNew: 3 }, error: null })),
}))
vi.mock('@/lib/supabase/vertraege', () => ({
  listVertraege: vi.fn(() =>
    Promise.resolve({
      data: [{ status: 'unterschrift_ausstehend' }, { status: 'in_vorbereitung' }, { status: 'abgelehnt' }, { status: 'aktiv' }],
      error: null,
    }),
  ),
}))
vi.mock('@/lib/supabase/taskAuthoring', () => ({
  countTasksInReview: vi.fn(() => Promise.resolve({ data: 12, error: null })),
}))

import { AdminLayout } from '@/components/edvance/admin/AdminLayout'

const eintrag = (aktivBei?: string[]): NavEintrag => ({
  id: 'x', route: '/admin/akten', aktivBei, nameKey: 'nav.schueler', kurzKey: 'nav.kurz.schueler', icon: () => null,
}) as unknown as NavEintrag

describe('istAktiv', () => {
  it('ohne Muster nur die eigene Route, mit * als Präfix', () => {
    expect(istAktiv(eintrag(), '/admin/akten')).toBe(true)
    expect(istAktiv(eintrag(), '/admin/akten/1')).toBe(false)
    expect(istAktiv(eintrag(['/admin/akten*']), '/admin/akten/1')).toBe(true)
    expect(istAktiv(eintrag(['/admin/report/*']), '/admin/report')).toBe(false)
  })
})

describe('ShellSidebar', () => {
  const zeige = (pfad: string, variante: 'voll' | 'schmal' = 'voll') =>
    render(
      <MemoryRouter initialEntries={[pfad]}>
        <ShellSidebar konfig={ADMIN_NAV} zaehler={{ leads: 3, vertraege: 0, itemPflege: 12 }} variante={variante} />
      </MemoryRouter>,
    )

  it('markiert den aktiven Eintrag auch auf Unterseiten', () => {
    zeige('/admin/slot-auswahl')
    expect(screen.getByRole('link', { name: /Stundenplan/ }).getAttribute('aria-current')).toBe('page')
    expect(screen.getByRole('link', { name: /Leads/ }).getAttribute('aria-current')).toBeNull()
  })

  it('zeigt Zähler über null, „bald“-Einträge sind kein Link', () => {
    zeige('/admin')
    expect(screen.getByRole('link', { name: /Leads/ }).textContent).toContain('3')
    expect(screen.getByRole('link', { name: /Verträge/ }).textContent).not.toMatch(/\d/)
    expect(screen.queryByRole('link', { name: /Eltern-Reports/ })).toBeNull()
    expect(screen.getByText('Eltern-Reports').closest('[aria-disabled="true"]')).toBeTruthy()
  })

  it('schmale Spalte: Kurzname, Zähler im Namen der Ansage', () => {
    zeige('/admin', 'schmal')
    expect(screen.getByRole('link', { name: 'Leads · 3 offen' })).toBeTruthy()
    expect(screen.getByText('Plan')).toBeTruthy()
  })
})

describe('AppShell als Schublade', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
    document.documentElement.style.removeProperty('--breakpoint-spalte')
    document.documentElement.style.removeProperty('--breakpoint-voll')
  })

  it('öffnet per Menü-Knopf, schließt bei Escape, Tippen daneben und Seitenwechsel', () => {
    document.documentElement.style.setProperty('--breakpoint-spalte', '900px')
    document.documentElement.style.setProperty('--breakpoint-voll', '1280px')
    vi.stubGlobal('matchMedia', () => ({ matches: false, addEventListener: () => {}, removeEventListener: () => {} }))
    render(
      <MemoryRouter initialEntries={['/admin/leads']}>
        <AppShell konfig={ADMIN_NAV} zaehler={{}}>
          <Link to="/admin/akten">weiter</Link>
        </AppShell>
      </MemoryRouter>,
    )
    const oeffnen = screen.getByRole('button', { name: 'Menü öffnen' })
    fireEvent.click(oeffnen)
    expect(screen.getByRole('dialog')).toBeTruthy()
    fireEvent.keyDown(window, { key: 'Escape' })
    expect(screen.queryByRole('dialog')).toBeNull()

    fireEvent.click(oeffnen)
    fireEvent.click(screen.getByRole('button', { name: 'Menü schließen' }))
    expect(screen.queryByRole('dialog')).toBeNull()

    fireEvent.click(oeffnen)
    fireEvent.click(screen.getByRole('dialog').querySelector('a[href="/admin/akten"]') as Element)
    expect(screen.queryByRole('dialog')).toBeNull()
  })
})

describe('AdminLayout', () => {
  const zeige = async () => {
    render(
      <MemoryRouter initialEntries={['/admin/akten']}>
        <Routes>
          <Route element={<AdminLayout />}>
            <Route path="/admin/akten" element={<p>Seite</p>} />
          </Route>
        </Routes>
      </MemoryRouter>,
    )
    await act(async () => {})
  }

  it('Admin: Hülle mit Zählern (offene Anträge ohne abgelehnte)', async () => {
    auth.rolle = 'admin'
    await zeige()
    expect(screen.getByRole('navigation', { name: 'Hauptnavigation' })).toBeTruthy()
    expect(screen.getByRole('link', { name: /Leads/ }).textContent).toContain('3')
    expect(screen.getByRole('link', { name: /Verträge/ }).textContent).toContain('2')
    expect(screen.getByRole('link', { name: /Item-Pflege/ }).textContent).toContain('12')
  })

  it('Coach: keine Leiste, nur die Seite', async () => {
    auth.rolle = 'coach'
    await zeige()
    expect(screen.queryByRole('navigation', { name: 'Hauptnavigation' })).toBeNull()
    expect(screen.getByText('Seite')).toBeTruthy()
  })
})
