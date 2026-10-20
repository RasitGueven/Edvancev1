// Slots S2: „Session jetzt starten“ (Entscheidung 7–9); W2: der Reiter Stundenplan ist im Wochenplan aufgegangen. Supabase ist gemockt.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { act, fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'
import type { KindBuchbar } from '@/types/stundenplan'

const auth = vi.hoisted(() => ({ rolle: 'admin' as string, user: { id: 'ZZ_admin' } }))
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: auth.user, role: auth.rolle, loading: false }) }))
const sp = vi.hoisted(() => ({
  ladeKinderBuchbar: vi.fn(),
  ladeSessionLeitung: vi.fn(),
  ladeStundenplanWoche: vi.fn(),
  sofortSessionAnlegen: vi.fn(),
}))
const slot = vi.hoisted(() => ({ ladeEinstellungen: vi.fn(), ladeWoche: vi.fn(), ladeCoaches: vi.fn(), ladeKinder: vi.fn() }))
vi.mock('@/lib/supabase/stundenplan', () => sp)
vi.mock('@/lib/supabase/slotplan', () => slot)
vi.mock('@/lib/supabase/sessions', () => ({
  KEIN_PLATZ_ZUGANG: 'ZG001', TESTLAUF_GESTARTET: '55000', TESTLAUF_NUR_TESTKONTEN: '22023',
  setSessionTestlauf: vi.fn(), createSession: vi.fn(), addStudentToSession: vi.fn(),
}))

const { SofortKnopf } = await import('./SofortKnopf')
const { SlotsPage } = await import('../SlotsPage')

const kind = (id: string, name: string, code: KindBuchbar['code'], ist_test = false): KindBuchbar =>
  ({ student_id: id, name, klasse: 8, ist_test, code, detail: null })

function Ort(): JSX.Element {
  const l = useLocation()
  return <p data-testid="ort">{l.pathname + l.search}</p>
}

async function dialog(studentId?: string): Promise<void> {
  render(
    <MemoryRouter initialEntries={['/start']}>
      <Routes>
        <Route path="/start" element={<SofortKnopf studentId={studentId} />} />
        <Route path="*" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
  fireEvent.click(screen.getByRole('button', { name: 'Session jetzt starten' }))
  await act(async () => {})
}

const zeile = (name: string): HTMLElement => screen.getByText(name).closest('li') as HTMLElement
const starten = (): HTMLButtonElement => screen.getByRole('button', { name: 'Starten' }) as HTMLButtonElement

beforeEach(() => {
  auth.rolle = 'admin'
  for (const f of [...Object.values(sp), ...Object.values(slot)]) f.mockReset()
  sp.ladeKinderBuchbar.mockResolvedValue({
    data: [kind('ZZ_echt', 'Emma Echt', 'ok'), kind('ZZ_test', 'Tim Test', 'ok', true), kind('ZZ_ab', 'Alex Ab', 'keine_einheit')],
    error: null,
  })
  sp.ladeSessionLeitung.mockResolvedValue({
    data: [{ id: 'ZZ_admin', name: 'Ada Admin', rolle: 'admin' }, { id: 'ZZ_coach', name: 'Carl Coach', rolle: 'coach' }], error: null,
  })
  slot.ladeEinstellungen.mockResolvedValue({
    data: { raeume: [{ id: 'ZZ_r1', name: 'Raum 1', aktiv_ab: '2020-01-01', inaktiv_ab: null, stammschichten: 0 }] }, error: null,
  })
})

describe('Sofort-Dialog', () => {
  it('lädt heute, belegt Leitung (angemeldeter Admin) und einzigen Raum vor', async () => {
    await dialog()
    expect(sp.ladeKinderBuchbar).toHaveBeenCalledWith(expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/))
    expect((screen.getByLabelText('Leitung') as HTMLSelectElement).value).toBe('ZZ_admin')
    expect((screen.getByLabelText('Raum') as HTMLSelectElement).value).toBe('ZZ_r1')
    expect(starten().disabled).toBe(true)
    expect(screen.getByText('Wähle mindestens ein Kind.')).toBeTruthy()
    expect(within(zeile('Alex Ab')).getByText('Keine offene Einheit')).toBeTruthy()
  })

  it('sperrt „Starten“ bei Testkonto und echtem Kind, mit Satz darunter', async () => {
    await dialog()
    fireEvent.click(within(zeile('Emma Echt')).getByRole('checkbox'))
    fireEvent.click(within(zeile('Tim Test')).getByRole('checkbox'))
    expect(starten().disabled).toBe(true)
    expect(screen.getByText('Testkonten und echte Kinder sitzen nie in derselben Session.')).toBeTruthy()
    fireEvent.click(within(zeile('Tim Test')).getByRole('checkbox'))
    expect(starten().disabled).toBe(false)
  })

  it('„Starten“ legt an und öffnet die Live-Sicht', async () => {
    sp.sofortSessionAnlegen.mockResolvedValue({ data: { session_id: 'ZZ_neu', testlauf: false }, error: null })
    await dialog()
    fireEvent.click(within(zeile('Emma Echt')).getByRole('checkbox'))
    fireEvent.click(starten())
    await act(async () => {})
    expect(sp.sofortSessionAnlegen).toHaveBeenCalledWith('ZZ_admin', 'ZZ_r1', ['ZZ_echt'])
    expect(screen.getByTestId('ort').textContent).toBe('/coach/session/ZZ_neu/live')
  })

  it('Ablehnung der Datenbank als Satz mit dem Namen des Kindes, nie Rohtext', async () => {
    sp.sofortSessionAnlegen.mockResolvedValue({ data: null, error: 'roh', code: '22023', hint: 'keine_einheit', detail: 'ZZ_echt' })
    await dialog()
    fireEvent.click(within(zeile('Emma Echt')).getByRole('checkbox'))
    fireEvent.click(starten())
    expect(await screen.findByText('Emma Echt: Ein Kind hat keine offene Einheit mehr.')).toBeTruthy()
    expect(screen.queryByText('roh')).toBeNull()
  })

  it('Akte: das Kind ist vorgewählt', async () => {
    await dialog('ZZ_echt')
    expect((within(zeile('Emma Echt')).getByRole('checkbox') as HTMLInputElement).checked).toBe(true)
    expect(starten().disabled).toBe(false)
  })

  it('Akte: ein nicht buchbares Kind wird nicht vorgewählt', async () => {
    await dialog('ZZ_ab')
    expect((within(zeile('Alex Ab')).getByRole('checkbox') as HTMLInputElement).checked).toBe(false)
  })

  it('ein Coach sieht keinen Knopf', () => {
    auth.rolle = 'coach'
    render(<MemoryRouter><SofortKnopf /></MemoryRouter>)
    expect(screen.queryByRole('button', { name: 'Session jetzt starten' })).toBeNull()
  })
})

