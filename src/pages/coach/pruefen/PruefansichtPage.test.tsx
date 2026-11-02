// Pruefansicht: mountet sie mit einer Kreis-Aufgabe, gilt der Sperrgrund, verlangt "Passt nicht"
// einen Grund, fuehrt "3" zur Entscheidung und danach zur naechsten offenen Aufgabe?
// Bereiche: Hinweise nur im Session-Bereich, Weiter bleibt im Bereich.
// P4: mit Sollzahlen folgt der Lauf dem Bedarf; beim Themenwechsel kommt erst das Zwischenbild.
// Alle Supabase-Wrapper sind gemockt (CI hat keine VITE_*-Variablen).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import type { JSX } from 'react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'
import type { PruefAufgabe, PruefBoardZeile, PruefSollZeile } from '@/types'

vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefAufgabe: vi.fn(),
  getPruefBoard: vi.fn(),
  getPruefSoll: vi.fn(),
  getAufgabenTypen: vi.fn().mockResolvedValue({ data: {}, error: null }),
  getFehlbilder: vi.fn(),
  getPruefEinstellungen: vi.fn(),
  pruefSpeichern: vi.fn(),
  pruefEntscheiden: vi.fn(),
  pruefRueckgaengig: vi.fn(),
  pruefTaschenrechnerSetzen: vi.fn(),
  pruefWertungTesten: vi.fn(),
}))
vi.mock('@/lib/supabase/taskPreview', () => ({
  getTaskPreview: vi.fn().mockResolvedValue({ data: null, error: null }),
  PREVIEW_RPC_MISSING: 'missing',
}))
vi.mock('@/hooks/useAuth', () => ({
  useAuth: () => ({ user: { id: 'lena', email: 'lena@edvance.de' }, role: 'coach', signOut: vi.fn() }),
}))

import {
  getFehlbilder, getPruefAufgabe, getPruefBoard, getPruefEinstellungen, getPruefSoll, pruefEntscheiden, pruefSpeichern,
  pruefTaschenrechnerSetzen,
} from '@/lib/supabase/pruefung'
import { PruefansichtPage } from './PruefansichtPage'

function Ort(): JSX.Element {
  const { search } = useLocation()
  return <p>Übersicht {search}</p>
}

const zeile = (id: string, reihenfolge: number, anlaesse = ['batu_lsa', 'batu_session']): PruefBoardZeile => ({
  task_id: id, stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', thema_sort: 470,
  skill_key: 'geo_kreis_umfang', skill_label: 'Umfang des Kreises', kurztitel: id, reihenfolge,
  lena_status: 'offen', geaendert: false, letzte_dauer_sek: null, anlaesse, hat_hinweise: true,
})

const sicht = {
  werte: [{ teil: null, werte: [{ wert: '22,62', schreibweisen: ['22,62', '22.62'] }] }],
  mc: null,
  regel: { art: 'wert' as const, mitte: null, toleranz: null, einheit_pflicht: false, einheit: 'm', einheit_am_feld: true },
  fehler: [{ slug: 'pi_vergessen', werte: [{ teil: null, wert: '7,2' }], text: 'π weggelassen.', klartext: 'Lässt π weg.' }],
  weitere_hinweise: [],
  hinweise: [{ stufe: 1, text: 'Was gehört in die Formel?', status: 'entwurf' as const }],
  skill_key: 'geo_kreis_umfang',
  afb: 'II' as const,
  flach_regel: true,
  ohne_erkennung: false,
}

