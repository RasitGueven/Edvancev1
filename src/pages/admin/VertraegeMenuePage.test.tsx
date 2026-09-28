// Verhalten des Vertragsmenues, mit gemocktem Supabase.
//
// Geprueft wird, was die Seite selbst leistet: zeigt sie "beginnt am" statt
// einer Zahl, solange ein Vertrag noch nicht laeuft, und verlangt sie den
// Pflichtgrund, bevor sie "keine Verlaengerung" abschickt.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { VertragAktuell } from '@/types'

vi.mock('@/lib/supabase/vertraegeMenue', () => ({
  listVertraegeAktuell: vi.fn(),
  vertragVerlaengerungSetzen: vi.fn(() => Promise.resolve({ data: true, error: null })),
  vertragZahlungsstatusSetzen: vi.fn(() => Promise.resolve({ data: true, error: null })),
}))
vi.mock('@/lib/supabase/vertraege', () => ({
  listVertraege: vi.fn(() => Promise.resolve({ data: [], error: null })),
  vertragAblehnen: vi.fn(() => Promise.resolve({ data: true, error: null })),
}))
vi.mock('@/lib/supabase/subscriptions', () => ({
  listTiers: vi.fn(() =>
    Promise.resolve({ data: [{ id: 't3', name: 'Premium', price_cents: 34990 }], error: null }),
  ),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))

import { listVertraegeAktuell, vertragVerlaengerungSetzen } from '@/lib/supabase/vertraegeMenue'
import { VertraegeMenuePage } from './VertraegeMenuePage'

function v(over: Partial<VertragAktuell> & { id: string }): VertragAktuell {
  return {
    wirksamer_status: 'aktiv',
    laufzeit_monat: 3,
    ist_aktueller_vertrag: true,
    beitrag_diesen_monat_cents: 38990,
    zugangscode_gueltig: true,
    endet_in_tagen: 200,
    eltern_vorname: 'ZZ_Anna',
    eltern_nachname: 'Muster',
    kind_vorname: 'ZZ_Mia',
    kind_nachname: 'Muster',
    klasse: 8,
    tier_id: 't3',
    laufzeit_monate: 6,
    preis_cents: 38990,
    vertragsbeginn: '2026-05-01',
    vertrag_ende: '2027-01-15',
    zahlungsstatus: 'in_ordnung',
    zahlungsstatus_seit: null,
    verlaengerung_status: null,
    wiedervorlage_am: null,
    ...over,
  } as VertragAktuell
}

function zeige(): void {
  render(
    <MemoryRouter>
      <VertraegeMenuePage />
    </MemoryRouter>,
  )
}

beforeEach(() => vi.clearAllMocks())

describe('Vertragsuebersicht', () => {
  // laufzeit_monat ist NULL, solange current_date < vertragsbeginn. Frueher
  // stand dort "-4"; jetzt sagt die Zeile, ab wann der Vertrag laeuft.
  it('zeigt "beginnt am", solange der Vertrag noch nicht laeuft', async () => {
    vi.mocked(listVertraegeAktuell).mockResolvedValue({
      data: [v({ id: 'a', laufzeit_monat: null, vertragsbeginn: '2027-02-01' })],
      error: null,
    })
    zeige()
    await waitFor(() => expect(screen.getByText(/beginnt am/)).toBeTruthy())
    expect(screen.getByText(/beginnt am 01\.02\.2027/)).toBeTruthy()
  })

  it('zeigt den Hinweis nicht, wenn der Vertrag laeuft', async () => {
    vi.mocked(listVertraegeAktuell).mockResolvedValue({
      data: [v({ id: 'a', laufzeit_monat: 3 })],
      error: null,
    })
    zeige()
    await waitFor(() => expect(screen.getByText('ZZ_Anna Muster')).toBeTruthy())
    expect(screen.queryByText(/beginnt am/)).toBeNull()
  })

  it('summiert nur die laufenden Vertraege', async () => {
    vi.mocked(listVertraegeAktuell).mockResolvedValue({
      data: [
        v({ id: 'a', wirksamer_status: 'aktiv', beitrag_diesen_monat_cents: 38990 }),
        v({ id: 'b', wirksamer_status: 'im_widerruf', beitrag_diesen_monat_cents: 38990 }),
        v({ id: 'c', wirksamer_status: 'ausgelaufen', beitrag_diesen_monat_cents: 19990 }),
      ],
      error: null,
    })
    zeige()
    // 779,80 steht nur in der Summenzeile — der ausgelaufene Vertrag mit
    // seinen 199,90 zaehlt nicht mit, sonst staenden dort 979,70.
    await waitFor(() => expect(screen.getAllByText(/779,80/).length).toBe(1))
    expect(screen.queryByText(/979,70/)).toBeNull()
  })
})

describe('keine Verlaengerung', () => {
  it('verlangt den Grund, bevor sie abschickt', async () => {
    vi.mocked(listVertraegeAktuell).mockResolvedValue({
      data: [v({ id: 'a', endet_in_tagen: 20 })],
      error: null,
    })
    zeige()

    fireEvent.click(await screen.findByRole('tab', { name: /Auslaufende/ }))
    const auswahl = await screen.findByLabelText('Verlängerung')
    fireEvent.change(auswahl, { target: { value: 'keine_verlaengerung' } })

    // Der Dialog fragt, statt die RPC in den Fehler laufen zu lassen.
    const uebernehmen = await screen.findByRole('button', { name: 'Übernehmen' })
    expect((uebernehmen as HTMLButtonElement).disabled).toBe(true)
    expect(vertragVerlaengerungSetzen).not.toHaveBeenCalled()

    fireEvent.change(screen.getByLabelText(/Grund/), { target: { value: 'Umzug' } })
    expect((uebernehmen as HTMLButtonElement).disabled).toBe(false)

    fireEvent.click(uebernehmen)
    await waitFor(() =>
      expect(vertragVerlaengerungSetzen).toHaveBeenCalledWith('a', 'keine_verlaengerung', 'Umzug', null),
    )
  })
})
