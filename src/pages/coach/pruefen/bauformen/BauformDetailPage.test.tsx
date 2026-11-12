// SP-1 S4: Lenas Prüfansicht einer Bauform. Klartext, Kommentare an Ankern, ein Knopf (Passt | Rückfrage), gesperrt bei
// leerem Kommentar, „Andere Beispiele“ behält kommentierte, Zeit je Stufe, Entwurf, danach die nächste Bauform.
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter, Route, Routes, useLocation, useParams } from 'react-router-dom'
import '@/i18n'
import type { BauformDetail } from '@/types/bauformPruefung'

const rolle = vi.hoisted(() => ({ role: 'coach' }))
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: { id: 'u' }, role: rolle.role, signOut: vi.fn() }) }))

const beispiel = (id: string, stufe: number) => ({
  task_id: id, stufe, rolle: stufe === 1 ? 'warmup' : 'home',
  loesung: '27' as unknown as Record<string, unknown>, known_errors: { '−78': 'qf_quadrat_als_verdopplung', '-78': 'qf_quadrat_als_verdopplung' },
  loesungsweg: 'f(−5) = 3 · (−5)²\n= 27', hinweise: [{ level: 1, text: 'Ersetze jedes x.' }],
  payload: { kind: 'short_input' as const, task_id: id, assets: [], prompt: `Berechne f(${id}).` },
})
const detail = (seed: number, behalten: string[] = []): BauformDetail => ({
  bauform_id: 'b1', schluessel: 'EIN-1', skill_key: 'term_einsetzen', skill_label: 'Werte in Terme einsetzen', kernidee_key: null,
  format: 'zahl', rollen: ['warmup', 'home'], version: 1, status: 'zur_pruefung', titel: 'Werte in Terme einsetzen',
  steckbrief: { text: 'Berechne f({x0}) für f(x) = {term}.', stufen: { '1': 'x von 1 bis 6 (ohne 2)' }, hinweise: [], loesungsweg: [], warum: null,
    fehlbilder: [{ key: 'qf_quadrat_als_verdopplung', rueckmeldung: 'x² heißt x mal x.', gilt_fuer_stufen: [1, 2] }] },
  stufen: [{ stufe: 1, beschreibung: 'x ist positiv.', beispiel: 'Berechne f(4).', zeit_min: 1 },
    { stufe: 2, beschreibung: 'x ist negativ.', beispiel: 'Berechne f(−4).', zeit_min: 1 }],
  pruefprotokoll: { gruen: 71, rot: 1 }, blindloeser: { geloest: 10, abweichend: [] }, verdacht: null,
  fehlbild_texte: { qf_quadrat_als_verdopplung: 'Rechnet x² als 2·x.' }, instanzen: 71, pruefungen: [], rueckfrage: null,
  beispiele: seed === 0 ? [beispiel('a1', 1), beispiel('a2', 2)] : [...behalten.map((id) => beispiel(id, 1)), beispiel('n1', 2)],
})

vi.mock('@/lib/supabase/bauformPruefung', () => ({
  getBauformDetail: vi.fn(async (_id: string, seed: number, behalten: string[]) => ({ data: detail(seed, behalten), error: null })),
  bauformPruefungSenden: vi.fn(async () => ({ data: { status: 'zur_freigabe', version: 1, pruefung_id: 'p', kommentare: 0 }, error: null })),
  getBauformPlan: vi.fn(async () => ({
    data: [
      { bauform_id: 'b1', schluessel: 'EIN-1', status: 'zur_pruefung', session_nr: 1, ist_voraussetzung: true, titel: 'Werte in Terme einsetzen', skill_label: 'S', gruen: 71, antwortart: 'zahl' },
      { bauform_id: 'b2', schluessel: 'KO-1', status: 'zur_pruefung', session_nr: 1, ist_voraussetzung: true, titel: 'Punkte ablesen', skill_label: 'S', gruen: 64 },
    ],
    error: null,
  })),
}))
import { bauformPruefungSenden, getBauformDetail } from '@/lib/supabase/bauformPruefung'
import { BauformDetailPage } from './BauformDetailPage'

function Ziel(): JSX.Element {
  const l = useLocation()
  return <p>Ziel {l.pathname} {(l.state as { meldung?: string } | null)?.meldung}</p>
}
function Weiche(): JSX.Element {
  return useParams().bauformId === 'b1' ? <BauformDetailPage /> : <Ziel />
}
const zeige = () => render(
  <MemoryRouter initialEntries={['/coach/pruefen/bauformen/b1']}>
    <Routes>
      <Route path="/coach/pruefen/bauformen/:bauformId" element={<Weiche />} />
      <Route path="*" element={<Ziel />} />
    </Routes>
  </MemoryRouter>,
)
const knopf = (name: RegExp | string) => screen.getByRole('button', { name })

