// Slots SL2 Test 5, W2: Das Slot-Panel ersetzt die Termin-Seite. "Ohne Raum" steht zuerst und nur, wenn es Kinder
// ohne Raum gibt; vergangener Termin ohne Aktionen. Neu je Raum: „+ Kind in …“ (gesperrt mit Grund bei 5/5),
// Session öffnen / Live-Sicht nach betriebAktion, bei laufender Session „Live“ je Kind. Erfundene Daten.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { SlotsTermin, TerminKind, TerminRaum } from '@/types/slotplan'

const sp = vi.hoisted(() => ({
  ladeTermin: vi.fn(), ladeKandidatenAlle: vi.fn(), zusatzterminBuchen: vi.fn(), stammplatzVergeben: vi.fn(),
  terminSessionAnlegen: vi.fn(), ladeZiele: vi.fn(), terminAbsagen: vi.fn(), terminUmbuchen: vi.fn(),
  absageZuruecknehmen: vi.fn(), terminAusgefallen: vi.fn(), terminCoachSetzen: vi.fn(), terminRaumSetzen: vi.fn(),
  terminFaelltAus: vi.fn(), terminRaumOeffnen: vi.fn(),
}))
vi.mock('@/lib/supabase/slotplan', () => sp)

const { SlotPanel } = await import('./SlotPanel')

const kind = (n: number, teil: Partial<TerminKind> = {}): TerminKind => ({
  student_id: `k${n}`, name: `Kind ${n}`, klasse: 8, fach: 'Mathematik', termin_id: `t${n}`, herkunft: 'stammplatz',
  zustand: 'planned', raum_fest: false, session_id: null, umgebucht_von: null, ...teil,
})

const raum1 = (teil: Partial<TerminRaum> = {}): TerminRaum => ({
  raum_id: 'r1', name: 'Raum 1', offen: true, art: 'stamm', coach_id: 'c1', coach_name: 'Tom Berg', stamm_coach_id: 'c1',
  stamm_coach_name: 'Tom Berg', vertretung: false, gemischt: false, session_id: null, gestartet: false,
  kinder: [kind(1), kind(2, { herkunft: 'zusatz' }), kind(3, { herkunft: 'zusatz', umgebucht_von: { termin_id: 'x', datum: '2028-03-14', beginn: '16:00' } })],
  ...teil,
})

