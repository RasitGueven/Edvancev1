import { describe, expect, it } from 'vitest'

import {
  familieVon,
  familienBefunde,
  FAMILIEN,
  lueckenFamilien,
  MIN_GEPRUEFT_ACHSE,
  verteilungsFall,
} from '@/lib/report/familien'

const s = (skillKey: string, zustand: string) => ({ skillKey, zustand })

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
      const b = familienBefunde(skills)
      expect(b).toHaveLength(6)
      expect(b.map((x) => x.key)).toEqual(FAMILIEN.map((f) => f.key))
    }
  })

  it('reproduziert das Profil von d8b0d885', () => {
    const b = familienBefunde(TOLUNAY)
    const nach = Object.fromEntries(b.map((x) => [x.key, `${x.traegt}/${x.geprueft}`]))
    expect(nach).toEqual({
      bruch: '2/2',
      prozent: '2/2',
      gleichung: '2/2',
      term: '0/2',
      geo: '3/8',
      vorzeichen: '0/0',
    })
  })

  it('unterscheidet "nicht geprüft" von "trägt nicht"', () => {
    // Der wichtigste Punkt des Diagramms. Beides an den Mittelpunkt zu
    // zeichnen, ohne es zu unterscheiden, hieße: nicht geprüft sieht aus wie
    // nichts gekonnt.
    const b = familienBefunde(TOLUNAY)
    const vorzeichen = b.find((x) => x.key === 'vorzeichen')!
    const term = b.find((x) => x.key === 'term')!

    expect(vorzeichen.geprueft).toBe(0)
    expect(vorzeichen.anteil).toBeNull()
    expect(vorzeichen.grund).toBe('nicht_geprueft')

    expect(term.anteil).toBe(0)
    expect(term.grund).toBeNull()
  })

  it('markiert eine Achse unter der Mindestzahl als zu dünn', () => {
    // Eine volle Achse aus einem Skill liest sich wie eine Bestnote und beruht
    // auf ein bis zwei Aufgaben.
    const b = familienBefunde([s('vorzeichen_vorrang', 'traegt')])
    const vorzeichen = b.find((x) => x.key === 'vorzeichen')!
    expect(vorzeichen.geprueft).toBe(1)
    expect(vorzeichen.geprueft).toBeLessThan(MIN_GEPRUEFT_ACHSE)
    expect(vorzeichen.anteil).toBeNull()
    expect(vorzeichen.grund).toBe('zu_wenig')
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
