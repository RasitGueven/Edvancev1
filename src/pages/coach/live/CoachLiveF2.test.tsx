// F2 Tests 1-3 (Oberflaeche, Trockenlauf 10.10.): Kopf nach den Kindern mit Restzeit, Check-in-Aufgaben des
// Coaches ueber dem Raster, solange ein Kind im Check-in ist, und der Hinweis „kein Testlauf“.
// Grundlage: echte Antworten aus coachLiveFixturesC3.json, nur Testkonten-Namen.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import '@/i18n'

const live = vi.hoisted(() => ({
  raum: null as unknown,
  testkontenLaden: vi.fn((ids: string[]) => Promise.resolve(new Map(ids.map((id) => [id, true])))),
  themenKatalog: vi.fn(() => Promise.resolve({ data: [], error: null })),
}))
vi.mock('@/lib/session/coachLive', () => ({
  LIVE_ABFRAGE_MS: 4000,
  testkontenLaden: live.testkontenLaden,
  themenKatalog: live.themenKatalog,
  checkinCoachSetzen: vi.fn(), eingriffNotieren: vi.fn(), pfadEntscheiden: vi.fn(), signalErledigen: vi.fn(),
  tabletLoesen: vi.fn(), tabletZuweisen: vi.fn(),
}))
vi.mock('@/hooks/useRaumLive', () => ({
  useRaumLive: () => ({ raum: live.raum, fehler: null, laedt: false, neuLaden: vi.fn() }),
}))
vi.mock('@/hooks/useAuth', () => ({ useAuth: () => ({ role: 'coach' }) }))
vi.mock('@/lib/supabase/sessionPruefung', () => ({ pruefungAufsTablet: vi.fn(), pruefungVomTablet: vi.fn() }))

import { raumAus } from '@/lib/session/coachLiveAbbildung'
import fixtures from '@/lib/session/coachLiveFixturesC3.json'
import type { KindRaum } from '@/types/sessionC2'
import type { RaumLive } from '@/types/sessionLive'
import { CoachLivePage } from './CoachLivePage'

const basis = (fixtures as unknown as Record<string, RaumLive>).raum_kern
const emir = basis.kinder[0]

/** Raum mit Kindern auf Tablet 1..n in den angegebenen Phasen; die Uhr steht bei Minute 2 (Check-in). */
function raum(phasen: (KindRaum['phase'])[], session: Partial<RaumLive['session']> = {}, kind: Partial<KindRaum> = {}) {
  const start = Date.parse(basis.stand) - 2 * 60_000
  const kinder = phasen.map((phase, i) => ({
    ...emir, ...kind, student_id: `kind-${i + 1}`, name: `Test Kind${i + 1}`, tablet_nr: i + 1, phase,
    checkin_fertig: phase !== 'checkin',
  })) as KindRaum[]
  const r: RaumLive = { ...basis, session: { ...basis.session, gestartet_am: new Date(start).toISOString(), ...session }, kinder }
  return raumAus(r, { detail: null, briefing: [], satz: {}, themen: new Map(), nichtErschienen: new Set(), pfadGeoeffnet: {} })
}

function zeige(): void {
  render(
    <MemoryRouter initialEntries={['/coach/live/s1']}>
      <Routes>
        <Route path="/coach/live/:id" element={<CoachLivePage />} />
      </Routes>
    </MemoryRouter>,
  )
}

beforeEach(() => vi.clearAllMocks())

describe('F2 1 Kopf folgt den Kindern', () => {
  it('Uhr bei Minute 2, zwei Kinder in der Kernarbeit: Raster der Kernarbeit, daneben die Restzeit', () => {
    live.raum = raum(['kern', 'kern'])
    zeige()
    expect(screen.getByRole('heading', { level: 2, name: /Kernarbeit/ })).toBeTruthy()
    expect(screen.getByText('noch 58 Min')).toBeTruthy()
  })
})

describe('F2 2 Check-in-Aufgaben des Coaches', () => {
  it('sichtbar ueber dem Raster, solange ein Kind im Check-in ist', () => {
    live.raum = raum(['kern', 'kern', 'checkin'])
    zeige()
    expect(screen.getByText('Noch im Check-in')).toBeTruthy()
    expect(screen.getByText('Test Kind3')).toBeTruthy()
    expect(screen.queryByText('Test Kind1')).toBeNull()
  })

  it('weg, sobald kein Kind mehr im Check-in ist', () => {
    live.raum = raum(['kern', 'warmup'])
    zeige()
    expect(screen.queryByText('Noch im Check-in')).toBeNull()
    expect(screen.queryByText('Ankommen')).toBeNull()
  })
})

describe('F2 3 Hinweis „kein Testlauf“', () => {
  const wartet = { schritt: { ...emir.schritt!, art: 'warten' as const, grund_code: 'pool_leer', task_id: null }, aufgabe: null }
  const text = 'Diese Session ist kein Testlauf. Testkonten bekommen hier nur freigegebene Aufgaben.'

  it('kein Testlauf, nur Testkonten, ein Kind wartet: Hinweis', async () => {
    live.raum = raum(['kern'], { testlauf: false }, wartet)
    zeige()
    expect(await screen.findByText(text)).toBeTruthy()
    expect(live.testkontenLaden).toHaveBeenCalledWith(['kind-1'])
  })

  it('im Testlauf: kein Hinweis, nichts geladen', async () => {
    live.raum = raum(['kern'], { testlauf: true }, wartet)
    zeige()
    await waitFor(() => expect(screen.getByText('noch 58 Min')).toBeTruthy())
    expect(screen.queryByText(text)).toBeNull()
    expect(live.testkontenLaden).not.toHaveBeenCalled()
  })

  it('ein Echtkind dabei: kein Hinweis', async () => {
    live.testkontenLaden.mockImplementationOnce(() => Promise.resolve(new Map([['kind-1', false]])))
    live.raum = raum(['kern'], { testlauf: false }, wartet)
    zeige()
    await waitFor(() => expect(live.testkontenLaden).toHaveBeenCalled())
    expect(screen.queryByText(text)).toBeNull()
  })
})
