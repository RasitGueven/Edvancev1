import { describe, expect, it } from 'vitest'

import {
  FAHRT,
  fahrtDauer,
  fahrtStand,
  frontBei,
  frontTabelle,
  kameraFuer,
  laufKoordinaten,
  schiebeDauer,
  type FahrtGeometrie,
} from '@/lib/report/praesentation/lernwegFahrt'

// Wie Batu im Prototyp: Spitze 300 → 1560 Entwurfs-px, Skala 1, 1180 px breit.
const G: FahrtGeometrie = { start: 300, ende: 1560, s: 1, breite: 1180, max: 2420 + 48 - 1180 }
const OHNE: FahrtGeometrie = { ...G, start: null, ende: null }
const zeiten = (g: FahrtGeometrie, schritt = 16): number[] =>
  Array.from({ length: Math.ceil(fahrtDauer(g) / schritt) + 20 }, (_, i) => i * schritt)

describe('lernwegFahrt (Entscheidung 24)', () => {
  it('Dauer aus etwa 115 Entwurfs-px/s, begrenzt auf 6–14 s', () => {
    expect(schiebeDauer(G)).toBeCloseTo((1260 / 115) * 1000)
    expect(schiebeDauer({ ...G, ende: 400 })).toBe(6000)
    expect(schiebeDauer({ ...G, ende: 5000 })).toBe(14000)
    expect(schiebeDauer(OHNE)).toBe(0)
  })

  it('wartet 1,5 s bei den Grundlagen', () => {
    expect(fahrtStand(0, G)).toMatchObject({ phase: 'warten', scrollLeft: 0, spitze: 300 })
    expect(fahrtStand(1499, G).phase).toBe('warten')
  })

  it('während der Fahrt: scrollLeft = Spitze · s − 0,62 · Breite (begrenzt)', () => {
    for (const s of [0.55, 1, 1.35]) {
      const g = { ...G, s, max: 2468 * s - 1180 }
      for (const t of zeiten(g)) {
        const st = fahrtStand(t, g)
        if (st.phase !== 'schieben') continue
        const erwartet = Math.max(0, Math.min(g.max, st.spitze! * s - 0.62 * g.breite))
        expect(st.scrollLeft).toBeCloseTo(erwartet, 6)
        expect(st.aufgedeckt).toBe(st.spitze)
      }
    }
  })

  it('die Spitze steigt monoton', () => {
    let vorher = -Infinity
    for (const t of zeiten(G)) {
      const sp = fahrtStand(t, G).spitze!
      expect(sp).toBeGreaterThanOrEqual(vorher)
      vorher = sp
    }
    expect(vorher).toBe(1560)
  })

  it('dann Kamera allein bis zum Ende, Pause, zurück; das Ende liegt bei scrollLeft 0', () => {
    const nachSchieben = FAHRT.warten + schiebeDauer(G)
    expect(fahrtStand(nachSchieben + FAHRT.kamera - 1, G).phase).toBe('kamera')
    expect(fahrtStand(nachSchieben + FAHRT.kamera + 10, G)).toMatchObject({ phase: 'pause', scrollLeft: G.max })
    expect(fahrtStand(nachSchieben + FAHRT.kamera + FAHRT.pause + 10, G).phase).toBe('zurueck')
    expect(fahrtStand(fahrtDauer(G), G)).toMatchObject({ phase: 'fertig', scrollLeft: 0, aufgedeckt: Infinity })
    expect(fahrtStand(fahrtDauer(G) + 5000, G).scrollLeft).toBe(0)
  })

  it('die Kamera fährt am Ende genau dort weiter, wo die Spitze sie gelassen hat', () => {
    const t = FAHRT.warten + schiebeDauer(G)
    expect(fahrtStand(t - 0.001, G).scrollLeft).toBeCloseTo(kameraFuer(1560, G), 1)
    expect(fahrtStand(t, G).scrollLeft).toBeCloseTo(kameraFuer(1560, G), 6)
  })

  it('nach einer Unterbrechung ändert sich scrollLeft nicht mehr', () => {
    for (const tu of [800, 5000, FAHRT.warten + schiebeDauer(G) + 1000, fahrtDauer(G) - 1000]) {
      const dort = fahrtStand(tu, G).scrollLeft
      for (const t of [tu, tu + 16, tu + 3000, tu + 60000]) {
        const st = fahrtStand(t, G, tu)
        expect(st.scrollLeft).toBe(dort)
        expect(st).toMatchObject({ phase: 'fertig', aufgedeckt: Infinity })
      }
    }
  })

  it('ohne Linien: reine Kamerafahrt, die bei den Grundlagen endet', () => {
    expect(fahrtStand(FAHRT.warten + 1, OHNE).phase).toBe('kamera')
    expect(fahrtStand(FAHRT.warten + 1, OHNE).spitze).toBeNull()
    const mitte = fahrtStand(FAHRT.warten + FAHRT.kamera / 2, OHNE)
    expect(mitte.aufgedeckt).toBeCloseTo((mitte.scrollLeft + OHNE.breite) / OHNE.s - FAHRT.vorlauf)
    expect(fahrtStand(fahrtDauer(OHNE), OHNE)).toMatchObject({ phase: 'fertig', scrollLeft: 0 })
  })
})