const aufgabe: PruefAufgabe = {
  task_id: 't1',
  kopf: { kurztitel: 'Umfang · Radius 3,6 m', stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', hilfsmittel: 'Taschenrechner, Stift und Zettel' },
  aufgabe: { input_type: 'NUMERIC', unit: 'm', status: 'draft', lena_status: 'offen', taschenrechner: false, pruef_version: 3, ausschluss: null, pilot: false, team_beanstandet: false, parts: [], optionen: [], bild_vorhanden: false },
  ...sicht,
  loesungsweg: 'U = 2 · π · 3,6 m ≈ 22,62 m',
  fertigkeit: { key: 'geo_kreis_umfang', label: 'Umfang des Kreises', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', stufe: 'zweite', voraussetzungen: ['Werte in Terme einsetzen'] },
  fertigkeit_optionen: [{ key: 'geo_kreis_umfang', label: 'Umfang des Kreises', gruppe: 'thema' }, { key: 'term_einsetzen', label: 'Werte in Terme einsetzen', gruppe: 'voraussetzung' }],
  afb_sicher: 'mittel',
  ausgang: sicht,
  aenderungen: [],
  letzte_pruefung: null,
  auffaelligkeiten: [],
}

function zeige(pfad = '/coach/pruefen/t1?bereich=session'): void {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes>
        <Route path="/coach/pruefen/:taskId" element={<PruefansichtPage />} />
        <Route path="/coach/pruefen" element={<Ort />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('PruefansichtPage', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe, error: null })
    vi.mocked(getPruefBoard).mockResolvedValue({ data: [zeile('t1', 1), zeile('t2', 2)], error: null })
    vi.mocked(getFehlbilder).mockResolvedValue({ data: [{ slug: 'pi_vergessen', klartext: 'Lässt π weg.' }], error: null })
    vi.mocked(getPruefEinstellungen).mockResolvedValue({ data: { hilfsmittel: 'x', nur_pilot: false, grund_pflicht: false }, error: null })
    vi.mocked(pruefEntscheiden).mockResolvedValue({ data: { pruef_version: 4, lena_status: 'passt' }, error: null })
    vi.mocked(getPruefSoll).mockResolvedValue({ data: [], error: null })
  })

  it('zeigt Kopf, Pruefkarte und "mittel sicher" in Lenas Sprache', async () => {
    zeige()
    expect(await screen.findByText(/Klasse 9\/10 · Lernstandsanalyse Mathe · Erlaubt: Taschenrechner/)).toBeTruthy()
    expect(screen.getByText('22,62')).toBeTruthy()
    expect(screen.getByText('Lässt π weg.')).toBeTruthy()
    expect(screen.getByText('mittel sicher')).toBeTruthy()
    expect(screen.getByText('Alles ist vorbefüllt. Wenn es stimmt: „Passt“.')).toBeTruthy()
    expect(document.body.textContent).not.toMatch(/Item|Stamm|NUMERIC|Mängel|Fehlbild/)
  })

  it('zeigt die Hinweise fuer das Kind und speichert Aenderungen im Entwurf (L5)', async () => {
    vi.mocked(pruefSpeichern).mockResolvedValue({ data: { pruef_version: 4, auffaelligkeiten: [], aenderungen: [] }, error: null })
    zeige()
    const feld = await screen.findByLabelText('Hinweis Stufe 1')
    expect(screen.getByText('Hinweise für das Kind')).toBeTruthy()
    expect(screen.getByText('Entwurf')).toBeTruthy()
    fireEvent.change(feld, { target: { value: 'Welche Formel gilt für den Umfang?' } })
    await waitFor(() => expect(pruefSpeichern).toHaveBeenCalledWith('t1', 3, expect.objectContaining({
      hinweise: [{ stufe: 1, text: 'Welche Formel gilt für den Umfang?' }],
    })), { timeout: 2000 })
  })

  it('LSA-Bereich: keine Hinweise, auch nicht eingeklappt', async () => {
    zeige('/coach/pruefen/t1?bereich=lsa')
    await screen.findByText('22,62')
    expect(screen.queryByText('Hinweise für das Kind')).toBeNull()
    expect(screen.queryByLabelText('Hinweis Stufe 1')).toBeNull()
    expect(document.body.textContent).not.toContain('Was gehört in die Formel?')
  })

  it('ohne ?bereich=: LSA, wenn die Aufgabe auch LSA ist; Session-Aufgabe zeigt Hinweise', async () => {
    zeige('/coach/pruefen/t1')
    await screen.findByText('22,62')
    expect(screen.queryByText('Hinweise für das Kind')).toBeNull()
  })

  it('ohne ?bereich=: reine Session-Aufgabe zeigt Hinweise', async () => {
    vi.mocked(getPruefBoard).mockResolvedValue({ data: [zeile('t1', 1, ['batu_session'])], error: null })
    zeige('/coach/pruefen/t1')
    expect(await screen.findByText('Hinweise für das Kind')).toBeTruthy()
  })

  it('Weiter bleibt im Bereich: im LSA-Bereich zaehlt eine reine Session-Aufgabe nicht', async () => {
    vi.mocked(getPruefBoard).mockResolvedValue({ data: [zeile('t1', 1), zeile('t2', 2, ['batu_session'])], error: null })
    zeige('/coach/pruefen/t1?bereich=lsa')
    await screen.findByText('22,62')
    fireEvent.keyDown(window, { key: '3' })
    expect(await screen.findByText('Übersicht ?abschluss=1&bereich=lsa')).toBeTruthy()
  })

  it('"Passt nicht" verlangt einen Grund', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: /^Passt nicht/ }))
    fireEvent.click(screen.getByText('Als „Passt nicht“ speichern'))
    expect(screen.getByRole('alert').textContent).toBe('Bitte mindestens einen Grund wählen.')
    expect(pruefEntscheiden).not.toHaveBeenCalled()
  })

  it('Taste 3 entscheidet "Passt" und oeffnet die naechste offene Aufgabe', async () => {
    zeige()
    await screen.findByText('22,62')
    fireEvent.keyDown(window, { key: '3' })
    await waitFor(() => expect(pruefEntscheiden).toHaveBeenCalledWith(
      expect.objectContaining({ taskId: 't1', version: 3, entscheidung: 'passt' })))
    expect(await screen.findByText(/Kreis: Umfang und Fläche, Aufgabe 1: Passt/)).toBeTruthy()
    await waitFor(() => expect(getPruefAufgabe).toHaveBeenLastCalledWith('t2'))
  })

  it('vom Team beanstandet: nur lesen, Hinweis, keine Entscheidung', async () => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({
      data: { ...aufgabe, aufgabe: { ...aufgabe.aufgabe, status: 'beanstandet', lena_status: 'passt_nicht', team_beanstandet: true } },
      error: null,
    })
    zeige()
    expect(await screen.findByText(/Vom Team beanstandet, wird überarbeitet\. Danach kommt/)).toBeTruthy()
    expect(screen.queryByText(/Schon bewertet/)).toBeNull()
    expect((screen.getByRole('button', { name: /✓ Passt/ }) as HTMLButtonElement).disabled).toBe(true)
    expect((screen.getByRole('button', { name: /^Passt nicht/ }) as HTMLButtonElement).disabled).toBe(true)
    expect(screen.queryByRole('button', { name: /Antwort 22,62 löschen/ })).toBeNull()
    fireEvent.keyDown(window, { key: '3' })
    expect(pruefEntscheiden).not.toHaveBeenCalled()
  })

  it('Schalter setzt das Feld mit der aktuellen Version und nennt den Rechner im Kopf', async () => {
    vi.mocked(pruefTaschenrechnerSetzen).mockResolvedValue({
      data: { pruef_version: 4, taschenrechner: true, hilfsmittel: 'Taschenrechner, Stift und Zettel' }, error: null,
    })
    zeige()
    fireEvent.click(await screen.findByRole('switch', { name: /Taschenrechner erlaubt/ }))
    await waitFor(() => expect(pruefTaschenrechnerSetzen).toHaveBeenCalledWith('t1', 3, true))
    expect(await screen.findByText(/Erlaubt: Taschenrechner, Stift und Zettel/)).toBeTruthy()
    expect((screen.getByRole('switch', { name: /Taschenrechner erlaubt/ }) as HTMLInputElement).checked).toBe(true)
  })

  it('freigegebene Aufgabe: fuer Lena gesperrt, mit Begruendung', async () => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({
      data: { ...aufgabe, aufgabe: { ...aufgabe.aufgabe, status: 'ready', lena_status: 'freigegeben' } }, error: null,
    })
    zeige()
    const schalter = await screen.findByRole('switch', { name: /Taschenrechner erlaubt/ }) as HTMLInputElement
    expect(schalter.disabled).toBe(true)
    expect(screen.getByText(/Freigegebene Aufgaben ändert nur ein Admin/)).toBeTruthy()
  })
})

