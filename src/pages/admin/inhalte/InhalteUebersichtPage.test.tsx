// IU-1 U2: Inhalte-Übersicht. Reiter, Filter, MSA-Zeile, Details mit Zurück (Reiter und Klasse bleiben), Sprung in
// Lenas Liste, Reihen und Themen ohne Reihe, Fehler- und Leerzustand, Tastatur.
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation } from 'react-router-dom'
import '@/i18n'

const m = vi.hoisted(() => ({
  frisch: vi.fn(), themen: vi.fn(), thema: vi.fn(), ziel: vi.fn(), reihen: vi.fn(), reihe: vi.fn(), ohne: vi.fn(),
}))
vi.mock('@/lib/supabase/inhalte', () => ({
  frischeInhalte: m.frisch, getLsaThemen: m.themen, getLsaThema: m.thema, getLsaPruefziel: m.ziel,
  getSessionReihen: m.reihen, getSessionReihe: m.reihe, getThemenOhneReihe: m.ohne,
}))

import type { InhalteReihe, InhalteThema } from '@/types/inhalte'
import { InhalteUebersichtPage } from './InhalteUebersichtPage'

const ok = <T,>(data: T) => Promise.resolve({ data, error: null })
const thema = (p: Partial<InhalteThema>): InhalteThema => ({
  thema_key: 'potenzen', titel: 'Potenzen', klasse: 9, quartal: 3, von: '2027-02-01', bis: '2027-04-10', komp_bereit: 3,
  komp_teil: 5, komp_offen: 4, pflicht_bereit: 0, pflicht_gesamt: 2, hat_einstieg: true, aufgaben_frei: 14,
  aufgaben_zur_freigabe: 0, aufgaben_zu_pruefen: 13, aufgaben_fehlen: 0, ampel: 'noch_nicht', schulen: 27,
  schulen_bestaetigt: 0, alle_zu_pruefen: 137, ...p,
})
const reihe: InhalteReihe = {
  reihe: 'quadratische_funktionen_gleichungen', titel: 'Quadratische Funktionen · Quadratische Gleichungen', thema_keys: [],
  klasse: 9, sessions: 7, quartal: 2, von: '2026-11-16', bis: '2026-12-31', bf_freigegeben: 0, bf_zur_freigabe: 0,
  bf_rueckfrage: 0, bf_offen: 47, bf_zu_pruefen: 47, vid_freigegeben: 0, vid_in_pruefung: 0, vid_fehlt: 9, vid_gesamt: 9,
  ampel: 'nicht_bereit', schulen: 27, schulen_bestaetigt: 0,
}
const ziel = (bereich: string | null, bereit: number) => ({
  bereich, titel: 'MSA-Vorbereitung (ZP10)', komp_bereit: bereit, komp_teil: 1, komp_offen: 5, fehlende_texte: 11,
  aufgaben_frei: 1, aufgaben_zur_freigabe: 0, aufgaben_zu_pruefen: 11, aufgaben_fehlen: 0, zu_leicht: 2, ampel: 'noch_nicht',
})

beforeEach(() => {
  m.frisch.mockReset().mockReturnValue(ok(false))
  m.themen.mockReset().mockImplementation(() => ok([thema({}), thema({ thema_key: 'flaechen', titel: 'Flächen', klasse: 8, ampel: 'eingeschraenkt' })]))
  m.ziel.mockReset().mockReturnValue(ok([ziel(null, 35), ziel('stochastik', 0)]))
  m.thema.mockReset().mockReturnValue(ok([
    { skill_key: 'potenzen', label: 'Potenzen', teil: 'pflicht', rolle: 'einstieg', texte: 1, erfuellt: false, zu_pruefen: 1, fehlen: 0, offene_task_ids: ['t1'] },
    { skill_key: 'quadrat', label: 'Quadratzahlen', teil: 'tiefe', rolle: 'tiefe', texte: 2, erfuellt: true, zu_pruefen: 0, fehlen: 0, offene_task_ids: [] },
  ]))
  m.reihen.mockReset().mockReturnValue(ok([reihe]))
  m.reihe.mockReset().mockReturnValue(ok([{ nr: 1, titel: 'Normalparabel', bauformen: 5, geprueft: 0, freigegeben: 0, rueckfrage: 0,
    zu_pruefen: 5, zur_freigabe: 0, video_status: 'fehlt', naechster_schritt: 'lena_prueft' }]))
  m.ohne.mockReset().mockReturnValue(ok([{ thema_key: 'kreis', titel: 'Kreis', klasse: 9, quartal: 2, von: null, bis: null,
    schulen: 27, schulen_bestaetigt: 0, bauformen: 1, lsa_frei: 25, vorarbeit: 'bauformen' }]))
})

function Adresse(): JSX.Element {
  const l = useLocation()
  return <output data-testid="adresse">{l.pathname + l.search}</output>
}
const zeige = (pfad = '/admin/inhalte'): void => {
  render(
    <MemoryRouter initialEntries={[pfad]}>
      <Routes><Route path="*" element={<><InhalteUebersichtPage /><Adresse /></>} /></Routes>
    </MemoryRouter>,
  )
}

