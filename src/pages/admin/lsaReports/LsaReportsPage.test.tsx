// Liste „LSA-Reports“ (LR-1): drei Wege je Zeile, Suche, leerer Zustand und
// die zwei Kennzeichen. listLsaReports ist gemockt.
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import '@/i18n'

import { LsaReportsPage } from '@/pages/admin/lsaReports/LsaReportsPage'
import type { LsaReportListItem } from '@/types/report'

const wrapper = vi.hoisted(() => ({ listLsaReports: vi.fn() }))
vi.mock('@/lib/supabase/lsaReportListe', () => ({ listLsaReports: wrapper.listLsaReports }))

const zeile = (id: string, extra: Partial<LsaReportListItem> = {}): LsaReportListItem => ({
  session_id: id,
  first_name: `ZZ_${id}`,
  grade: 7,
  subject: 'Mathematik',
  completed_at: '2026-10-20T22:30:00+00:00',
  testlauf: false,
  ist_test: false,
  modus: 'adaptiv',
  thema_key: null,
  thema_label: null,
  ...extra,
})

const seite = () =>
  render(
    <MemoryRouter>
      <LsaReportsPage />
    </MemoryRouter>,
  )

beforeEach(() => {
  wrapper.listLsaReports.mockReset()
})

describe('LsaReportsPage', () => {
  it('führt Name, Präsentation und PDF auf die richtigen Adressen', async () => {
    wrapper.listLsaReports.mockResolvedValue({ data: [zeile('mia', { thema_label: 'ZZ_Binome' })], error: null })
    seite()
    const reihe = (await screen.findByRole('link', { name: 'Report von ZZ_mia öffnen' })).closest('tr')!
    expect(within(reihe).getByRole('link', { name: 'Report von ZZ_mia öffnen' })).toHaveAttribute('href', '/admin/report/mia')
    expect(within(reihe).getByRole('link', { name: 'Präsentation für ZZ_mia öffnen' })).toHaveAttribute(
      'href',
      '/admin/report/mia?ansicht=praesentation',
    )
    expect(within(reihe).getByRole('link', { name: 'Report von ZZ_mia als PDF sichern' })).toHaveAttribute(
      'href',
      '/admin/report/mia?aktion=pdf',
    )
    expect(within(reihe).getByText('ZZ_Binome')).toBeInTheDocument()
    // Datum in Europe/Berlin: 22:30 UTC am 20.10. ist dort schon der 21.10.
    expect(within(reihe).getByText('21.10.2026')).toBeInTheDocument()
  })

  it('filtert per Suche nach Rufname und zeigt ohne Treffer einen leeren Zustand', async () => {
    wrapper.listLsaReports.mockResolvedValue({
      data: [zeile('mia'), zeile('ben'), zeile('x', { first_name: null })],
      error: null,
    })
    seite()
    await screen.findByText('ZZ_mia')
    expect(screen.getByText('Ohne Namen')).toBeInTheDocument()
    const suche = screen.getByRole('searchbox', { name: 'Kind suchen …' })
    fireEvent.change(suche, { target: { value: 'BEN' } })
    expect(screen.getByText('ZZ_ben')).toBeInTheDocument()
    expect(screen.queryByText('ZZ_mia')).toBeNull()
    expect(screen.queryByText('Ohne Namen')).toBeNull()
    fireEvent.change(suche, { target: { value: 'niemand' } })
    expect(screen.getByText('Kein Kind gefunden')).toBeInTheDocument()
  })

  it('zeigt EmptyState, wenn es keine abgeschlossene LSA gibt', async () => {
    wrapper.listLsaReports.mockResolvedValue({ data: [], error: null })
    seite()
    expect(await screen.findByText('Noch keine abgeschlossene LSA')).toBeInTheDocument()
    expect(screen.queryByRole('table')).toBeNull()
  })

  it('kennzeichnet Testlauf vor Testkonto, echte Kinder ohne Kennzeichen', async () => {
    wrapper.listLsaReports.mockResolvedValue({
      data: [
        zeile('lauf', { testlauf: true, ist_test: true }),
        zeile('konto', { ist_test: true }),
        zeile('echt'),
      ],
      error: null,
    })
    seite()
    const reihe = async (id: string) => (await screen.findByText(`ZZ_${id}`)).closest('tr')!
    expect(within(await reihe('lauf')).getByText('Testlauf')).toBeInTheDocument()
    expect(within(await reihe('lauf')).queryByText('Testkonto')).toBeNull()
    expect(within(await reihe('konto')).getByText('Testkonto')).toBeInTheDocument()
    expect(within(await reihe('echt')).queryByText(/Testlauf|Testkonto/)).toBeNull()
  })

  it('nicht auswertbar: Kennzeichen, Präsentation gesperrt mit Grund, PDF bleibt (LSA-R2)', async () => {
    wrapper.listLsaReports.mockResolvedValue({
      data: [
        zeile('klick', {
          auswertbar: false,
          nicht_auswertbar_grund: {
            antworten: 12,
            schnell_falsch: 6,
            anteil_schnell_falsch: 0.5,
            folge_schnell_falsch_max: 2,
            folge_schnell_aktuell: 0,
            nicht_auswertbar: true,
            grund: 'anteil',
            schwellen: { schnell_ms: 5000, folge: 5, anteil: 0.4, min_antworten: 10, hinweis_folge: 3 },
          },
        }),
        zeile('ruhig'),
      ],
      error: null,
    })
    seite()
    const klick = (await screen.findByText('ZZ_klick')).closest('tr')!
    expect(within(klick).getByText('Nicht auswertbar')).toBeInTheDocument()
    const knopf = within(klick).getByRole('button', { name: 'Präsentation' })
    expect(knopf).toBeDisabled()
    // Intl setzt vor % ein geschütztes Leerzeichen.
    expect(knopf.parentElement?.getAttribute('title')).toMatch(
      /^Nicht auswertbar: 50\s% der Antworten in unter 5 s und falsch\. Die Präsentation bleibt geschlossen\.$/,
    )
    expect(within(klick).queryByRole('link', { name: /Präsentation/ })).toBeNull()
    expect(within(klick).getByRole('link', { name: 'Report von ZZ_klick als PDF sichern' })).toBeInTheDocument()
    const ruhig = screen.getByText('ZZ_ruhig').closest('tr')!
    expect(within(ruhig).queryByText('Nicht auswertbar')).toBeNull()
    expect(within(ruhig).getByRole('link', { name: 'Präsentation für ZZ_ruhig öffnen' })).toBeInTheDocument()
  })

  it('zeigt einen Ladefehler als Hinweis', async () => {
    wrapper.listLsaReports.mockResolvedValue({ data: null, error: 'ZZ_kaputt' })
    seite()
    expect(await screen.findByText(/ZZ_kaputt/)).toBeInTheDocument()
  })
})
