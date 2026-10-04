import i18next from 'i18next'
import { beforeAll, describe, expect, it } from 'vitest'

import deReport from '@/i18n/locales/de/report.json'
import { baueRueckbezuege } from '@/lib/report/rueckbezug'
import { baueSuche, sucheSaetze } from '@/lib/report/suche'
import { FALL_A, KANTEN, THEMA_GLEICHUNGEN } from '@/lib/report/suche.fixtures'
import {
  berechneThemenraum,
  gespeicherterThemenraum,
  themenraumFuer,
} from '@/lib/report/themenraum'
import {
  GESPEICHERT_GLEICHUNGEN,
  GESPEICHERT_REELLE_ZAHLEN,
  KANTEN_SPAETER,
  SITZUNG_REELLE_ZAHLEN,
  THEMA_LABEL_REELLE_ZAHLEN,
  WEAK_A,
} from '@/lib/report/themenraum.fixtures'
import type { AnlassZuordnung, SucheSkill, Suchweg, Themenraum } from '@/types'

const i18n = i18next.createInstance()
beforeAll(async () => {
  await i18n.init({
    lng: 'de',
    ns: ['report'],
    defaultNS: 'report',
    resources: { de: { report: deReport } },
    interpolation: { escapeValue: false },
  })
})
const text = (s: Suchweg) => sucheSaetze(s, (k, w) => i18n.t(k, w), 'de').join(' ')

const GRUNDLAGEN: AnlassZuordnung = {
  thema: 'Grundlagen fehlen',
  anzeigename: 'fehlende Grundlagen',
  skillKeys: [],
  fehlbildFamilien: [],
  strukturell: true,
  messbar: true,
}

const rueckbezug = (skills: readonly SucheSkill[], raum: Themenraum | null) =>
  baueRueckbezuege({ weakTopics: WEAK_A, zuordnungen: [GRUNDLAGEN], skills, familien: [], raum })

const labels = (s: Suchweg, block: 'grundlagen' | 'angesehen') =>
  s[block].flatMap((st) => st.zeilen.flatMap((z) => z.eintraege.map((e) => e.label))).sort()

describe('themenraumFuer — gespeichert vor berechnet', () => {
  it('berechnet dasselbe wie public.lsa_themenraum (Graph aus dem pgTAP-Test)', () => {
    const kanten = [
      ['W5D_E1', 'W5D_E2'],
      ['W5D_E1', 'W5D_G1'],
      ['W5D_E2', 'W5D_G2'],
      ['W5D_G1', 'W5D_G3'],
      ['W5D_F1', 'W5D_G3'],
    ].map(([skillKey, voraussetzt]) => ({ skillKey, voraussetzt }))
    const r = berechneThemenraum('w5d_thema', ['W5D_E2', 'W5D_E1'], kanten)
    expect(r.einstieg).toEqual(['W5D_E1', 'W5D_E2'])
    expect(r.darunter).toEqual(['W5D_G1', 'W5D_G2', 'W5D_G3'])
  })

  it('liest stand = nachgetragen als eigene Herkunft', () => {
    const r = gespeicherterThemenraum({ ...GESPEICHERT_GLEICHUNGEN, stand: 'nachgetragen' }, 'terme_gleichungen')
    expect(r?.herkunft).toBe('nachgetragen')
  })

  it('verwirft einen kaputten oder fremden Raum und rechnet', () => {
    for (const roh of [
      { ...GESPEICHERT_GLEICHUNGEN, darunter: 'x' },
      { ...GESPEICHERT_GLEICHUNGEN, thema_key: 'anderes_thema' },
      'quatsch',
    ]) {
      const r = themenraumFuer({ themaKey: 'terme_gleichungen', gespeichert: roh, einstieg: ['gleichung_modellieren'], kanten: KANTEN })
      expect(r?.herkunft).toBe('berechnet')
    }
  })
})

