// PDF aus der Liste LSA-Reports (LR-1, Entscheidung 5): ?aktion=pdf öffnet den
// Druckdialog genau einmal, erst nach dem Laden, mit sprechendem Titel; danach
// ist der alte Titel zurück und nur ?aktion aus der URL. Wrapper gemockt.
import { act, fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { ReportPage } from '@/pages/admin/ReportPage'

const fall = PRAESENTATION_FAELLE.einSchwerpunkt
const daten = { ...fall.data, firstName: 'ZZ_Mia', analysedAt: '2026-10-20T08:00:00+00:00' }

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'u1' }, role: 'admin', signOut: vi.fn() }),
}))
const wrapper = vi.hoisted(() => ({ getReportData: vi.fn(), listTiers: vi.fn() }))
vi.mock('@/lib/supabase/lsaReport', () => ({ getReportData: wrapper.getReportData }))
vi.mock('@/lib/supabase/reportNotes', () => ({
  EMPTY_NOTES: { zielbild: '', empfehlung: '', paket: null },
  getReportNotes: vi.fn(() => Promise.resolve({ data: null, error: null, unavailable: false })),
  saveReportNotes: vi.fn(() => Promise.resolve({ data: null, error: null, unavailable: false })),
}))
vi.mock('@/lib/supabase/subscriptions', () => ({ listTiers: wrapper.listTiers }))

function Ort(): JSX.Element {
  return <p data-testid="ort">{useLocation().search}</p>
}

const seite = (pfad: string) =>
  render(
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

const TITEL = 'Edvance LSA-Report ZZ_Mia 20.10.2026'
let titelBeimDruck: string[] = []
let druck: ReturnType<typeof vi.spyOn>

describe('ReportPage — ?aktion=pdf', () => {
  beforeEach(() => {
    document.title = 'ZZ_Alt'
    titelBeimDruck = []
    druck = vi.spyOn(window, 'print').mockImplementation(() => {
      titelBeimDruck.push(document.title)
    })
    wrapper.getReportData.mockReset()
    wrapper.getReportData.mockResolvedValue({ data: daten, error: null })
    wrapper.listTiers.mockReset()
    wrapper.listTiers.mockResolvedValue({ data: fall.tiers, error: null })
  })
  afterEach(() => druck.mockRestore())

  it('druckt genau einmal, erst wenn auch die Pakete da sind', async () => {
    let gib: (wert: unknown) => void = () => {}
    wrapper.listTiers.mockReturnValue(new Promise((r) => (gib = r)))
    seite('/admin/report/s1?aktion=pdf&x=1')
    await screen.findByRole('button', { name: 'Drucken' })
    await act(() => new Promise((r) => setTimeout(r, 50)))
    expect(druck).not.toHaveBeenCalled()

    gib({ data: fall.tiers, error: null })
    await waitFor(() => expect(druck).toHaveBeenCalledTimes(1))
    expect(titelBeimDruck).toEqual([TITEL])
    // Bis afterprint bleibt der Titel und ?aktion steht noch.
    expect(screen.getByTestId('ort')).toHaveTextContent('aktion=pdf')

    act(() => {
      window.dispatchEvent(new Event('afterprint'))
    })
    expect(document.title).toBe('ZZ_Alt')
    await waitFor(() => expect(screen.getByTestId('ort')).toHaveTextContent('?x=1'))
    expect(screen.getByTestId('ort')).not.toHaveTextContent('aktion')
    await act(() => new Promise((r) => setTimeout(r, 50)))
    expect(druck).toHaveBeenCalledTimes(1)
  })

  it('druckt nicht, wenn der Bericht einen Fehler hat', async () => {
    wrapper.getReportData.mockResolvedValue({ data: null, error: 'ZZ_kaputt' })
    seite('/admin/report/s1?aktion=pdf')
    await screen.findByText('ZZ_kaputt')
    await act(() => new Promise((r) => setTimeout(r, 50)))
    expect(druck).not.toHaveBeenCalled()
  })

  it('druckt im Testlauf trotzdem, der Hinweis bleibt', async () => {
    wrapper.getReportData.mockResolvedValue({ data: { ...daten, testlauf: true }, error: null })
    seite('/admin/report/s1?aktion=pdf')
    await waitFor(() => expect(druck).toHaveBeenCalledTimes(1))
    expect(screen.getByText('Testlauf')).toBeInTheDocument()
  })

  it('ohne ?aktion kein Druck; der Knopf nutzt denselben Titel', async () => {
    seite('/admin/report/s1')
    fireEvent.click(await screen.findByRole('button', { name: 'Drucken' }))
    expect(titelBeimDruck).toEqual([TITEL])
    act(() => {
      window.dispatchEvent(new Event('afterprint'))
    })
    expect(document.title).toBe('ZZ_Alt')
    await act(() => new Promise((r) => setTimeout(r, 50)))
    expect(druck).toHaveBeenCalledTimes(1)
  })
})
