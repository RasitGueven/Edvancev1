import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import { BAUSTEIN_KOMPONENTEN } from '../remotion/bausteine'
import { BAUSTEINE } from './bausteine'
import { skriptPruefen } from './pruefen'
import type { Skript } from './typen'

const demo = JSON.parse(readFileSync('docs/reihe1/B/abnahme/b7/bausteine-demo.json', 'utf8')) as Skript

describe('Bausteine der Reihe 1 (B7)', () => {
  it('jeder Baustein der Bibliothek hat eine Remotion-Komponente und umgekehrt', () => {
    expect(Object.keys(BAUSTEIN_KOMPONENTEN).sort()).toEqual(Object.keys(BAUSTEINE).sort())
  })
  it('Abnahme-Skript mit beiden Bausteinen ist gültig', () => {
    const e = skriptPruefen(demo, { katalog: new Set() })
    expect(e.befunde.filter((b) => b.stufe !== 'hinweis')).toEqual([])
  })
  it.each([
    ['Parabel mit zwei statt drei Werten', (s: Skript) => (s.beats[0].params.parabel = [1, 0]), 'param_bereich'],
    ['Bereich als Text', (s: Skript) => (s.beats[0].params.x_bereich = '-4 bis 4'), 'param_liste'],
    ['zu viele Werte in der Tabelle', (s: Skript) => (s.beats[0].params.wertetabelle = [1, 2, 3, 4, 5, 6, 7, 8]), 'param_bereich'],
    ['Punkt ohne y', (s: Skript) => (s.beats[0].params.punkte = [[1]]), 'param_liste'],
    ['unbekannte Anzeige im Flächenmodell', (s: Skript) => (s.beats[4].params.zeigen = 'alles'), 'param_wahl'],
    ['Flächenmodell ohne b', (s: Skript) => delete s.beats[4].params.b, 'param_fehlt'],
    ['b negativ', (s: Skript) => (s.beats[4].params.b = -6), 'param_bereich'],
  ])('%s wird abgelehnt', (_n, aendern, code) => {
    const s = JSON.parse(JSON.stringify(demo)) as Skript
    aendern(s)
    expect(skriptPruefen(s, { katalog: null }).befunde.map((b) => b.code)).toContain(code)
  })
})
