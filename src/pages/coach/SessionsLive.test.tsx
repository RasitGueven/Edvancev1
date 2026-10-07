// C2 Phase 3: Einstieg auf der Coach-Startseite. Sessions von heute mit „Session starten“ bzw.
// „Live-Sicht öffnen“, dazu die eigenen offenen Sessions. Wrapper gemockt (kein Supabase-Client).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'

const m = vi.hoisted(() => ({ sessionStarten: vi.fn(), sessionsOffen: vi.fn() }))
vi.mock('@/lib/supabase/sessionCoach', () => ({ sessionStarten: m.sessionStarten }))
vi.mock('@/lib/supabase/sessionC2', () => ({ sessionsOffen: m.sessionsOffen }))

import type { CoachingSession } from '@/types'
import { SessionsLive } from './SessionsLive'

const jetzt = new Date().toISOString()
const s = (id: string, status: CoachingSession['status'], extra: Partial<CoachingSession> = {}): CoachingSession => ({
  id, created_at: jetzt, coach_id: 'c1', room: `Raum ${id}`, scheduled_at: jetzt, status, ...extra,
})

function Ort(): JSX.Element {
  return <p data-testid="ort">{useLocation().pathname}</p>
}

function zeige(sessions: CoachingSession[]): void {
  render(
    <MemoryRouter initialEntries={['/coach']}>
      <Routes>
        <Route path="/coach" element={<SessionsLive sessions={sessions} />} />
        <Route path="*" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  m.sessionStarten.mockReset().mockResolvedValue({ data: {}, error: null })
  m.sessionsOffen.mockReset().mockResolvedValue({ data: [], error: null })
})

describe('Coach-Startseite: Sessions heute', () => {
  it('startet eine geplante Session und öffnet die Live-Sicht', async () => {
    zeige([s('1', 'upcoming', { testlauf: true })])
    expect(screen.getByText('Testlauf')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Session starten' }))
    await waitFor(() => expect(m.sessionStarten).toHaveBeenCalledWith('1'))
    expect((await screen.findByTestId('ort')).textContent).toBe('/coach/session/1/live')
  })

  it('laufende Session: ein Knopf „Live-Sicht öffnen“, kein Start', () => {
    zeige([s('2', 'active')])
    expect(screen.queryByRole('button', { name: 'Session starten' })).toBeNull()
    fireEvent.click(screen.getByRole('button', { name: 'Live-Sicht öffnen' }))
    expect(screen.getByTestId('ort').textContent).toBe('/coach/session/2/live')
  })

  it('Fehler beim Start bleibt auf der Seite', async () => {
    m.sessionStarten.mockResolvedValue({ data: null, error: 'session_starten: Session ist nicht geplant', code: 'P0001' })
    zeige([s('3', 'upcoming')])
    fireEvent.click(screen.getByRole('button', { name: 'Session starten' }))
    expect(await screen.findByText(/ließ sich nicht starten/)).toBeTruthy()
    expect(screen.queryByTestId('ort')).toBeNull()
  })

  it('offene Sessions mit Link zum Abschluss; Sessions anderer Tage nicht unter „heute“', async () => {
    m.sessionsOffen.mockResolvedValue({
      data: [{ session_id: 'alt', scheduled_at: '2026-10-01T14:00:00.000Z', room: 'Raum alt', status: 'active', coach_id: 'c1',
               coach_name: 'C', testlauf: false, kinder: 3 }],
      error: null,
    })
    zeige([s('4', 'upcoming', { scheduled_at: '2026-10-01T14:00:00.000Z' })])
    expect(screen.getByText('Heute keine Session')).toBeTruthy()
    expect(await screen.findByText('1 Session ist noch offen')).toBeTruthy()
    expect(screen.getByRole('link', { name: 'Zum Abschluss' }).getAttribute('href')).toBe('/coach/session/alt/live')
  })
})
