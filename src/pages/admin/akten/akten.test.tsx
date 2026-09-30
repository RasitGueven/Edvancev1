// Schuelerakte S2 — Board und Akte mit gemocktem Supabase. Geprueft wird, was
// die Seiten selbst tun: Rollen-Unterschiede, Weiterleitung einer ruhenden
// Akte fuer Coaches, Anzeige ohne erfundene Werte (Report 1 ohne PDF) und die
// Sperre bei einem Gesundheitsbegriff. Testdaten tragen das Praefix ZZ_.

import { describe, expect, it, vi, beforeEach } from 'vitest'
import { fireEvent, render, screen, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { BoardSchueler, Schuelerakte } from '@/types'

const auth = vi.hoisted(() => ({ rolle: 'admin' as string }))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { email: 'zz@edvance.de' }, role: auth.rolle, loading: false, signOut: vi.fn() }),
}))

const daten = vi.hoisted(() => ({ akte: null as unknown }))
vi.mock('@/lib/supabase/akte', () => ({
  listBoardSchueler: vi.fn(),
  getSchuelerakte: vi.fn(() => Promise.resolve({ data: daten.akte, error: null })),
  getEinheitenStand: vi.fn(() =>
    Promise.resolve({
      data: {
        art: 'laufend', einheiten: 29, beginn: '2027-11-01', stichtag: '2028-06-15', verbraucht: 14, offen: 15,
        soll: 17.17, rueckstand: 3.17, ampel: 'leicht_im_rueckstand', wochen_rest: 10.8, noetig_pro_woche: 1.39,
        gleichmaessig_pro_woche: 1.09,
      },
      error: null,
    }),
  ),
  listAkteSessions: vi.fn(() =>
    Promise.resolve({
      data: [
        { session_id: 's1', scheduled_at: '2028-03-10T15:00:00Z', coach_name: 'ZZ Coach', attendance: 'present' },
        { session_id: 's2', scheduled_at: '2028-03-03T15:00:00Z', coach_name: 'ZZ Coach', attendance: 'unexcused' },
        { session_id: 's3', scheduled_at: '2028-02-24T15:00:00Z', coach_name: 'ZZ Coach', attendance: 'cancelled_by_us' },
      ],
      error: null,
    }),
  ),
  listFaecher: vi.fn(() => Promise.resolve({ data: ['Mathematik'], error: null })),
  listElternReports: vi.fn(() =>
    Promise.resolve({
      data: [{ id: 'r1', nr: 1, art: 'lernstandsanalyse', berichtsmonat: null, kernaussagen: null,
               freigegeben_von_name: null, versendet_am: null, pdf_pfad: null }],
      error: null,
    }),
  ),
  stammdatenSpeichern: vi.fn(),
  reportLink: vi.fn(),
}))
vi.mock('@/lib/supabase/akteNotizen', () => ({
  listNotizen: vi.fn(() => Promise.resolve({ data: [], error: null })),
  listWortlisteGesundheit: vi.fn(() =>
    Promise.resolve({ data: [{ wort: 'allergi', nur_ganzes_wort: false }], error: null }),
  ),
  notizAnlegen: vi.fn(),
  notizAusblenden: vi.fn(),
  notizEinblenden: vi.fn(),
  notizGesundheitEntfernen: vi.fn(),
}))
vi.mock('@/lib/supabase/schulen', () => ({
  listSchulen: vi.fn(() => Promise.resolve({ data: [], error: null })),
  schuleAnlegen: vi.fn(),
}))

import { listBoardSchueler } from '@/lib/supabase/akte'
import { BoardPage } from './BoardPage'
import { AktePage } from './AktePage'

function kind(over: Partial<BoardSchueler> & { student_id: string }): BoardSchueler {
  return {
    name: 'ZZ_Kind', klasse: 9, schule: 'ZZ_Gymnasium', zustand: 'aktiv', ruhend_seit: null,
    letzte_session: null, art: 'laufend', einheiten: 29, beginn: '2027-11-01', stichtag: '2028-06-15',
    verbraucht: 14, offen: 15, soll: 17.2, rueckstand: 3.2, ampel: 'leicht_im_rueckstand', ...over,
  }
}

const akteAktiv: Schuelerakte = {
  student_id: 'k1', name: 'ZZ_Efe Demir', klasse: 9, schule_id: null, schule: 'ZZ_Gymnasium',
  akte_seit: '2027-10-15', zustand: 'aktiv', ruhend_seit: null, letzte_session: null,
}

