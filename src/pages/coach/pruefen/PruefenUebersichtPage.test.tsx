// Uebersicht mit Bereichen: Umschalter "Fuer die LSA" / "Fuer die Session" mit offen / gesamt, Filter nach Anlass,
// Kennzeichnung bei beiden Anlaessen, Aufgaben ohne Anlass nur im Log, Sollzahlen je Anlass.
// Alle Supabase-Wrapper sind gemockt (CI hat keine VITE_*-Variablen).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { PruefBoardZeile, PruefSollZeile, Stufe } from '@/types'

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
  zeile('v1', 6, ['lsa_vorschau']),
]

const sollZeile = (skill: string, anlass: string, sort: number, rest: number): PruefSollZeile => ({
  skill_key: skill, skill_label: `Knoten ${skill}`, thema_key: 'thema_erste', thema_label: 'Thema erste', thema_sort: 1,
  stufe: 'erste', sort, anlaesse: [anlass], soll: rest, min_ohne_mc: 1, im_board: 1, gezaehlt: 0, gezaehlt_ohne_mc: 0,
  rest, reicht: false,
})

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
    expect(lsa).toHaveTextContent('3 offen / 4')
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
    expect(getPruefSoll).toHaveBeenCalledWith('lsa_vorschau')
    expect(getPruefSoll).toHaveBeenCalledWith('batu_session')
    expect(getPruefSoll).not.toHaveBeenCalledWith()
  })

  it('LSA: Vorschau-Aufgaben im Reiter, Restbedarf aus batu_lsa und lsa_vorschau zusammen', async () => {
    vi.mocked(getPruefSoll).mockImplementation(async (a) => ({
      data: a === 'batu_lsa' ? [sollZeile('k_l2', a, 410, 2)]
        : a === 'lsa_vorschau' ? [sollZeile('k_v1', a, 610, 3)]
          : [sollZeile('k_s1', a ?? '', 310, 7)],
      error: null,
    }))
    zeige()
    expect(await screen.findByRole('tab', { name: /Klasse 7\/8/ })).toHaveTextContent('noch 5 zu prüfen')
    fireEvent.click(screen.getByRole('button', { name: /Thema erste aufklappen/ }))
    expect(screen.getByRole('button', { name: /Aufgabe v1/ })).toBeInTheDocument()
  })

  it('Session: keine Vorschau-Aufgaben', async () => {
    zeige('/coach/pruefen?bereich=session')
    fireEvent.click(await screen.findByRole('button', { name: /Thema erste aufklappen/ }))
    expect(screen.queryByRole('button', { name: /Aufgabe v1/ })).toBeNull()
  })
})
