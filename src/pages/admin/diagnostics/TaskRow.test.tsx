import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { updateTaskDiagnostic } from '@/lib/supabase/tasks'
import { TaskRow } from './TaskRow'
import { makeTask } from './testFixtures'

// Kein echter Supabase-Call: die Lib-Funktion wird gespiegelt, damit der Test
// nur das Presentation-/Callback-Verhalten der extrahierten Zeile prüft.
vi.mock('@/lib/supabase/tasks', () => ({
  updateTaskDiagnostic: vi.fn(),
}))

// Die Vorschau ist eine eigenständige, separat getestete Komponente — hier zählt
// nur, dass TaskRow sie ein- und ausblendet (kein Markdown-/KaTeX-Rendering).
vi.mock('@/components/edvance/tasks/TaskPreviewCard', () => ({
  TaskPreviewCard: () => <div data-testid="task-preview" />,
}))

const updateMock = vi.mocked(updateTaskDiagnostic)

beforeEach(() => {
  updateMock.mockReset()
  updateMock.mockResolvedValue({ data: null, error: null })
})

describe('TaskRow', () => {
  it('rendert Frage, Badge und die Felder des übergebenen Task-Objekts', () => {
    render(<TaskRow task={makeTask()} onSaved={vi.fn()} />)

    screen.getByText('Wie viel ist 2 + 2?')
    screen.getByText('In Diagnose aktiv')
    expect(screen.getByLabelText('Diese Aufgabe im Diagnose-Test verwenden')).toBeTruthy()

    const selects = screen.getAllByRole('combobox') as HTMLSelectElement[]
    expect(selects.map((s) => s.value)).toEqual(['3', 'NUMERIC', 'FACT'])
  })

  it('nutzt den Titel, wenn vorhanden, sonst die Frage', () => {
    render(<TaskRow task={makeTask({ title: 'Bruch kürzen' })} onSaved={vi.fn()} />)
    screen.getByText('Bruch kürzen')
  })

  it('zeigt den Badge für nicht-diagnostische Aufgaben', () => {
    render(<TaskRow task={makeTask({ is_diagnostic: false })} onSaved={vi.fn()} />)
    screen.getByText('Nicht in Diagnose')
  })

  it('speichert den bearbeiteten Stand und meldet nach oben', async () => {
    const onSaved = vi.fn()
    render(<TaskRow task={makeTask()} onSaved={onSaved} />)

    fireEvent.click(screen.getByLabelText('Diese Aufgabe im Diagnose-Test verwenden'))
    fireEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    await waitFor(() =>
      expect(updateMock).toHaveBeenCalledWith('task-1', {
        is_diagnostic: false,
        difficulty: 3,
        input_type: 'NUMERIC',
        cognitive_type: 'FACT',
      }),
    )
    await waitFor(() => expect(onSaved).toHaveBeenCalledTimes(1))
  })

  it('zeigt den Fehler und meldet nicht nach oben, wenn das Speichern fehlschlägt', async () => {
    const onSaved = vi.fn()
    updateMock.mockResolvedValue({ data: null, error: 'Speichern fehlgeschlagen' })
    render(<TaskRow task={makeTask()} onSaved={onSaved} />)

    fireEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    await screen.findByText('Speichern fehlgeschlagen')
    expect(onSaved).not.toHaveBeenCalled()
  })

  it('blendet die Vorschau per Button ein und aus', () => {
    render(<TaskRow task={makeTask()} onSaved={vi.fn()} />)
    expect(screen.queryByTestId('task-preview')).toBeNull()

    fireEvent.click(screen.getByRole('button', { name: /Aufgabe ansehen/ }))
    expect(screen.getByTestId('task-preview')).toBeTruthy()

    fireEvent.click(screen.getByRole('button', { name: /Vorschau schließen/ }))
    expect(screen.queryByTestId('task-preview')).toBeNull()
  })
})
