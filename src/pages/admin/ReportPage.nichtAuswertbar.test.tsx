// Nicht auswertbare LSA (LSA-R2): keine Präsentation, eine Seite statt fünf,
// darüber der Hinweisbalken mit „LSA wiederholen“. Alle Supabase-Wrapper sind
// gemockt.
import { render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { PRAESENTATION_FAELLE } from '@/lib/report/praesentation/fixtures'
import { ReportPage } from '@/pages/admin/ReportPage'
import type { DurchklickStand, ReportData } from '@/types'

const fall = PRAESENTATION_FAELLE.laeuftNoch
const stand: DurchklickStand = {
  antworten: 135,
  schnell_falsch: 101,
  anteil_schnell_falsch: 0.75,
  folge_schnell_falsch_max: 15,
  folge_schnell_aktuell: 4,
  nicht_auswertbar: true,
  grund: 'folge',
  schwellen: { schnell_ms: 5000, folge: 5, anteil: 0.4, min_antworten: 10, hinweis_folge: 3 },
}
const daten: ReportData = {
  ...fall.data,
  firstName: 'ZZ_Tim',
  status: 'completed',
  auswertbar: false,
  nichtAuswertbarGrund: stand,
  leadId: 'ZZ_lead',
}

const auth = vi.hoisted(() => ({ role: 'admin' }))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'u1' }, role: auth.role, signOut: vi.fn() }),
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

describe('ReportPage — nicht auswertbar (LSA-R2)', () => {
  beforeEach(() => {
    auth.role = 'admin'
    wrapper.getReportData.mockReset()
    wrapper.getReportData.mockResolvedValue({ data: daten, error: null })
    wrapper.listTiers.mockReset()
    wrapper.listTiers.mockResolvedValue({ data: fall.tiers, error: null })
  })

  it('zeigt genau eine Seite mit dem sachlichen Kasten, ohne Zahlen und ohne Ausblick', async () => {
    seite('/admin/report/s1')
    const bogen = await screen.findByTestId('eb-nicht-auswertbar')
    expect(bogen.querySelectorAll('.eb-seite')).toHaveLength(1)
    expect(within(bogen).getByText(/Diese Lernstandsanalyse können wir nicht auswerten\./)).toHaveTextContent(
      'So kurze Antwortzeiten zeigen nicht, was ZZ_Tim kann.',
    )
    expect(within(bogen).getByText('1 / 1')).toBeInTheDocument()
    expect(within(bogen).queryByText(/Bereiche|Übungsbedarf|Auf einen Blick|Umfang/)).toBeNull()
    expect(bogen.querySelectorAll('.eb-nav-punkt')).toHaveLength(0)
    expect(screen.queryByTestId('eb-huelle')).toBeNull()
  })

  it('Hinweisbalken mit Grund, Kennzahlen und „LSA wiederholen“ zum Lead', async () => {
    seite('/admin/report/s1')
    const balken = await screen.findByTestId('nicht-auswertbar-balken')
    expect(balken).toHaveTextContent('Diese LSA ist nicht auswertbar')
    expect(balken).toHaveTextContent('15 Aufgaben in Folge in unter 5 s falsch beantwortet')
    expect(balken).toHaveTextContent('Antworten 135 · schnell falsch 101 (75 %) · längste Folge 15')
    expect(within(balken).getByRole('link', { name: 'LSA wiederholen' })).toHaveAttribute(
      'href',
      '/admin/leads?lead=ZZ_lead',
    )
    expect(balken).toHaveClass('print-hide')
  })

  it('Coach: „LSA wiederholen“ gesperrt, mit Grund im Tooltip', async () => {
    auth.role = 'coach'
    seite('/admin/report/s1')
    const balken = await screen.findByTestId('nicht-auswertbar-balken')
    const knopf = within(balken).getByRole('button', { name: 'LSA wiederholen' })
    expect(knopf).toBeDisabled()
    expect(knopf.parentElement).toHaveAttribute('title', 'Eine neue LSA gibt nur die Verwaltung frei.')
  })

  it('?ansicht=praesentation öffnet nicht, sondern landet auf dem Bogen', async () => {
    seite('/admin/report/s1?ansicht=praesentation')
    await screen.findByTestId('eb-nicht-auswertbar')
    await waitFor(() => expect(screen.getByTestId('ort')).toHaveTextContent(/^$/))
    expect(document.body.querySelector(':scope > .tp')).toBeNull()
    const knopf = screen.getByRole('button', { name: 'Präsentation' })
    expect(knopf).toBeDisabled()
    expect(knopf.parentElement?.getAttribute('title')).toMatch(/^Nicht auswertbar: 15 Aufgaben in Folge/)
  })
})
