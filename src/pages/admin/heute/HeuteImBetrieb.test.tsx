// Slots S3: „Session öffnen“ in „Heute im Betrieb“ — nach Erfolg in die Live-Sicht, bei Fehler der
// übersetzte Satz. Wrapper gemockt, Daten erfunden.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'
import type { SlotsTag, TagRaumTermin } from '@/types/slotplan'

vi.mock('@/lib/supabase/slotplan', () => ({ terminSessionAnlegen: vi.fn() }))
import { terminSessionAnlegen } from '@/lib/supabase/slotplan'
import { HeuteImBetrieb } from './HeuteImBetrieb'

const termin: TagRaumTermin = {
  zeit_id: 'z15', beginn: '15:00', ende: '16:00', raum_id: 'r1', raum_name: 'Raum A1', coach_id: 'c1', coach_name: 'ZZ_Coach',
  art: 'stamm', kapazitaet: 5, belegt: 3, session_id: null, gestartet: false, status: null,
}
const tag: SlotsTag = {
  datum: '2026-10-15', betrieb: true, anlass: null,
  raum_termine: [
    termin,
    { ...termin, zeit_id: 'z16', beginn: '16:00', raum_id: 'r2', raum_name: 'Raum B2', coach_id: null, coach_name: null },
    { ...termin, zeit_id: 'z17', beginn: '17:00', raum_id: 'r3', raum_name: 'Raum C3', session_id: 'cs3' },
  ],
  sessions_ohne_raum: [{
    session_id: 'e1', scheduled_at: '2026-10-15T08:00:00Z', room: null, status: 'upcoming', coach_id: 'c1', coach_name: 'ZZ_Einzel',
    testlauf: false, gestartet: false, kinder: 1,
  }],
  absagen: [],
}

function Ort(): JSX.Element {
  const { pathname } = useLocation()
  return <p data-testid="ort">{pathname}</p>
}

function setup(): void {
  render(
    <MemoryRouter initialEntries={['/admin']}>
      <Routes>
        <Route path="/admin" element={<HeuteImBetrieb tag={tag} lsa={[]} />} />
        <Route path="*" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
}

const zeile = (raum: string): HTMLElement => screen.getByText(raum).closest('li') as HTMLElement

describe('HeuteImBetrieb – Aktion je Zeile (S3)', () => {
  beforeEach(() => vi.mocked(terminSessionAnlegen).mockReset())

  it('je Zeile genau eine Aktion: öffnen, Termin-Link ohne Coach, Live-Sicht', () => {
    setup()
    expect(within(zeile('Raum A1')).getAllByRole('button').map((b) => b.textContent)).toEqual(['Session öffnen'])
    const ohne = zeile('Raum B2')
    expect(within(ohne).queryByRole('button')).toBeNull()
    expect(within(ohne).getByText('Kein Coach eingeteilt')).toBeTruthy()
    expect(within(ohne).getByRole('link', { name: 'Zum Termin' }).getAttribute('href')).toBe('/admin/slots/termin/2026-10-15/z16')
    expect(within(zeile('Raum C3')).getByRole('link', { name: 'Live-Sicht' }).getAttribute('href')).toBe('/coach/session/cs3/live')
    expect(within(zeile('Einzel-Session')).getByRole('link', { name: 'Live-Sicht' }).getAttribute('href')).toBe('/coach/session/e1/live')
  })

  it('„Session öffnen“ legt die Session an und führt in die Live-Sicht', async () => {
    vi.mocked(terminSessionAnlegen).mockResolvedValue({ data: { session_id: 'neu-s', neu: true, ausgelassen: [] }, error: null })
    setup()
    fireEvent.click(within(zeile('Raum A1')).getByRole('button', { name: 'Session öffnen' }))
    expect((await screen.findByTestId('ort')).textContent).toBe('/coach/session/neu-s/live')
    expect(terminSessionAnlegen).toHaveBeenCalledWith('2026-10-15', 'z15', 'r1')
  })

  it('bei Fehler bleibt die Seite und zeigt den übersetzten Satz', async () => {
    vi.mocked(terminSessionAnlegen).mockResolvedValue({ data: null, error: 'roh', code: '42501' } as never)
    setup()
    fireEvent.click(within(zeile('Raum A1')).getByRole('button', { name: 'Session öffnen' }))
    const alert = await within(zeile('Raum A1')).findByRole('alert')
    expect(alert.textContent).toBe('Dafür fehlen dir die Rechte.')
    expect(screen.queryByTestId('ort')).toBeNull()
  })
})
