import i18next from 'i18next'
import { beforeAll, describe, expect, it } from 'vitest'

import deReport from '@/i18n/locales/de/report.json'
import {
  ABSCHLUSS_MODELLIEREN,
  FALL_A,
  FALL_B,
  FALL_C,
  FALL_D,
  KANTEN,
} from '@/lib/report/suche.fixtures'
import { abschluss, baueSuche, nurEineAufgabe, sucheSaetze } from '@/lib/report/suche'
import type { SucheStufe, Suchweg } from '@/types'

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

/** Kompakte Sicht: "stufe/bereich: label=sicher|offen, …". */
const sicht = (stufen: readonly SucheStufe[]) =>
  stufen.flatMap((st) =>
    st.zeilen.map(
      (z) =>
        `${st.stufe}/${z.bereich} ${z.sicher}/${z.geprueft}: ` +
        z.eintraege.map((e) => `${e.label}=${e.sicher ? 'sicher' : 'offen'}`).join(', '),
    ),
  )

describe('abschluss', () => {
  it('rechnet dasselbe wie public.lsa_abschluss', () => {
    expect([...abschluss(['gleichung_modellieren'], KANTEN)].sort()).toEqual(ABSCHLUSS_MODELLIEREN)
  })

  it('übersteht Zyklen und kennt den Start nicht als eigene Voraussetzung', () => {
    const zyklus = [
      { skillKey: 'a', voraussetzt: 'b' },
      { skillKey: 'b', voraussetzt: 'a' },
    ]
    expect([...abschluss(['a'], zyklus)].sort()).toEqual(['a', 'b'])
    expect([...abschluss(['x'], zyklus)]).toEqual([])
  })
})

describe('a) echte Sitzung 143215f5 mit Thema der Gleichungen', () => {
  const s = baueSuche(FALL_A)!

  it('Block 1: der Einstiegsknoten, noch nicht sicher', () => {
    expect(s.fall).toBe('thema')
    expect(s.aktuell).toMatchObject({ geprueft: 1, sicher: 0 })
    expect(s.aktuell!.eintraege.map((e) => e.label)).toEqual([
      'Gleichungen aufstellen (Sachkontext)',
    ])
  })

  it('Block 2: nur, was im Abschluss liegt — nach Stufe und Bereich', () => {
    expect(sicht(s.grundlagen)).toEqual([
      'erste/terme 1/1: Ausmultiplizieren=sicher',
      'erste/gleichungen 1/1: Beidseitige Gleichungen=sicher',
    ])
    expect(s.grundlageSicher).toBe(true)
  })

  it('Volumen und Brüche stehen unter „Außerdem", nicht darunter', () => {
    expect(sicht(s.angesehen)).toEqual([
      'erste/geometrie 0/1: Fläche von Dreieck und Parallelogramm=offen',
      'erste/prozent 1/1: Prozentuale Veränderung=sicher',
      'erprobung/brueche 1/3: Brüche kürzen=sicher, Brüche dividieren=offen, Brüche multiplizieren=offen',
      'erprobung/groessen 1/3: Gemischte Schreibweise=sicher, Flächeneinheiten=offen, Volumeneinheiten=offen',
      'erprobung/geometrie 0/1: Fläche von Rechteck und Quadrat=offen',
    ])
    const darunter = s.grundlagen.flatMap((st) => st.zeilen.flatMap((z) => z.eintraege))
    expect(darunter.map((e) => e.label)).not.toContain('Volumeneinheiten')
    expect(darunter.map((e) => e.label)).not.toContain('Brüche dividieren')
  })

  it('der Text stellt Thema und Grundlagen konkret gegenüber', () => {
    expect(text(s)).toBe(
      'Beim Thema „Terme und Gleichungen“ war Ihr Kind noch nicht sicher: ' +
        'Gleichungen aufstellen (Sachkontext). ' +
        'Wir haben die Grundlagen geprüft, auf denen das Thema aufbaut, bis wir sicheren ' +
        'Boden gefunden haben: Ausmultiplizieren und Beidseitige Gleichungen sicher.',
    )
  })
})

describe('b) dieselbe Sitzung ohne Thema', () => {
  const s = baueSuche(FALL_B)!

  it('kein Block 1 und 2, alles unter „Angesehen"', () => {
    expect(s.fall).toBe('ohne_thema')
    expect(s.aktuell).toBeNull()
    expect(s.grundlagen).toEqual([])
    expect(s.angesehen.map((st) => st.stufe)).toEqual(['erste', 'erprobung'])
    expect(sicht(s.angesehen)[0]).toBe('erste/geometrie 0/1: Fläche von Dreieck und Parallelogramm=offen')
    expect(s.angesehen.flatMap((st) => st.zeilen).reduce((n, z) => n + z.geprueft, 0)).toBe(12)
  })

  it('sagt, dass ohne Thema gesucht wurde — kein darunter, kein Boden', () => {
    const t = text(s)
    expect(t).toBe(
      'Diese Analyse lief ohne gewähltes Thema. Angesehen haben wir 12 Bereiche; ' +
        'unten stehen sie nach Klassenstufe und Inhaltsbereich.',
    )
    expect(t).not.toMatch(/darunter|Boden/)
  })
})

