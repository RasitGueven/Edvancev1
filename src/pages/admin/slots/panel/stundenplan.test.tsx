// Slots S2/W2: Session-Karte (im Session-Panel des Wochenplans), Kinderwahl und Session planen. Früher SchedulePage.test.tsx (P5b, T2): Die Regeln
// setzt weiter die Datenbank durch (ZG001, Testlauf-Trigger); neu zeigt die Wahl alle Kinder, nicht buchbare
// ausgegraut mit Grund aus kinder_buchbar. Supabase ist gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { KindBuchbar, StundenplanSession } from '@/types/stundenplan'

const ses = vi.hoisted(() => ({
  KEIN_PLATZ_ZUGANG: 'ZG001',
  TESTLAUF_GESTARTET: '55000',
  TESTLAUF_NUR_TESTKONTEN: '22023',
  setSessionTestlauf: vi.fn(),
  createSession: vi.fn(),
  addStudentToSession: vi.fn(),
}))
const sp = vi.hoisted(() => ({
  ladeKinderBuchbar: vi.fn(),
  ladeSessionLeitung: vi.fn(),
  ladeStundenplanWoche: vi.fn(),
  sofortSessionAnlegen: vi.fn(),
}))
const slot = vi.hoisted(() => ({ ladeEinstellungen: vi.fn() }))
vi.mock('@/lib/supabase/sessions', () => ses)
vi.mock('@/lib/supabase/stundenplan', () => sp)
vi.mock('@/lib/supabase/slotplan', () => slot)
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: { id: 'ZZ_admin' }, role: 'admin', loading: false }) }))

const { SessionKarte } = await import('./SessionKarte')
const { KindAuswahl } = await import('./KindAuswahl')
const { SessionPlanen } = await import('./SessionPlanen')

const kind = (id: string, name: string, code: KindBuchbar['code'], detail: string | null = null, ist_test = false): KindBuchbar =>
  ({ student_id: id, name, klasse: 8, ist_test, code, detail })

const SESSION: StundenplanSession = {
  session_id: 'ZZ_session', scheduled_at: '2027-11-04T13:00:00Z', room: 'Raum 1', status: 'upcoming', testlauf: false,
  gestartet: false, coach_id: 'ZZ_admin', coach_name: 'Ada Admin', coach_rolle: 'admin', kinder: [],
}

function karte(session: StundenplanSession = SESSION, onGeaendert = vi.fn()): void {
  render(<MemoryRouter><SessionKarte session={session} onGeaendert={onGeaendert} /></MemoryRouter>)
}

beforeEach(() => {
  for (const f of [ses.setSessionTestlauf, ses.createSession, ses.addStudentToSession, ...Object.values(sp), slot.ladeEinstellungen]) f.mockReset()
  sp.ladeKinderBuchbar.mockResolvedValue({
    data: [kind('ZZ_mit', 'Mia Mit', 'ok'), kind('ZZ_ohne', 'Olaf Ohne', 'kein_vertrag')], error: null,
  })
})

describe('Kinderwahl: nicht buchbare Kinder ausgegraut mit Grund', () => {
  const FAELLE: [KindBuchbar['code'], string | null, string][] = [
    ['kein_vertrag', null, 'Kein Vertrag'],
    ['widerrufen', '2027-10-05', 'Vertrag widerrufen am 05.10.2027'],
    ['vertrag_ab', '2027-12-01', 'Vertrag beginnt am 01.12.2027'],
    ['vertrag_beendet', '2027-08-31', 'Vertrag endete am 31.08.2027'],
    ['keine_einheit', null, 'Keine offene Einheit'],
    ['schon_termin', null, 'Hat an diesem Tag schon einen Termin'],
    ['art_konflikt', null, 'Passt nicht zur Session (Testkonto und echtes Kind)'],
  ]

  it.each(FAELLE)('%s: ausgegraut, nicht wählbar, Satz aus slots.json', (code, detail, satz) => {
    const onWahl = vi.fn()
    render(<KindAuswahl kinder={[kind('ZZ_k', 'Kim Grund', code, detail)]} fehler={null} gewaehlt={[]} onWahl={onWahl} frei={5} />)
    const zeile = screen.getByText('Kim Grund').closest('li') as HTMLElement
    expect(within(zeile).getByText(satz)).toBeTruthy()
    const box = within(zeile).getByRole('checkbox') as HTMLInputElement
    expect(box.disabled).toBe(true)
    fireEvent.click(box)
    expect(onWahl).not.toHaveBeenCalled()
  })

  it('ok: wählbar, ohne Satz; Testkonto trägt „Test“; Suche filtert', () => {
    const onWahl = vi.fn()
    render(<KindAuswahl kinder={[kind('ZZ_a', 'Anna Ok', 'ok'), kind('ZZ_t', 'Tom Test', 'ok', null, true)]} fehler={null} gewaehlt={[]} onWahl={onWahl} frei={5} />)
    fireEvent.click(within(screen.getByText('Anna Ok').closest('li') as HTMLElement).getByRole('checkbox'))
    expect(onWahl).toHaveBeenCalledWith(['ZZ_a'])
    expect(within(screen.getByText('Tom Test').closest('li') as HTMLElement).getByText('Test')).toBeTruthy()
    fireEvent.change(screen.getByLabelText('Kind suchen'), { target: { value: 'tom' } })
    expect(screen.queryByText('Anna Ok')).toBeNull()
  })

  it('voll: weitere Kinder gesperrt mit Satz', () => {
    render(<KindAuswahl kinder={[kind('ZZ_a', 'Anna Ok', 'ok'), kind('ZZ_b', 'Ben Ok', 'ok')]} fehler={null} gewaehlt={['ZZ_a']} onWahl={vi.fn()} frei={1} />)
    const ben = screen.getByText('Ben Ok').closest('li') as HTMLElement
    expect((within(ben).getByRole('checkbox') as HTMLInputElement).disabled).toBe(true)
    expect(within(ben).getByText('Höchstens 1 Kinder pro Raum.')).toBeTruthy()
  })
})

