// T5 Test 8 (Oberflaeche): Die Schublade zeigt bei einer Pruefrage im Entwurf das Kennzeichen „Entwurf“, sonst nicht.
// Erwartung und Kriterium stehen in beiden Faellen da. Grundlage: echte Antworten aus coachLiveFixtures.json.

import { afterEach, describe, expect, it, vi } from 'vitest'
import { cleanup, render, screen } from '@testing-library/react'
import '@/i18n'

vi.mock('@/lib/session/coachLive', () => ({ masteryEntscheiden: vi.fn(), pruefungAufsTablet: vi.fn(), pruefungVomTablet: vi.fn() }))

import { raumAus } from '@/lib/session/coachLiveAbbildung'
import fixtures from '@/lib/session/coachLiveFixtures.json'
import type { CoachLiveRaum } from '@/types/coachLive'
import type { KindDetail, LernpfadEintrag, RaumLive, SkillPruefung } from '@/types'
import { LiveKontext } from './LiveKontext'
import { MasteryPruefung } from './MasteryPruefung'

const F = fixtures as unknown as { raum_kern: RaumLive; detail_kern: KindDetail; pruefung_v2: SkillPruefung[]; lernpfad_v2: LernpfadEintrag }
const EMIR = F.raum_kern.kinder[0].student_id

function zeige(entwurf: boolean, testlauf: boolean): void {
  const r: RaumLive = { ...F.raum_kern, session: { ...F.raum_kern.session, testlauf } }
  const raum: CoachLiveRaum = raumAus(r, {
    detail: { kindId: EMIR, detail: F.detail_kern, ziel: [], pruefung: { ...F.pruefung_v2[0], entwurf }, lernpfad: F.lernpfad_v2 },
    briefing: [], satz: {}, themen: new Map(), nichtErschienen: new Set(), pfadGeoeffnet: {},
  })
  const kind = raum.kinder.find((k) => k.id === EMIR)
  if (!kind?.masteryKandidat) throw new Error('Emir ohne Mastery-Kandidat')
  render(
    <LiveKontext.Provider
      value={{
        sessionId: raum.session.id, raum, ausfuehren: vi.fn(() => Promise.resolve(true)),
        oeffneKind: vi.fn(), zeigeZeitpunkt: vi.fn(), kind: () => kind,
      }}
    >
      <MasteryPruefung kind={kind} m={kind.masteryKandidat} />
    </LiveKontext.Provider>,
  )
}

afterEach(cleanup)

describe('T5: Kennzeichen „Entwurf“ in der Schublade', () => {
  it('Testlauf, Entwurfsfrage: Kennzeichen, Erwartung und Kriterium', () => {
    zeige(true, true)
    expect(screen.getByText('Entwurf')).toBeTruthy()
    expect(screen.getByText(F.pruefung_v2[0].erwartung)).toBeTruthy()
    expect(screen.getByText(F.pruefung_v2[0].kriterium)).toBeTruthy()
  })

  it('freigegebene Frage: kein Kennzeichen', () => {
    zeige(false, true)
    expect(screen.queryByText('Entwurf')).toBeNull()
    expect(screen.getByText(F.pruefung_v2[0].erwartung)).toBeTruthy()
  })

  it('echte Session: kein Kennzeichen', () => {
    zeige(false, false)
    expect(screen.queryByText('Entwurf')).toBeNull()
  })
})
