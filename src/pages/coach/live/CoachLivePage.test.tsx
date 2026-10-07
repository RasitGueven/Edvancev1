// C1 Tests 5, 6 und 7: Die Route weist Schuelerkonten ab (dieselben Rollen wie in
// App.tsx), Musterloesung und Fehlbild erscheinen nur in der Schublade, und der
// Abschluss wartet auf „nicht erschienen“. Datenquelle mit Beispieldaten, useAuth gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'coach' as string }))

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'coach@edvance.de' }, role: auth.rolle, loading: false, signOut: vi.fn() }),
}))
vi.mock('@/lib/supabase/freigabe', () => ({ getDarfPruefen: vi.fn() }))
// C2: Die App liest echte Daten; diese Tests laufen mit der Beispielquelle aus C1.
vi.mock('@/lib/session/coachLive', () => import('@/lib/session/coachLiveBeispielQuelle'))

import { ProtectedRoute } from '@/components/edvance/ProtectedRoute'
import { beispielZeitpunktSetzen, beispielZuruecksetzen, sessionAbschliessen, tabletLoesen } from '@/lib/session/coachLiveBeispielQuelle'
import { COACH_LIVE_ROLLEN, CoachLivePage } from './CoachLivePage'

function zeige(): void {
  render(
    <MemoryRouter initialEntries={['/coach/session/s1/live']}>
      <Routes>
        <Route
          path="/coach/session/:id/live"
          element={
            <ProtectedRoute allowedRoles={COACH_LIVE_ROLLEN}>
              <CoachLivePage />
            </ProtectedRoute>
          }
        />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  beispielZuruecksetzen()
  auth.rolle = 'coach'
})

describe('5 Route der Live-Sicht', () => {
  it('weist ein Schülerkonto ab', () => {
    auth.rolle = 'student'
    zeige()
    expect(screen.getByText('Kein Zugriff')).toBeTruthy()
    expect(screen.queryByText(/Session 16:30/)).toBeNull()
  })

  it('lässt Coach und Admin hinein', async () => {
    for (const rolle of ['coach', 'admin']) {
      auth.rolle = rolle
      const { unmount } = render(
        <MemoryRouter initialEntries={['/coach/session/s1/live']}>
          <Routes>
            <Route
              path="/coach/session/:id/live"
              element={
                <ProtectedRoute allowedRoles={COACH_LIVE_ROLLEN}>
                  <CoachLivePage />
                </ProtectedRoute>
              }
            />
          </Routes>
        </MemoryRouter>,
      )
      expect(await screen.findByText('Session 16:30 · Raum 1')).toBeTruthy()
      unmount()
    }
    expect(COACH_LIVE_ROLLEN).not.toContain('student')
  })
})

describe('6 Musterlösung und Fehlbild nur in der Schublade', () => {
  it('Kacheln und Warteschlange zeigen beides nicht, die Schublade schon', async () => {
    zeige()
    await screen.findByText('Session 16:30 · Raum 1')
    // Kernarbeit: Emir hängt bei Aufgabe 5.
    expect(screen.queryByText('Ergebnis: −6x + 15')).toBeNull()
    expect(screen.queryByText(/Minus nur auf den ersten Summanden/)).toBeNull()
    expect(screen.queryByText(/Musterlösung/)).toBeNull()
    expect(screen.queryByTestId('musterloesung')).toBeNull()

    fireEvent.click(screen.getByRole('button', { name: 'Emir Şahin öffnen' }))
    const schublade = await screen.findByRole('dialog', { name: 'Kind im Detail' })
    expect(within(schublade).getByTestId('musterloesung').textContent).toContain('Ergebnis: −6x + 15')
    expect(within(schublade).getByText('Fehlbild: Minus nur auf den ersten Summanden angewendet')).toBeTruthy()

    fireEvent.click(within(schublade).getByRole('button', { name: 'Schließen' }))
    expect(screen.queryByTestId('musterloesung')).toBeNull()
  })
})

