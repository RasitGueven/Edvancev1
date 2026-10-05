// Expertenliste mit Auswahl und Sammelaktionen (Bauauftrag E 18): reine Auswahl-Logik, Filterwechsel leert die
// Auswahl mit Hinweis, „Ausgelassene anzeigen“ waehlt genau die ausgelassenen IDs, Durchlauf und Zeilenklick
// oeffnen die Admin-Pruefansicht mit Reihe. Alle Supabase-Wrapper sind gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import { EMPTY_FILTERS } from '@/components/edvance/authoring/AuthoringFilters'
import { alleUmschalten, ausgelasseneAuswahl, fertigkeitWahl, filterGeaendert, kopfZustand, umschalten } from '@/lib/authoring/auswahl'
import { leseReihe } from '@/lib/pruefung/reihe'
import type { AuthoringTask } from '@/types'

vi.mock('@/lib/supabase/taskAuthoring', () => ({
  probeAuthoringSchema: vi.fn().mockResolvedValue({ hasStoffanker: true, hasSolutionRead: true, hasStatusGate: true, hasVorbefuellt: true }),
  listAuthoringTasks: vi.fn(),
  listClustersWithSubject: vi.fn().mockResolvedValue({ data: [], error: null }),
  listReviewMeta: vi.fn(() => Promise.resolve(new Map())),
}))
vi.mock('@/lib/supabase/freigabe', () => ({ freigabeMuster: vi.fn(), freigabeZuruecknehmen: vi.fn() }))
vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefAdminListe: vi.fn().mockResolvedValue({ data: [], error: null }),
  getFehlbilder: vi.fn().mockResolvedValue({ data: [], error: null }),
  pruefRueckfrageKlaeren: vi.fn(),
}))
vi.mock('@/lib/supabase/pruefungAdmin', () => ({ setzePilot: vi.fn(), pruefSammel: vi.fn(), getFertigkeitsgraph: vi.fn() }))
vi.mock('@/lib/supabase/themen', () => ({ listSkillThemen: vi.fn().mockResolvedValue({ data: [], error: null }) }))
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }) }))

import { listAuthoringTasks } from '@/lib/supabase/taskAuthoring'
import { pruefSammel } from '@/lib/supabase/pruefungAdmin'
import { AuthoringItemsPage } from '../AuthoringItemsPage'

describe('Auswahl-Logik', () => {
  it('Kopf: keine, teil, alle; „Alle im Filter“ waehlt alle und hebt sie wieder auf', () => {
    expect(kopfZustand(['a', 'b'], new Set())).toBe('keine')
    expect(kopfZustand(['a', 'b'], new Set(['a']))).toBe('teil')
    expect(kopfZustand(['a', 'b'], new Set(['a', 'b', 'x']))).toBe('alle')
    expect([...alleUmschalten(['a', 'b'], new Set(['a']))]).toEqual(['a', 'b'])
    expect(alleUmschalten(['a', 'b'], new Set(['a', 'b'])).size).toBe(0)
    expect([...umschalten(new Set(['a']), 'b')]).toEqual(['a', 'b'])
  })

  it('ein Filterwechsel zaehlt, die Sortierung nicht', () => {
    expect(filterGeaendert(EMPTY_FILTERS, { ...EMPTY_FILTERS, status: 'review' })).toBe(true)
    expect(filterGeaendert(EMPTY_FILTERS, { ...EMPTY_FILTERS, sort: 'title' })).toBe(false)
  })

  it('„Ausgelassene anzeigen“ waehlt genau die ausgelassenen IDs', () => {
    const s = ausgelasseneAuswahl({ betrifft: ['a'], ausgelassen: [{ task_id: 'b', grund: 'geaendert', text: null }, { task_id: 'c', grund: 'vera8', text: null }] })
    expect([...s]).toEqual(['b', 'c'])
  })

  it('Fertigkeiten: Thema der Aufgaben plus direkte Voraussetzungen, nur mit Heimat-Thema', () => {
    const themen = [
      { skill_key: 'k1', thema_key: 'kreis', label: 'Kreis', stufe: 'zweite' as const, sort: 1 },
      { skill_key: 'k2', thema_key: 'kreis', label: 'Kreis', stufe: 'zweite' as const, sort: 1 },
      { skill_key: 'v1', thema_key: 'terme', label: 'Terme', stufe: 'zweite' as const, sort: 2 },
    ]
    const skills = [{ skill_key: 'k1', label: 'Umfang', fundament_tiefe: 1 }, { skill_key: 'k2', label: 'Fläche', fundament_tiefe: 2 },
      { skill_key: 'v1', label: 'Einsetzen', fundament_tiefe: 0 }, { skill_key: 'v2', label: 'ohne Thema', fundament_tiefe: 0 }]
    const kanten = [{ skill_key: 'k1', voraussetzt_skill_key: 'v1' }, { skill_key: 'k1', voraussetzt_skill_key: 'v2' }]
    expect(fertigkeitWahl(['k1'], themen, skills, kanten, 'Voraussetzungen').map((f) => `${f.gruppe}:${f.key}`))
      .toEqual(['Kreis:k1', 'Kreis:k2', 'Voraussetzungen:v1'])
  })
})