describe('Reiter Lernstandsanalyse', () => {
  it('Kennzahlen, MSA-Zeile mit Prüfziel oben, Themen; frischt zuerst auf', async () => {
    zeige()
    const tabelle = await screen.findByRole('table', { name: 'Themen der Lernstandsanalyse' })
    expect(m.frisch).toHaveBeenCalled()
    const zeilen = within(tabelle).getAllByRole('button')
    expect(zeilen[0]).toHaveTextContent('MSA-Vorbereitung (ZP10)')
    expect(zeilen[0]).toHaveTextContent('Prüfziel')
    expect(zeilen[0]).toHaveTextContent('6 Kompetenzen fehlen')
    expect(zeilen[1]).toHaveTextContent('2 Pflicht-Kompetenzen fehlen')
    expect(zeilen[1]).toHaveTextContent('Lena: prüft noch 13 Aufgaben')
    const kpi = screen.getByRole('navigation', { name: 'Kennzahlen' })
    expect(kpi).toHaveTextContent('137')
    expect(kpi).toHaveTextContent('Themen mit eingeschränkter LSA')
  })

  it('Filter Klasse 9: nur diese Klasse, ohne MSA-Zeile; Adresse trägt die Klasse', async () => {
    zeige()
    await screen.findByRole('table')
    fireEvent.click(screen.getByRole('button', { name: 'Klasse 9' }))
    await waitFor(() => expect(m.themen).toHaveBeenLastCalledWith(9))
    expect(screen.getByTestId('adresse')).toHaveTextContent('reiter=lsa&klasse=9')
    await screen.findByRole('table')
    expect(screen.queryByText('MSA-Vorbereitung (ZP10)')).toBeNull()
  })

  it('Thema per Enter: Pflicht und Tiefe, „1 von 2“, Sprung in Lenas Liste; Zurück behält Reiter und Klasse', async () => {
    zeige('/admin/inhalte?reiter=lsa&klasse=9')
    const tabelle = await screen.findByRole('table')
    fireEvent.keyDown(within(tabelle).getAllByRole('button')[0], { key: 'Enter' })
    expect(await screen.findByText('Pflicht')).toBeInTheDocument()
    expect(screen.getByTestId('adresse')).toHaveTextContent('thema=potenzen')
    expect(screen.getByText('1 von 2')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Potenzen in Lenas Liste öffnen' })).toHaveAttribute('href', '/coach/pruefen?skill=potenzen')
    fireEvent.click(screen.getByRole('link', { name: 'Zur Übersicht' }))
    await screen.findByRole('table')
    expect(screen.getByTestId('adresse')).toHaveTextContent('/admin/inhalte?reiter=lsa&klasse=9')
  })

  it('MSA-Detail: Karte je Bereich mit Sprung in Lenas Liste (Prüfziel)', async () => {
    zeige('/admin/inhalte?reiter=lsa&ziel=msa_zp10')
    expect(await screen.findByText('Stochastik')).toBeInTheDocument()
    expect(screen.getByText('0 von 6 bereit')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Lena prüft 11 Aufgaben' })).toHaveAttribute('href', '/coach/pruefen?ziel=msa_zp10')
  })

  it('Fehler: Hinweis statt Tabelle', async () => {
    m.themen.mockReturnValue(Promise.resolve({ data: null, error: { code: 'x', message: 'x' } }))
    zeige()
    expect(await screen.findByText('Die Übersicht konnte nicht geladen werden')).toBeInTheDocument()
  })

  it('Leer: EmptyState', async () => {
    m.themen.mockReturnValue(ok([]))
    zeige('/admin/inhalte?reiter=lsa&klasse=8')
    expect(await screen.findByText('Für diese Klasse gibt es kein Thema im Plan.')).toBeInTheDocument()
  })
})

describe('Reiter Session-Reihen', () => {
  it('Reihen mit Balken und Schritten, Themen ohne Reihe mit gesperrtem „Reihe anlegen“', async () => {
    zeige('/admin/inhalte?reiter=reihen')
    const tabelle = await screen.findByRole('table', { name: 'Vorhandene Reihen' })
    expect(tabelle).toHaveTextContent('Quadratische Funktionen und Gleichungen')
    expect(tabelle).toHaveTextContent('0 frei · 0 zur Freigabe · 0 Rückfrage · 47 offen')
    expect(within(tabelle).getByRole('link', { name: /Studio: 9 Videos fehlen noch/ })).toHaveAttribute('href', '/admin/studio')
    const ohne = screen.getByRole('table', { name: 'Themen ohne Reihe' })
    expect(ohne).toHaveTextContent('1 Bauform passt')
    const knopf = within(ohne).getByRole('button', { name: 'Reihe anlegen' })
    expect(knopf).toBeDisabled()
    expect(knopf).toHaveAccessibleDescription('kommt später')
  })

  it('Klick auf die Reihe zeigt die Sessions als Karten', async () => {
    zeige('/admin/inhalte?reiter=reihen')
    const tabelle = await screen.findByRole('table', { name: 'Vorhandene Reihen' })
    fireEvent.click(within(tabelle).getAllByRole('button')[0])
    expect(await screen.findByText('Session 1 · offen')).toBeInTheDocument()
    expect(screen.getByText('Video fehlt')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Lena prüft 5 Bauformen' })).toHaveAttribute('href', '/coach/pruefen/bauformen')
    expect(screen.getByTestId('adresse')).toHaveTextContent('reiter=reihen&reihe=quadratische_funktionen_gleichungen')
  })
})
