// Kachel „Zuhause geübt“ (Reihe 1 · D2.3): Balken je Skill ohne Ergebnis, ein Vorschlag mit Übernehmen /
// Nicht heute, Fragen aus Eddie. Die Lib ist eine Attrappe.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import '@/i18n'

const lib = vi.hoisted(() => ({ getZuhauseStand: vi.fn(), zeigsMirEntscheiden: vi.fn(), coachFrageErledigt: vi.fn() }))
vi.mock('@/lib/session/zuhause', () => lib)

import { ZuhauseKachel } from './ZuhauseKachel'

const stand = (entscheidung: 'uebernehmen' | 'nicht_heute' | null = null) => ({
  data: {
    skills: [
      { skill_key: 'prim', label: 'Primfaktoren', quests: 3, aufgaben: 15, dauer_sek: 1500 },
      { skill_key: 'teil', label: 'Teilweise die Wurzel ziehen', quests: 1, aufgaben: 5, dauer_sek: 540 },
    ],
    vorschlag: { skill_key: 'prim', label: 'Primfaktoren', entscheidung },
    fragen: [{ id: 'f1', text: 'Warum ist 1 keine Primzahl?', am: '2026-10-26T15:00:00Z' }],
  },
  error: null,
})

beforeEach(() => {
  Object.values(lib).forEach((f) => f.mockReset())
  lib.zeigsMirEntscheiden.mockResolvedValue({ data: null, error: null })
  lib.coachFrageErledigt.mockResolvedValue({ data: null, error: null })
})

describe('ZuhauseKachel', () => {
  it('zeigt Menge je Skill, nie ein Ergebnis', async () => {
    lib.getZuhauseStand.mockResolvedValue(stand())
    render(<ZuhauseKachel kindId="k" sessionId="s" />)
    expect(await screen.findByText('3 Quests · 15 Aufgaben')).toBeTruthy()
    expect(screen.getByText('1 Quest · 5 Aufgaben')).toBeTruthy()
    expect(screen.getByText(/34 Minuten insgesamt/)).toBeTruthy()
    expect(screen.queryByText(/richtig gelöst|falsch|%/)).toBeNull()
    expect(screen.getByText('„Warum ist 1 keine Primzahl?“')).toBeTruthy()
  })

  it('Übernehmen speichert und zeigt den Stand', async () => {
    lib.getZuhauseStand.mockResolvedValueOnce(stand()).mockResolvedValue(stand('uebernehmen'))
    render(<ZuhauseKachel kindId="k" sessionId="s" />)
    fireEvent.click(await screen.findByText('Übernehmen'))
    await waitFor(() => expect(lib.zeigsMirEntscheiden).toHaveBeenCalledWith('k', 's', 'prim', 'uebernehmen'))
    expect(await screen.findByText(/Übernommen\./)).toBeTruthy()
  })

  it('Nicht heute und Frage besprochen', async () => {
    lib.getZuhauseStand.mockResolvedValue(stand())
    render(<ZuhauseKachel kindId="k" sessionId="s" />)
    fireEvent.click(await screen.findByText('Nicht heute'))
    await waitFor(() => expect(lib.zeigsMirEntscheiden).toHaveBeenCalledWith('k', 's', 'prim', 'nicht_heute'))
    fireEvent.click(screen.getByText('Besprochen'))
    await waitFor(() => expect(lib.coachFrageErledigt).toHaveBeenCalledWith('f1'))
  })

  it('ohne Übung ein ruhiger Satz', async () => {
    lib.getZuhauseStand.mockResolvedValue({ data: { skills: [], vorschlag: null, fragen: [] }, error: null })
    render(<ZuhauseKachel kindId="k" sessionId="s" />)
    expect(await screen.findByText('Seit der letzten Session nicht zuhause geübt.')).toBeTruthy()
  })
})
