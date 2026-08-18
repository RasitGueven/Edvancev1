import { describe, expect, it } from 'vitest'

import {
  familieVon,
  familienBefunde,
  familienBestand,
  FAMILIEN,
  lueckenFamilien,
  verteilungsFall,
} from '@/lib/report/familien'

const s = (skillKey: string, zustand: string) => ({ skillKey, zustand })

/**
 * Der Skill-Bestand, wie er am 18.08. in der Tabelle `skills` stand: 39 Skills,
 * ein Fach. Der Nenner beider Flächen des Profils.
 */
const BESTAND = {
  bruch: 8,
  prozent: 5,
  gleichung: 5,
  term: 4,
  geo: 12,
  vorzeichen: 3,
} as const

/** Die 17 direkt geprüften Skills der Sitzung d8b0d885 vom 16.08. */
const TOLUNAY = [
  s('gleichung_modellieren', 'traegt'),
  s('prozent_veraenderung', 'traegt'),
  s('gleichung_neg_koeffizient', 'traegt'),
  s('prozent_prozentsatz', 'traegt'),
  s('term_ausklammern', 'traegt_teilweise'),
  s('groessen_volumen', 'traegt_nicht'),
  s('term_minusklammer', 'traegt_nicht'),
  s('geo_massstab', 'traegt_nicht'),
  s('groessen_flaechen', 'traegt_nicht'),
  s('groessen_gemischt', 'traegt'),
  s('bruch_dezimal', 'traegt'),
  s('geo_flaeche_dreieck', 'traegt_nicht'),
  s('geo_volumen_quader', 'traegt_teilweise'),
  s('potenzen', 'traegt_teilweise'),
  s('bruch_div', 'traegt'),
  s('geo_flaeche_rechteck', 'traegt'),
  s('groessen_laengen', 'traegt'),
]

describe('familieVon', () => {
  it('ordnet die Präfixe zu', () => {
    expect(familieVon('gleichung_beidseitig')).toBe('gleichung')
    expect(familieVon('term_ausklammern')).toBe('term')
    expect(familieVon('vorzeichen_vorrang')).toBe('vorzeichen')
    expect(familieVon('bruch_div')).toBe('bruch')
    expect(familieVon('dezimal_mult')).toBe('bruch')
    expect(familieVon('prozent_grundwert')).toBe('prozent')
    expect(familieVon('proportionalitaet')).toBe('prozent')
    expect(familieVon('geo_massstab')).toBe('geo')
    expect(familieVon('groessen_flaechen')).toBe('geo')
  })

  it('gibt null für Skills außerhalb der sechs Familien', () => {
    // Kein Fehler: die beiden erscheinen weiterhin in den Skill-Listen des
    // Befunds — nur nicht auf einer Achse und nicht in der Familienzählung.
    expect(familieVon('potenzen')).toBeNull()
    expect(familieVon('runden_ueberschlag')).toBeNull()
  })
})

