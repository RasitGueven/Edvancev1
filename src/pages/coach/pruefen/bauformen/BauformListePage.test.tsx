// M1: Muster-Ansicht nach Sessions – Gruppen mit Titel und Fortschritt, Kopfzeile, Plan-Umschalter, Filter innerhalb
// der Gruppen, „Session n freigeben“ nur fuer Admins und nur bei erfuellter Bedingung, mit Bestaetigung.
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen, waitFor, within } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import '@/i18n'
import type { BauformPlanZeile } from '@/types/bauformPruefung'

const rolle = vi.hoisted(() => ({ role: 'admin' }))
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ user: { id: 'u' }, role: rolle.role, signOut: vi.fn() }) }))

const z = (schluessel: string, session_nr: number | null, status: BauformPlanZeile['status'], vor = false): BauformPlanZeile =>
  ({
    bauform_id: schluessel, schluessel, skill_key: 's', skill_label: 'Skill', reihe: 'quadratische_funktionen_gleichungen',
    format: 'mc', rollen: ['uebung'], version: 1, status, gruen: 8, letzte_entscheidung: null, letzte_notiz: null,
    geprueft_am: null, session_nr, session_titel: session_nr ? `Thema ${session_nr}` : null, kernidee_key: null,
    kernidee_titel: `Kernidee ${schluessel}`, ist_voraussetzung: vor,
  }) as BauformPlanZeile

const standard = [
  z('PAR-1', 1, 'zur_freigabe'), z('PAR-2', 1, 'freigegeben'), z('KO-1', 1, 'zur_pruefung', true),
  z('SCH-1', 2, 'zur_freigabe'), z('SCH-2', 2, 'rueckfrage'),
  z('BIN-9', null, 'zur_pruefung', true),
]
const batu = [z('PAR-1', 1, 'zur_freigabe'), z('SCH-1', 3, 'zur_freigabe')]

vi.mock('@/lib/supabase/bauformPruefung', () => ({
  getBauformPlan: vi.fn(async (kind?: string | null) => ({ data: kind ? batu : standard, error: null })),
  getPlanKinder: vi.fn(async () => ({ data: [{ student_id: 'k1', name: 'Batu', ist_test: false, reihe_id: 'r1' }], error: null })),
  getAuffaellig: vi.fn(async () => ({ data: [], error: null })),
  getPrueffragen: vi.fn(async () => ({ data: [], error: null })),
  bauformFreigeben: vi.fn(async () => ({ data: 1, error: null })),
  aufgabeReaktivieren: vi.fn(), bauformReaktivieren: vi.fn(), bauformZurUeberarbeitung: vi.fn(), prueffrageEntscheiden: vi.fn(),
}))
import { bauformFreigeben, getBauformPlan } from '@/lib/supabase/bauformPruefung'
import { BauformListePage } from './BauformListePage'

const zeige = (url = '/coach/pruefen/bauformen') =>
  render(<MemoryRouter initialEntries={[url]}><BauformListePage /></MemoryRouter>)
const abschnitt = (name: RegExp) => screen.getByRole('region', { name })

describe('BauformListePage nach Sessions', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    rolle.role = 'admin'
  })

  it('gruppiert nach Session mit Titel, Voraussetzungen zuerst, nicht zugeordnete am Ende', async () => {
    zeige()
    expect(await screen.findByRole('heading', { name: 'Session 1 · Thema 1' })).toBeInTheDocument()
    const ueberschriften = screen.getAllByRole('heading', { level: 2 }).map((h) => h.textContent)
    expect(ueberschriften).toEqual(['Session 1 · Thema 1', 'Session 2 · Thema 2', 'Voraussetzungen'])
    const s1 = within(abschnitt(/Session 1/)).getAllByRole('button').map((b) => b.textContent ?? '')
    expect(s1.filter((t) => /^(KO|PAR)/.test(t)).map((t) => t.slice(0, 5))).toEqual(['KO-1V', 'PAR-1', 'PAR-2'])
  })

  it('zeigt Kopfzeile und Fortschritt je Session', async () => {
    zeige()
    expect(await screen.findByText('3 von 6 geprüft · 1 freigegeben')).toBeInTheDocument()
    expect(within(abschnitt(/Session 1/)).getByText('2 von 3 geprüft')).toBeInTheDocument()
    expect(within(abschnitt(/Session 2/)).getByText('1 von 2 geprüft')).toBeInTheDocument()
  })

  it('Filter wirkt innerhalb der Gruppen', async () => {
    zeige('/coach/pruefen/bauformen?filter=rueckfrage')
    expect(await screen.findByText('SCH-2')).toBeInTheDocument()
    expect(screen.queryByText('PAR-1')).not.toBeInTheDocument()
    expect(screen.queryByRole('heading', { name: /Session 1/ })).not.toBeInTheDocument()
  })

  it('Freigabe-Knopf: aktiv bei Muster zur Freigabe, gesperrt bei Rueckfrage, mit Bestaetigung', async () => {
    zeige()
    const s1 = await screen.findByRole('button', { name: 'Session 1 freigeben' })
    const s2 = screen.getByRole('button', { name: 'Session 2 freigeben' })
    expect(s1).toBeEnabled()
    expect(s2).toBeDisabled()
    expect(s2).toHaveAttribute('title', 'Erst die Rückfragen dieser Session klären.')
    fireEvent.click(s1)
    expect(screen.getByText(/1 Muster der Session 1 freigeben \(PAR-1\)/)).toBeInTheDocument()
    expect(bauformFreigeben).not.toHaveBeenCalled()
    fireEvent.click(screen.getByRole('button', { name: '1 Muster freigeben' }))
    await waitFor(() => expect(bauformFreigeben).toHaveBeenCalledWith('quadratische_funktionen_gleichungen', ['PAR-1']))
  })

  it('kein Freigabe-Knopf fuer Lena', async () => {
    rolle.role = 'coach'
    zeige()
    await screen.findByRole('heading', { name: 'Session 1 · Thema 1' })
    expect(screen.queryByRole('button', { name: /freigeben/ })).not.toBeInTheDocument()
  })

  it('Plan-Umschalter laedt den Plan des Kindes', async () => {
    zeige()
    fireEvent.click(await screen.findByRole('button', { name: 'Batu' }))
    await waitFor(() => expect(getBauformPlan).toHaveBeenLastCalledWith('k1'))
    expect(await screen.findByRole('heading', { name: 'Session 3 · Thema 3' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Batu' })).toHaveAttribute('aria-pressed', 'true')
    expect(screen.getByRole('button', { name: 'Standard' })).toHaveAttribute('aria-pressed', 'false')
  })
})
