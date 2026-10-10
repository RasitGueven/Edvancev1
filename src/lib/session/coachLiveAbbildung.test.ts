// C2 Tests 5 bis 7: Abbildung echter Antworten auf das Ansichtsmodell, Fehlerabbildung, Detail nur
// fuer die offene Schublade, Prueffrage-Zustand. Die Fixtures sind echte Antworten der Coach-Funktionen
// aus einer Wegwerf-DB (docs/session/c2-coach-beispiele.sql → coachLiveFixtures.json).

import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { BriefingKind, KindDetail, LernpfadEintrag, RaumLive, SatzVorschlag, SkillPruefung, ZielFertigkeit } from '@/types'
import fixtures from './coachLiveFixtures.json'

const rpc = vi.hoisted(() => ({
  raumLive: vi.fn(),
  kindDetail: vi.fn(),
  sessionBriefing: vi.fn(),
  satzVorschlaege: vi.fn(),
  zielFertigkeiten: vi.fn(),
  skillPruefungen: vi.fn(),
  listLernpfad: vi.fn(),
  listThemen: vi.fn(),
  pruefungAufsTablet: vi.fn(),
  pruefungVomTablet: vi.fn(),
  tabletZuweisen: vi.fn(),
  masteryEntscheiden: vi.fn(),
}))
vi.mock('@/lib/supabase/sessionCoach', () => ({ raumLive: rpc.raumLive, kindDetail: rpc.kindDetail, tabletZuweisen: rpc.tabletZuweisen }))
vi.mock('@/lib/supabase/sessionC2', () => ({ sessionBriefing: rpc.sessionBriefing, satzVorschlaege: rpc.satzVorschlaege }))
vi.mock('@/lib/supabase/lernpfad', () => ({
  zielFertigkeiten: rpc.zielFertigkeiten, skillPruefungen: rpc.skillPruefungen, listLernpfad: rpc.listLernpfad,
  masteryEntscheiden: rpc.masteryEntscheiden,
}))
vi.mock('@/lib/supabase/themen', () => ({ listThemen: rpc.listThemen }))
vi.mock('@/lib/supabase/sessionPruefung', () => ({ pruefungAufsTablet: rpc.pruefungAufsTablet, pruefungVomTablet: rpc.pruefungVomTablet }))

const { ladeRaumLive, liveZuruecksetzen, masteryEntscheiden, pruefungAufsTablet, tabletZuweisen } = await import('./coachLive')
const { raumAus } = await import('./coachLiveAbbildung')
const { fehlerCode } = await import('./coachLiveFehler')

const F = fixtures as unknown as {
  raum_vorher: RaumLive; raum_kern: RaumLive; raum_gemeistert: RaumLive; raum_checkout: RaumLive; raum_testlauf: RaumLive
  detail_kern: KindDetail; ziel_kern: ZielFertigkeit[]; pruefung_v2: SkillPruefung[]; lernpfad_v2: LernpfadEintrag
  briefing: BriefingKind[]; satz: SatzVorschlag[]
  fehler_fremder_coach: { code: string; hint: string | null }; fehler_nicht_gebucht: { code: string; hint: string | null }
}
const EMIR = F.raum_kern.kinder[0].student_id
const DENIZ = F.raum_kern.kinder[1].student_id
const leer = { detail: null, briefing: [], satz: {}, themen: new Map<string, string>(), nichtErschienen: new Set<string>(), pfadGeoeffnet: {} }
const ok = <T>(data: T) => Promise.resolve({ data, error: null })

beforeEach(() => {
  liveZuruecksetzen()
  Object.values(rpc).forEach((f) => f.mockReset())
  rpc.raumLive.mockImplementation(() => ok(F.raum_kern))
  rpc.kindDetail.mockImplementation(() => ok(F.detail_kern))
  rpc.sessionBriefing.mockImplementation(() => ok(F.briefing))
  rpc.satzVorschlaege.mockImplementation(() => ok(F.satz))
  rpc.zielFertigkeiten.mockImplementation(() => ok(F.ziel_kern))
  rpc.skillPruefungen.mockImplementation(() => ok(F.pruefung_v2))
  rpc.listLernpfad.mockImplementation(() => ok([F.lernpfad_v2]))
  rpc.listThemen.mockImplementation(() => ok([{ thema_key: 'zz_a2_terme', label: 'ZZ Terme' }]))
})

