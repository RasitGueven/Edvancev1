// Einstieg in die Tablet-Präsentation (T2, Entscheidung 1): Knopf in den
// Aktionen, ?ansicht=praesentation öffnet, Schließen entfernt nur ?ansicht,
// Pakete einmal je Seite. Alle Supabase-Wrapper sind gemockt.
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { ReportPage } from '@/pages/admin/ReportPage'

const fall = PRAESENTATION_FAELLE.laeuftNoch

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'u1' }, role: 'admin', signOut: vi.fn() }),
}))
const wrapper = vi.hoisted(() => ({ getReportData: vi.fn(), listTiers: vi.fn() }))
vi.mock('@/lib/supabase/lsaReport', () => ({ getReportData: wrapper.getReportData }))
vi.mock('@/lib/supabase/reportNotes', () => ({
  EMPTY_NOTES: { zielbild: '', empfehlung: '', paket: null },
  getReportNotes: vi.fn(() => Promise.resolve({ data: fall.notes, error: null, unavailable: false })),
  saveReportNotes: vi.fn(() => Promise.resolve({ data: null, error: null, unavailable: false })),
}))
vi.mock('@/lib/supabase/subscriptions', () => ({ listTiers: wrapper.listTiers }))

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

const ebene = (): HTMLElement | null => document.body.querySelector(':scope > .tp')

describe('ReportPage — Präsentation', () => {
  beforeEach(() => {
    wrapper.getReportData.mockReset()
    wrapper.getReportData.mockResolvedValue({ data: fall.data, error: null })
    wrapper.listTiers.mockReset()
    wrapper.listTiers.mockResolvedValue({ data: fall.tiers, error: null })
  })

  it('zeigt den Knopf als ersten in den Aktionen, aktiv auch bei laufender Analyse', async () => {
    seite('/admin/report/s1')
    const knopf = await screen.findByRole('button', { name: 'Präsentation' })
    expect(knopf).toBeEnabled()
    await screen.findByText(/noch nicht abgeschlossen|läuft noch/i)
    const aktionen = knopf.parentElement!
    expect(within(aktionen).getAllByRole('button')[0]).toBe(knopf)
    expect(ebene()).toBeNull()
    // Seit R7-7 braucht auch der Bogen die Pakete: einmal je Seite.
    await waitFor(() => expect(wrapper.listTiers).toHaveBeenCalledTimes(1))
  })

  it('öffnet per Knopf mit ?ansicht=praesentation und lädt die Pakete einmal', async () => {
    seite('/admin/report/s1')
    fireEvent.click(await screen.findByRole('button', { name: 'Präsentation' }))
    expect(screen.getByTestId('ort')).toHaveTextContent('?ansicht=praesentation')
    await waitFor(() => expect(ebene()?.querySelectorAll('.tp-station')).toHaveLength(4))
    expect(within(ebene()!).getByText('Analyse läuft noch')).toBeInTheDocument()
    expect(wrapper.listTiers).toHaveBeenCalledTimes(1)
  })

  it('zeigt LoadingPulse, bis Report, Notizen und Pakete da sind', async () => {
    let gib: (wert: unknown) => void = () => {}
    wrapper.listTiers.mockReturnValue(new Promise((r) => (gib = r)))
    seite('/admin/report/s1?ansicht=praesentation')
    expect(await within(document.body).findByTestId('tp-laden')).toBeInTheDocument()
    await screen.findByRole('button', { name: 'Präsentation' })
    expect(within(ebene()!).getByTestId('tp-laden')).toBeInTheDocument()
    gib({ data: fall.tiers, error: null })
    await waitFor(() => expect(ebene()?.querySelectorAll('.tp-station')).toHaveLength(4))
  })

  it('läuft weiter, wenn die Pakete scheitern', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    wrapper.listTiers.mockResolvedValue({ data: null, error: 'kaputt' })
    seite('/admin/report/s1?ansicht=praesentation')
    await waitFor(() => expect(ebene()?.querySelectorAll('.tp-station')).toHaveLength(4))
    expect(warn).toHaveBeenCalled()
    warn.mockRestore()
  })

  it('lädt bei ?fassung=r7&ansicht=praesentation die Pakete nur einmal; ?fassung entfällt, Schließen entfernt ?ansicht', async () => {
    seite('/admin/report/s1?fassung=r7&ansicht=praesentation')
    await waitFor(() => expect(ebene()?.querySelectorAll('.tp-station')).toHaveLength(4))
    expect(document.querySelector('.eb-bogen')).not.toBeNull()
    expect(wrapper.listTiers).toHaveBeenCalledTimes(1)

    fireEvent.click(within(ebene()!).getByRole('button', { name: 'Präsentation schließen' }))
    expect(screen.getByTestId('ort')).toBeEmptyDOMElement()
    expect(ebene()).toBeNull()
    expect(document.querySelector('.eb-bogen')).not.toBeNull()
    expect(document.documentElement).not.toHaveClass('tp-offen')

    // Erneut öffnen: dieselben Pakete, kein zweiter Aufruf.
    fireEvent.click(screen.getByRole('button', { name: 'Präsentation' }))
    await waitFor(() => expect(ebene()?.querySelectorAll('.tp-station')).toHaveLength(4))
    expect(wrapper.listTiers).toHaveBeenCalledTimes(1)
  })
})
