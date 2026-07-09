import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import {
  getClustersBySubject,
  getSubjects,
  getTasksByCluster,
} from '@/lib/supabase/tasks'
import type { Task } from '@/types'
import { DiagnosticsPage } from './DiagnosticsPage'
import { makeCluster, makeSubject, makeTask } from './diagnostics/testFixtures'

vi.mock('@/lib/supabase/tasks', () => ({
  getSubjects: vi.fn(),
  getClustersBySubject: vi.fn(),
  getTasksByCluster: vi.fn(),
}))

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'admin@edvance.de' }, signOut: vi.fn() }),
}))

// Die Kinder sind eigenständig getestet. Hier zählt nur die Orchestrierung der
// Seite: laden, State halten, EmptyState vs. n TaskRow rendern.
vi.mock('./diagnostics/NewTaskForm', () => ({
  NewTaskForm: () => <div data-testid="new-task-form" />,
}))
vi.mock('./diagnostics/TaskRow', () => ({
  TaskRow: ({ task }: { task: Task }) => <div data-testid="task-row">{task.id}</div>,
}))

const subjectsMock = vi.mocked(getSubjects)
const clustersMock = vi.mocked(getClustersBySubject)
const tasksMock = vi.mocked(getTasksByCluster)

function renderPage(): void {
  render(
    <MemoryRouter>
      <DiagnosticsPage />
    </MemoryRouter>,
  )
}

/** Wählt das Cluster im zweiten Select der Seite und wartet auf den Lib-Aufruf. */
async function selectCluster(): Promise<void> {
  await waitFor(() => expect(clustersMock).toHaveBeenCalledWith('subject-1'))
  await screen.findByRole('option', { name: 'Bruchrechnung' })
  fireEvent.change(screen.getAllByRole('combobox')[1], { target: { value: 'cluster-1' } })
  await waitFor(() => expect(tasksMock).toHaveBeenCalledWith('cluster-1'))
}

beforeEach(() => {
  subjectsMock.mockReset()
  clustersMock.mockReset()
  tasksMock.mockReset()
  subjectsMock.mockResolvedValue({ data: [makeSubject()], error: null })
  clustersMock.mockResolvedValue({ data: [makeCluster()], error: null })
  tasksMock.mockResolvedValue({ data: [], error: null })
})

describe('DiagnosticsPage', () => {
  it('zeigt den EmptyState "Cluster wählen", solange kein Cluster gewählt ist', async () => {
    renderPage()

    await screen.findByText('Cluster wählen')
    expect(tasksMock).not.toHaveBeenCalled()
    expect(screen.queryAllByTestId('task-row')).toHaveLength(0)
  })

  it('zeigt den EmptyState "Keine Aufgaben" bei leerer Liste', async () => {
    renderPage()
    await selectCluster()

    await screen.findByText('Keine Aufgaben')
    expect(screen.queryAllByTestId('task-row')).toHaveLength(0)
  })

  it('rendert für n Tasks genau n TaskRow', async () => {
    tasksMock.mockResolvedValue({
      data: [makeTask({ id: 'task-1' }), makeTask({ id: 'task-2' }), makeTask({ id: 'task-3' })],
      error: null,
    })
    renderPage()
    await selectCluster()

    const rows = await screen.findAllByTestId('task-row')
    expect(rows).toHaveLength(3)
    expect(rows.map((r) => r.textContent)).toEqual(['task-1', 'task-2', 'task-3'])
  })

  it('zeigt einen Fehler aus dem Lib-Aufruf an', async () => {
    tasksMock.mockResolvedValue({ data: null, error: 'Laden fehlgeschlagen' })
    renderPage()
    await selectCluster()

    await screen.findByText('Laden fehlgeschlagen')
  })
})
