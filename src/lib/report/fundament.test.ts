import { describe, expect, it } from 'vitest'

import { baueFundament, findeEinbruch, sucheFall } from '@/lib/report/fundament'
import type { FundamentSkill } from '@/types'

/**
 * Die Testdaten sind die BEIDEN ECHTEN SITZUNGEN vom 16.08.2026, nicht
 * erfundene Beispiele. Genau an ihnen ist aufgefallen, dass der Report etwas
 * anderes erzählte als die Zahlen hergaben — sie sind der Grund für R4 und
 * damit der richtige Prüfstein.
 */

const s = (
  skillKey: string,
  fundamentTiefe: number,
  zustand: string,
  proben = 1,
): FundamentSkill => ({ skillKey, label: skillKey, fundamentTiefe, zustand, proben })

// d8b0d885 — 17 direkt geprüft, Spur 2/2 · 2/3 · 0/2 · 1/3 · 1/4 · 3/3
const TOLUNAY: FundamentSkill[] = [
  s('gleichung_modellieren', 8, 'traegt'),
  s('prozent_veraenderung', 8, 'traegt'),
  s('gleichung_neg_koeffizient', 7, 'traegt'),
  s('prozent_prozentsatz', 7, 'traegt'),
  s('term_ausklammern', 7, 'traegt_teilweise', 2),
  s('groessen_volumen', 6, 'traegt_nicht', 2),
  s('term_minusklammer', 6, 'traegt_nicht', 2),
  s('geo_massstab', 5, 'traegt_nicht', 2),
  s('groessen_flaechen', 5, 'traegt_nicht', 2),
  s('groessen_gemischt', 5, 'traegt'),
  s('bruch_dezimal', 4, 'traegt'),
  s('geo_flaeche_dreieck', 4, 'traegt_nicht', 2),
  s('geo_volumen_quader', 4, 'traegt_teilweise', 2),
  s('potenzen', 4, 'traegt_teilweise', 2),
  s('bruch_div', 3, 'traegt'),
  s('geo_flaeche_rechteck', 3, 'traegt'),
  s('groessen_laengen', 3, 'traegt'),
]

// 920d00ae — 20 direkt geprüft, Spur 2/2 · 2/3 · 1/2 · 1/2 · 3/4 · 5/5 · 2/2
const RASIT: FundamentSkill[] = [
  s('gleichung_modellieren', 8, 'traegt'),
  s('prozent_veraenderung', 8, 'traegt'),
  s('gleichung_neg_koeffizient', 7, 'traegt'),
  s('prozent_prozentsatz', 7, 'traegt'),
  s('term_ausklammern', 7, 'traegt_teilweise', 2),
  s('groessen_volumen', 6, 'traegt'),
  s('term_minusklammer', 6, 'traegt_nicht', 2),
  s('geo_massstab', 5, 'nicht_angesetzt', 2),
  s('groessen_gemischt', 5, 'traegt'),
  s('bruch_dezimal', 4, 'traegt'),
  s('geo_flaeche_dreieck', 4, 'traegt_nicht', 2),
  s('geo_volumen_quader', 4, 'traegt'),
  s('vorzeichen_vorrang', 4, 'traegt'),
  s('bruch_div', 3, 'traegt'),
  s('geo_flaeche_rechteck', 3, 'traegt'),
  s('geo_umfang', 3, 'traegt'),
  s('geo_winkel_summe', 3, 'traegt'),
  s('groessen_massen', 3, 'traegt'),
  s('bruch_add', 2, 'traegt'),
  s('runden_ueberschlag', 2, 'traegt'),
]

describe('baueFundament — die Schichtung der echten Sitzungen', () => {
  it('reproduziert die Ebenenspur von d8b0d885', () => {
    const f = baueFundament(TOLUNAY)!
    expect(f.einstiegTiefe).toBe(8)
    expect(f.geprueft).toBe(17)
    expect(f.traegt).toBe(9)
    expect(f.ebenen.map((e) => `${e.traegt}/${e.geprueft}`)).toEqual([
      '2/2',
      '2/3',
      '0/2',
      '1/3',
      '1/4',
      '3/3',
    ])
  })

  it('reproduziert die Ebenenspur von 920d00ae', () => {
    const f = baueFundament(RASIT)!
    expect(f.geprueft).toBe(20)
    expect(f.traegt).toBe(16)
    expect(f.ebenen.map((e) => `${e.traegt}/${e.geprueft}`)).toEqual([
      '2/2',
      '2/3',
      '1/2',
      '1/2',
      '3/4',
      '5/5',
      '2/2',
    ])
  })

  it('zählt nur "traegt" als tragend — teilweise und nicht_angesetzt nicht', () => {
    const f = baueFundament(RASIT)!
    const keys = f.luecken.map((l) => l.skillKey)
    expect(keys).toContain('term_ausklammern') // traegt_teilweise
    expect(keys).toContain('geo_massstab') // nicht_angesetzt
    expect(f.luecken).toHaveLength(4)
  })

  it('beschriftet Ebenen über delta, nicht über die absolute Tiefe', () => {
    const f = baueFundament(TOLUNAY)!
    expect(f.ebenen.map((e) => e.delta)).toEqual([0, 1, 2, 3, 4, 5])
  })

  it('gibt höchstens drei Labels je Ebene und zählt den Rest', () => {
    const f = baueFundament(TOLUNAY)!
    const vier = f.ebenen.find((e) => e.geprueft === 4)!
    expect(vier.labels).toHaveLength(3)
    expect(vier.weitere).toBe(1)

    const zwei = f.ebenen.find((e) => e.geprueft === 2)!
    expect(zwei.labels).toHaveLength(2)
    expect(zwei.weitere).toBe(0)
  })

  it('sortiert die Lücken von unten nach oben — tiefste zuerst', () => {
    const f = baueFundament(TOLUNAY)!
    const tiefen = f.luecken.map((l) => l.fundamentTiefe)
    expect(tiefen).toEqual([...tiefen].sort((a, b) => a - b))
    expect(tiefen[0]).toBe(4)
  })

  it('gibt null zurück, wenn nichts direkt geprüft wurde', () => {
    expect(baueFundament([])).toBeNull()
  })
})