describe('BauformDetailPage (SP-1)', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    window.localStorage.clear()
    rolle.role = 'coach'
  })

  it('Klartext: Titel, Kürzel als Etikett, Platzhalter als Wort, Stufen, typische Fehler mit gespeicherter Antwort', async () => {
    const { container } = zeige()
    expect(await screen.findByRole('heading', { level: 1, name: 'Werte in Terme einsetzen' })).toBeInTheDocument()
    expect(screen.getByText('EIN-1')).toBeInTheDocument()
    expect(await screen.findByText(/gebraucht in Session 1/)).toBeInTheDocument()
    expect(screen.getByText(/71 Aufgaben übernehmen deine Prüfung/)).toBeInTheDocument()
    expect(screen.getByText('Automatisch geprüft: 71 von 72 Aufgaben in Ordnung')).toBeInTheDocument()
    expect(screen.getByText('x ist negativ.')).toBeInTheDocument()
    expect(screen.getAllByText('−78')).toHaveLength(2)
    expect(screen.getAllByText('Warm-up').length).toBeGreaterThan(0)
    expect(container.textContent).not.toMatch(/qf_|graph_auswahl|warmup|\{|Blindlöser/)
  })

  it('ohne Kommentar: „Passt · 71 Aufgaben zur Freigabe“, danach die nächste Bauform', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Passt · 71 Aufgaben zur Freigabe' }))
    await waitFor(() => expect(bauformPruefungSenden).toHaveBeenCalledWith('b1', 1, [], {}, expect.any(Number)))
    expect(await screen.findByText(/Ziel \/coach\/pruefen\/bauformen\/b2 Passt\..*Weiter mit „Punkte ablesen“/)).toBeInTheDocument()
  })

  it('Kommentar am Beispiel: Fokus im Textfeld, gesperrt bis Grund, dann Rückfrage mit Instanz', async () => {
    zeige()
    await screen.findByText('Beispiel 1')
    fireEvent.click(knopf('Kommentar: Beispiel 1'))
    expect(screen.getByRole('textbox', { name: 'Kommentar zu Beispiel 1' })).toHaveFocus()
    expect(knopf('Kommentiert: Beispiel 1')).toHaveAttribute('aria-pressed', 'true')
    const senden = knopf('Rückfrage senden (1 Kommentar)')
    expect(senden).toBeDisabled()
    expect(senden).toHaveAttribute('title')
    fireEvent.click(knopf('Rechnung falsch'))
    expect(senden).toBeEnabled()
    fireEvent.click(senden)
    await waitFor(() => expect(bauformPruefungSenden).toHaveBeenCalledWith('b1', 1,
      [{ anker: 'beispiel', task_id: 'a1', gruende: ['rechnung_falsch'], text: null }], {}, expect.any(Number)))
  })

  it('Entfernen per ×, Überschrift springt zur Stelle', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Kommentar: Grundgerüst' }))
    expect(knopf('Rückfrage senden (1 Kommentar)')).toBeInTheDocument()
    fireEvent.click(knopf('Kommentar entfernen: Grundgerüst'))
    expect(knopf('Passt · 71 Aufgaben zur Freigabe')).toBeEnabled()
  })

  it('„Andere Beispiele“ behält kommentierte', async () => {
    zeige()
    await screen.findByText('Beispiel 1')
    fireEvent.click(knopf('Kommentar: Beispiel 1'))
    fireEvent.click(knopf('Andere Beispiele'))
    await waitFor(() => expect(getBauformDetail).toHaveBeenLastCalledWith('b1', 1, ['a1']))
    expect(await screen.findByText('Berechne f(a1).')).toBeInTheDocument()
    expect(screen.queryByText('Berechne f(a2).')).not.toBeInTheDocument()
  })

  it('Zeit je Stufe: Plus markiert „vorher“, geht mit Passt mit, Entwurf bleibt beim Verlassen', async () => {
    const { unmount } = zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Zeit Stufe 2 länger' }))
    expect(screen.getByText('vorher 1 Min')).toBeInTheDocument()
    expect(screen.getByText('Zeit geändert: Stufe 2 → 1,5 Min')).toBeInTheDocument()
    unmount()
    zeige()
    expect(await screen.findByText('vorher 1 Min')).toBeInTheDocument()
    fireEvent.click(knopf('Passt · 71 Aufgaben zur Freigabe'))
    await waitFor(() => expect(bauformPruefungSenden).toHaveBeenCalledWith('b1', 1, [], { '2': 1.5 }, expect.any(Number)))
  })

  it('Admin sieht die letzte Rückfrage mit erledigt-Notiz', async () => {
    rolle.role = 'admin'
    vi.mocked(getBauformDetail).mockResolvedValueOnce({ data: { ...detail(0), status: 'zur_freigabe', rueckfrage: {
      pruefung_id: 'p', version: 1, am: '2026-11-12', kommentare: [{ id: 'k', anker: 'beispiel', task_id: 'a1', gruende: ['rechnung_falsch'],
        text: null, frage: 'Berechne f(−5).', status: 'erledigt', erledigt_notiz: 'Zahlen korrigiert', erledigt_am: '2026-11-12' }] } }, error: null })
    zeige()
    const r = await screen.findByRole('region', { name: 'Letzte Rückfrage (Version 1)' })
    expect(within(r).getByText('erledigt: Zahlen korrigiert')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /^Passt/ })).not.toBeInTheDocument()
  })
})