describe('7 Abschluss nur nach Bestätigung der Kinder ohne Tablet', () => {
  it('sperrt den Abschluss, bis „nicht erschienen“ bestätigt ist', async () => {
    await tabletLoesen('s1', 'deniz')
    await beispielZeitpunktSetzen('s1', 'danach')
    expect((await sessionAbschliessen('s1')).error).toBe('ohneTabletOffen')

    zeige()
    const knopf = await screen.findByRole('button', { name: 'Session abschließen' })
    expect((knopf as HTMLButtonElement).disabled).toBe(true)
    const liste = screen.getByTestId('ohne-tablet')
    expect(within(liste).getByText('Deniz Arslan')).toBeTruthy()

    fireEvent.click(within(liste).getByRole('button', { name: 'Nicht erschienen bestätigen' }))
    await waitFor(() => expect((screen.getByRole('button', { name: 'Session abschließen' }) as HTMLButtonElement).disabled).toBe(false))
    fireEvent.click(screen.getByRole('button', { name: 'Session abschließen' }))
    expect(await screen.findByText('Abgeschlossen um 17:34')).toBeTruthy()
  })
})

describe('C2: Phasen im Kopf statt Beispielleiste', () => {
  it('zeigt keine Beispielleiste und schaltet die Ansicht über die Phasen im Kopf', async () => {
    zeige()
    await screen.findByText('Session 16:30 · Raum 1')
    expect(screen.queryByTestId('beispiel-leiste')).toBeNull()
    const leiste = screen.getByRole('group', { name: 'Phasen der Session' })
    const erwartet: [string, string][] = [
      ['Check-in', 'Check-in am Tablet'],
      ['Warm-up', 'Raum 1 · Warm-up'],
      ['Check-out', 'Check-out · ein konkreter Satz je Kind'],
      ['Kernarbeit', 'Raum 1 · Kernarbeit'],
    ]
    for (const [knopf, titel] of erwartet) {
      fireEvent.click(within(leiste).getByRole('button', { name: knopf }))
      expect(await screen.findByText(titel)).toBeTruthy()
    }
    fireEvent.click(screen.getByRole('button', { name: 'Abschluss' }))
    expect(await screen.findByText('Geht in die Akten')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Live folgen' }))
    expect(await screen.findByText('Raum 1 · Kernarbeit')).toBeTruthy()
  })
})

describe('C2 Test 7: Prüffrage-Knopf nur bei Mastery-Kandidaten', () => {
  it('Kandidatin Mila: aufs Tablet legen, Zustand „liegt auf dem Tablet“, wieder wegnehmen', async () => {
    zeige()
    await screen.findByText('Session 16:30 · Raum 1')
    fireEvent.click(screen.getByRole('button', { name: 'Mila Krämer öffnen' }))
    const schublade = await screen.findByRole('dialog', { name: 'Kind im Detail' })
    fireEvent.click(within(schublade).getByRole('button', { name: 'Prüffrage aufs Tablet' }))
    expect(await within(schublade).findByText('Die Prüffrage steht gerade auf dem Tablet von Mila.')).toBeTruthy()
    fireEvent.click(within(schublade).getByRole('button', { name: 'Vom Tablet nehmen' }))
    await waitFor(() => expect(within(schublade).getByRole('button', { name: 'Prüffrage aufs Tablet' })).toBeTruthy())
    expect(within(schublade).queryByText(/sieht das Abzeichen/)).toBeNull()
  })

  it('kein Knopf bei einem Kind ohne Kandidatur', async () => {
    zeige()
    await screen.findByText('Session 16:30 · Raum 1')
    fireEvent.click(screen.getByRole('button', { name: 'Emir Şahin öffnen' }))
    const schublade = await screen.findByRole('dialog', { name: 'Kind im Detail' })
    expect(within(schublade).queryByTestId('pruefung-tablet')).toBeNull()
  })
})