describe('5 Abbildung je Feld aus echten Antworten', () => {
  it('Session-Kopf: Zeitpunkt nach der Uhr, Raum, Coach, Klassen, Testlauf, Snapshot', () => {
    const r = raumAus(F.raum_kern, leer)
    expect(r.zeitpunkt).toBe('kern')
    expect(r.session).toMatchObject({ raum: 'Raum 1', coachName: 'A2 Coach A', klassen: [8, 8], plaetze: 5, testlauf: false, status: 'active' })
    expect(r.zeitleiste.map((z) => z.minuten)).toEqual([5, 10, 40, 5])
    expect(raumAus(F.raum_vorher, leer).zeitpunkt).toBe('vorher')
    expect(raumAus(F.raum_checkout, leer).zeitpunkt).toBe('checkout')
    expect(raumAus(F.raum_testlauf, leer).session.testlauf).toBe(true)
  })

  it('Kachel: Tablet, Phase, Status, Taetigkeit, Skill, Punkte, Signale, Eingriffe', () => {
    const [emir, deniz] = raumAus(F.raum_kern, leer).kinder
    expect(emir).toMatchObject({ name: 'Emir Beispiel', vorname: 'Emir', klasse: 8, stufe: 'erste', tablet: 1, phase: 'kern', status: 'kandidat' })
    expect(emir.taetigkeit).toEqual({ art: 'ueben' })
    expect(emir.skill).toBe('ZZ Klammern ausmultiplizieren')
    expect(emir.ergebnisfolge.at(-1)).toBe('aktuell')
    expect(emir.ergebnisfolge).toContain('hinweis')
    expect(emir.signale[0]).toMatchObject({ art: 'kandidat', grund: 'kandidat', skill: 'ZZ Proportionale Zuordnung' })
    expect(emir.eingreifen.eingriffe.map((e) => e.stufe)).toEqual([3])
    expect(emir.meta).toEqual({ art: 'hinweise', anzahl: 1 })
    expect(emir.ziel).toMatchObject({ fallVorschlag: 'schulthema', fallCoach: 'schulthema', themaKey: 'zz_a2_terme', themaLabel: 'ZZ Terme' })
    expect(deniz).toMatchObject({ tablet: null, status: 'laeuft', nichtErschienen: false })
  })

  it('ohne Schublade kein Detail: keine Musterloesung, keine Versuche, kein Ziel', () => {
    const emir = raumAus(F.raum_kern, leer).kinder[0]
    expect(emir.aufgabe).toBeNull()
    expect(emir.versuche).toEqual([])
    expect(emir.zielFertigkeiten).toEqual([])
  })

  it('Schublade: Aufgabe mit Musterloesung, Versuche mit Fehlbild, Ziel, Mastery-Kandidat mit Pruefgespraech', () => {
    const detail = { kindId: EMIR, detail: F.detail_kern, ziel: F.ziel_kern, pruefung: F.pruefung_v2[0], lernpfad: F.lernpfad_v2 }
    const emir = raumAus(F.raum_kern, { ...leer, detail }).kinder[0]
    expect(emir.aufgabe).toMatchObject({ kopf: { art: 'aufgabe', nr: 3 }, musterloesung: ['ZZ-LOESUNGSWEG: 3 + 4 = 7'] })
    expect(emir.aufgabe?.text).toContain('Wie viel ist 3 + 4?')
    // F1 (A3): Der falsche Versuch gehoert zu einer frueheren Aufgabe; die Schublade zeigt nur die aktuelle.
    expect(emir.versuche).toEqual([])
    expect(emir.eingreifen.fehlbild).toEqual({ slug: 'zz_a2_vz', klartext: 'Nur das erste Vorzeichen geändert' })
    expect(emir.zielFertigkeiten.map((z) => z.skillKey)).toEqual(['zz_a2_v1', 'zz_a2_v2', 'zz_a2_s1', 'zz_a2_s2'])
    expect(emir.zielFertigkeiten[1].notizen).toContainEqual({ art: 'pruefungFaellig' })
    expect(emir.masteryKandidat).toMatchObject({
      skillKey: 'zz_a2_v2', label: 'ZZ Proportionale Zuordnung', erwartung: 'Erst der Preis für ein Heft, dann mal 7.', entscheidung: null,
    })
  })

  it('nach „gemeistert“: Kachel gruen, Entscheidung mit Coach, Pruefrage nicht mehr auf dem Tablet', () => {
    const emir = raumAus(F.raum_gemeistert, leer).kinder[0]
    expect(emir.status).toBe('gemeistert')
    expect(emir.masteryKandidat?.entscheidung).toMatchObject({ art: 'gemeistert', von: 'A2 Coach A' })
    expect(emir.pruefungAufTablet).toBe(false)
    expect(raumAus(F.raum_gemeistert, leer).masteryEntschieden).toBe(1)
  })

  it('Check-out: Satz, gesagt, Notiz, Flags, Quest B, Vorschlaege', () => {
    const emir = raumAus(F.raum_checkout, { ...leer, satz: { [EMIR]: F.satz } }).kinder[0]
    expect(emir.checkout).toMatchObject({
      satz: 'Du hast heute konzentriert gearbeitet.', gesagt: true, notiz: 'Kam gut voran', flags: { eltern: false, pfad: true },
      questsAktiv: true, questB: { termin: F.raum_checkout.kinder[0].quest_b },
    })
    expect(emir.checkout.satzVorschlaege).toEqual(F.satz.map((v) => v.text))
    expect(emir.checkout.satzVorschlaege).toHaveLength(2)
  })

  it('Briefing und „Heute im Blick“ aus session_briefing', () => {
    const r = raumAus(F.raum_vorher, { ...leer, briefing: F.briefing })
    const emir = r.kinder.find((k) => k.id === EMIR)
    const deniz = r.kinder.find((k) => k.id === DENIZ)
    expect(emir?.briefing.tags).toContainEqual({ art: 'mastery' })
    expect(emir?.briefing.thema).toMatchObject({ label: 'ZZ Terme', quelle: 'schulthema' })
    expect(deniz?.briefing.tags).toContainEqual({ art: 'themaAlt', wochen: 4 })
    expect(r.imBlick).toContainEqual(expect.objectContaining({ art: 'mastery', kindId: EMIR, detail: 'ZZ Proportionale Zuordnung' }))
  })
})