describe('Session-Karte', () => {
  it('zeigt Uhrzeit, Raum, Leitung mit „Admin“ und Link zur Live-Sicht', () => {
    karte()
    expect(screen.getByText('14:00 Uhr')).toBeTruthy()
    expect(screen.getByText('Admin')).toBeTruthy()
    expect(screen.getByRole('link', { name: /Live-Sicht/ }).getAttribute('href')).toBe('/coach/session/ZZ_session/live')
  })

  it('Kinder zuweisen lädt kinder_buchbar(Tag, Session) und zeigt alle Kinder', async () => {
    karte()
    fireEvent.click(screen.getByRole('button', { name: 'Kinder zuweisen' }))
    expect(await screen.findByText('Mia Mit')).toBeTruthy()
    expect(sp.ladeKinderBuchbar).toHaveBeenCalledWith('2027-11-04', 'ZZ_session')
    expect(screen.getByText('Olaf Ohne')).toBeTruthy()
    expect(screen.getByText('Kein Vertrag')).toBeTruthy()
  })

  it('zeigt die Ablehnung der Datenbank (ZG001) als Satz, nie Rohtext', async () => {
    ses.addStudentToSession.mockResolvedValue({ data: null, error: 'roh', code: 'ZG001' })
    const onGeaendert = vi.fn()
    karte(SESSION, onGeaendert)
    fireEvent.click(screen.getByRole('button', { name: 'Kinder zuweisen' }))
    fireEvent.click(within((await screen.findByText('Mia Mit')).closest('li') as HTMLElement).getByRole('checkbox'))
    fireEvent.click(screen.getByRole('button', { name: '1 Kind zuweisen' }))
    expect(await screen.findByText('Das Kind hat an diesem Tag keinen laufenden Vertrag.')).toBeTruthy()
    expect(screen.queryByText('roh')).toBeNull()
  })

  it('weist zu und lädt die Woche neu', async () => {
    ses.addStudentToSession.mockResolvedValue({ data: {}, error: null })
    const onGeaendert = vi.fn()
    karte(SESSION, onGeaendert)
    fireEvent.click(screen.getByRole('button', { name: 'Kinder zuweisen' }))
    fireEvent.click(within((await screen.findByText('Mia Mit')).closest('li') as HTMLElement).getByRole('checkbox'))
    fireEvent.click(screen.getByRole('button', { name: '1 Kind zuweisen' }))
    await waitFor(() => expect(onGeaendert).toHaveBeenCalled())
    expect(ses.addStudentToSession).toHaveBeenCalledWith('ZZ_session', 'ZZ_mit')
  })

  it('Teil-Fehler: das gebuchte Kind verlässt die Wahl, das abgelehnte bleibt', async () => {
    sp.ladeKinderBuchbar.mockResolvedValue({ data: [kind('ZZ_a', 'Anna Ok', 'ok'), kind('ZZ_b', 'Ben Ok', 'ok')], error: null })
    ses.addStudentToSession
      .mockResolvedValueOnce({ data: {}, error: null })
      .mockResolvedValueOnce({ data: null, error: 'roh', code: 'ZG001' })
    karte()
    fireEvent.click(screen.getByRole('button', { name: 'Kinder zuweisen' }))
    fireEvent.click(within((await screen.findByText('Anna Ok')).closest('li') as HTMLElement).getByRole('checkbox'))
    fireEvent.click(within(screen.getByText('Ben Ok').closest('li') as HTMLElement).getByRole('checkbox'))
    fireEvent.click(screen.getByRole('button', { name: '2 Kinder zuweisen' }))
    expect(await screen.findByText('Das Kind hat an diesem Tag keinen laufenden Vertrag.')).toBeTruthy()
    expect(await screen.findByRole('button', { name: '1 Kind zuweisen' })).toBeTruthy()
    expect((within(screen.getByText('Anna Ok').closest('li') as HTMLElement).getByRole('checkbox') as HTMLInputElement).checked).toBe(false)
  })

  it('mit 5 Kindern ist der Raum voll: Zuweisen gesperrt mit Satz', () => {
    const fuenf = [1, 2, 3, 4, 5].map((n) => ({ student_id: `ZZ_${n}`, name: `Kind ${n}`, ist_test: false, attendance: 'planned' as const }))
    karte({ ...SESSION, kinder: fuenf })
    expect((screen.getByRole('button', { name: 'Kinder zuweisen' }) as HTMLButtonElement).disabled).toBe(true)
    expect(screen.getByText('Der Raum ist voll: höchstens 5 Kinder.')).toBeTruthy()
  })

  it('Testlauf setzen: Kennzeichen in der Karte', async () => {
    ses.setSessionTestlauf.mockResolvedValue({ data: null, error: null })
    karte()
    expect(screen.getAllByText('Testlauf').length).toBe(1)
    fireEvent.click(screen.getByRole('switch', { name: /Testlauf/ }))
    await waitFor(() => expect(ses.setSessionTestlauf).toHaveBeenCalledWith('ZZ_session', true))
    await waitFor(() => expect(screen.getAllByText('Testlauf').length).toBe(2))
  })

  it('im Testlauf: ruhige Meldung, wenn die Datenbank ein echtes Kind ablehnt', async () => {
    ses.addStudentToSession.mockResolvedValue({ data: null, error: 'Testlauf: nur Testkonten', code: '22023' })
    karte({ ...SESSION, testlauf: true })
    fireEvent.click(screen.getByRole('button', { name: 'Kinder zuweisen' }))
    fireEvent.click(within((await screen.findByText('Mia Mit')).closest('li') as HTMLElement).getByRole('checkbox'))
    fireEvent.click(screen.getByRole('button', { name: '1 Kind zuweisen' }))
    expect(await screen.findByText('Im Testlauf sind nur Testkonten buchbar.')).toBeTruthy()
  })
})

