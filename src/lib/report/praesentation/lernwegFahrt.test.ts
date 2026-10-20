import { describe, expect, it } from 'vitest'

import { FAHRT, fahrtDauer, fahrtStand, kameraFuer, schiebeDauer, type FahrtGeometrie } from '@/lib/report/praesentation/lernwegFahrt'

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