describe('a) gespeicherter Raum, danach geänderte Kanten → Report unverändert', () => {
  const quellen = {
    themaKey: 'terme_gleichungen',
    gespeichert: GESPEICHERT_GLEICHUNGEN,
    einstieg: ['gleichung_modellieren'],
  }
  const vorher = themenraumFuer({ ...quellen, kanten: KANTEN })!
  const nachher = themenraumFuer({ ...quellen, kanten: KANTEN_SPAETER })!

  it('der Raum kommt aus result_summary, nicht aus den Kanten', () => {
    expect(nachher.herkunft).toBe('abschluss')
    expect(nachher).toEqual(vorher)
  })

  it('Gliederung, Text und Rückbezug sind dieselben', () => {
    const a = baueSuche({ skills: FALL_A.skills, themaLabel: FALL_A.themaLabel, raum: vorher })!
    const b = baueSuche({ skills: FALL_A.skills, themaLabel: FALL_A.themaLabel, raum: nachher })!
    expect(b).toEqual(a)
    expect(text(b)).toBe(text(a))
    expect(rueckbezug(FALL_A.skills, nachher)).toEqual(rueckbezug(FALL_A.skills, vorher))
  })

  it('Kontrolle: gerechnet hätte sich der Report verschoben', () => {
    const gerechnet = berechneThemenraum('terme_gleichungen', ['gleichung_modellieren'], KANTEN_SPAETER)
    const s = baueSuche({ skills: FALL_A.skills, themaLabel: FALL_A.themaLabel, raum: gerechnet })!
    expect(labels(s, 'grundlagen')).toContain('Volumeneinheiten')
    expect(labels(baueSuche({ ...FALL_A, raum: nachher })!, 'grundlagen')).not.toContain('Volumeneinheiten')
  })
})

describe('b) alte Sitzung ohne gespeicherten Raum → berechnet wie heute', () => {
  const raum = themenraumFuer({
    themaKey: 'terme_gleichungen',
    gespeichert: null,
    einstieg: ['gleichung_modellieren'],
    kanten: KANTEN,
  })!

  it('rechnet aus thema_einstieg und skill_kante', () => {
    expect(raum.herkunft).toBe('berechnet')
    expect(raum).toEqual(THEMA_GLEICHUNGEN.raum)
  })

  it('ergibt genau die Gliederung aus #189', () => {
    expect(baueSuche({ ...FALL_A, raum })).toEqual(baueSuche(FALL_A))
  })
})

describe('c) Sitzung ohne Thema', () => {
  const raum = themenraumFuer({ themaKey: null, gespeichert: null, einstieg: [], kanten: KANTEN })

  it('hat keinen Raum, alles steht unter „angesehen"', () => {
    expect(raum).toBeNull()
    const s = baueSuche({ skills: FALL_A.skills, themaLabel: null, raum })!
    expect(s.fall).toBe('ohne_thema')
    expect(s.grundlagen).toEqual([])
    expect(labels(s, 'angesehen')).toHaveLength(FALL_A.skills.length)
  })

  it('„Grundlagen fehlen" bleibt ohne Aussage — kein Ursachen-Satz', () => {
    const [r] = rueckbezug(FALL_A.skills, raum)
    expect(r.richtung).toBe('offen')
    expect(r.fall).toBe('grundlagen_offen')
  })
})

describe('d) Reelle Zahlen: Wurzeln als Thema, Fläche nur angesehen', () => {
  const raum = themenraumFuer({
    themaKey: 'reelle_zahlen',
    gespeichert: GESPEICHERT_REELLE_ZAHLEN,
    einstieg: [],
    kanten: [],
  })!
  const s = baueSuche({ skills: SITZUNG_REELLE_ZAHLEN, themaLabel: THEMA_LABEL_REELLE_ZAHLEN, raum })!

  it('Block 1: die drei Wurzel-Einstiege', () => {
    expect(s.fall).toBe('thema')
    expect(s.aktuell).toMatchObject({ geprueft: 3, sicher: 1 })
  })

  it('Block 2: Quadratwurzel, Potenzen, Brüche, Dezimalzahlen', () => {
    expect(labels(s, 'grundlagen')).toEqual([
      'Bruch in Dezimalzahl',
      'Dezimalzahlen dividieren',
      'Potenzen und Quadratzahlen',
      'Quadratwurzel als Umkehrung des Quadrierens',
    ])
  })

  it('Block 3: die Fläche, und nur sie', () => {
    expect(labels(s, 'angesehen')).toEqual(['Fläche von Rechteck und Quadrat'])
  })

  it('der Text nennt die Fläche nicht', () => {
    expect(text(s)).not.toMatch(/Fläche/)
    expect(text(s)).toMatch(/Reelle Zahlen und Wurzeln/)
  })

  it('„Grundlagen fehlen" stützt sich nur auf den Raum: entlastend auf 4 Bereichen', () => {
    // Nach der alten Ebenen-Logik hätten die Fläche (Tiefe 3) und der
    // Einstieg „Rationale und irrationale Zahlen" (Tiefe 6) als Lücke darunter
    // gezählt — der Satz hätte die Vermutung bestätigt.
    const [r] = rueckbezug(SITZUNG_REELLE_ZAHLEN, raum)
    expect(r.richtung).toBe('entlastend')
    expect(r.fall).toBe('grundlagen_entlastend')
    expect(r.belege).toBe(4)
  })
})