describe('6 Fehlerabbildung und Detail nur fuer die offene Schublade', () => {
  it('SQLSTATE und Hinweis auf Fehler-Codes, Unbekanntes allgemein', () => {
    expect(fehlerCode(F.fehler_fremder_coach)).toBe('keinRecht')
    expect(fehlerCode(F.fehler_nicht_gebucht)).toBe('nichtGebucht')
    expect(fehlerCode({ code: 'P0001', hint: 'tablet_belegt' })).toBe('tabletBelegt')
    expect(fehlerCode({ code: '22023', hint: 'gesundheitsbegriff:krank' })).toBe('gesundheitsbegriff')
    expect(fehlerCode({ code: '22023', hint: null }, { '22023': 'grundPflicht' })).toBe('grundPflicht')
    expect(fehlerCode({ code: 'XX000', hint: null })).toBe('allgemein')
    expect(fehlerCode({})).toBe('allgemein')
  })

  it('Lesefehler liefert einen Code, nie den Rohtext', async () => {
    rpc.raumLive.mockResolvedValue({ data: null, error: 'coach_raum_live: nur der Coach der Session', code: '42501', hint: null })
    expect(await ladeRaumLive('s1')).toEqual({ data: null, error: 'keinRecht' })
  })

  it('Aktion: Fehler-Code statt Meldung', async () => {
    rpc.tabletZuweisen.mockResolvedValue({ data: null, error: 'tablet_zuweisen: Tablet 1 ist belegt', code: 'P0001', hint: 'tablet_belegt' })
    expect(await tabletZuweisen('s1', DENIZ, 1)).toEqual({ data: null, error: 'tabletBelegt' })
    expect((await masteryEntscheiden({ sessionId: 's1', studentId: EMIR, skillKey: 'zz_a2_v2', entscheidung: 'vertagt', grund: ' ' })).error).toBe('grundPflicht')
    expect(rpc.masteryEntscheiden).not.toHaveBeenCalled()
  })

  it('ohne offene Schublade kein coach_kind_detail; mit offener nur fuer dieses Kind', async () => {
    await ladeRaumLive('s1')
    expect(rpc.raumLive).toHaveBeenCalledTimes(1)
    expect(rpc.kindDetail).not.toHaveBeenCalled()
    const res = await ladeRaumLive('s1', EMIR)
    expect(rpc.kindDetail).toHaveBeenCalledTimes(1)
    expect(rpc.kindDetail).toHaveBeenCalledWith('s1', EMIR)
    expect(rpc.skillPruefungen).toHaveBeenCalledWith('zz_a2_v2')
    expect(res.data?.kinder.find((k) => k.id === EMIR)?.aufgabe).not.toBeNull()
    expect(res.data?.kinder.find((k) => k.id === DENIZ)?.aufgabe).toBeNull()
  })

  it('Briefing einmal (Zwischenspeicher), Satzvorschlaege nur im Check-out', async () => {
    await ladeRaumLive('s1')
    await ladeRaumLive('s1')
    expect(rpc.sessionBriefing).toHaveBeenCalledTimes(1)
    expect(rpc.satzVorschlaege).not.toHaveBeenCalled()
    rpc.raumLive.mockImplementation(() => ok(F.raum_checkout))
    await ladeRaumLive('s1')
    expect(rpc.satzVorschlaege).toHaveBeenCalledWith('s1', EMIR)
    expect(rpc.satzVorschlaege).toHaveBeenCalledTimes(1)
  })
})

describe('7 Pruefrage-Knopf: Zustand aus coach_raum_live', () => {
  it('liegt auf dem Tablet, solange pruefung_auf_tablet gesetzt ist', () => {
    const emir = raumAus(F.raum_kern, leer).kinder[0]
    expect(emir.pruefungAufTablet).toBe(true)
    expect(raumAus(F.raum_kern, leer).kinder[1].pruefungAufTablet).toBe(false)
  })

  it('ruft pruefung_aufs_tablet mit dem Skill des Kandidaten', async () => {
    rpc.pruefungAufsTablet.mockResolvedValue({ data: { skill_key: 'zz_a2_v2', aktiv: true }, error: null })
    expect(await pruefungAufsTablet('s1', EMIR, 'zz_a2_v2')).toEqual({ data: null, error: null })
    expect(rpc.pruefungAufsTablet).toHaveBeenCalledWith('s1', EMIR, 'zz_a2_v2')
  })
})