describe('Session planen', () => {
  it('Raum nur aus den an dem Tag aktiven Räumen, Zeit in Berlin, Woche springt zum Tag', async () => {
    ses.createSession.mockResolvedValue({ data: {}, error: null })
    const onAngelegt = vi.fn()
    const raeume = [
      { id: 'r1', name: 'Raum 1', aktiv_ab: '2020-01-01', inaktiv_ab: null, stammschichten: 0 },
      { id: 'r2', name: 'Raum Alt', aktiv_ab: '2020-01-01', inaktiv_ab: '2027-11-01', stammschichten: 0 },
    ]
    render(<SessionPlanen leitung={[{ id: 'ZZ_admin', name: 'Ada Admin', rolle: 'admin' }]} raeume={raeume} onAngelegt={onAngelegt} />)
    fireEvent.click(screen.getByRole('button', { name: 'Session planen' }))
    fireEvent.change(screen.getByLabelText('Datum'), { target: { value: '2027-11-04' } })
    const raum = screen.getByLabelText('Raum') as HTMLSelectElement
    expect([...raum.options].map((o) => o.textContent)).toEqual(['Bitte wählen', 'Raum 1'])
    expect(screen.getByText('Wähle die Leitung.')).toBeTruthy()
    fireEvent.change(screen.getByLabelText('Leitung'), { target: { value: 'ZZ_admin' } })
    fireEvent.change(screen.getByLabelText('Uhrzeit'), { target: { value: '14:00' } })
    fireEvent.change(raum, { target: { value: 'r1' } })
    fireEvent.click(screen.getByRole('button', { name: 'Session anlegen' }))
    await waitFor(() => expect(onAngelegt).toHaveBeenCalledWith('2027-11-04'))
    expect(ses.createSession).toHaveBeenCalledWith('ZZ_admin', '2027-11-04T13:00:00.000Z', 'Raum 1')
  })

  it('im Tagespanel (W2): Datum fest auf dem Tag, Knopf „+ Einzel-Session an diesem Tag planen“', async () => {
    ses.createSession.mockResolvedValue({ data: {}, error: null })
    const onAngelegt = vi.fn()
    const raeume = [{ id: 'r1', name: 'Raum 1', aktiv_ab: '2020-01-01', inaktiv_ab: null, stammschichten: 0 }]
    render(<SessionPlanen datum="2027-11-05" leitung={[{ id: 'ZZ_admin', name: 'Ada Admin', rolle: 'admin' }]} raeume={raeume} onAngelegt={onAngelegt} />)
    fireEvent.click(screen.getByRole('button', { name: '+ Einzel-Session an diesem Tag planen' }))
    expect(screen.queryByLabelText('Datum')).toBeNull()
    fireEvent.change(screen.getByLabelText('Leitung'), { target: { value: 'ZZ_admin' } })
    fireEvent.change(screen.getByLabelText('Uhrzeit'), { target: { value: '15:00' } })
    fireEvent.change(screen.getByLabelText('Raum'), { target: { value: 'r1' } })
    fireEvent.click(screen.getByRole('button', { name: 'Session anlegen' }))
    await waitFor(() => expect(onAngelegt).toHaveBeenCalledWith('2027-11-05'))
  })
})
