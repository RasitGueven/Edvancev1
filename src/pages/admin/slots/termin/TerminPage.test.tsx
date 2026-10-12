// Slots SL2, Test 5: "Ohne Raum" steht zuerst und nur, wenn es Kinder ohne Raum gibt. Vergangener Termin ohne Aktionen.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { SlotsTermin, TerminKind } from '@/types/slotplan'

const sp = vi.hoisted(() => ({ ladeTermin: vi.fn() }))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { TerminPage } = await import('./TerminPage')

const kind = (n: number, teil: Partial<TerminKind> = {}): TerminKind => ({
  student_id: `k${n}`, name: `Kind ${n}`, klasse: 8, fach: 'Mathematik', termin_id: `t${n}`, herkunft: 'stammplatz',
  zustand: 'planned', raum_fest: false, session_id: null, umgebucht_von: null, ...teil,
})

function termin(teil: Partial<SlotsTermin> = {}): SlotsTermin {
  return {
    datum: '2028-03-16', kw: 11, zeit: { id: 'z16', beginn: '16:00', ende: '17:00' }, betrieb: true, anlass: null,
    heute: false, vergangen: false, begonnen: false, festgeschrieben: false, kapazitaet: 5, belegt: 5,
    raeume: [
      { raum_id: 'r1', name: 'Raum 1', offen: true, art: 'stamm', coach_id: 'c1', coach_name: 'Tom Berg', stamm_coach_id: 'c1',
        stamm_coach_name: 'Tom Berg', vertretung: false, gemischt: false, session_id: null, gestartet: false,
        kinder: [kind(1), kind(2, { herkunft: 'zusatz' }), kind(3, { herkunft: 'zusatz', umgebucht_von: { termin_id: 'x', datum: '2028-03-14', beginn: '16:00' } })] },
      { raum_id: 'r2', name: 'Raum 2', offen: false, art: 'faellt_aus', coach_id: null, coach_name: null, stamm_coach_id: 'c2',
        stamm_coach_name: 'Jana Keller', vertretung: false, gemischt: false, session_id: null, gestartet: false, kinder: [] },
    ],
    ohne_raum: [kind(6), kind(7)],
    nicht_dabei: [{ student_id: 'k9', name: 'Kind 9', klasse: 9, fach: 'Deutsch', termin_id: 't9', zustand: 'cancelled', herkunft: 'stammplatz',
      absage_eingang: '2028-03-15T17:40:00+00:00', rechtzeitig: true, zuruecknehmbar: true }],
    anwesenheit_fehlt: false,
    raeume_schliessbar: [{ raum_id: 'r2', name: 'Raum 2' }],
    coaches: [{ id: 'c1', name: 'Tom Berg', raum_id: 'r1' }, { id: 'c2', name: 'Jana Keller', raum_id: null }],
    ...teil,
  }
}

async function zeige(t: SlotsTermin): Promise<void> {
  sp.ladeTermin.mockResolvedValue({ data: t, error: null })
  render(
    <MemoryRouter initialEntries={['/admin/slots/termin/2028-03-16/z16']}>
      <Routes>
        <Route path="/admin/slots/termin/:datum/:zeitId" element={<TerminPage />} />
      </Routes>
    </MemoryRouter>,
  )
  await act(async () => {})
}

beforeEach(() => sp.ladeTermin.mockReset())

describe('Termin', () => {
  it('Kopf mit Datum, Uhrzeit und Stand; "Ohne Raum" steht vor den Räumen, mit genau zwei Knöpfen je Kind', async () => {
    await zeige(termin())
    expect(screen.getByRole('heading', { level: 1 }).textContent).toBe('Donnerstag, 16. März · 16:00–17:00')
    expect(screen.getByText('5 Kinder · 5 Plätze · 1 von 2 Räumen geöffnet')).toBeTruthy()
    const ueberschriften = screen.getAllByRole('heading', { level: 2 }).map((h) => h.textContent)
    expect(ueberschriften[0]).toBe('Ohne Raum: 2 Kinder')
    expect(ueberschriften.slice(1)).toEqual(['Raum 1', 'Raum 2', 'Nicht dabei'])
    expect(screen.getAllByRole('button', { name: 'Umbuchen' })).toHaveLength(2)
    expect(screen.getAllByRole('button', { name: 'Ausgefallen (durch uns)' })).toHaveLength(2)
    expect(screen.getByText('umgebucht von Di 14.03.')).toBeTruthy()
    expect(screen.getByText('Zusatz')).toBeTruthy()
    expect(screen.getByText('Geschlossen · Stammschicht Jana Keller')).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Kind hinzufügen' })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Zurücknehmen' })).toBeTruthy()
  })

  it('ohne Kinder ohne Raum keine Karte "Ohne Raum"', async () => {
    await zeige(termin({ ohne_raum: [] }))
    expect(screen.queryByText(/^Ohne Raum/)).toBeNull()
    expect(screen.getAllByRole('heading', { level: 2 })[0].textContent).toBe('Raum 1')
  })

  it('vergangener Termin: nur Ansicht, Anwesenheit als Abzeichen, keine Aktionen', async () => {
    await zeige(termin({
      vergangen: true, begonnen: true, ohne_raum: [], anwesenheit_fehlt: true,
      raeume: [{ ...termin().raeume[0], kinder: [kind(1, { zustand: 'present' }), kind(2, { zustand: 'planned' })] }],
      nicht_dabei: [{ ...termin().nicht_dabei[0], zustand: 'unexcused', zuruecknehmbar: false }],
    }))
    expect(screen.getByText(/Vergangener Termin: nur Ansicht/)).toBeTruthy()
    // einmal im Kopf, einmal am Kind ohne Anwesenheit
    expect(screen.getAllByText('Anwesenheit fehlt')).toHaveLength(2)
    expect(screen.getByText('anwesend')).toBeTruthy()
    expect(screen.queryByRole('button', { name: 'Kind hinzufügen' })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Weitere Aktionen' })).toBeNull()
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(screen.queryByRole('button', { name: 'Zurücknehmen' })).toBeNull()
  })
})
