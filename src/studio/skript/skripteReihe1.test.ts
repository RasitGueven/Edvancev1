import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import { skriptPruefen } from './pruefen'
import type { Skript } from './typen'

/**
 * B8: Die acht Skripte V1–V8 der Reihe 1 bestehen die Importprüfung — gegen den Fehlbild-Katalog von Auftrag A
 * (Stand der qf_-Schlüssel in Prod, docs/reihe1/B/skripte/katalog-qf.json) und nach den Regeln aus Konzept §8.
 */
const ORDNER = 'docs/reihe1/B/skripte'
const katalog = new Set(JSON.parse(readFileSync(`${ORDNER}/katalog-qf.json`, 'utf8')) as string[])
const laden = (n: number) => JSON.parse(readFileSync(`${ORDNER}/V${n}.json`, 'utf8')) as Skript

/** Fehlbild und Rücksprung je Video laut Konzept §8. */
const PFLICHT: Record<number, [string, string]> = {
  1: ['qf_quadrat_negativ', 'Ein Quadrat ist nie negativ'],
  2: ['qf_streckfaktor_umgekehrt', 'a = 2 im Vergleich'],
  3: ['qf_verschiebung_vorzeichen', 'Wo wird die Klammer null?'],
  4: ['qf_ergaenzung_nicht_abgezogen', 'Was wir dazugeben, ziehen wir ab'],
  5: ['qf_nur_positive_loesung', 'Auch (−3)² = 9'],
  6: ['qf_null_vergessen', 'Ein Faktor ist x selbst'],
  7: ['qf_halbes_p_nicht_quadriert', 'Die Ergänzung'],
  8: ['qf_scheitel_statt_nullstelle', 'f(x) = 0'],
}

describe.each([1, 2, 3, 4, 5, 6, 7, 8])('Skript V%i', (n) => {
  const s = laden(n)
  const e = skriptPruefen(s, { katalog })

  it('besteht die Importprüfung ohne Sperre und ohne gesperrte Welt', () => {
    expect(e.befunde.filter((b) => b.stufe !== 'hinweis')).toEqual([])
    expect(e.ok).toBe(true)
  })
  it('Sprechtext ohne Ziffern (Zahlen ausgeschrieben)', () => {
    expect(e.befunde.filter((b) => b.code === 'ziffer_im_text')).toEqual([])
  })
  it('6–12 Beats, 2–3 Mini-Checks, jeder mit Zwilling (andere Zahlen)', () => {
    expect(s.beats.length).toBeGreaterThanOrEqual(6)
    expect(s.beats.length).toBeLessThanOrEqual(12)
    expect(s.minichecks.length).toBeGreaterThanOrEqual(2)
    expect(s.minichecks.length).toBeLessThanOrEqual(3)
    for (const m of s.minichecks) expect(m.zwillinge?.length ?? 0).toBeGreaterThan(0)
  })
  it('Fehlbild und Rücksprung aus Konzept §8', () => {
    const [fehlbild, sprungmarke] = PFLICHT[n]
    const ziel = s.beats.find((b) => b.titel === sprungmarke)
    expect(ziel).toBeDefined()
    const optionen = s.minichecks.flatMap((m) => m.optionen)
    expect(optionen).toContainEqual(expect.objectContaining({ fehlbild, ruecksprung: ziel?.id }))
  })
  it('Zwillinge haben dieselben Fehlbilder wie die Hauptfrage', () => {
    for (const m of s.minichecks) {
      const haupt = m.optionen.map((o) => o.fehlbild ?? (o.richtig ? 'richtig' : '-')).join()
      for (const z of m.zwillinge ?? []) expect(z.optionen.map((o) => o.fehlbild ?? (o.richtig ? 'richtig' : '-')).join()).toBe(haupt)
    }
  })
})
