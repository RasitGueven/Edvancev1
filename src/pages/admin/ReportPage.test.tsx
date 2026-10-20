// Report-Seite nach R7-7: immer der Bogen R7, kein Umschalter, ?fassung fällt
// aus der URL, Pakete einmal je Seite, Neumessen entprellt. Alle Supabase-
// Wrapper sind gemockt.
import { act, fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { ReportPage } from '@/pages/admin/ReportPage'

const fall = FAELLE.testlauf

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'u1' }, role: 'admin', signOut: vi.fn() }),
}))
vi.mock('@/lib/supabase/lsaReport', () => ({
  getReportData: vi.fn(() => Promise.resolve({ data: fall.data, error: null })),
}))
vi.mock('@/lib/supabase/reportNotes', () => ({
  EMPTY_NOTES: { zielbild: '', empfehlung: '', paket: null },
  getReportNotes: vi.fn(() => Promise.resolve({ data: fall.notes, error: null, unavailable: false })),
  saveReportNotes: vi.fn(() => Promise.resolve({ data: null, error: null, unavailable: false })),
}))
const tiers = vi.hoisted(() => ({ listTiers: vi.fn() }))
vi.mock('@/lib/supabase/subscriptions', () => ({ listTiers: tiers.listTiers }))

function Ort(): JSX.Element {
  return <p data-testid="ort">{useLocation().search}</p>
}

function seite(pfad: string) {
  return render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route
          path="/admin/report/:sessionId"
          element={
            <>
              <ReportPage />
              <Ort />
            </>
          }
        />
      </Routes>
    </MemoryRouter>,
  )
}

describe('ReportPage — nur noch der Bogen R7', () => {
  beforeEach(() => {
    tiers.listTiers.mockReset()
    tiers.listTiers.mockResolvedValue({ data: fall.tiers, error: null })
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  it('zeigt ohne Parameter den Bogen, ohne Umschalter, und lädt die Pakete einmal', async () => {
    const { container } = seite('/admin/report/s1')
    await screen.findAllByTestId('eb-chip')
    expect(container.querySelector('.eb-ansicht .eb-bogen')).not.toBeNull()
    expect(container.querySelectorAll('.eb-seite')).toHaveLength(5)
    expect(screen.queryByRole('button', { name: 'Neue Fassung (Druck)' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Bisherige Fassung' })).toBeNull()
    // Testlauf-Banner und Ausblick stehen außerhalb des Bogens, nicht auf Papier.
    const banner = screen.getByRole('status')
    expect(banner.closest('.print-hide')).not.toBeNull()
    expect(banner.closest('.eb-bogen')).toBeNull()
    expect(container.querySelector('#report-zielbild')?.closest('.print-hide')).not.toBeNull()
    expect(tiers.listTiers).toHaveBeenCalledTimes(1)
  })

  it('zeigt mit ?fassung=r6 ebenso den Bogen und entfernt nur ?fassung aus der URL', async () => {
    const { container } = seite('/admin/report/s1?fassung=r6&quelle=leads')
    await screen.findAllByTestId('eb-chip')
    expect(container.querySelector('.eb-bogen')).not.toBeNull()
    expect(screen.getByTestId('ort')).toHaveTextContent(/^\?quelle=leads$/)
  })

  it('behält ?ansicht, wenn ?fassung entfernt wird, und lädt die Pakete trotzdem einmal', async () => {
    seite('/admin/report/s1?fassung=r7&ansicht=praesentation')
    await screen.findAllByTestId('eb-chip')
    expect(screen.getByTestId('ort')).toHaveTextContent(/^\?ansicht=praesentation$/)
    expect(tiers.listTiers).toHaveBeenCalledTimes(1)
  })

  it('hängt den Bogen nach einer Eingabe im Ausblick erst nach 400 ms neu ein', async () => {
    const { container } = seite('/admin/report/s1')
    await screen.findAllByTestId('eb-chip')
    vi.useFakeTimers()
    const vorher = container.querySelector('.eb-bogen')
    const feld = container.querySelector<HTMLTextAreaElement>('#report-zielbild')!

    fireEvent.change(feld, { target: { value: 'Neues Ziel' } })
    fireEvent.change(feld, { target: { value: 'Neues Ziel, länger' } })
    act(() => vi.advanceTimersByTime(399))
    expect(container.querySelector('.eb-bogen')).toBe(vorher)

    act(() => vi.advanceTimersByTime(1))
    const nachher = container.querySelector('.eb-bogen')
    expect(nachher).not.toBeNull()
    expect(nachher).not.toBe(vorher)
  })
})
