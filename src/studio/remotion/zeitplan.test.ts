import { describe, expect, it } from 'vitest'
import { frameVonBeat, kapitel, untertitel, zeitplan } from './zeitplan'

const beats = [
  { key: 'b1', titel: 'Worum es geht', dauerMs: 2000, text: 'Quadratwurzeln.' },
  { key: 'b2', titel: 'Ein Quadrat', dauerMs: 3150, text: 'Stell dir ein Quadrat vor.' },
]

describe('Zeitplan', () => {
  it('Beat-Länge = Audio + Pause, auf Frames aufgerundet', () => {
    const z = zeitplan(beats)
    expect(z.beats.map((b) => [b.vonFrame, b.frames])).toEqual([[0, 71], [71, 105]])
    expect(z.frames).toBe(176)
  })
  it('Kapitel und Sprungziel aus derselben Rechnung', () => {
    expect(kapitel(beats)).toEqual([
      { beat: 'b1', start: 0, titel: 'Worum es geht' },
      { beat: 'b2', start: 2.367, titel: 'Ein Quadrat' },
    ])
    expect(frameVonBeat(beats, 'b2') / 30).toBeCloseTo(2.367, 2)
  })
  it('Untertitel im WebVTT-Format', () => {
    expect(untertitel(beats)).toBe(
      'WEBVTT\n\nb1\n00:00:00.000 --> 00:00:02.000\nQuadratwurzeln.\n\nb2\n00:00:02.367 --> 00:00:05.517\nStell dir ein Quadrat vor.\n',
    )
  })
})
