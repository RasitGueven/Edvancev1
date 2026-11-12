import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { ArchivZeile } from '@/types/archiv'

const mocks = vi.hoisted(() => ({
  listArchiv: vi.fn(),
  archivWiederherstellen: vi.fn(),
}))
vi.mock('@/lib/supabase/archiv', () => ({
  listArchiv: mocks.listArchiv,
  archivWiederherstellen: mocks.archivWiederherstellen,
  countArchiv: vi.fn(),
}))

import { ArchivPage } from './ArchivPage'

const zeile = (id: string, skill: string, grund: ArchivZeile['grund'], status = 'draft'): ArchivZeile => ({
  id,
  kurztext: `Aufgabe ${id}`,
  skill_key: skill,
  skill_label: skill.toUpperCase(),
  status,
  input_type: 'NUMERIC',
  einsatz: ['lsa'],
  grund,
  archiviert_am: '2026-11-12T16:00:00Z',
  archiviert_von: null,
})

const ansicht = (): void => {
  render(
    <MemoryRouter>
      <ArchivPage />
    </MemoryRouter>,
  )
}

describe('ArchivPage', () => {
  beforeEach(() => {
    mocks.listArchiv.mockReset()
    mocks.archivWiederherstellen.mockReset()
  })

  it('zeigt archivierte Aufgaben und filtert nach Skill und Grund', async () => {
    mocks.listArchiv.mockResolvedValue({
      data: [zeile('a', 'bruch_add', 'nicht_notwendig'), zeile('b', 'potenzen', 'sonstiges', 'ready')],
      error: null,
    })
    ansicht()
    expect(await screen.findByText('Aufgabe a')).toBeInTheDocument()
    expect(screen.getByText('Aufgabe b')).toBeInTheDocument()
    fireEvent.change(screen.getByLabelText('Grund'), { target: { value: 'sonstiges' } })
    expect(screen.queryByText('Aufgabe a')).not.toBeInTheDocument()
    fireEvent.change(screen.getByLabelText('Grund'), { target: { value: '' } })
    fireEvent.change(screen.getByLabelText('Skill'), { target: { value: 'bruch_add' } })
    expect(screen.queryByText('Aufgabe b')).not.toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /löschen/i })).not.toBeInTheDocument()
  })

  it('stellt erst nach der Rückfrage wieder her, für die Auswahl', async () => {
    mocks.listArchiv.mockResolvedValueOnce({
      data: [zeile('a', 'bruch_add', 'nicht_notwendig'), zeile('b', 'bruch_add', 'nicht_notwendig')],
      error: null,
    })
    mocks.listArchiv.mockResolvedValueOnce({ data: [zeile('b', 'bruch_add', 'nicht_notwendig')], error: null })
    mocks.archivWiederherstellen.mockResolvedValue({ data: 1, error: null })
    ansicht()
    fireEvent.click(await screen.findByLabelText('Auswählen: Aufgabe a'))
    fireEvent.click(screen.getByRole('button', { name: 'Auswahl wiederherstellen (1)' }))
    expect(mocks.archivWiederherstellen).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Ja, wiederherstellen' }))
    await waitFor(() => expect(mocks.archivWiederherstellen).toHaveBeenCalledWith(['a']))
    expect(await screen.findByText('1 Aufgabe wiederhergestellt')).toBeInTheDocument()
    await waitFor(() => expect(screen.queryByText('Aufgabe a')).not.toBeInTheDocument())
  })

  it('Abbrechen stellt nichts wieder her; leeres Archiv zeigt einen Hinweis', async () => {
    mocks.listArchiv.mockResolvedValueOnce({ data: [zeile('a', 'x', 'nicht_notwendig')], error: null })
    ansicht()
    fireEvent.click((await screen.findAllByRole('button', { name: 'Wiederherstellen' }))[0])
    fireEvent.click(screen.getByRole('button', { name: 'Abbrechen' }))
    expect(mocks.archivWiederherstellen).not.toHaveBeenCalled()
  })

  it('leeres Archiv', async () => {
    mocks.listArchiv.mockResolvedValue({ data: [], error: null })
    ansicht()
    expect(await screen.findByText('Das Archiv ist leer')).toBeInTheDocument()
  })
})