describe('c) Thema sofort sicher, nur Breite', () => {
  const s = baueSuche(FALL_C)!

  it('Block 1 sicher, Block 2 leer, die Breite unter „Außerdem"', () => {
    expect(s.aktuell).toMatchObject({ geprueft: 1, sicher: 1 })
    expect(s.grundlagen).toEqual([])
    expect(s.angesehen.flatMap((st) => st.zeilen).map((z) => z.bereich)).toEqual([
      'prozent',
      'brueche',
      'groessen',
    ])
  })

  it('kein sicherer Boden, wenn nicht abgestiegen wurde', () => {
    const t = text(s)
    expect(t).toBe(
      'Beim Thema „Terme und Gleichungen“ war Ihr Kind sicher: ' +
        'Gleichungen aufstellen (Sachkontext). Die Grundlagen, auf denen das Thema ' +
        'aufbaut, kamen in dieser Analyse nicht dran.',
    )
    expect(t).not.toMatch(/Boden/)
  })

  it('markiert das provisorische Urteil als „nur eine Aufgabe"', () => {
    const laengen = s.angesehen
      .flatMap((st) => st.zeilen.flatMap((z) => z.eintraege))
      .find((e) => e.label === 'Längen umrechnen')!
    expect(laengen).toMatchObject({ sicher: true, nurEineAufgabe: true })
    // Eindeutiger Treffer: Probe 1 'voll', offen = false.
    expect(s.aktuell!.eintraege[0].nurEineAufgabe).toBe(false)
  })
})

describe('d) Thema ohne Einstiegsknoten', () => {
  const s = baueSuche(FALL_D)!

  it('nennt das Thema, aber gliedert alles unter „Angesehen"', () => {
    expect(s.fall).toBe('thema_ungeprueft')
    expect(s.aktuell).toBeNull()
    expect(s.grundlagen).toEqual([])
    expect(sicht(s.angesehen)).toEqual([
      'erste/zuordnungen 1/1: Dreisatz, proportional und antiproportional=sicher',
      'erprobung/brueche 1/1: Brüche kürzen=sicher',
      'erprobung/dezimalzahlen 0/1: Dezimalzahlen multiplizieren=offen',
    ])
  })

  it('behauptet weder Abstieg noch Boden', () => {
    const t = text(s)
    expect(t).toMatch(/^Gewählt war das Thema „Proportionale und antiproportionale Zuordnungen“\./)
    expect(t).not.toMatch(/darunter|Boden/)
  })
})

describe('Textregeln', () => {
  it('Boden nur mit sicherem Skill auf dem Abstiegsweg', () => {
    const ohneSicherenGrund = baueSuche({
      ...FALL_A,
      skills: FALL_A.skills.map((x) =>
        x.skillKey === 'gleichung_beidseitig' || x.skillKey === 'term_ausmultiplizieren'
          ? { ...x, zustand: 'traegt_nicht', proben: 2 }
          : x,
      ),
    })!
    expect(ohneSicherenGrund.grundlageSicher).toBe(false)
    expect(text(ohneSicherenGrund)).not.toMatch(/Boden/)
    expect(text(ohneSicherenGrund)).toMatch(/Auch bei den Grundlagen, .* noch nicht sicher/)
  })

  it('kürzt lange Listen auf drei Labels', () => {
    const viele = baueSuche({
      ...FALL_A,
      einstieg: ['bruch_div', 'bruch_mult', 'groessen_volumen', 'geo_flaeche_dreieck', 'gleichung_modellieren'],
    })!
    expect(text(viele)).toMatch(/und 2 weitere Bereiche/)
  })

  it('kein Satz sagt „trägt" oder „gemeistert"', () => {
    for (const f of [FALL_A, FALL_B, FALL_C, FALL_D]) {
      expect(text(baueSuche(f)!)).not.toMatch(/trägt|trug|gemeistert/i)
    }
  })

  it('nichts geprüft: kein Abschnitt', () => {
    expect(baueSuche({ ...FALL_A, skills: [] })).toBeNull()
  })

  it('nurEineAufgabe: zwei Proben sind nie „nur eine"', () => {
    const x = FALL_A.skills[0]
    expect(nurEineAufgabe({ ...x, proben: 2, zustand: 'traegt_nicht' })).toBe(false)
    expect(nurEineAufgabe({ ...x, proben: 1, zustand: 'traegt_nicht', offen: true })).toBe(true)
  })
})
