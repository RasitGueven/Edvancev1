// Reihe 1 A5: Lenas Pruefansicht einer Bauform (Steckbrief, Beispiele, Andere Beispiele, Entscheidung mit Taste 3).
import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { BauformDetail } from '@/types/bauformPruefung'

const detail = (seed: number): BauformDetail => ({
  bauform_id: 'b1', schluessel: 'NP-2', skill_key: 'gleichung_quadr_faktor', skill_label: 'Nullprodukt', kernidee_key: null,
  format: 'loesungsmenge', rollen: ['uebung'], version: 1, status: 'zur_pruefung',
  steckbrief: { text: 'Löse {term} = 0.', stufen: { '1': 'a = 1' }, hinweise: [], loesungsweg: [], warum: null,
    fehlbilder: [{ key: 'qf_null_vergessen', rueckmeldung: 'Ein Faktor ist x selbst.', gilt_fuer_stufen: [1, 2] }] },
  pruefprotokoll: { gruen: 83, rot: 3 }, blindloeser: { geloest: 10, abweichend: [] }, verdacht: null,
  fehlbild_texte: { qf_null_vergessen: 'Übersieht x = 0.' }, instanzen: 83, pruefungen: [],
  beispiele: [{ task_id: `t${seed}`, stufe: 1, rolle: 'uebung', loesung: { menge: ['0', '6'], fehlbilder: [{ key: 'qf_null_vergessen', menge: ['6'] }] },
    known_errors: null, loesungsweg: 'x(x − 6) = 0', hinweise: [{ level: 1, text: 'Was haben beide gemeinsam?' }],
    payload: { kind: 'format', task_id: `t${seed}`, assets: [], prompt: `Löse x² − ${seed + 6}x = 0.`, format: 'loesungsmenge',
      payload: { format: 'loesungsmenge', element: 'zahl', max_felder: 3, variable: 'x' } } }],
})

vi.mock('@/lib/supabase/bauformPruefung', () => ({
  getBauformDetail: vi.fn(async (_id: string, seed: number) => ({ data: detail(seed), error: null })),
  bauformPruefen: vi.fn(async () => ({ data: { status: 'zur_freigabe', version: 1 }, error: null })),
  getBauformPlan: vi.fn(async () => ({
    data: [{ bauform_id: 'b1', session_nr: 5, kernidee_titel: 'x ausklammern' }, { bauform_id: 'b2', session_nr: 1 }],
    error: null,
  })),
}))
import { bauformPruefen, getBauformDetail } from '@/lib/supabase/bauformPruefung'
import { BauformDetailPage } from './BauformDetailPage'

const zeige = () => render(
  <MemoryRouter initialEntries={['/coach/pruefen/bauformen/b1']}>
    <Routes><Route path="/coach/pruefen/bauformen/:bauformId" element={<BauformDetailPage />} /></Routes>
  </MemoryRouter>,
)

describe('BauformDetailPage', () => {
  beforeEach(() => vi.clearAllMocks())
  it('zeigt Steckbrief, Fehlbild mit Rückmeldung, Beispiel mit Lösung und Befund', async () => {
    zeige()
    expect(await screen.findByText('Löse x² − 6x = 0.')).toBeInTheDocument()
    expect(screen.getByText('„Ein Faktor ist x selbst.“')).toBeInTheDocument()
    expect(screen.getByText('L = {0; 6}')).toBeInTheDocument()
    expect(screen.getByText('Blindlöser: 10 gelöst, keine Abweichung')).toBeInTheDocument()
    expect(await screen.findByText('gebraucht in Session 5 · x ausklammern')).toBeInTheDocument()
  })
  it('„Andere Beispiele“ lädt mit neuem Seed', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Andere Beispiele' }))
    expect(await screen.findByText('Löse x² − 7x = 0.')).toBeInTheDocument()
    expect(getBauformDetail).toHaveBeenLastCalledWith('b1', 1)
  })
  it('Taste 3 entscheidet „passt“ und zeigt zur Freigabe', async () => {
    zeige()
    await screen.findByText('Löse x² − 6x = 0.')
    fireEvent.keyDown(window, { key: '3' })
    await waitFor(() => expect(bauformPruefen).toHaveBeenCalledWith('b1', 1, 'passt', [], null, expect.any(Number)))
    expect(await screen.findByRole('status')).toHaveTextContent('Zur Freigabe')
  })
})