describe('Einstieg und Fundament — die Achsen der Fallwahl', () => {
  it('erkennt bei beiden echten Sitzungen, dass der Einstieg trägt', () => {
    expect(baueFundament(TOLUNAY)!.einstiegTraegt).toBe(true)
    expect(baueFundament(RASIT)!.einstiegTraegt).toBe(true)
  })

  it('wählt für beide echten Sitzungen den Fall "Einstieg trägt, darunter Lücken"', () => {
    // Genau dieser Fall fehlte bis R4 — der Renderer behauptete stattdessen,
    // das Einstiegsthema säße noch nicht sicher.
    expect(sucheFall(baueFundament(TOLUNAY)!)).toBe('einstieg_traegt_fundament_luecken')
    expect(sucheFall(baueFundament(RASIT)!)).toBe('einstieg_traegt_fundament_luecken')
  })

  it('trennt "nichts darunter geprüft" von "darunter trägt nicht"', () => {
    const nurEinstieg = baueFundament([s('a', 8, 'traegt'), s('b', 8, 'traegt')])!
    expect(nurEinstieg.einstiegTraegt).toBe(true)
    expect(nurEinstieg.fundamentGeprueft).toBe(false)
    expect(nurEinstieg.fundamentTraegt).toBe(false)
    // Kein Abstieg stattgefunden -> kein Satz darüber.
    expect(sucheFall(nurEinstieg)).toBeNull()
  })

  it('deckt die übrigen drei Fälle ab', () => {
    const allesTraegt = baueFundament([s('a', 8, 'traegt'), s('b', 7, 'traegt')])!
    expect(sucheFall(allesTraegt)).toBe('alles_traegt')

    const einstiegHakt = baueFundament([s('a', 8, 'traegt_nicht'), s('b', 7, 'traegt')])!
    expect(sucheFall(einstiegHakt)).toBe('einstieg_luecken_fundament_traegt')

    const beides = baueFundament([
      s('a', 8, 'traegt_nicht'),
      s('b', 7, 'traegt_nicht'),
    ])!
    expect(sucheFall(beides)).toBe('einstieg_luecken_fundament_luecken')
  })
})

describe('findeEinbruch — der Abstieg ist nicht monoton', () => {
  it('findet bei d8b0d885 die Ebene mit 0 von 2, nicht die unterste', () => {
    const f = baueFundament(TOLUNAY)!
    expect(f.einbruch).not.toBeNull()
    expect(f.einbruch!.delta).toBe(2)
    expect(f.einbruch!.traegt).toBe(0)
    expect(f.einbruch!.geprueft).toBe(2)
  })

  it('meldet für beide echten Sitzungen, dass ganz unten alles trägt', () => {
    expect(baueFundament(TOLUNAY)!.bodenTraegt).toBe(true)
    expect(baueFundament(RASIT)!.bodenTraegt).toBe(true)
  })

  it('wertet den Anteil, nicht die absolute Zahl fehlender Bereiche', () => {
    // 0 von 2 wiegt schwerer als 1 von 4, obwohl dort mehr Bereiche fehlen.
    const einbruch = findeEinbruch([
      { tiefe: 8, delta: 0, geprueft: 2, traegt: 2, labels: [], weitere: 0 },
      { tiefe: 7, delta: 1, geprueft: 4, traegt: 1, labels: [], weitere: 0 },
      { tiefe: 6, delta: 2, geprueft: 2, traegt: 0, labels: [], weitere: 0 },
    ])
    expect(einbruch!.delta).toBe(2)
  })

  it('bevorzugt bei gleichem Anteil die breitere Grundlage', () => {
    const einbruch = findeEinbruch([
      { tiefe: 8, delta: 0, geprueft: 2, traegt: 1, labels: [], weitere: 0 },
      { tiefe: 7, delta: 1, geprueft: 6, traegt: 3, labels: [], weitere: 0 },
    ])
    expect(einbruch!.geprueft).toBe(6)
  })

  it('gibt null zurück, wenn jede Ebene vollständig trägt', () => {
    const f = baueFundament([s('a', 8, 'traegt'), s('b', 7, 'traegt')])!
    expect(f.einbruch).toBeNull()
  })
})
