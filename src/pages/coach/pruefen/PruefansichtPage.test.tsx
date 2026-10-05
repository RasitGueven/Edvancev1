// Pruefansicht: mountet sie mit einer Kreis-Aufgabe, gilt der Sperrgrund, verlangt "Passt nicht"
// einen Grund, fuehrt "3" zur Entscheidung und danach zur naechsten offenen Aufgabe?
// Alle Supabase-Wrapper sind gemockt (CI hat keine VITE_*-Variablen).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'
import type { PruefAufgabe, PruefBoardZeile } from '@/types'

vi.mock('@/lib/supabase/pruefung', () => ({
  getPruefAufgabe: vi.fn(),
  getPruefBoard: vi.fn(),
  getFehlbilder: vi.fn(),
  getPruefEinstellungen: vi.fn(),
  pruefSpeichern: vi.fn(),
  pruefEntscheiden: vi.fn(),
  pruefRueckgaengig: vi.fn(),
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
  getFehlbilder, getPruefAufgabe, getPruefBoard, getPruefEinstellungen, pruefEntscheiden,
} from '@/lib/supabase/pruefung'
import { PruefansichtPage } from './PruefansichtPage'

const zeile = (id: string, reihenfolge: number): PruefBoardZeile => ({
  task_id: id, stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', thema_sort: 470,
  skill_key: 'geo_kreis_umfang', skill_label: 'Umfang des Kreises', kurztitel: id, reihenfolge,
  lena_status: 'offen', geaendert: false, letzte_dauer_sek: null,
})

const sicht = {
  werte: [{ teil: null, werte: [{ wert: '22,62', schreibweisen: ['22,62', '22.62'] }] }],
  mc: null,
  regel: { art: 'wert' as const, mitte: null, toleranz: null, einheit_pflicht: false, einheit: 'm', einheit_am_feld: true },
  fehler: [{ slug: 'pi_vergessen', werte: [{ teil: null, wert: '7,2' }], text: 'π weggelassen.', klartext: 'Lässt π weg.' }],
  weitere_hinweise: [],
  skill_key: 'geo_kreis_umfang',
  afb: 'II' as const,
  flach_regel: true,
  ohne_erkennung: false,
}

const aufgabe: PruefAufgabe = {
  task_id: 't1',
  kopf: { kurztitel: 'Umfang · Radius 3,6 m', stufe: 'zweite', thema_key: 'kreis', thema_label: 'Kreis: Umfang und Fläche', hilfsmittel: 'Taschenrechner, Stift und Zettel' },
  aufgabe: { input_type: 'NUMERIC', unit: 'm', status: 'draft', lena_status: 'offen', pruef_version: 3, ausschluss: null, pilot: false, parts: [], optionen: [], bild_vorhanden: false },
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

function zeige(): void {
  render(
    <MemoryRouter initialEntries={['/coach/pruefen/t1']}>
      <Routes>
        <Route path="/coach/pruefen/:taskId" element={<PruefansichtPage />} />
        <Route path="/coach/pruefen" element={<p>Übersicht</p>} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('PruefansichtPage', () => {
  beforeEach(() => {
    vi.mocked(getPruefAufgabe).mockResolvedValue({ data: aufgabe, error: null })
    vi.mocked(getPruefBoard).mockResolvedValue({ data: [zeile('t1', 1), zeile('t2', 2)], error: null })
    vi.mocked(getFehlbilder).mockResolvedValue({ data: [{ slug: 'pi_vergessen', klartext: 'Lässt π weg.' }], error: null })
    vi.mocked(getPruefEinstellungen).mockResolvedValue({ data: { hilfsmittel: 'x', nur_pilot: false, grund_pflicht: false }, error: null })
    vi.mocked(pruefEntscheiden).mockResolvedValue({ data: { pruef_version: 4, lena_status: 'passt' }, error: null })
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
})
