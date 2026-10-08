// Liste der Erklaerungen (L6): Lena sieht alle nach Thema, der Admin filtert nach „Bereit zur Freigabe“ und
// „Rückfragen“. Wrapper gemockt (CI ohne VITE_*-Variablen).

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { ErklaerListenZeile } from '@/types/erklaerPruefung'

vi.mock('@/lib/supabase/erklaerPruefung', () => ({ getErklaerListe: vi.fn() }))
import { getErklaerListe } from '@/lib/supabase/erklaerPruefung'
import { ErklaerListePage } from './ErklaerListePage'

function zeile(teil: Partial<ErklaerListenZeile>): ErklaerListenZeile {
  return {
    kernidee_id: 'k', skill_key: 'fkt_linear', skill_label: 'Lineare Funktionen', thema_key: 'k8_linfkt',
    thema_label: 'Lineare Funktionen', klasse: 8, nr: 1, titel: 'Titel', status: 'entwurf', stand: 'offen',
    rueckfrage: false, bereit: false, varianten: 2, schritte: 4, schritte_offen: 4, checks: 1, checks_soll: 1,
    geaendert_am: '2026-10-07T10:00:00Z', ...teil,
  }
}

const ZEILEN = [
  zeile({ kernidee_id: 'a', nr: 1, titel: 'Steigung ablesen' }),
  zeile({ kernidee_id: 'b', nr: 2, titel: 'Steigungsdreieck', stand: 'unsicher', rueckfrage: true }),
  zeile({ kernidee_id: 'c', nr: 3, titel: 'Achsenabschnitt', stand: 'passt', status: 'geprueft', bereit: true }),
]

function zeige(modus: 'lena' | 'admin', pfad = '/'): void {
  vi.mocked(getErklaerListe).mockResolvedValue({ data: ZEILEN, error: null })
  render(<MemoryRouter initialEntries={[pfad]}><ErklaerListePage modus={modus} /></MemoryRouter>)
}

describe('ErklaerListePage', () => {
  it('Lena: alle Kernideen nach Thema mit Stand, ohne Admin-Filter', async () => {
    zeige('lena')
    expect(await screen.findByText('Kernidee 1: Steigung ablesen')).toBeInTheDocument()
    expect(screen.getByText('Kernidee 2: Steigungsdreieck')).toBeInTheDocument()
    expect(screen.getByText('Kernidee 3: Achsenabschnitt')).toBeInTheDocument()
    expect(screen.queryByRole('tab', { name: /Bereit zur Freigabe/ })).toBeNull()
    expect(screen.getByRole('button', { name: 'Nächste offene prüfen' })).toBeInTheDocument()
  })

  it('Admin: Filter „Bereit zur Freigabe“ und „Rückfragen“ mit Zahlen', async () => {
    zeige('admin')
    const bereit = await screen.findByRole('tab', { name: /Bereit zur Freigabe/ })
    expect(within(bereit).getByText('1')).toBeInTheDocument()
    fireEvent.click(bereit)
    expect(screen.getByText('Kernidee 3: Achsenabschnitt')).toBeInTheDocument()
    expect(screen.queryByText('Kernidee 1: Steigung ablesen')).toBeNull()

    fireEvent.click(screen.getByRole('tab', { name: /Rückfragen/ }))
    expect(screen.getByText('Kernidee 2: Steigungsdreieck')).toBeInTheDocument()
    expect(screen.getByText('Rückfrage')).toBeInTheDocument()
    expect(screen.queryByText('Kernidee 3: Achsenabschnitt')).toBeNull()
  })

  it('Admin: leerer Filter zeigt einen einladenden Leerzustand', async () => {
    vi.mocked(getErklaerListe).mockResolvedValue({ data: [ZEILEN[0]], error: null })
    render(<MemoryRouter initialEntries={['/?filter=rueckfragen']}><ErklaerListePage modus="admin" /></MemoryRouter>)
    expect(await screen.findByText('Lena hat gerade keine offene Rückfrage.')).toBeInTheDocument()
  })

  it('ohne Pruefrecht: Hinweis statt Liste', async () => {
    vi.mocked(getErklaerListe).mockResolvedValue({ data: null, error: { code: '42501', hint: null, message: 'x', fehlt: null } })
    render(<MemoryRouter><ErklaerListePage modus="lena" /></MemoryRouter>)
    expect(await screen.findByText('Dafür fehlt dir das Recht.')).toBeInTheDocument()
  })
})
