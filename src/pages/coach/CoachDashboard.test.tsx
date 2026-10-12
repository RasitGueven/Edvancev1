// Slots SL3: Coach „Heute“ — Einsätze aus dem Plan neben festgeschriebenen Sessions, ohne Doppelung,
// und die Kennzahl „Nächste Session“ aus einem Slot-Termin vor dem Festschreiben (erfundene Daten).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import { berlinLocalToIso, berlinToday } from '@/lib/datetime'
import { dieseWoche, wocheVerschieben } from '@/components/edvance/wochenNavigation.model'
import type { MeinEinsatz } from '@/types/slotplan'

const daten = vi.hoisted(() => ({ sessions: [] as unknown[], diese: [] as unknown[], naechste: [] as unknown[] }))
const USER = vi.hoisted(() => ({ user: { id: 'c1', email: 'coach@edvance.de' }, role: 'coach' }))

vi.mock('@/hooks/useAuth', () => ({ useAuth: () => USER }))
vi.mock('@/lib/supabase/sessions', () => ({
  listSessionsForCoach: vi.fn(() => Promise.resolve({ data: daten.sessions, error: null })),
  getSessionStudents: vi.fn(() => Promise.resolve({ data: [], error: null })),
  setAttendance: vi.fn(),
}))
vi.mock('@/lib/supabase/interventions', () => ({
  listInterventionsForSession: vi.fn(() => Promise.resolve({ data: [], error: null })),
  resolveIntervention: vi.fn(),
  startIntervention: vi.fn(),
}))
vi.mock('@/lib/supabase/students', () => ({ listStudentsWithName: vi.fn(() => Promise.resolve({ data: [], error: null })) }))
vi.mock('@/lib/supabase/freigabe', () => ({ getDarfPruefen: vi.fn(() => Promise.resolve({ data: false, error: null })) }))
vi.mock('@/lib/supabase/akte', () => ({ zaehleAktiveAkten: vi.fn(() => Promise.resolve({ data: 4, error: null })) }))
vi.mock('@/lib/supabase/sessionCoach', () => ({ sessionStarten: vi.fn() }))
vi.mock('@/lib/supabase/sessionC2', () => ({ sessionsOffen: vi.fn(() => Promise.resolve({ data: [], error: null })) }))
vi.mock('@/lib/supabase/progress', () => ({ getStudentProgress: vi.fn(() => Promise.resolve({ data: null, error: null })) }))
vi.mock('@/lib/supabase/slotplan', () => ({
  ladeMeineEinsaetze: vi.fn((montag: string) =>
    Promise.resolve({
      data: { montag, kw: 42, heute: '', einsaetze: montag === dieseWoche() ? daten.diese : daten.naechste },
      error: null,
    }),
  ),
  terminSessionAnlegen: vi.fn(),
}))

import { CoachDashboard } from './CoachDashboard'

const heute = berlinToday()
const einsatz = (datum: string, beginn: string, raum: string, extra: Partial<MeinEinsatz> = {}): MeinEinsatz => ({
  datum, zeit_id: `z-${beginn}`, beginn, ende: '23:59', raum_id: raum, raum_name: `ZZ Raum ${raum}`, heute: datum === heute,
  session_id: null, kinder: [{ student_id: `k-${raum}`, name: `ZZ_Kind ${raum}`, klasse: 8, fach: 'Mathematik' }], ...extra,
})

const zeige = (): void => {
  render(
    <MemoryRouter>
      <CoachDashboard />
    </MemoryRouter>,
  )
}

const kennzahl = (label: string): string =>
  (screen.getByText(label).parentElement?.querySelector('p:last-child')?.textContent ?? '').trim()

beforeEach(() => {
  daten.sessions = []
  daten.diese = []
  daten.naechste = []
})

describe('CoachDashboard (Slots SL3)', () => {
  it('keine Doppelung: ein festgeschriebener Einsatz steht nur als Session da, der offene Plan-Einsatz mit „Session öffnen“', async () => {
    daten.sessions = [
      { id: 's-fest', scheduled_at: berlinLocalToIso(heute, '23:57'), status: 'upcoming', room: 'ZZ Raum 1', coach_id: 'c1', testlauf: false },
    ]
    daten.diese = [einsatz(heute, '23:57', '1', { session_id: 's-fest' }), einsatz(heute, '23:58', '2')]
    zeige()
    const live = (await screen.findByRole('heading', { name: 'Heute im Raum' })).closest('section') as HTMLElement
    expect(await within(live).findByRole('region', { name: 'Einsatz 23:58, ZZ Raum 2' })).toBeTruthy()
    expect(within(live).queryByRole('region', { name: 'Einsatz 23:57, ZZ Raum 1' })).toBeNull()
    expect(within(live).getAllByText(/ZZ Raum 1/)).toHaveLength(1)
    expect(within(live).getAllByRole('button', { name: 'Session öffnen' })).toHaveLength(1)
    expect(within(live).getByRole('button', { name: 'Session starten' })).toBeTruthy()
    expect(kennzahl('Sessions heute')).toBe('2')
  })

  it('„Nächste Session“ zeigt einen Slot-Termin, der noch nicht festgeschrieben ist', async () => {
    const naechsterMontag = wocheVerschieben(dieseWoche(), 1)
    daten.sessions = [{ id: 'alt', scheduled_at: '2020-01-01T10:00:00Z', status: 'upcoming', room: 'ZZ', coach_id: 'c1', testlauf: false }]
    daten.naechste = [einsatz(naechsterMontag, '15:00', '1')]
    zeige()
    await screen.findByRole('heading', { name: 'Heute im Raum' })
    await vi.waitFor(() => expect(kennzahl('Nächste Session')).toMatch(/15:00 Uhr$/))
    const [y, m, d] = naechsterMontag.split('-')
    expect(kennzahl('Nächste Session')).toContain(`${d}.${m}.${y}`)
  })
})
