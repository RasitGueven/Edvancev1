// Startseite „Heute“ (Admin-Hülle H3) mit gemockten Wrappern. Geprüft wird,
// was die Seite selbst leistet: Gruß mit Vornamen aus profiles, Zahlen je
// Liste, grüne Null, „Neuer Lead“ und „Termin“.

import { describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'

const heute = new Date().toISOString()

vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'u1', email: 'admin@edvance.de' }, role: 'admin', signOut: vi.fn() }),
}))
vi.mock('@/lib/supabase/adminStats', () => ({
  getAdminStats: vi.fn(() =>
    Promise.resolve({ data: { students: 4, leadsOpen: 3, leadsNew: 2, coaches: 2 }, error: null }),
  ),
}))
vi.mock('@/lib/supabase/akte', () => ({
  profilNamen: vi.fn(() => Promise.resolve(new Map([['u1', 'ZZ_Rasit Güven']]))),
  listBoardSchueler: vi.fn(() =>
    Promise.resolve({
      data: [
        { student_id: 's1', name: 'ZZ_Ben', klasse: 8, zustand: 'aktiv', ampel: 'deutlich_im_rueckstand', rueckstand: 3, verbraucht: 2, einheiten: 10 },
        { student_id: 's2', name: 'ZZ_Lea', klasse: 9, zustand: 'aktiv', ampel: 'im_plan', rueckstand: 0, verbraucht: 5, einheiten: 10 },
      ],
      error: null,
    }),
  ),
}))
vi.mock('@/lib/supabase/heute', async (orig) => ({
  ...(await orig<typeof import('@/lib/supabase/heute')>()),
  listAufgabenFuerAdmin: vi.fn(() =>
    Promise.resolve({
      data: [
        { id: 't1', skill_key: 'bruch', status: 'review' },
        { id: 't2', skill_key: 'bruch', status: 'rueckfrage' },
        { id: 't3', skill_key: null, status: 'rueckfrage' },
      ],
      error: null,
    }),
  ),
  listSessionsHeute: vi.fn(() =>
    Promise.resolve({ data: [{ id: 'cs1', scheduled_at: heute, room: 'A1', coach_id: 'c1', coach_name: 'ZZ_Coach', belegt: 3 }], error: null }),
  ),
}))
vi.mock('@/lib/supabase/sessionC2', () => ({
  sessionsOffen: vi.fn().mockResolvedValue({
    data: [{ session_id: 'zz-s', scheduled_at: '2026-10-06T14:00:00.000Z', room: 'ZZ Raum', status: 'active', coach_id: 'c1',
             coach_name: 'ZZ Coach', testlauf: true, kinder: 2 }],
    error: null,
  }),
  sessionsNichtGestartet: vi.fn().mockResolvedValue({
    data: [
      { session_id: 'n1', scheduled_at: '2026-09-04T07:00:00.000Z', room: 'A1', testlauf: false, kinder: 1 },
      { session_id: 'n2', scheduled_at: '2026-09-15T14:00:00.000Z', room: 'A1', testlauf: false, kinder: 1 },
    ],
    error: null,
  }),
}))
vi.mock('@/lib/supabase/leads', () => ({
  listLeads: vi.fn(() =>
    Promise.resolve({
      data: [
        { id: 'l1', full_name: 'ZZ_Alt', status: 'new', created_at: '2026-01-01T08:00:00Z', class_level: 7, subjects: ['Mathematik'], erstgespraech_at: null },
        { id: 'l2', full_name: 'ZZ_Neu', status: 'new', created_at: heute, class_level: 8, subjects: [], erstgespraech_at: null },
        { id: 'l3', full_name: 'ZZ_Fertig', status: 'lsa_fertig', created_at: heute, lsa_fertig_at: heute, subjects: [], erstgespraech_at: null },
      ],
      error: null,
    }),
  ),
  updateLead: vi.fn(() => Promise.resolve({ data: null, error: null })),
}))
vi.mock('@/lib/supabase/leadLsa', () => ({
  listReportSessionsByLead: vi.fn(() => Promise.resolve({ data: { l3: 'r1' }, error: null })),
}))
vi.mock('@/lib/supabase/lsaReport', () => ({
  listTodaysLsaSessions: vi.fn(() => Promise.resolve({ data: [], error: null })),
}))
vi.mock('@/lib/supabase/platz', () => ({
  listActivePlaetzeByLead: vi.fn(() => Promise.resolve({ data: {}, error: null })),
}))
vi.mock('@/lib/supabase/themen', () => ({
  listSkillThemen: vi.fn(() => Promise.resolve({ data: [], error: null })),
}))
vi.mock('@/lib/supabase/vertraege', () => ({
  listVertraege: vi.fn(() => Promise.resolve({ data: [], error: null })),
  vertragStarten: vi.fn(() => Promise.resolve({ data: 'v1', error: null })),
}))
vi.mock('@/lib/supabase/vertraegeMenue', () => ({
  listVertraegeAktuell: vi.fn(() => Promise.resolve({ data: [], error: null })),
}))

