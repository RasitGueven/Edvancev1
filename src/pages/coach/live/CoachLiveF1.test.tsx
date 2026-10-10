// F1 Tests 1-3 (Oberflaeche, Trockenlauf 08.10.): Thema waehlen ohne Schulthema (A1), Grund beim Warten (A1),
// Phase des Kindes in Kopf und Kachel (A4), „heute“ je Skill und „heute sicher“ im Ziel (A6).
// Grundlage: echte Antworten aus coachLiveFixturesC3.json, ergaenzt um die F1-Felder.

import { beforeEach, describe, expect, it, vi } from 'vitest'
import { fireEvent, render, screen } from '@testing-library/react'
import '@/i18n'

const live = vi.hoisted(() => ({
  checkinCoachSetzen: vi.fn(() => Promise.resolve({ data: null, error: null })),
  themenKatalog: vi.fn(() =>
    Promise.resolve({
      data: [{ thema_key: 'quadratische_funktionen', label: 'Quadratische Funktionen', fach: 'mathematik', klasse: 9, stufe: 'erste', sort: 1 }],
      error: null,
    }),
  ),
}))
vi.mock('@/lib/session/coachLive', () => ({
  ...live, eingriffNotieren: vi.fn(), pfadEntscheiden: vi.fn(), signalErledigen: vi.fn(), tabletLoesen: vi.fn(), tabletZuweisen: vi.fn(),
}))
vi.mock('@/lib/supabase/sessionPruefung', () => ({ pruefungAufsTablet: vi.fn(), pruefungVomTablet: vi.fn() }))

import { raumAus } from '@/lib/session/coachLiveAbbildung'
import fixtures from '@/lib/session/coachLiveFixturesC3.json'
import type { CoachLiveRaum } from '@/types/coachLive'
import type { ZielFertigkeit } from '@/types/lernpfad'
import type { KindRaum } from '@/types/sessionC2'
import type { KindDetail, RaumLive } from '@/types/sessionLive'
import type { Thema } from '@/types/themen'
import { CheckinZeile } from './CheckinZeile'
import { LiveKontext } from './LiveKontext'
import { LiveKopf } from './LiveKopf'
import { LiveRaster } from './LiveRaster'
import { Schublade } from './Schublade'

const F = fixtures as unknown as Record<string, RaumLive | KindDetail>
const basis = F.raum_kern as RaumLive
const emir = basis.kinder[0]

function raumMit(kind: Partial<KindRaum>, detail?: Partial<KindDetail>, ziel: ZielFertigkeit[] = []): CoachLiveRaum {
  const r: RaumLive = { ...basis, kinder: [{ ...emir, ...kind } as KindRaum] }
  return raumAus(r, {
    detail: detail ? { kindId: emir.student_id, detail: { ...(F.detail_kern_Emir as KindDetail), ...detail }, ziel, pruefung: null, lernpfad: null } : null,
    briefing: [], satz: {}, themen: new Map(), nichtErschienen: new Set(), pfadGeoeffnet: {},
  })
}

function zeige(raum: CoachLiveRaum, inhalt: JSX.Element, ausfuehren = vi.fn((p: Promise<unknown>) => p.then(() => true))): void {
  render(
    <LiveKontext.Provider
      value={{ sessionId: raum.session.id, raum, ausfuehren, oeffneKind: vi.fn(), zeigeZeitpunkt: vi.fn(), kind: () => raum.kinder[0] }}
    >
      {inhalt}
    </LiveKontext.Provider>,
  )
}

const ziel = (key: string, label: string, n: number): ZielFertigkeit => ({
  reihenfolge: n, skill_key: key, label, klasse_herkunft: 9, rolle: 'einstieg', stand_system: null, stand_coach: null, stand: 'offen', pruefung_faellig: false,
})

beforeEach(() => vi.clearAllMocks())

