// Rueckfrage klaeren: hoechstens zwei Knoepfe; "Zurueckweisen" nur ueber das "…"-Menue und nur mit Grund.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'

vi.mock('@/lib/supabase/pruefung', () => ({
  pruefRueckfrageKlaeren: vi.fn(),
}))

import { pruefRueckfrageKlaeren } from '@/lib/supabase/pruefung'
import { RueckfrageKlaeren } from './RueckfrageKlaeren'

describe('RueckfrageKlaeren', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(pruefRueckfrageKlaeren).mockResolvedValue({ data: { status: 'beanstandet' }, error: null })
  })

  it('zeigt Freigeben und Zurueck an Lena, Zurueckweisen erst im Menue', () => {
    render(<RueckfrageKlaeren taskId="t1" onReload={vi.fn()} />)
    expect(screen.getByRole('button', { name: 'Freigeben' })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Zurück an Lena' })).toBeTruthy()
    expect(screen.queryByRole('button', { name: 'Zurückweisen' })).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: 'Weitere Aktionen' }))
    expect(screen.getByRole('menuitem', { name: 'Zurückweisen …' })).toBeTruthy()
  })

  it('Zurueckweisen verlangt mindestens einen Grund', async () => {
    const onReload = vi.fn()
    render(<RueckfrageKlaeren taskId="t1" onReload={onReload} />)
    fireEvent.click(screen.getByRole('button', { name: 'Weitere Aktionen' }))
    fireEvent.click(screen.getByRole('menuitem', { name: 'Zurückweisen …' }))
    fireEvent.click(screen.getByRole('button', { name: 'Zurückweisen' }))
    expect(screen.getByRole('alert').textContent).toBe('Zum Zurückweisen bitte mindestens einen Grund wählen.')
    expect(pruefRueckfrageKlaeren).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: 'Sprachlich zu schwer für Kinder' }))
    fireEvent.click(screen.getByRole('button', { name: 'Zurückweisen' }))
    await waitFor(() => expect(pruefRueckfrageKlaeren).toHaveBeenCalledWith('t1', 'zurueckweisen', '', ['sprache_zu_schwer']))
    expect(onReload).toHaveBeenCalled()
  })
})