function termin(teil: Partial<SlotsTermin> = {}): SlotsTermin {
  return {
    datum: '2028-03-16', kw: 11, zeit: { id: 'z16', beginn: '16:00', ende: '17:00' }, betrieb: true, anlass: null,
    heute: false, vergangen: false, begonnen: false, laeuft: false, festgeschrieben: false, kapazitaet: 5, belegt: 5,
    raeume: [
      raum1(),
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
    <MemoryRouter>
      <SlotPanel datum={t.datum} zeitId={t.zeit.id} einzel={[]} onPanel={vi.fn()} onClose={vi.fn()} onGeaendert={vi.fn()} />
    </MemoryRouter>,
  )
  await act(async () => {})
}

const raumKarte = (name: string): HTMLElement => screen.getByRole('heading', { level: 3, name }).closest('div.flex') as HTMLElement

beforeEach(() => {
  for (const f of Object.values(sp)) f.mockReset()
})

describe('Slot-Panel (früher Termin-Seite)', () => {
  it('Kopf mit Datum, Uhrzeit und Stand; "Ohne Raum" steht vor den Räumen, mit genau zwei Knöpfen je Kind', async () => {
    await zeige(termin())
    expect(screen.getByRole('heading', { level: 2 }).textContent).toBe('Donnerstag, 16. März · 16:00–17:00')
    expect(screen.getByText('5 von 5 Plätzen belegt · 1 Raum mit Coach')).toBeTruthy()
    const ueberschriften = screen.getAllByRole('heading', { level: 3 }).map((h) => h.textContent)
    expect(ueberschriften[0]).toBe('Ohne Raum: 2 Kinder')
    expect(ueberschriften.slice(1)).toEqual(['Raum 1', 'Raum 2', 'Nicht dabei'])
    expect(screen.getAllByRole('button', { name: 'Umbuchen' })).toHaveLength(2)
    expect(screen.getAllByRole('button', { name: 'Ausgefallen (durch uns)' })).toHaveLength(2)
    expect(screen.getByText('umgebucht von Di 14.03.')).toBeTruthy()
    expect(screen.getByText('Zusatz')).toBeTruthy()
    expect(screen.getByText('Geschlossen · Stammschicht Jana Keller')).toBeTruthy()
    expect(screen.getByRole('button', { name: '+ Kind in Raum 1' })).toBeTruthy()
    // Ein Raum ohne Coach bekommt kein „+ Kind“: das Kind säße ohne Coach (S4 nicht freigegeben).
    expect(screen.queryByRole('button', { name: '+ Kind in Raum 2' })).toBeNull()
    expect(screen.getByRole('button', { name: 'Zurücknehmen' })).toBeTruthy()
    // Zukünftiger Termin: Session erst am Termintag.
    expect(screen.getByText('Öffnen am Termintag')).toBeTruthy()
  })

  it('ohne Kinder ohne Raum keine Karte "Ohne Raum"', async () => {
    await zeige(termin({ ohne_raum: [] }))
    expect(screen.queryByText(/^Ohne Raum/)).toBeNull()
    expect(screen.getAllByRole('heading', { level: 3 })[0].textContent).toBe('Raum 1')
  })

  it('vergangener Termin: nur Ansicht, Anwesenheit als Abzeichen, keine Aktionen', async () => {
    await zeige(termin({
      vergangen: true, begonnen: true, ohne_raum: [], anwesenheit_fehlt: true,
      raeume: [{ ...raum1(), kinder: [kind(1, { zustand: 'present' }), kind(2, { zustand: 'planned' })] }],
      nicht_dabei: [{ ...termin().nicht_dabei[0], zustand: 'unexcused', zuruecknehmbar: false }],
    }))
    expect(screen.getByText(/Vergangener Termin: nur Ansicht/)).toBeTruthy()
    expect(screen.getAllByText('Anwesenheit fehlt')).toHaveLength(2)
    expect(screen.getByText('anwesend')).toBeTruthy()
    expect(screen.queryByRole('button', { name: /^\+ Kind/ })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Weitere Aktionen' })).toBeNull()
    expect(screen.queryByRole('combobox')).toBeNull()
    expect(screen.queryByRole('button', { name: 'Zurücknehmen' })).toBeNull()
  })

  it('voller Raum (5/5) sperrt „+ Kind“ mit Grund', async () => {
    await zeige(termin({ raeume: [raum1({ kinder: [1, 2, 3, 4, 5].map((n) => kind(n)) })], ohne_raum: [] }))
    const knopf = screen.getByRole('button', { name: '+ Kind in Raum 1' }) as HTMLButtonElement
    expect(knopf.disabled).toBe(true)
    expect(knopf.getAttribute('title')).toBe('Raum ist voll (5 von 5).')
    expect(screen.getByText('Raum ist voll (5 von 5).')).toBeTruthy()
  })

  it('Raum mit Kindern ohne Coach: rot gefüllt „kein Coach“ mit Satz', async () => {
    await zeige(termin({
      ohne_raum: [],
      raeume: [{ ...raum1(), offen: false, art: 'faellt_aus', coach_id: null, coach_name: null }],
    }))
    const karte = raumKarte('Raum 1')
    expect(within(karte).getByText('kein Coach')).toBeTruthy()
    expect(within(karte).getByText(/Tom Berg fällt aus\. 3 Kinder sitzen in einem Raum ohne Coach/)).toBeTruthy()
  })

  it('„Live“ je Kind nur bei laufender Session', async () => {
    await zeige(termin({ heute: true, laeuft: true, begonnen: true, ohne_raum: [], raeume: [raum1({ session_id: 's1', gestartet: true })] }))
    const links = screen.getAllByRole('link', { name: 'Live' })
    expect(links).toHaveLength(3)
    expect(links[0].getAttribute('href')).toBe('/coach/session/s1/live')
    expect(screen.getByRole('link', { name: 'Live-Sicht' }).getAttribute('href')).toBe('/coach/session/s1/live')
    document.body.innerHTML = ''
    await zeige(termin({ heute: true, ohne_raum: [], raeume: [raum1({ session_id: 's1' })] }))
    expect(screen.queryByRole('link', { name: 'Live' })).toBeNull()
  })

  it('am Termintag: „Session öffnen“ nur im Raum mit Kindern (betriebAktion), leerer Raum ohne Knopf', async () => {
    await zeige(termin({
      heute: true, ohne_raum: [],
      raeume: [raum1(), { ...raum1({ raum_id: 'r3', name: 'Raum 3', coach_id: 'c3', kinder: [] }) }],
    }))
    expect(screen.getAllByRole('button', { name: 'Session öffnen' })).toHaveLength(1)
    expect(within(raumKarte('Raum 3')).getByText('Noch keine Kinder: keine Session nötig.')).toBeTruthy()
  })

  it('„+ Kind in Raum 1“ öffnet den Dialog für genau diesen Raum', async () => {
    sp.ladeKandidatenAlle.mockResolvedValue({ data: [], error: null })
    await zeige(termin())
    fireEvent.click(screen.getByRole('button', { name: '+ Kind in Raum 1' }))
    await act(async () => {})
    expect(sp.ladeKandidatenAlle).toHaveBeenCalledWith('2028-03-16', 'z16', 'r1')
    expect(screen.getByRole('dialog', { name: 'Kind in Raum 1' })).toBeTruthy()
  })
})
