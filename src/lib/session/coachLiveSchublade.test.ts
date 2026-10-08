// C3 Test 5 (Abbildung): Pfad-Vorschlag, Heute, Grund mit Zahl, Erklaersequenz und Warm-up-Beleg aus echten
// Antworten von coach_kind_detail (Wegwerf-DB, docs/session/c3-coach-beispiele.sql → coachLiveFixturesC3.json).
// Fehlende Felder bleiben null; was die Seite daraus macht, prueft SchubladeC3.test.tsx.

import { describe, expect, it } from 'vitest'
import type { CoachLiveKind } from '@/types/coachLive'
import type { KindDetail, RaumLive } from '@/types/sessionLive'
import { raumAus, type LiveZusatz } from './coachLiveAbbildung'
import { grundAus, heuteAus, pfadVorschlagAus } from './coachLiveSchublade'
import fixtures from './coachLiveFixturesC3.json'
import alteFixtures from './coachLiveFixtures.json'

const F = fixtures as unknown as Record<string, RaumLive | KindDetail>
const raum = (name: string): RaumLive => F[`raum_${name}`] as RaumLive
const detail = (name: string): KindDetail => F[`detail_${name}`] as KindDetail

function kindMit(szene: string, vorname: string, d: KindDetail = detail(`${szene}_${vorname}`), z: Partial<LiveZusatz> = {}): CoachLiveKind {
  const r = raum(szene)
  const kindId = r.kinder.find((k) => k.name?.startsWith(vorname))?.student_id ?? ''
  const zusatz: LiveZusatz = {
    detail: { kindId, detail: d, ziel: [], pruefung: null, lernpfad: null },
    briefing: [], satz: {}, themen: new Map(), nichtErschienen: new Set(), pfadGeoeffnet: {}, ...z,
  }
  const kind = raumAus(r, zusatz).kinder.find((k) => k.id === kindId)
  if (!kind) throw new Error(`kind ${vorname} fehlt`)
  return kind
}

describe('C3 Pfad-Vorschlag', () => {
  it('bildet das offene Signal mit allen Zahlen ab', () => {
    expect(kindMit('warmup', 'Emir').pfadVorschlag).toEqual({
      skillPlan: 'Klammern ausmultiplizieren',
      skillTiefer: 'Minus vor der Klammer',
      klasseTiefer: 7,
      warmupRichtig: 1,
      warmupVon: 3,
      fehlbild: 'Nur das erste Vorzeichen geändert',
      fehlbildAm: detail('warmup_Emir').pfad_vorschlag?.fehlbild_am,
      themaLabel: 'Terme und Gleichungen',
      entscheidung: null,
    })
  })

  it('verschwindet nach der Entscheidung und kommt beim Ändern wieder', () => {
    const k = kindMit('kern', 'Emir')
    expect(k.pfadVorschlag).toBeNull()
    expect(k.pfadEntscheidung?.art).toBe('plan')
    const zeit = raum('kern').kinder.find((x) => x.name?.startsWith('Emir'))?.pfad_entscheidung?.zeit ?? ''
    const wieder = kindMit('kern', 'Emir', undefined, { pfadGeoeffnet: { [k.id]: new Date(Date.parse(zeit) + 1000).toISOString() } })
    expect(wieder.pfadVorschlag?.skillTiefer).toBe('Minus vor der Klammer')
    expect(wieder.pfadVorschlag?.entscheidung).toBeNull()
  })

  it('Signal vor A2d: ohne Warm-up-Zahlen und ohne Fehlbild', () => {
    const p = pfadVorschlagAus(detail('alt_signal').pfad_vorschlag, null, undefined)
    expect(p).toMatchObject({ skillTiefer: 'Proportionale Zuordnung', warmupRichtig: null, warmupVon: null, fehlbild: null, fehlbildAm: null })
  })

  it('ohne Ziel-Skill oder ohne Feld kein Vorschlag', () => {
    const p = detail('warmup_Emir').pfad_vorschlag
    expect(pfadVorschlagAus(p && { ...p, ziel_label: null }, null, undefined)).toBeNull()
    expect(pfadVorschlagAus(undefined, null, undefined)).toBeNull()
  })
})

