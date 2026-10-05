// Admin-Pruefansicht: Knopf-Matrix der Leiste je Status (inkl. Ausschluss und beanstandet ohne Freigeben) und
// die Seite mit gemockten Wrappern: Rueckfrage (Antwort an Lena, Freigeben, Zurueck an Lena, Zurueckweisen im
// Menue), Befund sperrt Freigeben, Freigeben speichert zuerst und oeffnet die naechste Aufgabe der Reihe.
// Alle Supabase-Wrapper sind gemockt (CI hat keine VITE_*-Variablen).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import { leistenInfo, leistenKnoepfe } from '@/lib/pruefung/leiste'
import { neueReihe, speichereReihe } from '@/lib/pruefung/reihe'
import type { AdminPruefKontext, AuthoringTask, PruefAufgabe, TaskSolution } from '@/types'

vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefAufgabe: vi.fn(),
  getFehlbilder: vi.fn().mockResolvedValue({ data: [], error: null }),
  pruefSpeichern: vi.fn(),
  pruefWertungTesten: vi.fn(),
  pruefRueckfrageKlaeren: vi.fn(),
}))
vi.mock('@/lib/supabase/pruefungAdmin', () => ({
  getAdminPruefKontext: vi.fn(),
  pruefAdminFreigeben: vi.fn(),
  pruefAnLena: vi.fn(),
  pruefAdminZurueckweisen: vi.fn(),
  pruefFreigabeZuruecknehmen: vi.fn(),
  setzePilot: vi.fn(),
}))
vi.mock('@/lib/supabase/taskAuthoring', () => ({
  getAuthoringTask: vi.fn(),
  getTaskSolution: vi.fn(),
  probeAuthoringSchema: vi.fn().mockResolvedValue({ hasStoffanker: true, hasStatusGate: true }),
}))
vi.mock('@/lib/supabase/taskPreview', () => ({
  getTaskPreview: vi.fn().mockResolvedValue({ data: null, error: null }),
  PREVIEW_RPC_MISSING: 'missing',
}))

import { getPruefAufgabe, pruefRueckfrageKlaeren } from '@/lib/supabase/pruefung'
import { getAdminPruefKontext, pruefAdminFreigeben } from '@/lib/supabase/pruefungAdmin'
import { getAuthoringTask, getTaskSolution } from '@/lib/supabase/taskAuthoring'
import { AdminPruefansichtPage } from './AdminPruefansichtPage'

describe('Knopf-Matrix der Leiste', () => {
  const k = (status: string, ausgeschlossen = false, team = false) => leistenKnoepfe({ status, ausgeschlossen, team })

  it('offen, passt und Rueckfrage: Freigeben, Zurueck an Lena, im Menue Zurueckweisen und Editor', () => {
    for (const s of ['draft', 'review', 'rueckfrage']) {
      expect(k(s)).toEqual({ primaer: 'freigeben', sekundaer: 'anLena', menue: ['zurueckweisen', 'editor'] })
    }
  })

  it('beanstandet: kein Freigeben; Zurueckweisen nur bei Lenas „Passt nicht“', () => {
    expect(k('beanstandet')).toEqual({ primaer: 'anLena', sekundaer: 'editor', menue: ['zurueckweisen'] })
    expect(k('beanstandet', false, true)).toEqual({ primaer: 'anLena', sekundaer: 'editor', menue: [] })
    for (const s of ['beanstandet']) expect([k(s).primaer, k(s).sekundaer, ...k(s).menue]).not.toContain('freigeben')
  })

  it('freigegeben: nur Editor und Freigabe zuruecknehmen', () => {
    expect(k('ready')).toEqual({ primaer: null, sekundaer: 'editor', menue: ['freigabeZurueck'] })
  })

  it('Ausschluss: „Auf Offen setzen“ statt „Zurueck an Lena“, bei draft entfaellt der Knopf', () => {
    expect(k('review', true).sekundaer).toBe('aufOffen')
    expect(k('beanstandet', true).primaer).toBe('aufOffen')
    expect(k('draft', true).sekundaer).toBeNull()
  })

  it('Infotext: beanstandet sagt „erst ueberarbeiten“, ein Befund sperrt', () => {
    const l = { ausgeschlossen: false, team: false, lenaStatus: 'passt', geaendert: 0 }
    expect(leistenInfo({ ...l, status: 'beanstandet', befund: null })).toBe('beanstandet')
    expect(leistenInfo({ ...l, status: 'review', befund: 'Stoffanker fehlt' })).toBe('befund')
    expect(leistenInfo({ ...l, status: 'review', befund: null, geaendert: 2 })).toBe('geaendert')
  })
})

