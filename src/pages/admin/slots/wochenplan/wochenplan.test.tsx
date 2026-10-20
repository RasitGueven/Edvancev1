// Slots W2: Wochenplan als eine Planungsfläche. Raster mit Räumen je Zelle (Farbe, „kein Coach“), Kennzahlen mit
// Testkonten, Zeile „Einzel“, Panels über die URL (Zurück schließt) und die Umleitungen der alten Adressen.
// Supabase gemockt, erfundene Daten.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import '@/i18n'
import type { SlotsTag, SlotsTermin, SlotsWoche, WocheZelle, ZelleRaum } from '@/types/slotplan'
import type { StundenplanSession } from '@/types/stundenplan'

vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: { id: 'ZZ_admin' }, role: 'admin', loading: false }) }))
const slot = vi.hoisted(() => ({
  ladeWoche: vi.fn(), ladeCoaches: vi.fn(), ladeTermin: vi.fn(), ladeTag: vi.fn(), ladeEinstellungen: vi.fn(), ladeKinder: vi.fn(),
}))
const sp = vi.hoisted(() => ({ ladeStundenplanWoche: vi.fn(), ladeSessionLeitung: vi.fn(), ladeKinderBuchbar: vi.fn(), sofortSessionAnlegen: vi.fn() }))
vi.mock('@/lib/supabase/slotplan', () => slot)
vi.mock('@/lib/supabase/stundenplan', () => sp)
vi.mock('@/lib/supabase/sessions', () => ({
  KEIN_PLATZ_ZUGANG: 'ZG001', TESTLAUF_GESTARTET: '55000', TESTLAUF_NUR_TESTKONTEN: '22023',
  setSessionTestlauf: vi.fn(), createSession: vi.fn(), addStudentToSession: vi.fn(),
}))

const { SlotsPage } = await import('../SlotsPage')
const { ScheduleUmleitung, TerminUmleitung } = await import('../SlotsUmleitung')

const raum = (name: string, belegt: number, offen = true): ZelleRaum => ({
  raum_id: name, name, offen, art: offen ? 'stamm' : 'faellt_aus', coach_id: offen ? 'c' : null, coach_name: offen ? 'Sara' : null, belegt,
})
const zelle = (datum: string, zeit_id: string, raeume: ZelleRaum[], teil: Partial<WocheZelle> = {}): WocheZelle => ({
  datum, zeit_id, kapazitaet: 10, belegt: 0, ohne_raum: 0, coach_fehlt: 0, faecher: [], vergangen: false, laeuft: false, raeume, ...teil,
})
const TAGE = ['2026-11-02', '2026-11-03', '2026-11-04', '2026-11-05', '2026-11-06']
const WOCHE: SlotsWoche = {
  montag: '2026-11-02', kw: 45, a_woche: true, heute: '2026-11-02',
  tage: TAGE.map((datum, i) => ({ datum, wochentag: i + 1, betrieb: i !== 4, anlass: i === 4 ? 'Brückentag' : null, heute: i === 0, vergangen: false })),
  zeiten: [{ id: 'z14', beginn: '14:00', ende: '15:00' }, { id: 'z15', beginn: '15:00', ende: '16:00' }],
  zellen: [
    zelle('2026-11-02', 'z14', [raum('A1', 4), raum('B1', 2)]),
    zelle('2026-11-02', 'z15', [raum('A1', 3), raum('B1', 2, false)], { laeuft: true }),
    zelle('2026-11-03', 'z14', [raum('A1', 0, false)]),
    zelle('2026-11-03', 'z15', [raum('A1', 5)]),
    zelle('2026-11-04', 'z14', [raum('A1', 1)]),
    zelle('2026-11-04', 'z15', []),
    zelle('2026-11-05', 'z14', [raum('A1', 3)]),
    zelle('2026-11-05', 'z15', [raum('A1', 3)]),
  ],
  kopf: {
    plaetze: 40, belegt: 21, belegt_test: 2, auslastung: 21 / 40, auslastung_mit_test: 23 / 40, ohne_raum: 0, erster_ohne_raum: null,
    ohne_stammplatz: 2, ohne_stammplatz_test: 4, ohne_stammplatz_laufend: 1, raeume_ohne_coach: 1,
  },
}
const EINZEL: StundenplanSession = {
  session_id: 'e1', scheduled_at: '2026-11-03T09:30:00Z', room: 'B1', status: 'upcoming', testlauf: true, gestartet: false,
  coach_id: 'ZZ_admin', coach_name: 'Ada Admin', coach_rolle: 'admin', kinder: [],
}
const TERMIN = {
  datum: '2026-11-02', kw: 45, zeit: { id: 'z14', beginn: '14:00', ende: '15:00' }, betrieb: true, anlass: null, heute: true, vergangen: false,
  begonnen: false, laeuft: false, festgeschrieben: false, kapazitaet: 10, belegt: 0, raeume: [], ohne_raum: [], nicht_dabei: [],
  anwesenheit_fehlt: false, raeume_schliessbar: [], coaches: [],
} as SlotsTermin
const TAG: SlotsTag = {
  datum: '2026-11-03', betrieb: true, anlass: null, absagen: [],
  raum_termine: [
    { zeit_id: 'z15', beginn: '15:00', ende: '16:00', raum_id: 'A1', raum_name: 'A1', coach_id: 'c', coach_name: 'Deniz Aydın', art: 'stamm',
      offen: true, kapazitaet: 5, belegt: 5, session_id: null, gestartet: false, status: null },
  ],
  sessions_ohne_raum: [{ session_id: 'e1', scheduled_at: '2026-11-03T09:30:00Z', room: 'B1', status: 'upcoming', coach_id: 'ZZ_admin',
    coach_name: 'Ada Admin', testlauf: true, gestartet: false, kinder: 0 }],
}

