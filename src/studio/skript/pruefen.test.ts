import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import { skriptPruefen } from './pruefen'
import { zahlenIn, zahlwort, formelImText } from './zahlen'
import type { Skript } from './typen'

/** Test-Katalog: Schlüssel der Referenz-Skripte und aus Konzept Sessionreihe 1 §8. */
export const TEST_KATALOG = new Set([
  'haelfte_statt_wurzel',
  'flaeche_mit_umfang_verwechselt',
  'quadriert_statt_wurzel',
  'qf_quadrat_negativ',
  'qf_streckfaktor_umgekehrt',
  'qf_verschiebung_vorzeichen',
  'qf_ergaenzung_nicht_abgezogen',
  'qf_nur_positive_loesung',
  'qf_null_vergessen',
  'qf_halbes_p_nicht_quadriert',
  'qf_scheitel_statt_nullstelle',
])

const laden = (name: string) => JSON.parse(readFileSync(`docs/reihe1/referenz/${name}`, 'utf8')) as Skript
const kopie = <T,>(x: T): T => JSON.parse(JSON.stringify(x)) as T

describe('Zahlwörter', () => {
  it('liest zusammengesetzte Zahlwörter', () => {
    expect(zahlwort('neunundvierzig')).toBe(49)
    expect(zahlwort('einundzwanzig')).toBe(21)
    expect(zahlwort('vierhundertsechsundneunzig')).toBe(496)
    expect(zahlwort('viertausendsechsundneunzig')).toBe(4096)
    expect(zahlwort('hundert')).toBe(100)
    expect(zahlwort('ein')).toBeNull()
    expect(zahlwort('achtung')).toBeNull()
  })
  it('Ziffern und Wörter ergeben dieselben Werte', () => {
    expect([...zahlenIn('7 · 7 = 49')].sort()).toEqual(['49', '7'])
    expect([...zahlenIn('sieben mal sieben ergibt neunundvierzig')].sort()).toEqual(['49', '7'])
    expect([...zahlenIn('drei Viertel')].sort()).toEqual(['1/4', '3'])
  })
  it('erkennt Formeln im Sprechtext', () => {
    expect(formelImText('drei Viertel')).toBeNull()
    expect(formelImText('3/4 vom Kuchen')).toBe('/')
    expect(formelImText('x² ist nie negativ')).toBe('²')
    expect(formelImText('die p-q-Formel')).toBeNull()
  })
})

