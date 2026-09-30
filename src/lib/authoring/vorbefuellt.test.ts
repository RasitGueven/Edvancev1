import { describe, expect, it } from 'vitest'
import { geaenderteSpalten, hatEintraege, LOESUNGS_FELDER, ohneSpalten, spalteVon } from './vorbefuellt'

const m = {
  afb: { art: 'neu' as const, grund: 'g' },
  'parts.2.afb': { art: 'neu' as const, grund: 'g' },
  'correct_answers.1': { art: 'ergaenzt' as const, grund: 'g' },
  solution: { art: 'neu' as const, grund: 'g' },
}

describe('vorbefuellt', () => {
  it('ordnet Schluessel ihrer Spalte zu', () => {
    expect(spalteVon('parts.2.afb')).toBe('parts')
    expect(spalteVon('correct_answers.1')).toBe('correct_answers')
    expect(spalteVon('afb')).toBe('afb')
  })

  it('entfernt die Eintraege gespeicherter Spalten, auch je Teilaufgabe', () => {
    expect(Object.keys(ohneSpalten(m, ['afb', 'parts']))).toEqual(['correct_answers.1', 'solution'])
    expect(ohneSpalten(m, LOESUNGS_FELDER)).toEqual({ afb: m.afb, 'parts.2.afb': m['parts.2.afb'] })
  })

  it('erkennt Loesungs-Eintraege', () => {
    expect(hatEintraege(m, LOESUNGS_FELDER)).toBe(true)
    expect(hatEintraege({ afb: m.afb }, LOESUNGS_FELDER)).toBe(false)
    expect(hatEintraege(undefined)).toBe(false)
  })

  it('findet nur wirklich geaenderte Spalten', () => {
    expect(geaenderteSpalten({ afb: 'I', unit: null, parts: [] }, { afb: 'II', unit: null, parts: [] })).toEqual(['afb'])
  })
})
