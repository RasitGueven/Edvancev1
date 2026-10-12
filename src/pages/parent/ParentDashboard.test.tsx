// Slots SL3: Die nächste Session im Eltern-Dashboard kommt aus naechste_termine und steht schon vor
// dem Festschreiben da (Entscheidung 14). Erfundene Daten.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import { formatSessionDate } from '@/lib/datetime'
import type { CoachingSession } from '@/types'
import { naechsteSessionEltern } from './naechsteSession'

const daten = vi.hoisted(() => ({ termine: { data: [] as unknown[] | null, error: null as string | null }, sessions: [] as unknown[] }))
const USER = vi.hoisted(() => ({ user: { id: 'p1', email: 'eltern@edvance.de' }, role: 'parent', signOut: () => undefined }))

vi.mock('@/hooks/useAuth', () => ({ useAuth: () => USER }))
vi.mock('@/lib/supabase/students', () => ({
  listStudentsWithName: vi.fn(() =>
    Promise.resolve({ data: [{ id: 'k1', full_name: 'ZZ_Ada Beispiel', class_level: 8, school_name: null, school_type: null }], error: null }),
  ),
}))
vi.mock('@/lib/supabase/parentReports', () => ({ listReportsForStudent: vi.fn(() => Promise.resolve({ data: [], error: null })) }))
vi.mock('@/lib/supabase/sessions', () => ({
  listUpcomingSessionsForStudent: vi.fn(() => Promise.resolve({ data: daten.sessions, error: null })),
}))
vi.mock('@/lib/supabase/slotplan', () => ({ ladeNaechsteTermine: vi.fn(() => Promise.resolve(daten.termine)) }))

import { ParentDashboard } from './ParentDashboard'

const termin = { beginn: '2028-03-14T14:00:00.000Z', datum: '2028-03-14', uhrzeit: '15:00', ende: '16:00', festgeschrieben: false, session_id: null }

beforeEach(() => {
  daten.termine = { data: [termin], error: null }
  daten.sessions = []
})

describe('ParentDashboard: nächste Session', () => {
  it('zeigt einen Slot-Termin, der noch nicht festgeschrieben ist', async () => {
    render(
      <MemoryRouter>
        <ParentDashboard />
      </MemoryRouter>,
    )
    expect(await screen.findByText(formatSessionDate(termin.beginn))).toBeTruthy()
    expect(screen.queryByText('Noch kein Termin geplant.')).toBeNull()
  })

  it('ohne Termin: „Noch kein Termin geplant.“', async () => {
    daten.termine = { data: [], error: null }
    render(
      <MemoryRouter>
        <ParentDashboard />
      </MemoryRouter>,
    )
    expect(await screen.findByText('Noch kein Termin geplant.')).toBeTruthy()
  })
})

describe('naechsteSessionEltern', () => {
  const session = { id: 's1', scheduled_at: '2028-03-14T14:00:00.000Z', room: 'ZZ Raum 1' } as CoachingSession

  it('festgeschrieben: Raum aus der Session', () => {
    expect(naechsteSessionEltern([{ ...termin, festgeschrieben: true, session_id: 's1' }], [session])).toEqual({ beginn: termin.beginn, room: 'ZZ Raum 1' })
  })

  it('naechste_termine gescheitert: bisherige Quelle', () => {
    expect(naechsteSessionEltern(null, [session])).toEqual({ beginn: session.scheduled_at, room: 'ZZ Raum 1' })
  })
})
