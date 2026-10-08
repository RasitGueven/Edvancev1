// C3 Test 5 (Oberflaeche): Pfad-Vorschlag, Heute und Grund aus echten Antworten (coachLiveFixturesC3.json).
// Fehlt ein Feld (Signal vor A2d, kein Fehlbild, kein Thema), laesst die Schublade die Zeile weg.

import { describe, expect, it, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'

vi.mock('@/lib/session/coachLive', () => ({ eingriffNotieren: vi.fn(), pfadEntscheiden: vi.fn(), signalErledigen: vi.fn() }))
vi.mock('@/lib/supabase/sessionPruefung', () => ({ pruefungAufsTablet: vi.fn(), pruefungVomTablet: vi.fn() }))

import { raumAus } from '@/lib/session/coachLiveAbbildung'
import fixtures from '@/lib/session/coachLiveFixturesC3.json'
import type { CoachLiveKind, CoachLiveRaum, PfadVorschlag } from '@/types/coachLive'
import type { KindDetail, RaumLive } from '@/types/sessionLive'
import { PfadEntscheidung } from './Eingreifen'
import { LiveKontext } from './LiveKontext'
import { Schublade } from './Schublade'

const F = fixtures as unknown as Record<string, RaumLive | KindDetail>

function szene(name: string, vorname: string): { raum: CoachLiveRaum; kind: CoachLiveKind } {
  const r = F[`raum_${name}`] as RaumLive
  const kindId = r.kinder.find((k) => k.name?.startsWith(vorname))?.student_id ?? ''
  const raum = raumAus(r, {
    detail: { kindId, detail: F[`detail_${name}_${vorname}`] as KindDetail, ziel: [], pruefung: null, lernpfad: null },
    briefing: [], satz: {}, themen: new Map(), nichtErschienen: new Set(), pfadGeoeffnet: {},
  })
  const kind = raum.kinder.find((k) => k.id === kindId)
  if (!kind) throw new Error(`kind ${vorname} fehlt`)
  return { raum, kind }
}

function zeige(raum: CoachLiveRaum, inhalt: JSX.Element): void {
  render(
    <LiveKontext.Provider
      value={{
        sessionId: raum.session.id, raum, ausfuehren: vi.fn(() => Promise.resolve(true)),
        oeffneKind: vi.fn(), zeigeZeitpunkt: vi.fn(), kind: (id) => raum.kinder.find((k) => k.id === id) ?? raum.kinder[0],
      }}
    >
      {inhalt}
    </LiveKontext.Provider>,
  )
}

describe('C3 Pfad-Vorschlag in der Schublade', () => {
  it('zeigt Warm-up, Fehlbild mit Datum und Thema', () => {
    const { raum, kind } = szene('warmup', 'Emir')
    zeige(raum, <PfadEntscheidung kind={kind} p={kind.pfadVorschlag as PfadVorschlag} />)
    expect(screen.getByText(/Statt „Klammern ausmultiplizieren“ zuerst „Minus vor der Klammer“ aus Klasse 7/)).toBeTruthy()
    expect(screen.getByText('Warm-up: Minus vor der Klammer 1 von 3')).toBeTruthy()
    expect(screen.getByText(/^Gleiches Fehlbild wie am .*: Nur das erste Vorzeichen geändert$/)).toBeTruthy()
    expect(screen.getByText('Das Schulthema Terme und Gleichungen baut darauf auf')).toBeTruthy()
  })

  it('lässt fehlende Zeilen weg', () => {
    const { raum, kind } = szene('warmup', 'Emir')
    const p: PfadVorschlag = { ...(kind.pfadVorschlag as PfadVorschlag), warmupRichtig: null, warmupVon: null, fehlbild: null, fehlbildAm: null, themaLabel: null, klasseTiefer: null }
    zeige(raum, <PfadEntscheidung kind={kind} p={p} />)
    expect(screen.getByText(/Statt „Klammern ausmultiplizieren“ zuerst „Minus vor der Klammer“\.$/)).toBeTruthy()
    expect(screen.queryByText(/^Warm-up:/)).toBeNull()
    expect(screen.queryByText(/Fehlbild/)).toBeNull()
    expect(screen.queryByText(/baut darauf auf/)).toBeNull()
    expect(screen.queryByText(/Klasse/)).toBeNull()
  })

  it('Fehlbild ohne frühere Session: ohne Datum', () => {
    const { raum, kind } = szene('warmup', 'Emir')
    zeige(raum, <PfadEntscheidung kind={kind} p={{ ...(kind.pfadVorschlag as PfadVorschlag), fehlbildAm: null }} />)
    expect(screen.getByText('Fehlbild heute: Nur das erste Vorzeichen geändert')).toBeTruthy()
  })
})

describe('C3 Heute und Grund in der Schublade', () => {
  it('Lea: Grund mit Zahl und Heute-Zeilen', () => {
    const { raum, kind } = szene('grund', 'Lea')
    zeige(raum, <Schublade kind={kind} onSchliessen={vi.fn()} />)
    expect(screen.getByText(/^0 von 5 ohne Hinweis richtig, unter der Ziel-Erfolgsquote \(80\s?%\)/)).toBeTruthy()
    expect(screen.getByText('Klammern ausmultiplizieren · 0 von 5 · ohne Hinweis')).toBeTruthy()
  })

  it('Emir: eingemischt mit Anteil, Kernarbeit mit Hinweis', () => {
    const { raum, kind } = szene('kern', 'Emir')
    zeige(raum, <Schublade kind={kind} onSchliessen={vi.fn()} />)
    expect(screen.getByText(/^Ältere Aufgabe eingemischt \(Anteil 30\s?%\)/)).toBeTruthy()
    expect(screen.getByText('Klammern ausmultiplizieren · 1 von 3 · 1 Hinweis')).toBeTruthy()
    expect(screen.getByText(/^Proportionale Zuordnung · 1 von 1 · ohne Hinweis · Anteil 30\s?%$/)).toBeTruthy()
  })

  it('Jonas: Kernideen mit Titel und Fehlbild der letzten Runde', () => {
    const { raum, kind } = szene('kern', 'Jonas')
    zeige(raum, <Schublade kind={kind} onSchliessen={vi.fn()} />)
    expect(screen.getByText('y-Achsenabschnitt ablesen')).toBeTruthy()
    expect(screen.getByText(/Runde 1 falsch: Nur das erste Vorzeichen geändert\. Variante B gezeigt/)).toBeTruthy()
    expect(screen.getByText('Steigung · Kernidee 1 in Runde 2')).toBeTruthy()
  })
})