const task: AuthoringTask = {
  id: 't1', title: 'AFB II · Umfang · Radius 3,6 m', question: 'Ein Kreis hat den Radius 3,6 m.', status: 'rueckfrage',
  input_type: 'NUMERIC', afb: 'II', competency_content: 'geometrie', competency_process: 'ope', cluster_id: 'c1',
  unit: 'm', est_duration_sec: 120, skill_key: 'geo_kreis_umfang', class_level: 9, curriculum_grade: 9, parts: [],
  assets: [], needs_image: null, licence_text: null, question_payload: null, source: 'eigen', source_ref: 'x',
  is_active: true, created_at: '2026-10-01T00:00:00Z',
}
const loesung: TaskSolution = {
  exists: true, correct_answers: ['22,62'], solution: 'U = 2 · π · 3,6 m', beleg: [], hints: [], coach_hints: [],
  typical_errors: [{ error: 'π vergessen' }],
}
const aufgabe = (status: string, lena: PruefAufgabe['aufgabe']['lena_status'], team = false): PruefAufgabe => ({
  task_id: 't1',
  kopf: { kurztitel: 'Umfang · Radius 3,6 m', stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', hilfsmittel: 'Taschenrechner' },
  aufgabe: { input_type: 'NUMERIC', unit: 'm', status, lena_status: lena, pruef_version: 3, ausschluss: null, pilot: true,
    team_beanstandet: team, parts: [], optionen: [], bild_vorhanden: false },
  werte: [{ teil: null, werte: [{ wert: '22,62', schreibweisen: ['22,62'] }] }], mc: null,
  regel: { art: 'wert', mitte: null, toleranz: null, einheit_pflicht: false, einheit: 'm', einheit_am_feld: true },
  fehler: [], weitere_hinweise: [], flach_regel: true, ohne_erkennung: false, loesungsweg: 'U = 2 · π · 3,6 m',
  fertigkeit: { key: 'geo_kreis_umfang', label: 'Umfang des Kreises', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', stufe: 'zweite', voraussetzungen: [] },
  fertigkeit_optionen: [{ key: 'geo_kreis_umfang', label: 'Umfang des Kreises', gruppe: 'thema' }],
  afb: 'II', afb_sicher: null, ausgang: null, aenderungen: [], letzte_pruefung: null, auffaelligkeiten: [],
})
const kontext: AdminPruefKontext = {
  lena: { entscheidung: 'unsicher', gruende: [], notiz: 'Ist 22,61 auch richtig?', aenderungen: [], aenderung_grund: null,
    dauer_sek: 96, geprueft_von: 'Lena', geprueft_am: '2026-10-05T08:14:00Z', antwort: null, beantwortet_von: null, beantwortet_am: null },
  team: null, hand: null, protokoll: [], freigabe: null,
}

const zeige = (id = 't1') => render(
  <MemoryRouter initialEntries={[`/admin/pruefen/${id}`]}>
    <Routes>
      <Route path="/admin/pruefen/:taskId" element={<AdminPruefansichtPage />} />
      <Route path="/admin/pruefen/ende" element={<p>Ende der Reihe</p>} />
    </Routes>
  </MemoryRouter>,
)

beforeEach(() => {
  vi.clearAllMocks()
  sessionStorage.clear()
  vi.mocked(getAuthoringTask).mockResolvedValue({ data: task, error: null })
  vi.mocked(getTaskSolution).mockResolvedValue({ data: loesung, error: null })
  vi.mocked(getAdminPruefKontext).mockResolvedValue({ data: kontext, error: null })
})

describe('AdminPruefansichtPage', () => {
  it('Rueckfrage: Frage in „Lenas Ergebnis“, Antwort an Lena, Freigeben und Zurueck an Lena, Zurueckweisen im Menue', async () => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe('rueckfrage', 'unsicher'), error: null })
    zeige()
    expect(await screen.findByText('„Ist 22,61 auch richtig?“')).toBeTruthy()
    expect(screen.getByLabelText(/Antwort an Lena/)).toBeTruthy()
    expect(screen.getByRole('button', { name: /Freigeben/ })).toBeTruthy()
    expect(screen.getByRole('button', { name: 'Zurück an Lena' })).toBeTruthy()
    fireEvent.click(screen.getByRole('button', { name: 'Weitere Aktionen' }))
    expect(screen.getByRole('menuitem', { name: 'Zurückweisen' })).toBeTruthy()
  })

  it('Freigeben bei einer Rueckfrage laeuft ueber pruef_rueckfrage_klaeren mit der Antwort und oeffnet die naechste Aufgabe', async () => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe('rueckfrage', 'unsicher'), error: null })
    vi.mocked(pruefRueckfrageKlaeren).mockResolvedValue({ data: { status: 'ready' }, error: null })
    speichereReihe(neueReihe(['t1'], 'liste', 'Expertenliste · Filter: Rückfrage', '/admin/authoring/liste'))
    zeige()
    const feld = await screen.findByLabelText(/Antwort an Lena/)
    fireEvent.change(feld, { target: { value: 'Ja, 22,61 zählt auch.' } })
    const knopf = screen.getByRole('button', { name: /Freigeben/ })
    await waitFor(() => expect((knopf as HTMLButtonElement).disabled).toBe(false))
    fireEvent.click(knopf)
    await waitFor(() => expect(pruefRueckfrageKlaeren).toHaveBeenCalledWith('t1', 'freigeben', 'Ja, 22,61 zählt auch.'))
    expect(await screen.findByText('Ende der Reihe')).toBeTruthy()
  })

  it('ein Befund (Stoffanker fehlt) sperrt Freigeben, mit dem Befund als Grund', async () => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe('review', 'passt'), error: null })
    vi.mocked(getAuthoringTask).mockResolvedValue({ data: { ...task, status: 'review', curriculum_grade: null }, error: null })
    zeige()
    expect(await screen.findByText('Vor der Freigabe klären')).toBeTruthy()
    const knopf = screen.getByRole('button', { name: /Freigeben/ })
    await waitFor(() => expect(knopf.parentElement?.getAttribute('title')).toMatch(/Stoffanker/))
    expect((knopf as HTMLButtonElement).disabled).toBe(true)
    expect(pruefAdminFreigeben).not.toHaveBeenCalled()
  })

  it('beanstandet vom Team: kein Freigeben, Infotext „Erst überarbeiten, dann zurück an Lena.“', async () => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe('beanstandet', 'passt_nicht', true), error: null })
    zeige()
    expect(await screen.findByText(/Erst überarbeiten, dann zurück an Lena/)).toBeTruthy()
    expect(screen.queryByRole('button', { name: /Freigeben/ })).toBeNull()
    expect(screen.getByRole('button', { name: 'Zurück an Lena' })).toBeTruthy()
  })
})