describe('Laufkoordinate (Nachbesserung R7-9, Entscheidung 4)', () => {
  // Stamm von (300|255) nach rechts bis 1480, eine Linie biegt bei 362 nach unten ab.
  const stamm = [
    { x: 300, y: 255 },
    { x: 1480, y: 255 },
  ]
  const abzweig = [
    { x: 300, y: 255 },
    { x: 362, y: 255 },
    { x: 362, y: 415 },
    { x: 394, y: 415 },
  ]

  it('w = x + senkrechte Wege; der gemeinsame Stamm hat dasselbe w und wächst gleich schnell', () => {
    expect(laufKoordinaten(stamm)).toEqual([300, 1480])
    expect(laufKoordinaten(abzweig)).toEqual([300, 362, 522, 554])
    // Bei w = 340 sind beide 40 px gewachsen: dasselbe Stück, dieselbe Länge.
    expect(laufKoordinaten(stamm)[0]).toBe(laufKoordinaten(abzweig)[0])
  })

  it('ein senkrechtes Stück wächst stetig mit der Spitze, nicht auf einen Schlag', () => {
    const g: FahrtGeometrie = { ...G, start: 300, ende: 554, front: frontTabelle(proben(abzweig)) }
    let vorher = -Infinity
    let senkrechtMax = 0
    for (const t of zeiten(g)) {
      const st = fahrtStand(t, g)
      if (st.phase !== 'schieben') continue
      const w = st.spitze!
      // Gewachsene Länge des senkrechten Stücks (w zwischen 362 und 522).
      const senkrecht = Math.max(0, Math.min(160, w - 362))
      if (vorher !== -Infinity) senkrechtMax = Math.max(senkrechtMax, senkrecht - vorher)
      vorher = senkrecht
    }
    expect(senkrechtMax).toBeLessThan(40)
  })

  it('die Kamera folgt dem größten x der Front; auf dem senkrechten Stück steht sie', () => {
    const tab = frontTabelle(proben(abzweig))
    expect(frontBei(340, tab)).toBe(340)
    expect(frontBei(450, tab)).toBe(362)
    expect(frontBei(554, tab)).toBe(394)
    const g: FahrtGeometrie = { ...G, s: 1, breite: 200, max: 1000, start: 300, ende: 554, front: tab }
    for (const t of zeiten(g)) {
      const st = fahrtStand(t, g)
      if (st.phase !== 'schieben') continue
      expect(st.scrollLeft).toBeCloseTo(kameraFuer(frontBei(st.spitze!, tab), g), 6)
      expect(st.aufgedeckt).toBe(st.front)
    }
  })
})

/** Stichproben alle 4 px entlang eines achsparallelen Linienzugs, mit w. */
function proben(punkte: { x: number; y: number }[]): { w: number; x: number }[] {
  const out: { w: number; x: number }[] = []
  const w = laufKoordinaten(punkte)
  for (let i = 1; i < punkte.length; i++) {
    const [a, b] = [punkte[i - 1], punkte[i]]
    const len = Math.abs(b.x - a.x) + Math.abs(b.y - a.y)
    for (let l = 0; l < len; l += 4) out.push({ w: w[i - 1] + l, x: a.x + (b.x - a.x) * (l / len) })
  }
  out.push({ w: w[w.length - 1], x: punkte[punkte.length - 1].x })
  return out
}
