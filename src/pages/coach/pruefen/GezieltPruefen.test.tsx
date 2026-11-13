// IU-1 U3: „Gezielt prüfen“ mit Prüfziel MSA und Kompetenz-Filter. Ohne Parameter ruft die Liste wie bisher.
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'

const m = vi.hoisted(() => ({ liste: vi.fn(), stand: vi.fn(), wirkung: vi.fn() }))
vi.mock('@/lib/supabase/lsaAbdeckung', () => ({
  getPruefZielListe: m.liste, getPruefZielStand: m.stand, getLsaWirkung: m.wirkung,
}))

import type { PruefBoardZeile, PruefZielStandZeile, PruefZielZeile } from '@/types'
import { GezieltPruefen } from './GezieltPruefen'

const ok = <T,>(data: T) => Promise.resolve({ data, error: null })
const zeile = (skill_key: string, label: string, ids: string[], p: Partial<PruefZielZeile> = {}): PruefZielZeile => ({
  abschnitt: 'gezielt', skill_key, skill_label: label, thema_key: 't', thema_label: 'Thema', fehlende_texte: 1, rest: 1,
  hebel_pakete: 0, hebel_schulen: 0, fokus_treffer: 0, sort: 1, task_ids: ids, freigabe_ids: [], pilot_fehlt: [], ...p,
})
const stand = (skill_key: string, label: string, bereich: string, texte: number): PruefZielStandZeile => ({
  skill_key, skill_label: label, bereich, texte, erfuellt: texte >= 2, zu_leicht: 0,
})
const task = (id: string, kurztitel: string): PruefBoardZeile => ({
  task_id: id, stufe: 'erste', thema_key: 't', thema_label: 'T', thema_sort: 1, skill_key: 's', skill_label: 'S', kurztitel,
  reihenfolge: 1, lena_status: 'offen', geaendert: false, letzte_dauer_sek: null, anlaesse: ['lsa_vorschau'], hat_hinweise: false,
} as PruefBoardZeile)
const board = [task('t1', 'Aufgabe Wurzel'), task('t2', 'Aufgabe Kegel')]

beforeEach(() => {
  m.liste.mockReset().mockImplementation((_f: boolean, _q: null, filter: { ziel?: string | null; skill?: string | null }) =>
    ok(filter.ziel
      ? [zeile('wurzel', 'Wurzeln', ['t1']), zeile('kegel', 'Kegel', ['t2'], { rest: 2, hebel_schulen: 0 })]
      : [zeile('wurzel', 'Wurzeln', ['t1'], { hebel_schulen: 4 })]))
  m.stand.mockReset().mockReturnValue(ok([
    stand('wurzel', 'Wurzeln', 'arithmetik_algebra', 1), stand('bruch', 'Brüche', 'arithmetik_algebra', 2),
    stand('kegel', 'Kegel', 'geometrie', 0),
  ]))
  m.wirkung.mockReset().mockReturnValue(ok([]))
})

function Adresse(): JSX.Element {
  const l = useLocation()
  return <output data-testid="adresse">{l.search}</output>
}
const zeige = (suche = ''): void => {
  render(
    <MemoryRouter initialEntries={[`/coach/pruefen${suche}`]}>
      <Routes><Route path="/coach/pruefen" element={<><GezieltPruefen board={board} onOeffne={vi.fn()} /><Adresse /></>} /></Routes>
    </MemoryRouter>,
  )
}

describe('Gezielt prüfen mit Prüfziel', () => {
  it('ohne Parameter: Aufruf wie bisher, Umschalter steht auf „Alle“', async () => {
    zeige()
    expect(await screen.findByText('Aufgabe Wurzel')).toBeInTheDocument()
    expect(m.liste).toHaveBeenCalledWith(false, null, { ziel: null, skill: null })
    expect(m.stand).not.toHaveBeenCalled()
    expect(screen.getByRole('button', { name: 'Alle' })).toHaveAttribute('aria-pressed', 'true')
  })

  it('MSA: Kopfzeile, Gruppen je Bereich, „1 von 2“, erledigte eingeklappt mit Haken', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'MSA (ZP10)' }))
    expect(await screen.findByText('Noch 3 Aufgaben · danach ist die MSA-LSA möglich')).toBeInTheDocument()
    expect(screen.getByTestId('adresse')).toHaveTextContent('?ziel=msa_zp10')
    const algebra = screen.getByTestId('bereich-arithmetik_algebra')
    expect(within(algebra).getByRole('heading', { name: 'Arithmetik und Algebra' })).toBeInTheDocument()
    expect(within(algebra).getByText('1 von 2')).toBeInTheDocument()
    expect(within(algebra).getByText('1 Kompetenz erledigt')).toBeInTheDocument()
    expect(within(algebra).getByText('Brüche')).not.toBeVisible()
    expect(within(screen.getByTestId('bereich-geometrie')).getByText('Aufgabe Kegel')).toBeInTheDocument()
    // Fortschritt zählt die erledigte Kompetenz mit: (1 + 2 + 0) / 6 = 50 %.
    expect(screen.getByRole('progressbar')).toHaveAttribute('aria-valuenow', '50')
  })

  it('Sprung mit Kompetenz: gefiltert, Hinweis, Filter aufheben behält das Prüfziel', async () => {
    zeige('?ziel=msa_zp10&skill=wurzel')
    expect(await screen.findByText('Gefiltert: Wurzeln')).toBeInTheDocument()
    expect(m.liste).toHaveBeenCalledWith(false, null, { ziel: 'msa_zp10', skill: 'wurzel' })
    expect(screen.queryByTestId('bereich-geometrie')).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: 'Filter aufheben' }))
    await waitFor(() => expect(screen.getByTestId('adresse')).toHaveTextContent('?ziel=msa_zp10'))
    expect(screen.getByTestId('adresse')).not.toHaveTextContent('skill')
    expect(await screen.findByTestId('bereich-geometrie')).toBeInTheDocument()
  })
})
