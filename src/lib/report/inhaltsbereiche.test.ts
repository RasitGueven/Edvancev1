import { describe, expect, it } from 'vitest'

import deReport from '@/i18n/locales/de/report.json'
import { INHALTSBEREICHE, inhaltsbereich, stufeAusKlasse } from '@/lib/report/inhaltsbereiche'
import { SKILL_BESTAND } from '@/lib/report/skillBestand'

describe('inhaltsbereich', () => {
  it('ordnet jeden Skill aus dem Prod-Abzug einem benannten Bereich zu', () => {
    expect(SKILL_BESTAND).toHaveLength(130)
    const weitere = SKILL_BESTAND.filter((key) => inhaltsbereich(key) === 'weitere')
    expect(weitere).toEqual([])
  })

  it('ordnet die Familien aus K8–K10 zu', () => {
    const erwartet: [string, string][] = [
      ['zahl_wurzel_quadrat', 'wurzeln'],
      ['zahl_wurzel_irrational', 'wurzeln'],
      ['zahl_potenz_gesetze', 'potenzen'],
      ['zahl_potenz_zehner', 'potenzen'],
      ['fkt_quadr_scheitel', 'funktionen'],
      ['fkt_exp_halbwert', 'funktionen'],
      ['fkt_sinus_graph', 'funktionen'],
      ['geo_pythagoras_kathete', 'geometrie'],
      ['geo_trigo_kosinussatz', 'geometrie'],
      ['geo_koerper_kegel', 'geometrie'],
      ['geo_aehnlich_streckfaktor', 'geometrie'],
      ['geo_kreis_sektor', 'geometrie'],
      ['geo_flaeche_trapez', 'geometrie'],
      ['geo_winkel_thales', 'geometrie'],
      ['stoch_laplace', 'stochastik'],
      ['stoch_bedingt_vierfeld', 'stochastik'],
      ['stoch_pfad_produkt', 'stochastik'],
      ['gleichung_lgs_addition', 'gleichungen'],
      ['gleichung_quadr_formel', 'gleichungen'],
      ['prozent_zins_zinseszins', 'prozent'],
    ]
    for (const [key, bereich] of erwartet) {
      expect(inhaltsbereich(key), key).toBe(bereich)
    }
  })

  it('nimmt den längsten Präfix: zahl_wurzel vor zahl', () => {
    expect(inhaltsbereich('zahl_wurzel_neu')).toBe('wurzeln')
    expect(inhaltsbereich('zahl_neu')).toBe('zahlen')
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