describe('C3 Heute', () => {
  it('ankommen, Warm-up, Kernarbeit und Eingemischtes mit Zahlen', () => {
    const h = kindMit('kern', 'Emir').heute
    expect(h.map((z) => z.abschnitt)).toEqual(['ankommen', 'warmup', 'kern', 'eingemischt'])
    expect(h[0].zeit).toBe((detail('kern_Emir').heute[0] as { zeit: string }).zeit)
    expect(h[1]).toMatchObject({ skill: 'Minus vor der Klammer', richtig: 1, von: 3, hinweise: 0, zusatz: null })
    expect(h[2]).toMatchObject({ skill: 'Klammern ausmultiplizieren', richtig: 1, von: 3, hinweise: 1 })
    expect(h[3]).toMatchObject({ skill: 'Proportionale Zuordnung', richtig: 1, von: 1, zusatz: 'mischanteil' })
  })

  it('Erklärsequenz: Kernideen sicher, aktuelle Kernidee und Runde', () => {
    expect(kindMit('kern', 'Jonas').heute.find((z) => z.abschnitt === 'erklaerung')).toMatchObject({
      skill: 'Steigung', kernideen: { sicher: 0, aktuell: 1, runde: 2 }, richtig: null, von: null,
    })
  })

  it('ohne erledigte Aufgabe keine Zahl', () => {
    const [z] = heuteAus([{ abschnitt: 'kern', skill_key: 'x', label: 'X', richtig: 0, von: 0, hinweise: 0 }])
    expect(z).toMatchObject({ richtig: null, von: null })
  })
})

describe('C3 Grund mit Zahl', () => {
  it('Fenster ausgewertet: unter der Quote mit richtig und von', () => {
    expect(kindMit('grund', 'Lea').grundLetzterSchritt).toEqual({ art: 'unterQuote', quote: 0.8, richtig: 0, von: 5 })
  })

  it('eingemischt: Mischanteil aus dem Schritt', () => {
    expect(kindMit('kern', 'Emir').grundLetzterSchritt).toEqual({ art: 'eingemischt', anteil: 0.3 })
  })

  it('ältere Zeile ohne details: grob wie bisher', () => {
    const k = raum('kern').kinder[0]
    expect(grundAus({ ...k, schritt: k.schritt && { ...k.schritt, eingemischt: false, grund_code: 'tiefer_gesetzt' } }, {}, {})).toEqual({ art: 'tiefer' })
    expect(grundAus(k, { richtig: 4, von: 5, ziel: 0.8, aenderung: 0 }, {})).toBeNull()
  })
})

describe('C3 Erklärsequenz', () => {
  it('alle Kernideen mit Titel, Stand, Runde und Fehlbild der letzten Runde', () => {
    expect(kindMit('kern', 'Jonas').erklaersequenz?.kernideen).toEqual([
      { text: 'Steigung pro Schritt nach rechts', stand: 'laeuft', runde: 2, fehlbild: 'Nur das erste Vorzeichen geändert', variante: 'B' },
      { text: 'y-Achsenabschnitt ablesen', stand: 'offen', runde: 1, fehlbild: null, variante: null },
    ])
  })
})

describe('C3 Mastery-Beleg', () => {
  it('Warm-up von heute, wenn der Kandidat heute im Warm-up dran war', () => {
    expect(kindMit('kern', 'Mila').masteryKandidat?.belege).toContainEqual({ art: 'warmupHeute', richtig: 3, von: 3 })
  })

  it('ohne Warm-up auf dem Skill kein Beleg', () => {
    const d = { ...detail('kern_Mila'), heute: [] }
    expect(kindMit('kern', 'Mila', d).masteryKandidat?.belege.some((b) => b.art === 'warmupHeute')).toBe(false)
  })
})

describe('C3 ältere Antwort ohne neue Felder', () => {
  it('blendet aus statt zu raten', () => {
    const alt = alteFixtures as unknown as { raum_kern: RaumLive; detail_kern: KindDetail }
    const kindId = alt.raum_kern.kinder[0].student_id
    const k = raumAus(alt.raum_kern, {
      detail: { kindId, detail: alt.detail_kern, ziel: [], pruefung: null, lernpfad: null },
      briefing: [], satz: {}, themen: new Map(), nichtErschienen: new Set(), pfadGeoeffnet: {},
    }).kinder[0]
    expect(k.pfadVorschlag).toBeNull()
    expect(k.heute).toEqual([])
  })
})