function Ort(): JSX.Element {
  const l = useLocation()
  const navigate = useNavigate()
  return (
    <>
      <p data-testid="ort">{l.pathname + l.search}</p>
      <button type="button" onClick={() => navigate(-1)}>Browser zurück</button>
    </>
  )
}

async function zeige(pfad: string): Promise<void> {
  render(
    <MemoryRouter initialEntries={['/start', pfad]} initialIndex={1}>
      <Routes>
        <Route path="/admin/slots" element={<><SlotsPage /><Ort /></>} />
        <Route path="/admin/schedule" element={<ScheduleUmleitung />} />
        <Route path="/admin/slots/termin/:datum/:zeitId" element={<TerminUmleitung />} />
        <Route path="*" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
  await act(async () => {})
}
const ort = (): string => screen.getByTestId('ort').textContent ?? ''

beforeEach(() => {
  for (const f of [...Object.values(slot), ...Object.values(sp)]) f.mockReset()
  slot.ladeWoche.mockResolvedValue({ data: WOCHE, error: null })
  slot.ladeCoaches.mockResolvedValue({ data: null, error: null })
  slot.ladeTermin.mockResolvedValue({ data: TERMIN, error: null })
  slot.ladeTag.mockResolvedValue({ data: TAG, error: null })
  slot.ladeEinstellungen.mockResolvedValue({ data: { raeume: [] }, error: null })
  sp.ladeStundenplanWoche.mockResolvedValue({ data: { montag: '2026-11-02', sessions: [EINZEL] }, error: null })
  sp.ladeSessionLeitung.mockResolvedValue({ data: [], error: null })
})

describe('Wochenplan', () => {
  it('Reiter ohne Stundenplan; Kennzahlen nennen Kinder und Testkonten getrennt; A-Woche', async () => {
    await zeige('/admin/slots?woche=2026-11-02')
    expect(within(screen.getByRole('tablist')).getAllByRole('tab').map((r) => r.textContent?.replace(/\d+$/, ''))).toEqual([
      'Wochenplan', 'Kinder', 'Coaches', 'Einstellungen',
    ])
    expect(screen.getByText('23')).toBeTruthy()
    expect(screen.getByText('21 Kinder · 2 Testkonten')).toBeTruthy()
    expect(screen.getByText('ohne Testkonten 53 %')).toBeTruthy()
    expect(screen.getByText('Coach setzen oder umbuchen')).toBeTruthy()
    expect(screen.getByText('Kinder · dazu 4 Testkonten')).toBeTruthy()
    expect(screen.getByText('A-Woche (ungerade KW)')).toBeTruthy()
  })

  it('Raster: je Raum eine Zeile, „kein Coach“, „x frei“, „läuft gerade“, „kein Raum besetzt“, Tag ohne Betrieb mit Anlass, Zeile „Einzel“', async () => {
    await zeige('/admin/slots?woche=2026-11-02')
    const z1 = screen.getByRole('button', { name: '6 Kinder, 4 frei' })
    expect(within(z1).getByText('4/5')).toBeTruthy()
    expect(within(z1).getByText('2/5')).toBeTruthy()
    const z2 = screen.getByRole('button', { name: /^5 Kinder, 2 frei, läuft gerade/ })
    expect(within(z2).getByText('kein Coach')).toBeTruthy()
    // Geschlossener Raum ohne Kinder steht nicht in der Zelle.
    expect(screen.getAllByText('kein Raum besetzt')).toHaveLength(2)
    expect(screen.getByText('Brückentag')).toBeTruthy()
    expect(screen.getByRole('button', { name: /10:30 · B1/ }).textContent).toContain('Testlauf · Ada Admin')
  })

  it('Klick auf eine Zelle öffnet das Slot-Panel über die URL; Zurück schließt es', async () => {
    await zeige('/admin/slots?woche=2026-11-02')
    fireEvent.click(screen.getByRole('button', { name: '6 Kinder, 4 frei' }))
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-02&slot=2026-11-02_z14')
    expect(slot.ladeTermin).toHaveBeenCalledWith('2026-11-02', 'z14')
    expect(screen.getByRole('dialog', { name: 'Montag, 2. November · 14:00–15:00' })).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Browser zurück' }))
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-02')
    expect(screen.queryByRole('dialog')).toBeNull()
  })

  it('Schließen-Knopf geht einen Schritt zurück; Tagespanel → „Öffnen“ ersetzt den Schritt', async () => {
    await zeige('/admin/slots?woche=2026-11-02')
    fireEvent.click(screen.getByRole('button', { name: /Dienstag/ }))
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-02&tag=2026-11-03')
    const panel = screen.getByRole('dialog', { name: 'Dienstag, 3. November' })
    expect(within(panel).getByText('Deniz Aydın')).toBeTruthy()
    expect(within(panel).getByText('Freie Plätze über den Tag: 0 · 5 Kinder eingeplant')).toBeTruthy()
    fireEvent.click(within(panel).getByRole('button', { name: '15:00 öffnen' }))
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-02&slot=2026-11-03_z15')
    fireEvent.click(screen.getAllByRole('button', { name: 'Schließen' }).at(-1) as HTMLElement)
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-02')
  })

  it('Einzel-Session öffnet das Session-Panel mit Testlauf-Schalter', async () => {
    await zeige('/admin/slots?woche=2026-11-02')
    fireEvent.click(screen.getByRole('button', { name: /10:30 · B1/ }))
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-02&einzel=2026-11-03_e1')
    expect(screen.getByRole('switch', { name: /Testlauf/ })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Kinder zuweisen' })).toBeTruthy()
  })

  it('direkt über die URL geöffnet: Schließen bleibt in den Slots und behält die Woche des Panels', async () => {
    await zeige('/admin/slots?slot=2026-11-09_z14')
    expect(slot.ladeWoche).toHaveBeenCalledWith('2026-11-09')
    fireEvent.click(screen.getAllByRole('button', { name: 'Schließen' }).at(-1) as HTMLElement)
    await act(async () => {})
    expect(ort()).toBe('/admin/slots?woche=2026-11-09')
  })
})

describe('Umleitungen (Entscheidung 1 und 6)', () => {
  it('?reiter=stundenplan landet im Wochenplan, die Woche bleibt', async () => {
    await zeige('/admin/slots?woche=2026-11-02&reiter=stundenplan')
    expect(ort()).toBe('/admin/slots?woche=2026-11-02')
    expect(screen.getByRole('tab', { name: /Wochenplan/ }).getAttribute('aria-selected')).toBe('true')
  })

  it('/admin/schedule landet im Wochenplan, die Woche bleibt', async () => {
    await zeige('/admin/schedule?woche=2026-11-09')
    expect(ort()).toBe('/admin/slots?woche=2026-11-09')
  })

  it('/admin/slots/termin/:datum/:zeitId öffnet das Slot-Panel', async () => {
    await zeige('/admin/slots/termin/2026-11-02/z14')
    expect(ort()).toBe('/admin/slots?slot=2026-11-02_z14')
    expect(screen.getByRole('dialog', { name: 'Montag, 2. November · 14:00–15:00' })).toBeTruthy()
  })
})
