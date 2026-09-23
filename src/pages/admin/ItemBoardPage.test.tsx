// Das Freigabe-Board: mountet es, navigiert es ueber die URL, und wirkt der
// Filter auf Themen und Aufgaben? Supabase ist gemockt (wie AuthoringItemsPage).

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { AuthoringTask } from '@/types'

vi.mock('@/lib/supabase/taskAuthoring', () => ({
  listAuthoringTasks: vi.fn(),
  listClustersWithSubject: vi.fn(),
}))
vi.mock('@/lib/supabase/freigabe', () => ({
  freigabeCluster: vi.fn(),
  listLetzteBeanstandungen: vi.fn(),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))

import { listAuthoringTasks, listClustersWithSubject } from '@/lib/supabase/taskAuthoring'
import { listLetzteBeanstandungen } from '@/lib/supabase/freigabe'
import { ItemBoardPage } from './ItemBoardPage'

const task = (id: string, over: Partial<AuthoringTask>): AuthoringTask =>
  ({ id, title: id, question: `Frage ${id}`, status: 'draft', cluster_id: 'c1', class_level: 8, ...over }) as AuthoringTask

function setup(url: string): void {
  vi.mocked(listAuthoringTasks).mockResolvedValue({
    data: [
      task('Offene Aufgabe', {}),
      task('Freie Aufgabe', { status: 'ready' }),
      task('Abgelehnte Aufgabe', { status: 'beanstandet', cluster_id: 'c2' }),
    ],
    error: null,
  })
  vi.mocked(listClustersWithSubject).mockResolvedValue({
    data: [
      { id: 'c1', name: 'Zahl & Rechnen', subject_id: 's1', subject_name: 'Mathematik' },
      { id: 'c2', name: 'Daten & Zufall', subject_id: 's1', subject_name: 'Mathematik' },
    ],
    error: null,
  })
  vi.mocked(listLetzteBeanstandungen).mockResolvedValue({
    data: new Map([['Abgelehnte Aufgabe', { kategorie: 'formulierung', notiz: null }]]),
    error: null,
  })
  render(
    <MemoryRouter initialEntries={[url]}>
      <ItemBoardPage />
    </MemoryRouter>,
  )
}

describe('ItemBoardPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('zeigt die Bereiche, Sessions ist leer und gesperrt', async () => {
    setup('/admin/authoring')
    expect(await screen.findByText('3 Aufgaben · 1 geprüft')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Sessions/ })).toBeDisabled()
  })

  it('sperrt Klasse 9 und 10', async () => {
    setup('/admin/authoring?bereich=lsa')
    expect(await screen.findByRole('button', { name: /Klasse 8/ })).toBeEnabled()
    expect(screen.getByRole('button', { name: /Klasse 9/ })).toBeDisabled()
  })

  it('filtert Themen und Aufgaben und zeigt den Rueckweisungsgrund', async () => {
    setup('/admin/authoring?bereich=lsa&klasse=8&fach=Mathematik')
    // Standard "Offen": nur das Thema mit offener Aufgabe.
    expect(await screen.findByText('Zahl & Rechnen')).toBeInTheDocument()
    expect(screen.queryByText('Daten & Zufall')).not.toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /Zurückgewiesen 1/ }))
    fireEvent.click(screen.getByRole('button', { name: /Daten & Zufall/ }))
    expect(screen.queryByText('Zahl & Rechnen')).not.toBeInTheDocument()
    expect(screen.getByText('Abgelehnte Aufgabe')).toBeInTheDocument()
    expect(screen.getByText('Unklar formuliert')).toBeInTheDocument()
  })
})