import { HeutePage } from './HeutePage'

function Ort(): JSX.Element {
  const { pathname, search } = useLocation()
  return <p data-testid="ort">{pathname + search}</p>
}

function setup(): void {
  render(
    <MemoryRouter initialEntries={['/admin']}>
      <Routes>
        <Route path="/admin" element={<HeutePage />} />
        <Route path="*" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
}

const karte = (titel: string): HTMLElement => screen.getByRole('heading', { name: titel, level: 3 }).closest('div.flex.flex-col.p-4') as HTMLElement

describe('HeutePage', () => {
  it('Gruß mit Vornamen aus profiles und Summe offener Punkte', async () => {
    setup()
    expect(await screen.findByRole('heading', { level: 1, name: /, ZZ_Rasit$/ })).toBeTruthy()
    // 2 neue Leads + 1 LSA + 1 Schüler im Rückstand + 1 review + 2 Rückfragen
    expect(screen.getByText(/^7 offene Punkte/)).toBeTruthy()
  })

  it('Listen: älteste zuerst, Amber ab 7 Tagen, leere Liste grün', async () => {
    setup()
    await screen.findByRole('heading', { name: 'Neue Leads', level: 3 })
    const leads = karte('Neue Leads')
    const namen = within(leads).getAllByText(/^ZZ_/).map((e) => e.textContent)
    expect(namen).toEqual(['ZZ_Alt', 'ZZ_Neu'])
    expect(within(karte('Erstgespräche')).getByText('nichts offen')).toBeTruthy()
    expect(within(karte('Schüler im Rückstand')).getByText('deutlich im Rückstand')).toBeTruthy()
    expect(within(karte('Schüler im Rückstand')).queryByText('ZZ_Lea')).toBeNull()
    expect(screen.queryByText(/gemeistert/i)).toBeNull()
  })

  it('fertige Analyse verlinkt den Report und bietet den Vertragsprozess', async () => {
    setup()
    const link = await screen.findByRole('link', { name: 'ZZ_Fertig' })
    expect(link.getAttribute('href')).toBe('/admin/report/r1')
    expect(within(karte('Lernstandsanalysen')).getByRole('button', { name: 'Vertragsprozess' })).toBeTruthy()
  })

  it('Inhalte freigeben: Zeile „Rückfragen von Lena“ mit Pille „Unsicher“ öffnet die Rückfragen als Reihe', async () => {
    setup()
    await screen.findByRole('heading', { name: 'Inhalte freigeben', level: 3 })
    const inhalte = karte('Inhalte freigeben')
    expect(within(inhalte).getByText('3')).toBeTruthy()
    expect(within(inhalte).getByText('Unsicher')).toBeTruthy()
    expect(within(inhalte).getByText('Nicht zugeordnet')).toBeTruthy()
    // Seit der Admin-Prüfansicht öffnet die Zeile die Rückfragen direkt, als Reihe (Bauauftrag F 19).
    fireEvent.click(within(inhalte).getByRole('button', { name: '2 Rückfragen von Lena' }))
    expect(JSON.parse(sessionStorage.getItem('edvance.adminPruefReihe') ?? '{}').ids).toEqual(['t2', 't3'])
  })

  it('Heute im Betrieb: Session mit Raum, Coach und Plätzen', async () => {
    setup()
    expect(await screen.findByText('Raum A1')).toBeTruthy()
    expect(screen.getByText('ZZ_Coach')).toBeTruthy()
    expect(screen.getByLabelText('3 von 5 Plätzen belegt')).toBeTruthy()
  })

  it('C2: Offen geblieben zeigt nicht abgeschlossene Sessions mit Testlauf und Link in die Live-Sicht', async () => {
    setup()
    expect(await screen.findByText('Offen geblieben')).toBeTruthy()
    expect(await screen.findByText(/ZZ Raum/)).toBeTruthy()
    expect(screen.getByText('läuft noch · ZZ Coach · 2 Kinder')).toBeTruthy()
    expect(screen.getByText('Testlauf')).toBeTruthy()
    expect(screen.getByRole('link', { name: 'Live-Sicht' }).getAttribute('href')).toBe('/coach/session/zz-s/live')
    // Nie gestartete Sessions: nur Zahl mit Link zum Stundenplan, kein Link in die Live-Sicht.
    const nie = await screen.findByTestId('nicht-gestartet')
    expect(within(nie).getByText('Nicht gestartet (2)')).toBeTruthy()
    expect(within(nie).getByRole('link').getAttribute('href')).toBe('/admin/schedule')
    expect(within(nie).queryByRole('button')).toBeNull()
  })

  it('„Termin“ öffnet den Termin-Dialog, „Neuer Lead“ führt ins Formular', async () => {
    setup()
    const termin = await screen.findAllByRole('button', { name: 'Termin' })
    fireEvent.click(termin[0])
    expect(await screen.findByRole('dialog')).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: /Neuer Lead/ }))
    expect((await screen.findByTestId('ort')).textContent).toBe('/admin/leads?neu=1')
  })
})
