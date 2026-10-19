// Umschalter der Report-Seite (Bauauftrag R7, Entscheidung 1): ohne Parameter
// R6, mit ?fassung=r7 der Druckbogen. Alle Supabase-Wrapper sind gemockt.
import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
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

describe('ReportPage — Fassung', () => {
  beforeEach(() => {
    tiers.listTiers.mockReset()
    tiers.listTiers.mockResolvedValue({ data: fall.tiers, error: null })
  })

  it('zeigt ohne Parameter R6 und lädt keine Pakete', async () => {
    const { container } = seite('/admin/report/s1')
    expect(await screen.findByRole('button', { name: 'Neue Fassung (Druck)' })).toBeInTheDocument()
    await screen.findByText(/Testlauf/i, { selector: 'span' })
    expect(container.querySelector('.report-sheet')).not.toBeNull()
    expect(container.querySelector('.eb-bogen')).toBeNull()
    expect(tiers.listTiers).not.toHaveBeenCalled()
  })

  it('zeigt mit ?fassung=r7 den Bogen, Hinweise nur am Bildschirm, und lädt die Pakete', async () => {
    const { container } = seite('/admin/report/s1?fassung=r7')
    expect(await screen.findByRole('button', { name: 'Bisherige Fassung' })).toBeInTheDocument()
    await screen.findAllByTestId('eb-chip')
    expect(container.querySelector('.report-sheet')).toBeNull()
    expect(container.querySelector('.eb-ansicht .eb-bogen')).not.toBeNull()
    expect(container.querySelectorAll('.eb-seite')).toHaveLength(5)
    // Testlauf-Banner und Ausblick stehen außerhalb des Bogens, nicht auf Papier.
    const banner = screen.getByRole('status')
    expect(banner.closest('.print-hide')).not.toBeNull()
    expect(banner.closest('.eb-bogen')).toBeNull()
    expect(tiers.listTiers).toHaveBeenCalledTimes(1)
  })

  it('schaltet über den Knopf hin und zurück', async () => {
    const { container } = seite('/admin/report/s1')
    fireEvent.click(await screen.findByRole('button', { name: 'Neue Fassung (Druck)' }))
    expect(screen.getByTestId('ort')).toHaveTextContent('?fassung=r7')
    expect(container.querySelector('.eb-bogen')).not.toBeNull()

    fireEvent.click(screen.getByRole('button', { name: 'Bisherige Fassung' }))
    expect(screen.getByTestId('ort')).toBeEmptyDOMElement()
    expect(container.querySelector('.report-sheet')).not.toBeNull()
  })
})
