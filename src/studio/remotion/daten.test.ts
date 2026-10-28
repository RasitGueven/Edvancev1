import { readFileSync } from 'node:fs'
import { describe, expect, it } from 'vitest'
import type { Skript } from '../skript/typen'
import { videoDatenAus } from './daten'
import { zeitplan } from './zeitplan'

const skript = JSON.parse(readFileSync('docs/reihe1/referenz/quadratwurzel-skript.json', 'utf8')) as Skript

describe('Videodaten je Welt', () => {
  it('Quadratwurzeln in allen vier Welten: eigener Text und Bild der Welt, sonst Skelett', () => {
    for (const welt of ['skelett', 'fussball', 'gaming', 'musik']) {
      const d = videoDatenAus(skript, welt, {})
      expect(d.beats).toHaveLength(10)
      expect(d.beats[1].text).toBe(skript.beats[1].text[welt])
      expect(d.beats[4].text).toBe(skript.beats[4].text.skelett)
      expect(zeitplan(d.beats).frames).toBeGreaterThan(0)
    }
    expect(videoDatenAus(skript, 'gaming', {}).beats[1].bild).toEqual({ einheit: 'Blöcke' })
  })
  it('Audio bestimmt die Dauer', () => {
    const d = videoDatenAus(skript, 'skelett', { b1: { url: 'https://x/a.mp3', dauerMs: 1234 } })
    expect(d.beats[0]).toMatchObject({ audioUrl: 'https://x/a.mp3', dauerMs: 1234 })
    expect(d.beats[1].audioUrl).toBeNull()
  })
})
