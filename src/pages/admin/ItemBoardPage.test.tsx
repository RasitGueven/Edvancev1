// Das Freigabe-Board: mountet es, navigiert es ueber die URL, gliedert es nach
// Heimat-Thema (nicht nach Cluster), und wirkt der Filter auf Themen und
// Aufgaben? Supabase ist gemockt (wie AuthoringItemsPage).

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
  freigabeThema: vi.fn(),
  listLetzteBeanstandungen: vi.fn(),
}))
vi.mock('@/lib/supabase/themen', () => ({
  listSkillThemen: vi.fn(),
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))

import { listAuthoringTasks, listClustersWithSubject } from '@/lib/supabase/taskAuthoring'
import { listLetzteBeanstandungen } from '@/lib/supabase/freigabe'
import { listSkillThemen } from '@/lib/supabase/themen'
import { ItemBoardPage } from './ItemBoardPage'

const task = (id: string, over: Partial<AuthoringTask>): AuthoringTask =>
  ({
    id,
    title: id,
    question: `Frage ${id}`,
    status: 'draft',
    cluster_id: 'c1',
    class_level: 8,
    skill_key: 'prozent_grundwert',
    ...over,
  }) as AuthoringTask

function setup(url: string, extra: AuthoringTask[] = []): void {
  vi.mocked(listAuthoringTasks).mockResolvedValue({
    data: [
      task('Offene Aufgabe', {}),
      task('Freie Aufgabe', { status: 'ready' }),
      task('Abgelehnte Aufgabe', { status: 'beanstandet', cluster_id: 'c2', skill_key: 'bruch_kuerzen' }),
      task('Potenzaufgabe', { skill_key: 'potenzen' }),
      ...extra,
    ],
    error: null,
  })
  vi.mocked(listSkillThemen).mockResolvedValue({
    data: [
      { skill_key: 'prozent_grundwert', thema_key: 'zinsrechnung', label: 'Prozent- und Zinsrechnung', stufe: 'erste', sort: 230 },
      { skill_key: 'bruch_kuerzen', thema_key: 'brueche', label: 'Brüche und Anteile', stufe: 'erprobung', sort: 90 },
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
    expect(await screen.findByText('4 Aufgaben · 1 geprüft')).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Sessions/ })).toBeDisabled()
  })

  it('sperrt Klasse 9 und 10, solange es keine Aufgabe mit class_level 9 gibt', async () => {
    setup('/admin/authoring?bereich=lsa')
    expect(await screen.findByRole('button', { name: /Klasse 8/ })).toBeEnabled()
    expect(screen.getByRole('button', { name: /Klasse 9/ })).toBeDisabled()
    expect(screen.getByRole('button', { name: /Klasse 10/ })).toBeDisabled()
  })

  it('Klasse 9 wird aktiv, sobald es eine Aufgabe mit class_level 9 gibt', async () => {
    setup('/admin/authoring?bereich=lsa', [task('Kreisaufgabe', { class_level: 9, skill_key: 'geo_kreis_umfang' })])
    expect(await screen.findByRole('button', { name: /Klasse 9/ })).toBeEnabled()
    expect(screen.getByRole('button', { name: /Klasse 10/ })).toBeDisabled()
  })

  it('zeigt Themen nach Stufe, keine Inhaltsfelder, Ohne Thema zuletzt', async () => {
    setup('/admin/authoring?bereich=lsa&klasse=8&fach=Mathematik')
    expect(await screen.findByText('Prozent- und Zinsrechnung')).toBeInTheDocument()
    expect(screen.getByText('Klasse 7/8')).toBeInTheDocument()
    expect(screen.getByText('Ohne Thema')).toBeInTheDocument()
    expect(screen.queryByText('Zahl & Rechnen')).not.toBeInTheDocument()
    expect(screen.queryByText('Daten & Zufall')).not.toBeInTheDocument()
    // Standard "Offen": das Bruch-Thema hat nur eine zurueckgewiesene Aufgabe.
    expect(screen.queryByText('Brüche und Anteile')).not.toBeInTheDocument()
    const zeilen = screen.getAllByRole('button', { name: /Prozent- und Zinsrechnung|Ohne Thema/ })
    expect(zeilen.map((z) => z.textContent)).toEqual(['Prozent- und Zinsrechnung', 'Ohne Thema'])
  })

  it('filtert Themen und Aufgaben und zeigt den Rueckweisungsgrund', async () => {
    setup('/admin/authoring?bereich=lsa&klasse=8&fach=Mathematik')
    expect(await screen.findByText('Prozent- und Zinsrechnung')).toBeInTheDocument()

    fireEvent.click(screen.getByRole('button', { name: /Zurückgewiesen 1/ }))
    expect(screen.getByText('Klasse 5/6')).toBeInTheDocument()
    fireEvent.click(screen.getByRole('button', { name: /Brüche und Anteile/ }))
    expect(screen.queryByText('Prozent- und Zinsrechnung')).not.toBeInTheDocument()
    expect(screen.getByText('Abgelehnte Aufgabe')).toBeInTheDocument()
    expect(screen.getByText('Unklar formuliert')).toBeInTheDocument()
  })
})
