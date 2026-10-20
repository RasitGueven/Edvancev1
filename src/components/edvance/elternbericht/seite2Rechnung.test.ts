import { describe, expect, it } from 'vitest'

import {
  LUECKE,
  SPUR,
  deutung,
  gepruefteZeilen,
  linienLage,
  segmentBreite,
  segmente,
  teile,
  zeilenAbstand,
} from '@/components/edvance/elternbericht/seite2Rechnung'
import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import type { EbProfilZeile, Elternbericht } from '@/types'

const bericht = (fall: keyof typeof FAELLE): Elternbericht => {
  const { data } = FAELLE[fall]
  const b = baueElternbericht({
    kompetenzen: data.erzaehlung.kompetenzen,
    katalog: data.erzaehlung.katalog,
    klasse: data.grade,
  })
  if (!b) throw new Error(fall)
  return b
}

const zeile = (vorhanden: number, sicher = 0, uebung = 0): EbProfilZeile => ({
  feld: 'brueche',
  vorhanden,
  sicher,
  uebung,
})

describe('segmente', () => {
  it('ilkay: nur Felder mit geprüften Bereichen, ein Segment je geprüftem Bereich', () => {
    const profil = gepruefteZeilen(bericht('ilkay').profil)
    expect(profil.map((z) => [z.feld, segmente(z).length])).toEqual([
      ['brueche', 5],
      ['prozent', 4],
      ['terme', 4],
      ['geometrie', 6],
      ['groessen', 5],
      ['zahlen', 3],
    ])
    for (const z of profil) {
      const s = segmente(z)
      expect(s.filter((x) => x.art === 'sicher')).toHaveLength(z.sicher)
      expect(s.filter((x) => x.art === 'uebung')).toHaveLength(z.uebung)
    }
  })

  it('reiht erst sicher, dann Übungsbedarf — nichts für nicht Geprüftes', () => {
    expect(segmente(zeile(5, 2, 1)).map((s) => s.art)).toEqual(['sicher', 'sicher', 'uebung'])
  })

  it('Breite min(18, (226 − (n − 1) · 4) / n) für n = 1, 5, 12, 40', () => {
    expect(segmentBreite(1)).toBe(18)
    expect(segmentBreite(5)).toBe(18)
    expect(segmentBreite(12)).toBeCloseTo((226 - 11 * 4) / 12) // 15,17
    expect(segmentBreite(40)).toBeCloseTo((226 - 39 * 4) / 40) // 1,75
  })

  it('linksbündig mit Lücke 4 pt, nie breiter als die Spur', () => {
    for (const n of [1, 5, 12, 40]) {
      const s = segmente(zeile(n, n, 0))
      expect(s, String(n)).toHaveLength(n)
      expect(s[0].x).toBe(0)
      if (n > 1) expect(s[1].x - s[0].x - s[0].breite, String(n)).toBeCloseTo(LUECKE)
      const letztes = s[n - 1]
      expect(letztes.x + letztes.breite, String(n)).toBeLessThanOrEqual(SPUR + 1e-9)
    }
    // Ein geprüfter Bereich füllt die Spur nicht.
    expect(segmente(zeile(1, 1, 0))[0].breite).toBe(18)
  })

  it('Radius min(3,5, Breite / 3)', () => {
    expect(segmente(zeile(1, 1, 0))[0].radius).toBe(3.5)
    const [s] = segmente(zeile(40, 40, 0))
    expect(s.radius).toBeCloseTo(s.breite / 3)
    expect(s.radius).toBeLessThan(3.5)
  })

  it('ohne geprüften Bereich keine Segmente', () => {
    expect(segmente(zeile(8))).toEqual([])
  })
})

describe('gepruefteZeilen', () => {
  it('nur Felder mit mindestens einem geprüften Bereich, Reihenfolge bleibt', () => {
    for (const fall of ['ilkay', 'allesSicher', 'weitereBereiche'] as const) {
      const alle = bericht(fall).profil
      const z = gepruefteZeilen(alle)
      expect(z.every((x) => x.sicher + x.uebung > 0), fall).toBe(true)
      expect(z.map((x) => x.feld), fall).toEqual(alle.filter((x) => x.sicher + x.uebung > 0).map((x) => x.feld))
    }
    expect(gepruefteZeilen(bericht('weitereBereiche').profil).at(-1)!.feld).toBe('weitere')
  })
})

describe('zeilenAbstand und teile', () => {
  it('40,8 pt bis sechs Zeilen, ab sieben 33,4 pt', () => {
    expect(zeilenAbstand(6)).toBe(40.8)
    expect(zeilenAbstand(7)).toBe(33.4)
    expect(zeilenAbstand(8)).toBe(33.4)
    expect(zeilenAbstand(9)).toBe(30)
  })

  it('Trennlinie zwischen Unterzeile (Grundlinie 20) und nächster Spur', () => {
    for (const n of [6, 7, 9]) {
      const a = zeilenAbstand(n)
      expect(linienLage(a)).toBeGreaterThan(22)
      expect(linienLage(a)).toBeLessThan(a - 3)
    }
  })

  it('nennt nur die von null verschiedenen Teile', () => {
    expect(teile(zeile(5, 2, 0))).toEqual([{ art: 'sicher', anzahl: 2 }])
    expect(teile(zeile(5, 0, 3))).toEqual([{ art: 'uebung', anzahl: 3 }])
    expect(teile(zeile(5, 2, 3))).toEqual([
      { art: 'sicher', anzahl: 2 },
      { art: 'uebung', anzahl: 3 },
    ])
    expect(teile(zeile(5))).toEqual([])
  })
})

describe('deutung', () => {
  it('ilkay: je höchstens zwei Felder, keins in beiden Sätzen', () => {
    // Profil ilkay: brueche 2/3, prozent 1/3, terme 2/2, geometrie 1/5, groessen 3/2, zahlen 2/1
    const d = deutung(bericht('ilkay').profil)
    expect(d.sicher).toEqual(['groessen', 'zahlen'])
    expect(d.uebung).toEqual(['geometrie', 'brueche'])
  })

  it('allesSicher: nur der Sicher-Satz', () => {
    const d = deutung(bericht('allesSicher').profil)
    expect(d.sicher.length).toBeGreaterThan(0)
    expect(d.uebung).toEqual([])
  })

  it('nichtsSicher: nur der Übungs-Satz', () => {
    const d = deutung(bericht('nichtsSicher').profil)
    expect(d.sicher).toEqual([])
    expect(d.uebung.length).toBeGreaterThan(0)
  })

  it('kein Feld steht in beiden Sätzen, Gleichstand nach Reihenfolge der Felder', () => {
    for (const fall of Object.keys(FAELLE).filter((f) => f !== 'ohneKatalog')) {
      const d = deutung(bericht(fall as keyof typeof FAELLE).profil)
      expect(d.sicher.filter((f) => d.uebung.includes(f)), fall).toEqual([])
    }
    const d = deutung([
      { feld: 'terme', vorhanden: 5, sicher: 0, uebung: 2 },
      { feld: 'brueche', vorhanden: 5, sicher: 0, uebung: 2 },
      { feld: 'zahlen', vorhanden: 5, sicher: 0, uebung: 3 },
    ])
    expect(d.uebung).toEqual(['zahlen', 'terme'])
  })
})
