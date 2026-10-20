// Slots W2: Farbe je Raum (Entscheidung 4), Kennzahlen mit Testkonten (Entscheidung 7), Panel in der URL,
// Umleitungen, Tagespanel und Einzel-Sessions je Berliner Tag. Erfundene Daten.

import { describe, expect, it } from 'vitest'
import type { SlotsWoche, TagRaumTermin, TagSessionOhneRaum, WocheZelle } from '@/types/slotplan'
import type { StundenplanSession } from '@/types/stundenplan'
import {
  einzelAmTag, freiePlaetze, isoWochentag, panelAusSuche, raumFarbe, slotZiel, sucheMitPanel, sucheOhneStundenplan, tagZeilen,
  wochenKennzahlen, zellRaeume,
} from './wochenplan.model'

describe('Farbe je Raum nach Belegung', () => {
  it.each([
    [0, true, 'leer'],
    [1, true, 'rot'],
    [2, true, 'rot'],
    [3, true, 'gelb'],
    [4, true, 'gruen'],
    [5, true, 'gruen'],
    [2, false, 'keinCoach'],
    [5, false, 'keinCoach'],
    [0, false, 'leer'],
  ] as const)('%i Kinder, Coach %s → %s', (belegt, coach, farbe) => {
    expect(raumFarbe(belegt, coach)).toBe(farbe)
  })
})

describe('Räume einer Zelle und freie Plätze', () => {
  const zelle: WocheZelle = {
    datum: '2026-11-02', zeit_id: 'z14', kapazitaet: 10, belegt: 6, ohne_raum: 0, coach_fehlt: 1, faecher: [], vergangen: false, laeuft: false,
    raeume: [
      { raum_id: 'a', name: 'A1', offen: true, art: 'stamm', coach_id: 'c1', coach_name: 'Sara', belegt: 4 },
      { raum_id: 'b', name: 'B1', offen: true, art: 'stamm', coach_id: 'c2', coach_name: 'Jonas', belegt: 0 },
      { raum_id: 'c', name: 'C1', offen: false, art: 'faellt_aus', coach_id: null, coach_name: null, belegt: 2 },
      { raum_id: 'd', name: 'D1', offen: false, art: 'faellt_aus', coach_id: null, coach_name: null, belegt: 0 },
    ],
  }
  it('Räume mit Coach oder Kindern; geschlossen und leer fällt weg', () => {
    expect(zellRaeume(zelle).map((r) => r.name)).toEqual(['A1', 'B1', 'C1'])
  })
  it('frei zählt nur Räume mit Coach', () => {
    expect(freiePlaetze(zellRaeume(zelle))).toBe(1 + 5)
  })
})

describe('Kennzahlen zählen Testkonten sichtbar mit', () => {
  const kopf: SlotsWoche['kopf'] = {
    plaetze: 110, belegt: 67, belegt_test: 6, auslastung: 67 / 110, auslastung_mit_test: 73 / 110, ohne_raum: 0, erster_ohne_raum: null,
    ohne_stammplatz: 2, ohne_stammplatz_test: 4, ohne_stammplatz_laufend: 2, raeume_ohne_coach: 1,
  }
  it('Belegt 73 = 67 Kinder + 6 Testkonten; Auslastung mit und ohne Testkonten', () => {
    const k = wochenKennzahlen(kopf)
    expect([k.belegt, k.echt, k.test]).toEqual([73, 67, 6])
    expect(k.auslastung).toBeCloseTo(0.6636, 3)
    expect(k.auslastungOhneTest).toBeCloseTo(0.6091, 3)
  })
  it('Ohne Stammplatz 2, dazu 4 Testkonten; handeln nur, wenn ein Vertrag schon läuft', () => {
    const k = wochenKennzahlen(kopf)
    expect([k.ohneStammplatz, k.ohneStammplatzTest, k.ohneStammplatzHandeln, k.raeumeOhneCoach]).toEqual([2, 4, true, 1])
    expect(wochenKennzahlen({ ...kopf, ohne_stammplatz_laufend: 0 }).ohneStammplatzHandeln).toBe(false)
  })
})