describe('Slots: Einzel-Sessions im Wochenplan (W2, früher Reiter Stundenplan)', () => {
  function slots(pfad: string): void {
    slot.ladeWoche.mockResolvedValue({ data: null, error: null })
    slot.ladeCoaches.mockResolvedValue({ data: null, error: null })
    sp.ladeStundenplanWoche.mockResolvedValue({ data: { montag: '2027-11-01', sessions: [] }, error: null })
    render(
      <MemoryRouter initialEntries={[pfad]}>
        <Routes>
          <Route path="/admin/slots" element={<><SlotsPage /><Ort /></>} />
        </Routes>
      </MemoryRouter>,
    )
  }

  it('kein Reiter Stundenplan mehr; der Wochenplan lädt die Einzel-Sessions der Woche', async () => {
    slots('/admin/slots?woche=2027-11-01&reiter=stundenplan')
    await act(async () => {})
    const titel = within(screen.getByRole('tablist')).getAllByRole('tab').map((r) => r.textContent ?? '')
    expect(titel.some((x) => x.startsWith('Stundenplan'))).toBe(false)
    expect(screen.getByTestId('ort').textContent).toBe('/admin/slots?woche=2027-11-01')
    expect(sp.ladeStundenplanWoche).toHaveBeenCalledWith('2027-11-01')
  })

  it('Knopf „Session jetzt starten“ im Kopf der Slots', async () => {
    slots('/admin/slots')
    await act(async () => {})
    expect(screen.getByRole('button', { name: 'Session jetzt starten' })).toBeTruthy()
  })

  it('ein Coach sieht den Knopf nicht (die Route lässt ihn ohnehin nicht herein)', async () => {
    auth.rolle = 'coach'
    slots('/admin/slots?reiter=stundenplan')
    await act(async () => {})
    expect(screen.queryByRole('tab', { name: /Stundenplan/ })).toBeNull()
    expect(screen.queryByRole('button', { name: 'Session jetzt starten' })).toBeNull()
  })
})
