// T5 Test 8: Die Live-Sicht liest die Pruefrage ueber skill_pruefung_session, sobald sie eine Session kennt. Im
// Testlauf traegt eine nicht freigegebene Frage das Kennzeichen „Entwurf“; echt nie. Fehlerabbildung unveraendert.
// Grundlage sind die echten Antworten aus coachLiveFixtures.json (Emir: Mastery-Kandidat zz_a2_v2).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { KindDetail, RaumLive, SkillPruefung } from '@/types'
import fixtures from './coachLiveFixtures.json'

const rpc = vi.hoisted(() => ({
  raumLive: vi.fn(),
  kindDetail: vi.fn(),
  sessionBriefing: vi.fn(),
  satzVorschlaege: vi.fn(),
  zielFertigkeiten: vi.fn(),
  skillPruefungen: vi.fn(),
  skillPruefungSession: vi.fn(),
  listLernpfad: vi.fn(),
  listThemen: vi.fn(),
}))
vi.mock('@/lib/supabase/sessionCoach', () => ({ raumLive: rpc.raumLive, kindDetail: rpc.kindDetail }))
vi.mock('@/lib/supabase/sessionC2', () => ({ sessionBriefing: rpc.sessionBriefing, satzVorschlaege: rpc.satzVorschlaege }))
vi.mock('@/lib/supabase/lernpfad', () => ({
  zielFertigkeiten: rpc.zielFertigkeiten, skillPruefungen: rpc.skillPruefungen, listLernpfad: rpc.listLernpfad,
  masteryEntscheiden: vi.fn(),
}))
vi.mock('@/lib/supabase/themen', () => ({ listThemen: rpc.listThemen }))
vi.mock('@/lib/supabase/testmodus', () => ({ getStudentIstTest: vi.fn() }))
vi.mock('@/lib/supabase/sessionPruefung', () => ({
  pruefungAufsTablet: vi.fn(), pruefungVomTablet: vi.fn(), skillPruefungSession: rpc.skillPruefungSession,
}))

const { ladeRaumLive, liveZuruecksetzen } = await import('./coachLive')

const F = fixtures as unknown as { raum_kern: RaumLive; detail_kern: KindDetail; pruefung_v2: SkillPruefung[] }
const EMIR = F.raum_kern.kinder[0].student_id
const FREI = F.pruefung_v2[0]
const ENTWURF: SkillPruefung = { ...FREI, id: 'zz-t5-entwurf', frage: 'ZZ T5 Entwurfsfrage', erwartung: 'ZZ Erwartung', kriterium: 'ZZ Kriterium' }
const testlauf: RaumLive = { ...F.raum_kern, session: { ...F.raum_kern.session, testlauf: true } }
const ok = <T>(data: T) => Promise.resolve({ data, error: null })

async function kandidat(sessionId = 's1') {
  const res = await ladeRaumLive(sessionId, EMIR)
  return res.data?.kinder.find((k) => k.id === EMIR)?.masteryKandidat
}

beforeEach(() => {
  liveZuruecksetzen()
  Object.values(rpc).forEach((f) => f.mockReset())
  rpc.raumLive.mockImplementation(() => ok(F.raum_kern))
  rpc.kindDetail.mockImplementation(() => ok(F.detail_kern))
  rpc.sessionBriefing.mockImplementation(() => ok([]))
  rpc.satzVorschlaege.mockImplementation(() => ok([]))
  rpc.zielFertigkeiten.mockImplementation(() => ok([]))
  rpc.listLernpfad.mockImplementation(() => ok([]))
  rpc.listThemen.mockImplementation(() => ok([]))
  rpc.skillPruefungen.mockImplementation(() => ok([FREI]))
  rpc.skillPruefungSession.mockImplementation(() => ok([FREI]))
})

describe('T5: Pruefrage der Live-Sicht', () => {
  it('echte Session: skill_pruefung_session mit der Session, ohne Kennzeichen, kein zweiter Aufruf', async () => {
    const m = await kandidat()
    expect(rpc.skillPruefungSession).toHaveBeenCalledWith('s1', 'zz_a2_v2')
    expect(rpc.skillPruefungen).not.toHaveBeenCalled()
    expect(m).toMatchObject({ frage: FREI.frage, erwartung: FREI.erwartung, kriterium: FREI.kriterium, entwurf: false })
  })

  it('Testlauf: Entwurfsfrage mit Erwartung, Kriterium und Kennzeichen', async () => {
    rpc.raumLive.mockImplementation(() => ok(testlauf))
    rpc.skillPruefungSession.mockImplementation(() => ok([ENTWURF, FREI]))
    rpc.skillPruefungen.mockImplementation(() => ok([]))
    const m = await kandidat()
    expect(rpc.skillPruefungen).toHaveBeenCalledWith('zz_a2_v2')
    expect(m).toMatchObject({ frage: 'ZZ T5 Entwurfsfrage', erwartung: 'ZZ Erwartung', kriterium: 'ZZ Kriterium', entwurf: true })
  })

  it('Testlauf: freigegebene Frage ohne Kennzeichen', async () => {
    rpc.raumLive.mockImplementation(() => ok(testlauf))
    rpc.skillPruefungSession.mockImplementation(() => ok([FREI, ENTWURF]))
    expect(await kandidat()).toMatchObject({ frage: FREI.frage, entwurf: false })
  })

  it('Testlauf: scheitert der Abgleich, bleibt das Kennzeichen weg', async () => {
    rpc.raumLive.mockImplementation(() => ok(testlauf))
    rpc.skillPruefungSession.mockImplementation(() => ok([ENTWURF]))
    rpc.skillPruefungen.mockResolvedValue({ data: null, error: 'skill_pruefung_lesen: kaputt', code: 'XX000' })
    expect(await kandidat()).toMatchObject({ frage: 'ZZ T5 Entwurfsfrage', entwurf: false })
  })

  it('Fehler der Pruefrage: Kandidat ohne Frage, die Sicht laedt weiter (wie bisher)', async () => {
    rpc.skillPruefungSession.mockResolvedValue({ data: null, error: 'skill_pruefung_session: nur der Coach der Session oder ein Admin', code: '42501' })
    const res = await ladeRaumLive('s1', EMIR)
    expect(res.error).toBeNull()
    expect(res.data?.kinder.find((k) => k.id === EMIR)?.masteryKandidat).toMatchObject({ frage: '', erwartung: '', kriterium: '', entwurf: false })
  })

  it('Lesefehler des Raums bleibt ein Code (Fehlerabbildung unveraendert)', async () => {
    rpc.raumLive.mockResolvedValue({ data: null, error: 'coach_raum_live: nur der Coach der Session', code: '42501', hint: null })
    expect(await ladeRaumLive('s1', EMIR)).toEqual({ data: null, error: 'keinRecht' })
    expect(rpc.skillPruefungSession).not.toHaveBeenCalled()
  })
})