describe('familienBefunde — die feste Achsenmenge', () => {
  it('liefert IMMER alle sechs Achsen, in fester Reihenfolge', () => {
    // Der Grund für die feste Menge: Bis R4 zeichnete das Diagramm nur die
    // geprüften Familien — fünf Achsen bei der einen Sitzung, sechs bei der
    // anderen. Zwei Reports nebeneinander waren nicht vergleichbar.
    for (const skills of [TOLUNAY, [], [s('bruch_div', 'traegt')]]) {
      const b = familienBefunde(skills, BESTAND)
      expect(b).toHaveLength(6)
      expect(b.map((x) => x.key)).toEqual(FAMILIEN.map((f) => f.key))
    }
  })

  it('reproduziert das Profil von d8b0d885 — beide Werte gegen den Bestand', () => {
    const b = familienBefunde(TOLUNAY, BESTAND)
    const nach = Object.fromEntries(
      b.map((x) => [x.key, `${x.geprueft}|${x.traegt}/${x.vorhanden}`]),
    )
    expect(nach).toEqual({
      bruch: '2|2/8',
      prozent: '2|2/5',
      gleichung: '2|2/5',
      term: '2|0/4',
      geo: '8|3/12',
      vorzeichen: '0|0/3',
    })
  })

  it('teilt beide Flächen denselben Nenner — den Bestand, nicht die Stichprobe', () => {
    // Der Kern der Korrektur. Mit `traegt / geprueft` ergaben Brüche eine VOLLE
    // Achse (2 von 2), obwohl nur zwei von acht vorhandenen Bereichen angesehen
    // wurden. Je weniger geprüft, desto besser sah die Familie aus.
    const b = familienBefunde(TOLUNAY, BESTAND)
    const bruch = b.find((x) => x.key === 'bruch')!
    expect(bruch.anteilGeprueft).toBeCloseTo(2 / 8)
    expect(bruch.anteilTraegt).toBeCloseTo(2 / 8)

    // Gründlich geprüft, trägt wenig: die beiden Flächen klaffen auseinander.
    const geo = b.find((x) => x.key === 'geo')!
    expect(geo.anteilGeprueft).toBeCloseTo(8 / 12)
    expect(geo.anteilTraegt).toBeCloseTo(3 / 12)
  })

  it('lässt die innere Fläche nie über die äußere hinausgehen', () => {
    // Ein Skill traegt nicht, ohne geprueft worden zu sein.
    for (const skills of [TOLUNAY, [], [s('term_ausklammern', 'traegt')]]) {
      for (const b of familienBefunde(skills, BESTAND)) {
        expect(b.anteilTraegt!).toBeLessThanOrEqual(b.anteilGeprueft!)
      }
    }
  })

  it('markiert eine Familie ohne geprüften Skill, statt sie als Null zu zeigen', () => {
    const b = familienBefunde(TOLUNAY, BESTAND)
    const vorzeichen = b.find((x) => x.key === 'vorzeichen')!
    expect(vorzeichen.geprueft).toBe(0)
    expect(vorzeichen.grund).toBe('nicht_geprueft')

    // Eine echte Null bleibt davon unberührt: Terme wurden geprüft.
    const term = b.find((x) => x.key === 'term')!
    expect(term.anteilTraegt).toBe(0)
    expect(term.anteilGeprueft).toBeCloseTo(0.5)
    expect(term.grund).toBeNull()
  })

  it('braucht keine Sonderregel mehr für dünn geprüfte Familien', () => {
    // Frueher war „1 geprueft, 1 traegt" eine volle Achse und musste
    // ausgegraut werden. Mit dem Bestand als Nenner sind es 1 von 3 — die
    // Warnung steckt jetzt in der Zahl.
    const b = familienBefunde([s('vorzeichen_vorrang', 'traegt')], BESTAND)
    const vorzeichen = b.find((x) => x.key === 'vorzeichen')!
    expect(vorzeichen.anteilTraegt).toBeCloseTo(1 / 3)
    expect(vorzeichen.grund).toBeNull()
  })
})

describe('familienBestand', () => {
  it('zählt den Bestand je Familie und ignoriert Skills ohne Familie', () => {
    const bestand = familienBestand([
      'bruch_div',
      'dezimal_mult',
      'geo_massstab',
      'groessen_flaechen',
      'potenzen',
      'runden_ueberschlag',
    ])
    expect(bestand.bruch).toBe(2)
    expect(bestand.geo).toBe(2)
    expect(bestand.term).toBe(0)
  })

  it('liefert für jede der sechs Familien einen Wert', () => {
    const bestand = familienBestand([])
    expect(Object.keys(bestand).sort()).toEqual(FAMILIEN.map((f) => f.key).sort())
  })
})

describe('lueckenFamilien und verteilungsFall', () => {
  it('zählt die Familien der Lücken von d8b0d885', () => {
    const luecken = TOLUNAY.filter((x) => x.zustand !== 'traegt')
    const { familien, ohneFamilie } = lueckenFamilien(luecken)
    expect(familien).toEqual(['term', 'geo'])
    expect(ohneFamilie).toBe(1) // potenzen
  })

  it('zählt die Familien der Lücken von 920d00ae', () => {
    const luecken = [
      s('term_ausklammern', 'traegt_teilweise'),
      s('term_minusklammer', 'traegt_nicht'),
      s('geo_massstab', 'nicht_angesetzt'),
      s('geo_flaeche_dreieck', 'traegt_nicht'),
    ]
    const { familien } = lueckenFamilien(luecken)
    // Genau hier lag der Fehler, den R5 behebt: Der Empfehlungstext sagte
    // „die Bereiche liegen dicht beieinander" — bei Lücken in ZWEI Familien.
    expect(familien).toEqual(['term', 'geo'])
    expect(verteilungsFall(familien.length)).toBe('zwei')
  })

  it('bildet die drei Verteilungsfälle ab', () => {
    expect(verteilungsFall(0)).toBe('eine')
    expect(verteilungsFall(1)).toBe('eine')
    expect(verteilungsFall(2)).toBe('zwei')
    expect(verteilungsFall(3)).toBe('mehrere')
    expect(verteilungsFall(6)).toBe('mehrere')
  })
})
