// tools/formeln-svg.mjs: Formeln der Erklaerschritte als SVG (Bauauftrag E1.4).
// Drei Formeln wie im Auftrag: Bruch, Wurzel, Potenz. Dazu Trockenlauf und Fehlerfall.

import { describe, expect, it, vi } from 'vitest'
import { formelnFinden, lauf, pruefeSvg, schrittFormeln, svgHash, texZuSvg } from '../tools/formeln-svg.mjs'

const INHALT =
  'Die Steigung ist $m = \\frac{\\Delta y}{\\Delta x}$. Die Diagonale ist $\\sqrt{a^2 + b^2}$, die Fläche $x^{2}$.'

describe('formelnFinden', () => {
  it('findet die Formeln in Reihenfolge, wie erklaer_formel_anzahl in SQL', () => {
    expect(formelnFinden(INHALT)).toEqual(['m = \\frac{\\Delta y}{\\Delta x}', '\\sqrt{a^2 + b^2}', 'x^{2}'])
    expect(formelnFinden('ohne Formel, 5 $ Rabatt')).toEqual([])
  })
})

describe('texZuSvg', () => {
  it.each([
    ['Bruch', '\\frac{1}{2}', 'mfrac'],
    ['Wurzel', '\\sqrt{2}', 'msqrt'],
    ['Potenz', '2^{3}', 'msup'],
  ])('%s wird ein eigenstaendiges SVG', (_name, tex, knoten) => {
    const svg = texZuSvg(tex)
    expect(pruefeSvg(svg)).toBeNull()
    expect(svg).toContain(`data-mml-node="${knoten}"`)
    expect(svg).toContain('currentColor')
    expect(svg).not.toContain('<use') // fontCache 'none': keine Verweise auf fremde Glyphen
  })

  it('ist deterministisch: gleiche Formel, gleicher Hash', () => {
    expect(svgHash(texZuSvg('\\frac{1}{2}'))).toBe(svgHash(texZuSvg('\\frac{1}{2}')))
    expect(svgHash(texZuSvg('\\frac{1}{2}'))).toMatch(/^[0-9a-f]{64}$/)
  })

  it('wirft bei einem TeX-Fehler', () => {
    expect(() => texZuSvg('\\frac{1}{')).toThrow(/TeX-Fehler|Formel/)
  })
})

describe('lauf', () => {
  it('Trockenlauf laedt nichts und schreibt nichts', async () => {
    const hochladen = vi.fn()
    const eintragen = vi.fn()
    const log: string[] = []
    const stand = await lauf({
      schritte: [{ id: 's1', inhalt: INHALT }],
      dryRun: true,
      hochladen,
      eintragen,
      log: (z) => log.push(z),
    })
    expect(stand).toEqual({ geladen: 1, uebersprungen: 0, fehler: 0 })
    expect(hochladen).not.toHaveBeenCalled()
    expect(eintragen).not.toHaveBeenCalled()
    expect(log.filter((z) => z.includes('wuerde laden: erklaer/formeln/'))).toHaveLength(3)
  })

  it('laedt je Formel und traegt die Hashes in Reihenfolge ein', async () => {
    const hochladen = vi.fn()
    const eintragen = vi.fn()
    await lauf({ schritte: [{ id: 's1', inhalt: INHALT }], dryRun: false, hochladen, eintragen, log: () => {} })
    const erwartet = schrittFormeln(INHALT).map((f) => f.hash)
    expect(hochladen).toHaveBeenCalledTimes(3)
    expect(hochladen.mock.calls[0][0]).toBe(`erklaer/formeln/${erwartet[0]}.svg`)
    expect(eintragen).toHaveBeenCalledWith('s1', INHALT, erwartet)
  })

  it('faellt eine Formel durch, wird fuer den Schritt nichts geladen', async () => {
    const hochladen = vi.fn()
    const eintragen = vi.fn()
    const stand = await lauf({
      schritte: [{ id: 'kaputt', inhalt: 'gut $\\sqrt{2}$, kaputt $\\frac{1}{$' }],
      dryRun: false,
      hochladen,
      eintragen,
      log: () => {},
    })
    expect(stand.fehler).toBe(1)
    expect(hochladen).not.toHaveBeenCalled()
    expect(eintragen).not.toHaveBeenCalled()
  })
})