function zeige(pfad: string): void {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route path="/admin/akten" element={<BoardPage />} />
        <Route path="/admin/akten/:studentId" element={<AktePage />} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => {
  auth.rolle = 'admin'
  daten.akte = akteAktiv
  vi.mocked(listBoardSchueler).mockResolvedValue({
    data: [
      kind({ student_id: 'a', name: 'ZZ_Mia Wenzel', klasse: 8, ampel: 'im_plan' }),
      kind({ student_id: 'b', name: 'ZZ_Efe Demir' }),
      kind({ student_id: 'c', name: 'ZZ_Ben Lindner', klasse: 10, zustand: 'ruhend', art: 'keiner' }),
    ],
    error: null,
  })
})

describe('Board', () => {
  it('Admin: Spalten je Klasse, Zustandsfilter, ruhende erst ueber den Filter', async () => {
    zeige('/admin/akten')
    expect(await screen.findByLabelText('Klasse 8')).toBeTruthy()
    expect(screen.getByLabelText('Klasse 9')).toBeTruthy()
    expect(screen.queryByLabelText('Klasse 10')).toBeNull()
    fireEvent.change(screen.getByLabelText('Zustand'), { target: { value: 'alle' } })
    expect(screen.getByLabelText('Klasse 10')).toBeTruthy()
    expect(within(screen.getByLabelText('Klasse 9')).getByText('14 von 29 verbraucht')).toBeTruthy()
  })

  it('Coach: kein Zustandsfilter, Hinweis nach ruhender Akte', async () => {
    auth.rolle = 'coach'
    daten.akte = null
    zeige('/admin/akten/c')
    expect(await screen.findByText('Ruhende Akten sind für Coaches nicht sichtbar.')).toBeTruthy()
    expect(screen.queryByLabelText('Zustand')).toBeNull()
  })

  it('globale Suche zeigt die Trefferzahl', async () => {
    zeige('/admin/akten')
    await screen.findByLabelText('Klasse 8')
    fireEvent.change(screen.getByLabelText('Suche über alle Klassen (Name oder Schule)'), { target: { value: 'demir' } })
    expect(screen.getByText('1 Treffer')).toBeTruthy()
  })
})

describe('Akte', () => {
  it('zeigt Einheiten-Stand, Anwesenheitssummen und Report 1 ohne erfundene Felder', async () => {
    zeige('/admin/akten/k1')
    expect(await screen.findByText('leicht im Rückstand')).toBeTruthy()
    expect(screen.getByText(/braucht es ab jetzt 1,4 Einheiten pro Betriebswoche — gleichmäßig verteilt wären es 1,1/)).toBeTruthy()
    expect(screen.getByText('anwesend: 1')).toBeTruthy()
    expect(screen.getByText('unentschuldigt: 1')).toBeTruthy()
    expect(screen.getByText('ausgefallen (durch uns): 1')).toBeTruthy()
    expect(screen.getByText('Report 1')).toBeTruthy()
    expect(screen.getByText('keine gespeicherte Fassung')).toBeTruthy()
    expect(screen.queryByText(/freigegeben von/)).toBeNull()
    expect(screen.getByText('Kommt: aktuelles Thema und Station je Fach, vom Coach bestätigte Kompetenzen.')).toBeTruthy()
  })

  it('Notiz mit Gesundheitsbegriff: Hinweis und Speichern gesperrt', async () => {
    zeige('/admin/akten/k1')
    const feld = await screen.findByLabelText('Neue Notiz')
    fireEvent.change(screen.getByLabelText('Kategorie'), { target: { value: 'lernen' } })
    fireEvent.change(feld, { target: { value: 'Hat eine Allergie' } })
    expect(screen.getByRole('alert').textContent).toContain('„allergi“')
    expect((screen.getByRole('button', { name: 'Notiz speichern' }) as HTMLButtonElement).disabled).toBe(true)
    fireEvent.change(feld, { target: { value: 'Standardaufgaben sitzen' } })
    expect((screen.getByRole('button', { name: 'Notiz speichern' }) as HTMLButtonElement).disabled).toBe(false)
  })

  it('Coach: Stammdaten nur lesend', async () => {
    auth.rolle = 'coach'
    zeige('/admin/akten/k1')
    await screen.findByText('Stammdaten')
    expect(screen.queryByRole('button', { name: 'Stammdaten speichern' })).toBeNull()
    expect(screen.getByText('Mathematik')).toBeTruthy()
  })
})