describe('Panel in der URL', () => {
  it('slot, tag und einzel hin und zurück; Woche und Reiter bleiben', () => {
    const s = new URLSearchParams('woche=2026-11-02')
    const slot = sucheMitPanel(s, { art: 'slot', datum: '2026-11-04', zeitId: 'abc-123' })
    expect(slot.toString()).toBe('woche=2026-11-02&slot=2026-11-04_abc-123')
    expect(panelAusSuche(slot)).toEqual({ art: 'slot', datum: '2026-11-04', zeitId: 'abc-123' })
    const tag = sucheMitPanel(slot, { art: 'tag', datum: '2026-11-03' })
    expect(tag.toString()).toBe('woche=2026-11-02&tag=2026-11-03')
    expect(panelAusSuche(tag)).toEqual({ art: 'tag', datum: '2026-11-03' })
    const einzel = sucheMitPanel(tag, { art: 'einzel', datum: '2026-11-03', sessionId: 's9' })
    expect(panelAusSuche(einzel)).toEqual({ art: 'einzel', datum: '2026-11-03', sessionId: 's9' })
    expect(sucheMitPanel(einzel, null).toString()).toBe('woche=2026-11-02')
  })
  it('Kaputte Werte öffnen kein Panel', () => {
    expect(panelAusSuche(new URLSearchParams('slot=gestern'))).toBeNull()
    expect(panelAusSuche(new URLSearchParams('tag=2026-11'))).toBeNull()
    expect(panelAusSuche(new URLSearchParams('slot=2026-11-04_'))).toBeNull()
  })
  it('alte Termin-Adresse und Reiter Stundenplan', () => {
    expect(slotZiel('2026-11-04', 'z15')).toBe('/admin/slots?slot=2026-11-04_z15')
    expect(sucheOhneStundenplan(new URLSearchParams('woche=2026-11-09&reiter=stundenplan')).toString()).toBe('woche=2026-11-09')
    expect(sucheOhneStundenplan(new URLSearchParams('reiter=kinder')).toString()).toBe('reiter=kinder')
  })
  it('ISO-Wochentag', () => {
    expect(isoWochentag('2026-11-02')).toBe(1)
    expect(isoWochentag('2026-11-06')).toBe(5)
    expect(isoWochentag('2026-11-08')).toBe(7)
  })
})

const session = (id: string, at: string): StundenplanSession => ({
  session_id: id, scheduled_at: at, room: 'B1', status: 'upcoming', testlauf: false, gestartet: false,
  coach_id: 'c1', coach_name: null, coach_rolle: 'coach', kinder: [],
})

describe('Einzel-Sessions je Berliner Tag (früher nachTag im Stundenplan)', () => {
  it('23:30 UTC gehört zum Folgetag; nach Beginn sortiert', () => {
    const liste = [session('b', '2027-11-04T15:00:00Z'), session('a', '2027-11-04T08:00:00Z'), session('c', '2027-11-04T23:30:00Z')]
    expect(einzelAmTag(liste, '2027-11-04').map((s) => s.session_id)).toEqual(['a', 'b'])
    expect(einzelAmTag(liste, '2027-11-05').map((s) => s.session_id)).toEqual(['c'])
  })
})

describe('Tagespanel', () => {
  const rt = (zeit_id: string, beginn: string, raum: string, belegt: number, offen = true): TagRaumTermin => ({
    zeit_id, beginn, ende: '', raum_id: raum, raum_name: raum, coach_id: offen ? 'c' : null, coach_name: offen ? 'Sara' : null,
    art: offen ? 'stamm' : 'faellt_aus', offen, kapazitaet: 5, belegt, session_id: null, gestartet: false, status: null,
  })
  const ohne = (id: string, at: string): TagSessionOhneRaum => ({
    session_id: id, scheduled_at: at, room: 'B1', status: 'upcoming', coach_id: 'c', coach_name: 'Rasit', testlauf: false, gestartet: false, kinder: 1,
  })
  it('je Uhrzeit Räume und freie Plätze, Einzel-Sessions an ihrer Uhrzeit', () => {
    const zeiten = [{ id: 'z15', beginn: '15:00', ende: '16:00' }, { id: 'z14', beginn: '14:00', ende: '15:00' }]
    const zeilen = tagZeilen(
      zeiten,
      [rt('z14', '14:00', 'B1', 2), rt('z14', '14:00', 'A1', 4), rt('z14', '14:00', 'C1', 0, false), rt('z15', '15:00', 'A1', 3, false)],
      // 09:30 und 14:30 Berlin (Winterzeit, UTC+1)
      [ohne('e2', '2026-11-04T13:30:00Z'), ohne('e1', '2026-11-04T08:30:00Z')],
    )
    expect(zeilen.map((z) => (z.art === 'slot' ? `${z.zeit.beginn}:${z.raeume.map((r) => r.raum_name).join('+')}:${z.frei}` : `einzel ${z.uhr}`)))
      .toEqual(['einzel 09:30', '14:00:A1+B1:4', 'einzel 14:30', '15:00:A1:0'])
  })
})