describe('F1 A1 Thema waehlen', () => {
  it('ohne Schulthema: „Thema wählen“ öffnet die Suche, Auswahl setzt Fall Schulthema und Thema', async () => {
    const raum = raumMit({ phase: 'checkin', schulthema_key: null, ziel_thema_key: null, ziel_thema_label: null, thema_antwort: 'noch_dran', checkin_fertig: true })
    const katalog = [{ thema_key: 'quadratische_funktionen', label: 'Quadratische Funktionen', fach: 'mathematik', klasse: 9, stufe: 'erste', sort: 1 }] as unknown as Thema[]
    zeige(raum, <CheckinZeile kind={raum.kinder[0]} katalog={katalog} />)
    fireEvent.click(screen.getByRole('button', { name: 'Thema wählen' }))
    fireEvent.change(screen.getByRole('textbox'), { target: { value: 'quadr' } })
    fireEvent.click(await screen.findByText('Quadratische Funktionen'))
    expect(live.checkinCoachSetzen).toHaveBeenCalledWith(raum.session.id, emir.student_id, 'schulthema', 'quadratische_funktionen')
  })

  it('Kind wartet mit kein_ziel: Grund in Klartext und gleich die Themensuche, Hinweis „ab der nächsten Aufgabe“', async () => {
    const schritt = { ...emir.schritt!, art: 'warten' as const, grund_code: 'kein_ziel', task_id: null }
    const raum = raumMit({ schritt, aufgabe: null }, {})
    zeige(raum, <Schublade kind={raum.kinder[0]} onSchliessen={vi.fn()} />)
    expect(screen.getByTestId('wartet-grund').textContent).toMatch(/wartet: Es gibt kein Thema und keine Lücke im Lernpfad/)
    expect(await screen.findByText(/gilt ab der nächsten Aufgabe/)).toBeTruthy()
  })

  it('pool_leer hat einen eigenen Satz', () => {
    const schritt = { ...emir.schritt!, art: 'warten' as const, grund_code: 'pool_leer', task_id: null }
    const raum = raumMit({ schritt, aufgabe: null }, {})
    zeige(raum, <Schublade kind={raum.kinder[0]} onSchliessen={vi.fn()} />)
    expect(screen.getByTestId('wartet-grund').textContent).toMatch(/keine passende Aufgabe mehr/)
  })
})

describe('F1 A4 Phase des Kindes', () => {
  it('Kachel: Kernarbeit seit … ohne Warm-up mit Grund', () => {
    const raum = raumMit({ phase: 'kern', phase_seit: '2026-10-08T10:18:30+02:00', warmup_entfallen: 'kein_stoff' })
    zeige(raum, <LiveRaster gewaehlt={null} />)
    expect(screen.getByTestId('kachel-phase').textContent).toBe(
      'Kernarbeit seit 10:18 · ohne Warm-up: kein Warm-up-Stoff (kein sicherer Skill und keine Voraussetzung mit Aufgaben)',
    )
  })

  it('Kopf: Phasen der Kinder neben der Uhr, antippbar', () => {
    const raum = { ...raumMit({ phase: 'kern' }), zeitpunkt: 'checkin' as const }
    const onZeige = vi.fn()
    render(<LiveKopf raum={raum} eigeneAnsicht={false} onZeige={onZeige} onZurueck={vi.fn()} />)
    fireEvent.click(screen.getByRole('button', { name: 'Kernarbeit: 1' }))
    expect(onZeige).toHaveBeenCalledWith('kern')
  })

  it('mit Warm-up nichts Zusätzliches', () => {
    const raum = raumMit({ phase: 'warmup', phase_seit: '2026-10-08T10:18:30+02:00', warmup_entfallen: null })
    zeige(raum, <LiveRaster gewaehlt={null} />)
    expect(screen.getByTestId('kachel-phase').textContent).toBe('Warm-up seit 10:18')
  })
})

describe('F1 A6 Ziel der Stunde je Skill', () => {
  it('„heute n von m“ je Skill, „heute sicher“ wie die Engine', () => {
    const heute = [
      { abschnitt: 'kern' as const, skill_key: 'fkt_linear_steigung', label: 'Steigung', richtig: 2, von: 3, hinweise: 0 },
      { abschnitt: 'kern' as const, skill_key: 'fkt_linear_yabschnitt', label: 'y-Achsenabschnitt', richtig: 1, von: 1, hinweise: 0 },
    ]
    const raum = raumMit({}, { heute, heute_sicher: ['fkt_linear_steigung'] }, [
      ziel('fkt_linear_steigung', 'Steigung', 1), ziel('fkt_linear_yabschnitt', 'y-Achsenabschnitt', 2), ziel('fkt_linear_gleichung', 'Funktionsgleichung', 3),
    ])
    const [st, ya, gl] = raum.kinder[0].zielFertigkeiten
    expect(st.notizen).toEqual([{ art: 'heute', richtig: 2, von: 3 }, { art: 'heuteSicher' }])
    expect(ya.notizen).toEqual([{ art: 'heute', richtig: 1, von: 1 }])
    expect(gl.notizen).toEqual([])
  })
})
