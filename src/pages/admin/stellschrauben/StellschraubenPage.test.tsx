// C2 Test 8: Stellschrauben-Seite. Speichern ohne Grund und ausserhalb der Spanne geht nicht;
// Coaches sehen die Seite nicht (Route nur admin, Eintrag nur in der Admin-Leiste).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const auth = vi.hoisted(() => ({ rolle: 'admin' as string }))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'a1', email: 'admin@edvance.de' }, role: auth.rolle, loading: false, signOut: vi.fn() }),
}))
vi.mock('@/lib/supabase/freigabe', () => ({ getDarfPruefen: vi.fn() }))
const m = vi.hoisted(() => ({ list: vi.fn(), protokoll: vi.fn(), setzen: vi.fn() }))
vi.mock('@/lib/supabase/sessionEinstellungen', () => ({
  listStellschrauben: m.list, listStellschraubenProtokoll: m.protokoll, stellschraubeSetzen: m.setzen,
}))

import { ProtectedRoute } from '@/components/edvance/ProtectedRoute'
import { ADMIN_NAV } from '@/components/edvance/admin/adminNav'
import { coachNav } from '@/components/edvance/coach/coachNav'
import { speichernSperre, wertAusEingabe } from '@/lib/session/stellschrauben'
import type { Stellschraube } from '@/types'
import { StellschraubenPage } from './StellschraubenPage'

const signal: Stellschraube = {
  schluessel: 'signal_fehlversuche', beschreibung: 'Signal nach Fehlversuchen in Folge', typ: 'zahl', wert: 2, startwert: 2,
  min: 1, max: 4, ganzzahl: true, werte: null, einheit: 'anzahl', geaendert_am: null,
}
const quote: Stellschraube = {
  schluessel: 'ziel_erfolgsquote', beschreibung: 'Ziel-Erfolgsquote', typ: 'zahl', wert: 0.8, startwert: 0.8,
  min: 0.6, max: 0.9, ganzzahl: false, werte: null, einheit: 'anteil', geaendert_am: '2026-10-06T10:00:00.000Z',
}

function zeige(): void {
  render(
    <MemoryRouter initialEntries={['/admin/stellschrauben']}>
      <Routes>
        <Route path="/admin/stellschrauben" element={<ProtectedRoute allowedRoles={['admin']}><StellschraubenPage /></ProtectedRoute>} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  auth.rolle = 'admin'
  m.list.mockReset().mockResolvedValue({ data: [signal, quote], error: null })
  m.protokoll.mockReset().mockResolvedValue({
    data: [{ id: 'p1', schluessel: 'ziel_erfolgsquote', alt: 0.75, neu: 0.8, grund: 'ZZ Erfahrung aus den ersten Sessions', von: 'a1', am: '2026-10-06T10:00:00.000Z' }],
    error: null,
  })
  m.setzen.mockReset().mockResolvedValue({ data: null, error: null })
})

describe('8 Regeln', () => {
  it('Spanne, Ganzzahl und Grund', () => {
    expect(speichernSperre(signal, wertAusEingabe(signal, '5'), 'Grund')).toBe('ausserhalb')
    expect(speichernSperre(signal, wertAusEingabe(signal, '2,5'), 'Grund')).toBe('ausserhalb')
    expect(speichernSperre(signal, wertAusEingabe(signal, '3'), '  ')).toBe('grundFehlt')
    expect(speichernSperre(signal, wertAusEingabe(signal, '2'), 'Grund')).toBe('unveraendert')
    expect(speichernSperre(signal, wertAusEingabe(signal, '3'), 'Grund')).toBeNull()
    expect(speichernSperre(quote, wertAusEingabe(quote, '0,85'), 'Grund')).toBeNull()
  })
})

describe('8 Stellschrauben-Seite', () => {
  it('zeigt Wert, Startwert, Spanne, Einheit und den Snapshot-Hinweis', async () => {
    zeige()
    expect(await screen.findByText('Ziel-Erfolgsquote')).toBeTruthy()
    expect(screen.getByText(/ab der nächsten gestarteten Session/)).toBeTruthy()
    expect(screen.getByText('60 % bis 90 %')).toBeTruthy()
    expect(screen.getByText('1 bis 4')).toBeTruthy()
  })

  it('Speichern ohne Grund und außerhalb der Spanne nicht möglich; mit Grund ruft es einstellung_setzen', async () => {
    zeige()
    fireEvent.click(await screen.findByText('Signal nach Fehlversuchen in Folge'))
    const karte = await screen.findByTestId('stellschraube-bearbeiten')
    const knopf = within(karte).getByRole('button', { name: 'Wert speichern' }) as HTMLButtonElement
    const feld = within(karte).getByRole('textbox', { name: 'Neuer Wert' })

    fireEvent.change(feld, { target: { value: '7' } })
    fireEvent.change(within(karte).getByRole('textbox', { name: 'Grund der Änderung' }), { target: { value: 'ZZ Test' } })
    expect(knopf.disabled).toBe(true)
    expect(knopf.title).toBe('Der Wert liegt außerhalb der erlaubten Spanne.')

    fireEvent.change(feld, { target: { value: '3' } })
    fireEvent.change(within(karte).getByRole('textbox', { name: 'Grund der Änderung' }), { target: { value: '' } })
    expect(knopf.disabled).toBe(true)
    expect(knopf.title).toBe('Ohne Grund lässt sich nicht speichern.')
    fireEvent.click(knopf)
    expect(m.setzen).not.toHaveBeenCalled()

    fireEvent.change(within(karte).getByRole('textbox', { name: 'Grund der Änderung' }), { target: { value: 'ZZ Kinder warten zu lange' } })
    expect(knopf.disabled).toBe(false)
    fireEvent.click(knopf)
    await waitFor(() => expect(m.setzen).toHaveBeenCalledWith('signal_fehlversuche', 3, 'ZZ Kinder warten zu lange'))
  })

  it('Verlauf je Schlüssel aus dem Protokoll', async () => {
    zeige()
    fireEvent.click(await screen.findByText('Ziel-Erfolgsquote'))
    expect(await screen.findByText('ZZ Erfahrung aus den ersten Sessions')).toBeTruthy()
    expect(screen.getByText('75 % → 80 %')).toBeTruthy()
    expect(m.protokoll).toHaveBeenCalledWith('ziel_erfolgsquote')
  })

  it('Coaches sehen die Seite nicht: Route nur admin, Eintrag nur in der Admin-Leiste', async () => {
    auth.rolle = 'coach'
    zeige()
    expect(screen.getByText('Kein Zugriff')).toBeTruthy()
    expect(m.list).not.toHaveBeenCalled()
    const routen = (nav: { gruppen: { eintraege: { route?: string }[] }[] }): (string | undefined)[] =>
      nav.gruppen.flatMap((g) => g.eintraege.map((e) => e.route))
    expect(routen(ADMIN_NAV)).toContain('/admin/stellschrauben')
    expect(routen(coachNav(true))).not.toContain('/admin/stellschrauben')
  })
})
