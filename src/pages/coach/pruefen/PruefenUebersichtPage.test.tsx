// Uebersicht mit Bereichen: Umschalter "Fuer die LSA" / "Fuer die Session" mit offen / gesamt, Filter nach Anlass,
// Kennzeichnung bei beiden Anlaessen, Aufgaben ohne Anlass nur im Log, Sollzahlen je Anlass.
// Alle Supabase-Wrapper sind gemockt (CI hat keine VITE_*-Variablen).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { PruefBoardZeile, Stufe } from '@/types'

vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefBoard: vi.fn(),
  getPruefSoll: vi.fn(),
  getMeineDauer: vi.fn(),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'lena', email: 'lena@edvance.de' }, role: 'coach', signOut: vi.fn() }),
}))

import { getPruefBoard, getPruefSoll } from '@/lib/supabase/pruefung'
import { PruefenUebersichtPage } from './PruefenUebersichtPage'

const zeile = (id: string, n: number, anlaesse: string[], stufe: Stufe = 'erste', status: 'offen' | 'passt' = 'offen'): PruefBoardZeile => ({
  task_id: id, stufe, thema_key: `thema_${stufe}`, thema_label: `Thema ${stufe}`, thema_sort: n, skill_key: `k_${id}`,
  skill_label: `Knoten ${id}`, kurztitel: `Aufgabe ${id}`, reihenfolge: n, lena_status: status, geaendert: false,
  letzte_dauer_sek: null, anlaesse, hat_hinweise: false,
})

const board = [
  zeile('l1', 1, ['batu_lsa'], 'erste', 'passt'),
  zeile('l2', 2, ['batu_lsa']),
  zeile('b1', 3, ['batu_lsa', 'batu_session']),
  zeile('s1', 4, ['batu_session'], 'zweite'),
  zeile('o1', 5, []),
]

function zeige(pfad = '/coach/pruefen'): void {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route path="/coach/pruefen" element={<PruefenUebersichtPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('PruefenUebersichtPage · Bereiche', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(getPruefBoard).mockResolvedValue({ data: board, error: null })
    vi.mocked(getPruefSoll).mockResolvedValue({ data: [], error: null })
  })

  it('Umschalter mit offen / gesamt; LSA ist Standard', async () => {
    const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
    zeige()
    const lsa = await screen.findByRole('tab', { name: /Für die LSA/ })
    expect(lsa).toHaveTextContent('2 offen / 3')
    expect(lsa).toHaveAttribute('aria-selected', 'true')
    expect(screen.getByRole('tab', { name: /Für die Session/ })).toHaveTextContent('2 offen / 2')
    expect(warn).toHaveBeenCalledWith(expect.stringContaining('without'), 1)
    expect(document.body.textContent).not.toContain('Aufgabe o1')
    warn.mockRestore()
  })

  it('LSA: Stufen-Reiter, nur LSA-Aufgaben, "auch Session" an der Doppelaufgabe', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: /Thema erste aufklappen/ }))
    expect(screen.getByRole('tab', { name: /Klasse 7\/8/ })).toBeInTheDocument()
    expect(screen.queryByRole('tab', { name: /Klasse 9\/10/ })).toBeNull()
    expect(screen.getByRole('button', { name: /Aufgabe b1/ })).toHaveTextContent('auch Session')
    expect(screen.getByRole('button', { name: /Aufgabe l2/ })).not.toHaveTextContent('auch')
  })

  it('Session: alle Themen ohne Stufen-Reiter, "auch LSA" an der Doppelaufgabe', async () => {
    zeige('/coach/pruefen?bereich=session')
    expect(await screen.findByText('Nach Thema und Fertigkeit')).toBeInTheDocument()
    expect(screen.queryByRole('tab', { name: /Klasse/ })).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: /Thema erste aufklappen/ }))
    expect(screen.getByRole('button', { name: /Aufgabe b1/ })).toHaveTextContent('auch LSA')
    expect(screen.queryByRole('button', { name: /Aufgabe l2/ })).toBeNull()
    expect(screen.getByRole('button', { name: /Thema zweite aufklappen/ })).toBeInTheDocument()
  })

  it('Sollzahlen je Bereich nur mit dem passenden Anlass', async () => {
    zeige()
    await screen.findByRole('tab', { name: /Für die LSA/ })
    expect(getPruefSoll).toHaveBeenCalledWith('batu_lsa')
    expect(getPruefSoll).toHaveBeenCalledWith('batu_session')
    expect(getPruefSoll).not.toHaveBeenCalledWith()
  })
})