describe('Importprüfung', () => {
  it('Referenz-Skript Quadratwurzel importiert ohne Befund', () => {
    const e = skriptPruefen(laden('quadratwurzel-skript.json'), { katalog: TEST_KATALOG })
    expect(e.befunde.filter((b) => b.stufe !== 'hinweis')).toEqual([])
    expect(e.ok).toBe(true)
    expect(e.gesperrteWelten).toEqual([])
    expect(e.bereiche).toEqual({
      'zahl_wurzel_quadrat:k1': { von: 'b1', bis: 'b7' },
      'zahl_wurzel_quadrat:k2': { von: 'b8', bis: 'b10' },
    })
  })

  it('Musik-b3 sagt „fünfzig“: nur die Musik-Variante ist gesperrt (Abnahmefall 2)', () => {
    const e = skriptPruefen(laden('quadratwurzel-skript-fehler.json'), { katalog: TEST_KATALOG })
    expect(e.ok).toBe(true)
    expect(e.gesperrteWelten).toEqual(['musik'])
    const b = e.befunde.find((x) => x.stufe === 'welt')
    expect(b).toMatchObject({ code: 'zahlen_sperre', beat: 'b3', welt: 'musik', werte: { fehlt: '49', neu: '50' } })
  })

  it('unbekannter Baustein: nichts speicherbar, der Beat steht in der Meldung (Abnahmefall 1)', () => {
    const s = laden('quadratwurzel-skript.json')
    s.beats[3].baustein = 'zauberwuerfel'
    const e = skriptPruefen(s, { katalog: TEST_KATALOG })
    expect(e.ok).toBe(false)
    expect(e.skript).toBeNull()
    expect(e.befunde).toContainEqual(
      expect.objectContaining({ stufe: 'sperre', code: 'baustein_unbekannt', beat: 'b4' }),
    )
  })

  it.each([
    ['ungültiger Parameter', (s: Skript) => (s.beats[1].params.zeilen = 70), 'param_bereich'],
    ['unbekannter Parameter', (s: Skript) => (s.beats[1].params.farbe = 'rot'), 'param_unbekannt'],
    ['Pflichtparameter fehlt', (s: Skript) => delete s.beats[1].params.zeilen, 'param_fehlt'],
    ['Beat-ID doppelt', (s: Skript) => (s.beats[2].id = 'b2'), 'beat_doppelt'],
    ['Sprungmarke zu lang', (s: Skript) => (s.beats[0].titel = 'x'.repeat(41)), 'sprungmarke_zu_lang'],
    ['Rücksprung ins Leere', (s: Skript) => (s.minichecks[0].optionen[1].ruecksprung = 'b99'), 'ruecksprung_unbekannt'],
    ['Formel im Skelett-Text', (s: Skript) => (s.beats[6].text.skelett = 'Die Wurzel aus 49 ist 7, also √49 = 7.'), 'formel_im_text'],
    ['Fehlbild nicht im Katalog', (s: Skript) => (s.minichecks[0].optionen[1].fehlbild = 'gibt_es_nicht'), 'fehlbild_unbekannt'],
    ['zwei richtige Optionen', (s: Skript) => (s.minichecks[0].optionen[1] = { antwort: '32', richtig: true, rueckmeldung: 'x' }), 'richtig_genau_eine'],
    ['Kernidee zerrissen', (s: Skript) => (s.beats[9].kernidee = 'k1'), 'kernidee_nicht_zusammen'],
  ])('%s sperrt den Import', (_name, aendern, code) => {
    const s = kopie(laden('quadratwurzel-skript.json'))
    aendern(s)
    const e = skriptPruefen(s, { katalog: TEST_KATALOG })
    expect(e.ok).toBe(false)
    expect(e.befunde.map((b) => b.code)).toContain(code)
  })

  it('Formel in einer Variante sperrt nur diese Welt', () => {
    const s = kopie(laden('quadratwurzel-skript.json'))
    s.beats[5].text.gaming = 'Die Seite ist sieben Blöcke lang, denn 7 · 7 = 49.'
    const e = skriptPruefen(s, { katalog: TEST_KATALOG })
    expect(e.ok).toBe(true)
    expect(e.gesperrteWelten).toEqual(['gaming'])
  })

  it('andere Zahlen in der Welt-Fassung der Frage sperren die Welt', () => {
    const s = kopie(laden('quadratwurzel-skript.json'))
    s.minichecks[0].frage.fussball = 'Ein Trainingsfeld hat 81 Platten. Wie lang ist eine Seitenlinie?'
    const e = skriptPruefen(s, { katalog: TEST_KATALOG })
    expect(e.gesperrteWelten).toEqual(['fussball'])
  })

  it('Langform der Kernidee für einen zweiten Skill', () => {
    const s = kopie(laden('quadratwurzel-skript.json'))
    for (const b of s.beats.slice(7)) b.kernidee = 'gleichung_quadr_wurzel:k1'
    const e = skriptPruefen(s, { katalog: TEST_KATALOG })
    expect(e.ok).toBe(true)
    expect(Object.keys(e.bereiche)).toEqual(['zahl_wurzel_quadrat:k1', 'gleichung_quadr_wurzel:k1'])
  })

  it('ohne Katalog werden Fehlbilder nicht geprüft', () => {
    const s = kopie(laden('quadratwurzel-skript.json'))
    s.minichecks[0].optionen[1].fehlbild = 'noch_nicht_im_katalog'
    expect(skriptPruefen(s, { katalog: null }).ok).toBe(true)
  })

  it('Rücksprung ohne Zwilling und Sprung in eine andere Kernidee sind nur Hinweise', () => {
    const e = skriptPruefen(laden('quadratwurzel-skript.json'), { katalog: TEST_KATALOG })
    expect(e.befunde).toContainEqual(expect.objectContaining({ stufe: 'hinweis', code: 'ohne_zwilling' }))
    expect(e.befunde).toContainEqual(
      expect.objectContaining({ stufe: 'hinweis', code: 'ruecksprung_andere_kernidee', werte: { ziel: 'b8' } }),
    )
  })
})
