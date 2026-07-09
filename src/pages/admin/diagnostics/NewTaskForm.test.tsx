import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { createDiagnosticTask, getMicroskillsByCluster } from '@/lib/supabase/tasks'
import { NewTaskForm } from './NewTaskForm'
import { makeCluster } from './testFixtures'

// Kein echter Supabase-Call: der Schreibaufruf bleibt an seiner Stelle im
// Formular, wird hier aber als Spy beobachtet.
vi.mock('@/lib/supabase/tasks', () => ({
  createDiagnosticTask: vi.fn(),
  getMicroskillsByCluster: vi.fn(),
}))

const createMock = vi.mocked(createDiagnosticTask)
const microskillsMock = vi.mocked(getMicroskillsByCluster)

const clusters = [makeCluster()]

beforeEach(() => {
  createMock.mockReset()
  createMock.mockResolvedValue({ data: null, error: null })
  microskillsMock.mockReset()
  microskillsMock.mockResolvedValue({ data: [], error: null })
})

describe('NewTaskForm', () => {
  it('rendert alle Eingabefelder', () => {
    render(<NewTaskForm clusters={clusters} onCreated={vi.fn()} />)

    expect(screen.getAllByRole('combobox')).toHaveLength(5)
    expect(screen.getByLabelText('Klassenstufe')).toBeTruthy()
    expect(screen.getByLabelText('Frage')).toBeTruthy()
    expect(screen.getByLabelText('Lösung')).toBeTruthy()
    screen.getByRole('button', { name: 'Diagnose-Aufgabe anlegen' })
    screen.getByRole('option', { name: 'Bruchrechnung' })
  })

  it('validiert die leere Frage und ruft die Lib nicht auf', async () => {
    const onCreated = vi.fn()
    render(<NewTaskForm clusters={clusters} onCreated={onCreated} />)

    fireEvent.click(screen.getByRole('button', { name: 'Diagnose-Aufgabe anlegen' }))

    await screen.findByText('Frage erforderlich.')
    expect(createMock).not.toHaveBeenCalled()
    expect(onCreated).not.toHaveBeenCalled()
  })

  it('legt eine Aufgabe mit getrimmter Frage an und meldet nach oben', async () => {
    const onCreated = vi.fn()
    render(<NewTaskForm clusters={clusters} onCreated={onCreated} />)

    fireEvent.change(screen.getByLabelText('Frage'), { target: { value: '  2 + 2 = ?  ' } })
    fireEvent.click(screen.getByRole('button', { name: 'Diagnose-Aufgabe anlegen' }))

    await waitFor(() =>
      expect(createMock).toHaveBeenCalledWith({ question: '2 + 2 = ?', cluster_id: null }),
    )
    await waitFor(() => expect(onCreated).toHaveBeenCalledTimes(1))
  })

  it('lädt Microskills zum gewählten Cluster und reicht die cluster_id weiter', async () => {
    render(<NewTaskForm clusters={clusters} onCreated={vi.fn()} />)

    const clusterSelect = screen.getAllByRole('combobox')[0]
    fireEvent.change(clusterSelect, { target: { value: 'cluster-1' } })

    await waitFor(() => expect(microskillsMock).toHaveBeenCalledWith('cluster-1'))

    fireEvent.change(screen.getByLabelText('Frage'), { target: { value: 'Kürze 4/8.' } })
    fireEvent.click(screen.getByRole('button', { name: 'Diagnose-Aufgabe anlegen' }))

    await waitFor(() =>
      expect(createMock).toHaveBeenCalledWith({ question: 'Kürze 4/8.', cluster_id: 'cluster-1' }),
    )
  })

  it('übernimmt Schwierigkeit, Antwortformat und Anspruch in den Lib-Aufruf', async () => {
    render(<NewTaskForm clusters={clusters} onCreated={vi.fn()} />)

    const [, , difficulty, inputType, cognitiveType] = screen.getAllByRole('combobox')
    fireEvent.change(difficulty, { target: { value: '4' } })
    fireEvent.change(inputType, { target: { value: 'MC' } })
    fireEvent.change(cognitiveType, { target: { value: 'TRANSFER' } })
    fireEvent.change(screen.getByLabelText('Klassenstufe'), { target: { value: '9' } })
    fireEvent.change(screen.getByLabelText('Frage'), { target: { value: 'Frage?' } })

    fireEvent.click(screen.getByRole('button', { name: 'Diagnose-Aufgabe anlegen' }))

    await waitFor(() =>
      expect(createMock).toHaveBeenCalledWith({
        question: 'Frage?',
        difficulty: 4,
        input_type: 'MC',
        cognitive_type: 'TRANSFER',
        class_level: 9,
        cluster_id: null,
      }),
    )
  })

  it('zeigt den Lib-Fehler und meldet nicht nach oben', async () => {
    const onCreated = vi.fn()
    createMock.mockResolvedValue({ data: null, error: 'Anlegen fehlgeschlagen' })
    render(<NewTaskForm clusters={clusters} onCreated={onCreated} />)

    fireEvent.change(screen.getByLabelText('Frage'), { target: { value: 'Frage?' } })
    fireEvent.click(screen.getByRole('button', { name: 'Diagnose-Aufgabe anlegen' }))

    await screen.findByText('Anlegen fehlgeschlagen')
    expect(onCreated).not.toHaveBeenCalled()
  })
})
