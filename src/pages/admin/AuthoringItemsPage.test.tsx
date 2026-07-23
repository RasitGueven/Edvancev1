// Smoke- und Verhaltenstest der Pflege-Liste.
//
// Supabase ist gemockt — geprueft wird, was die Liste selbst leistet: mountet sie,
// zaehlt sie die Befunde richtig, filtert sie, und sagt sie ehrlich, dass diese
// Datenbank die A01-Felder noch nicht hat.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { AuthoringTask } from '@/types'

vi.mock('@/lib/supabase/taskAuthoring', () => ({
  probeAuthoringSchema: vi.fn(),
  listAuthoringTasks: vi.fn(),
  listClustersWithSubject: vi.fn(),
  listReviewMeta: vi.fn(() => Promise.resolve(new Map())),
}))

// Die Navbar zieht useAuth → supabase/client, und der braucht Env-Variablen, die
// im Test nicht gesetzt sind. Auth ist hier ohnehin nicht Gegenstand.
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))

import {
  listAuthoringTasks,
  listClustersWithSubject,
  probeAuthoringSchema,
} from '@/lib/supabase/taskAuthoring'
import { AuthoringItemsPage } from './AuthoringItemsPage'

const task = (over: Partial<AuthoringTask>): AuthoringTask => ({
  id: 'id-1',
  title: 'Zwanzig Prozent',
  question: 'Berechne 20 % von 80 m.',
  status: 'draft',
  input_type: 'SHORT_TEXT',
  afb: 'I',
  competency_content: 'arithmetik_algebra',
  competency_process: 'ope',
  cluster_id: 'c1',
  unit: 'm',
  skill_key: 'prozent_prozentwert',
  est_duration_sec: 120,
  class_level: 8,
  curriculum_grade: 7,
  parts: [],
  assets: [],
  needs_image: null,
  licence_text: null,
  question_payload: null,
  // Eigenbau — der Quellen-Filter steht per Default auf "Nur Eigenbauten", also
  // ist das die Herkunft, mit der die Liste ein Item ueberhaupt zeigt.
  source: 'edvance_original',
  source_ref: null,
  is_active: true,
  created_at: '2026-07-01T00:00:00Z',
  ...over,
})

/** Ein Item aus dem VERA-Bestand — vom Quellen-Filter standardmaessig verdeckt. */
const veraTask = (over: Partial<AuthoringTask> = {}): AuthoringTask =>
  task({ id: 'vera-1', title: 'VERA-Aufgabe', source: 'VERA8_IQB', source_ref: 'ref-1', ...over })

const FULL_SCHEMA = { hasStoffanker: true, hasSolutionRead: true, hasStatusGate: true }

function setup(tasks: AuthoringTask[], schema = FULL_SCHEMA): void {
  vi.mocked(probeAuthoringSchema).mockResolvedValue(schema)
  vi.mocked(listAuthoringTasks).mockResolvedValue({ data: tasks, error: null })
  vi.mocked(listClustersWithSubject).mockResolvedValue({
    data: [{ id: 'c1', name: 'Zahl & Rechnen', subject_id: 's1', subject_name: 'Mathematik' }],
    error: null,
  })
  render(
    <MemoryRouter>
      <AuthoringItemsPage />
    </MemoryRouter>,
  )
}

describe('AuthoringItemsPage', () => {
  beforeEach(() => vi.clearAllMocks())

  it('listet die Items und meldet ein vollstaendiges als vollstaendig', async () => {
    setup([task({})])
    expect(await screen.findByText('Zwanzig Prozent')).toBeInTheDocument()
    expect(screen.getByText('Vollständig')).toBeInTheDocument()
    expect(screen.getByText('Stoff Kl. 7')).toBeInTheDocument()
  })

  it('zaehlt den fehlenden Stoffanker als blockierenden Befund', async () => {
    setup([task({ curriculum_grade: null })])
    expect(await screen.findByText('Stoffanker fehlt')).toBeInTheDocument()
    expect(screen.getByText('1 blockiert Freigabe')).toBeInTheDocument()
  })

  it('zaehlt fehlende Loesungen NICHT mit — die Liste hat sie nicht geladen', async () => {
    // Ohne die SOLUTION_CODES-Filterung haette dieses vollstaendige Item hier
    // "keine Lösung", nur weil die Liste nicht nachgesehen hat.
    setup([task({})])
    await screen.findByText('Zwanzig Prozent')
    expect(screen.queryByText(/Lösung/)).not.toBeInTheDocument()
  })

  it('filtert ueber die Suche im Titel', async () => {
    setup([task({}), task({ id: 'id-2', title: 'Pflaumen' })])
    await screen.findByText('Pflaumen')

    fireEvent.change(screen.getByPlaceholderText('Im Titel suchen'), {
      target: { value: 'pflaum' },
    })

    await waitFor(() => expect(screen.queryByText('Zwanzig Prozent')).not.toBeInTheDocument())
    expect(screen.getByText('Pflaumen')).toBeInTheDocument()
    expect(screen.getByText('1 von 2 Items')).toBeInTheDocument()
  })

  it('zeigt einen einladenden Leerzustand, wenn kein Item passt', async () => {
    setup([task({})])
    await screen.findByText('Zwanzig Prozent')

    fireEvent.change(screen.getByPlaceholderText('Im Titel suchen'), {
      target: { value: 'gibtesnicht' },
    })

    expect(await screen.findByText('Keine Items in dieser Auswahl')).toBeInTheDocument()
  })

  it('blendet den VERA-Bestand standardmaessig aus', async () => {
    setup([task({}), veraTask()])
    await screen.findByText('Zwanzig Prozent')

    expect(screen.queryByText('VERA-Aufgabe')).not.toBeInTheDocument()
    // Ehrlich gezaehlt: die Gesamtzahl verschweigt das Ausgeblendete nicht.
    expect(screen.getByText('1 von 2 Items')).toBeInTheDocument()
  })

  it('holt VERA ueber das Quellen-Dropdown zurueck — nichts ist geloescht', async () => {
    setup([task({}), veraTask()])
    await screen.findByText('Zwanzig Prozent')

    fireEvent.change(screen.getByLabelText('Quelle'), { target: { value: 'all' } })
    expect(await screen.findByText('VERA-Aufgabe')).toBeInTheDocument()
    expect(screen.getByText('Zwanzig Prozent')).toBeInTheDocument()

    fireEvent.change(screen.getByLabelText('Quelle'), { target: { value: 'vera' } })
    await waitFor(() =>
      expect(screen.queryByText('Zwanzig Prozent')).not.toBeInTheDocument(),
    )
    expect(screen.getByText('VERA-Aufgabe')).toBeInTheDocument()
  })

  it('warnt, wenn die Datenbank die A01-Felder noch nicht hat', async () => {
    setup([task({ curriculum_grade: undefined })], {
      hasStoffanker: false,
      hasSolutionRead: false,
      hasStatusGate: false,
    })
    expect(
      await screen.findByText('Diese Datenbank ist noch nicht auf Stand A01'),
    ).toBeInTheDocument()
    // Der fehlende Stoffanker darf dann NICHT blockieren — das Feld gibt es ja nicht.
    expect(screen.queryByText(/blockiert Freigabe/)).not.toBeInTheDocument()
  })
})