const soll = (skill: string, thema: string, sort: number, gezaehlt: number): PruefSollZeile => ({
  skill_key: skill, skill_label: skill, thema_key: thema, thema_label: thema, thema_sort: 1, stufe: 'zweite', sort,
  anlaesse: ['batu_lsa'], soll: 3, min_ohne_mc: 1, im_board: 3, gezaehlt, gezaehlt_ohne_mc: gezaehlt,
  rest: 3 - gezaehlt, reicht: gezaehlt >= 3,
})

describe('PruefansichtPage · Lauf nach Soll (P4)', () => {
  const dreieck = { ...zeile('t3', 0, ['batu_lsa']), thema_key: 'dreieck', thema_label: 'Dreiecke', skill_key: 'geo_dreieck', skill_label: 'Dreiecksfläche' }

  function mitSoll(umfangGezaehlt: number): void {
    vi.mocked(getPruefBoard).mockResolvedValue({ data: [dreieck, zeile('t1', 1, ['batu_lsa']), zeile('t2', 2, ['batu_lsa'])], error: null })
    vi.mocked(getPruefSoll).mockImplementation(async (a) => ({
      data: a === 'batu_lsa' ? [soll('geo_kreis_umfang', 'kreis', 10, umfangGezaehlt), soll('geo_dreieck', 'dreieck', 20, 1)] : [],
      error: null,
    }))
  }

  beforeEach(() => {
    vi.clearAllMocks()
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe, error: null })
    vi.mocked(getFehlbilder).mockResolvedValue({ data: [], error: null })
    vi.mocked(getPruefEinstellungen).mockResolvedValue({ data: { hilfsmittel: 'x', nur_pilot: false, grund_pflicht: false }, error: null })
    vi.mocked(pruefEntscheiden).mockResolvedValue({ data: { pruef_version: 4, lena_status: 'passt' }, error: null })
  })

  it('Kopf zeigt Thema · Knoten · noch n noetig im Thema', async () => {
    mitSoll(2)
    zeige('/coach/pruefen/t1?bereich=lsa')
    expect(await screen.findByText('Kreis: Umfang und Fläche · Umfang des Kreises · noch 1 nötig im Thema')).toBeTruthy()
    expect(screen.getByText('Aufgabe 1 von 2')).toBeTruthy()
  })

  it('"Passt" auf der letzten noetigen Aufgabe: Zwischenbild mit "3 von 3 noetig", "Weiter" oeffnet das naechste Thema', async () => {
    mitSoll(2)
    zeige('/coach/pruefen/t1?bereich=lsa')
    await screen.findByText(/noch 1 nötig im Thema/)
    fireEvent.keyDown(window, { key: '3' })
    expect(await screen.findByText('Kreis: Umfang und Fläche ist fertig: 3 von 3 nötig geprüft.')).toBeTruthy()
    expect(screen.getByText('Weiter mit Dreiecke · noch 2 nötig')).toBeTruthy()
    expect(screen.queryByRole('button', { name: /✓ Passt/ })).toBeNull()
    expect(getPruefAufgabe).toHaveBeenLastCalledWith('t1')
    fireEvent.keyDown(window, { key: 'Enter' })
    await waitFor(() => expect(getPruefAufgabe).toHaveBeenLastCalledWith('t3'))
    expect(screen.queryByText(/ist fertig/)).toBeNull()
  })

  it('innerhalb eines Themas kein Zwischenbild, auch wenn die Aufgabe im Board weiter vorn liegt', async () => {
    mitSoll(0)
    zeige('/coach/pruefen/t2?bereich=lsa')
    await screen.findByText(/noch 3 nötig im Thema/)
    fireEvent.keyDown(window, { key: '3' })
    await waitFor(() => expect(getPruefAufgabe).toHaveBeenLastCalledWith('t1'))
    expect(screen.queryByText(/ist fertig/)).toBeNull()
  })
})