const task = (id: string, title: string, over: Partial<AuthoringTask> = {}): AuthoringTask => ({
  id, title, question: 'Berechne.', status: 'review', input_type: 'NUMERIC', afb: 'I', competency_content: 'arithmetik_algebra',
  competency_process: 'ope', cluster_id: 'c1', unit: null, skill_key: null, est_duration_sec: 60, class_level: 8,
  curriculum_grade: 7, parts: [], assets: [], needs_image: null, licence_text: null, question_payload: null,
  source: 'edvance_original', source_ref: null, is_active: true, created_at: '2026-07-01T00:00:00Z', ...over,
})

const zeige = (): void => {
  vi.mocked(listAuthoringTasks).mockResolvedValue({
    data: [task('a', 'Aufgabe Alpha'), task('b', 'Aufgabe Beta'), task('c', 'Aufgabe Gamma')], error: null,
  })
  render(
    <MemoryRouter initialEntries={['/admin/authoring/liste']}>
      <Routes>
        <Route path="/admin/authoring/liste" element={<AuthoringItemsPage />} />
        <Route path="/admin/pruefen/:taskId" element={<p>Prüfansicht geöffnet</p>} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('Expertenliste mit Auswahl', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    sessionStorage.clear()
  })

  it('Auswahl zeigt die Sammelleiste; der Kopf ist halb markiert; ein Filterwechsel leert die Auswahl mit Hinweis', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('checkbox', { name: 'Aufgabe Alpha auswählen' }))
    expect(screen.getByText('1 ausgewählt')).toBeTruthy()
    const kopf = screen.getByRole('checkbox', { name: /Alle im Filter \(3\)/ }) as HTMLInputElement
    expect(kopf.indeterminate).toBe(true)
    fireEvent.change(screen.getByPlaceholderText('Im Titel suchen'), { target: { value: 'Beta' } })
    expect(screen.queryByText('1 ausgewählt')).toBeNull()
    expect(screen.getByText('Auswahl aufgehoben, weil der Filter geändert wurde.')).toBeTruthy()
  })

  it('Freigeben: Vorschau, Bestaetigen mit Zahl, „Ausgelassene anzeigen“ waehlt genau die Ausgelassenen', async () => {
    const ergebnis = { betrifft: ['a'], ausgelassen: [{ task_id: 'b', grund: 'geaendert', text: null }, { task_id: 'c', grund: 'rueckfrage_offen', text: null }] }
    vi.mocked(pruefSammel).mockResolvedValue({ data: ergebnis, error: null })
    zeige()
    fireEvent.click(await screen.findByRole('checkbox', { name: /Alle im Filter \(3\)/ }))
    fireEvent.click(within(screen.getByRole('region', { name: 'Sammelaktionen' })).getAllByRole('button', { name: /Freigeben/ })[0])
    const bestaetigen = await screen.findByRole('button', { name: '1 freigeben' })
    expect(screen.getByText('geändert, einzeln prüfen')).toBeTruthy()
    expect(vi.mocked(pruefSammel).mock.calls[0]).toEqual(['freigeben', ['a', 'b', 'c'], {}, true])
    fireEvent.click(bestaetigen)
    await waitFor(() => expect(vi.mocked(pruefSammel).mock.calls[1]).toEqual(['freigeben', ['a', 'b', 'c'], {}, false]))
    fireEvent.click(await screen.findByRole('button', { name: 'Ausgelassene anzeigen' }))
    await waitFor(() => expect(screen.getByText('2 ausgewählt')).toBeTruthy())
    expect((screen.getByRole('checkbox', { name: 'Aufgabe Beta auswählen' }) as HTMLInputElement).checked).toBe(true)
    expect((screen.getByRole('checkbox', { name: 'Aufgabe Gamma auswählen' }) as HTMLInputElement).checked).toBe(true)
    expect((screen.getByRole('checkbox', { name: 'Aufgabe Alpha auswählen' }) as HTMLInputElement).checked).toBe(false)
  })

  it('ein Klick auf die Zeile oeffnet die Admin-Pruefansicht mit dem Filter als Reihe', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Aufgabe Beta' }))
    expect(await screen.findByText('Prüfansicht geöffnet')).toBeTruthy()
    const reihe = leseReihe()
    expect(reihe?.ids).toHaveLength(3)
    expect(reihe?.herkunft).toBe('liste')
    expect(reihe?.zurueck).toBe('/admin/authoring/liste?wiederherstellen=1')
  })

  it('„Durchlauf starten · n“ ersetzt die Pflege-Strecke', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: /Durchlauf starten · 3/ }))
    expect(await screen.findByText('Prüfansicht geöffnet')).toBeTruthy()
    expect(screen.queryByText(/Pflege-Strecke/)).toBeNull()
  })
})
