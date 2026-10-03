import { describe, expect, it } from 'vitest'

import deReport from '@/i18n/locales/de/report.json'
import { INHALTSBEREICHE, inhaltsbereich, stufeAusKlasse } from '@/lib/report/inhaltsbereiche'

/** Alle 54 skill_keys in Prod, Stand 03.10.2026. */
const BESTAND = [
  'dezimal_add_sub', 'geo_flaeche_rechteck', 'geo_umfang', 'groessen_laengen', 'groessen_massen',
  'groessen_zeit', 'runden_ueberschlag', 'bruch_add', 'bruch_dezimal', 'bruch_div',
  'bruch_kuerzen', 'bruch_mult', 'dezimal_div', 'dezimal_mult', 'geo_flaeche_dreieck',
  'geo_koordinaten', 'geo_massstab', 'geo_volumen_quader', 'groessen_flaechen',
  'groessen_gemischt', 'groessen_volumen', 'geo_winkel_summe', 'gleichung_beidseitig',
  'gleichung_einschrittig', 'gleichung_neg_koeffizient', 'gleichung_zweischrittig', 'potenzen',
  'proportionalitaet', 'prozent_grundwert', 'prozent_prozentsatz', 'prozent_prozentwert',
  'prozent_veraenderung', 'prozent_zins_jahreszins', 'prozent_zins_rueckrechnung',
  'prozent_zins_teilzins', 'prozent_zins_zinseszins', 'term_ausklammern',
  'term_ausmultiplizieren', 'term_einsetzen', 'term_minusklammer', 'term_zusammenfassen',
  'vorzeichen_add_sub', 'vorzeichen_mult_div', 'vorzeichen_vorrang', 'fkt_linear_gleichung',
  'fkt_linear_graph', 'fkt_linear_nullstelle', 'fkt_linear_steigung', 'fkt_linear_yabschnitt',
  'gleichung_modellieren', 'term_binom_faktorisieren', 'term_binom_gemischt',
  'term_binom_quadrat', 'term_binom_quadratdifferenz',
]

describe('inhaltsbereich', () => {
  it('ordnet jeden Skill im Bestand einem echten Bereich zu', () => {
    expect(BESTAND).toHaveLength(54)
    for (const key of BESTAND) {
      expect(inhaltsbereich(key), key).not.toBe('weitere')
    }
  })

  it('leitet aus der Familie ab', () => {
    expect(inhaltsbereich('bruch_kuerzen')).toBe('brueche')
    expect(inhaltsbereich('vorzeichen_vorrang')).toBe('negative_zahlen')
    expect(inhaltsbereich('groessen_volumen')).toBe('groessen')
    expect(inhaltsbereich('term_binom_quadrat')).toBe('terme')
    expect(inhaltsbereich('prozent_zins_zinseszins')).toBe('prozent')
    expect(inhaltsbereich('fkt_linear_graph')).toBe('funktionen')
  })

  it('kennt die Ausnahmen ohne Familie', () => {
    expect(inhaltsbereich('proportionalitaet')).toBe('zuordnungen')
    expect(inhaltsbereich('potenzen')).toBe('potenzen')
    expect(inhaltsbereich('runden_ueberschlag')).toBe('zahlen')
  })

  it('fällt bei Unbekanntem auf „weitere", nie auf den Schlüssel', () => {
    expect(inhaltsbereich('geokreis')).toBe('weitere')
    expect(inhaltsbereich('xyz_neu')).toBe('weitere')
  })

  it('hat für jeden Bereich einen Anzeigenamen', () => {
    for (const b of INHALTSBEREICHE) {
      expect(deReport.suche.bereich[b], b).toBeTruthy()
    }
  })
})

describe('stufeAusKlasse', () => {
  it('folgt der Stufung des KLP G9', () => {
    expect([5, 6].map(stufeAusKlasse)).toEqual(['erprobung', 'erprobung'])
    expect([7, 8].map(stufeAusKlasse)).toEqual(['erste', 'erste'])
    expect([9, 10].map(stufeAusKlasse)).toEqual(['zweite', 'zweite'])
  })
})
