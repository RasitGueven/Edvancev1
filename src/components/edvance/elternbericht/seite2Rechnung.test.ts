import { describe, expect, it } from 'vitest'

import {
  SPUR,
  deutung,
  linienLage,
  luecke,
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
  it('ilkay: eine Zeile je Feld mit Katalogbereichen, ein Segment je Kompetenz', () => {
    const { profil } = bericht('ilkay')
    expect(profil.map((z) => [z.feld, segmente(z).length])).toEqual([
      ['brueche', 8],
      ['prozent', 9],
      ['terme', 23],
      ['geometrie', 40],
      ['groessen', 6],
      ['zahlen', 14],
      ['funktionen', 20],
      ['zufall', 10],
    ])
    for (const z of profil) {
      const s = segmente(z)
      expect(s.filter((x) => x.art === 'sicher')).toHaveLength(z.sicher)
      expect(s.filter((x) => x.art === 'uebung')).toHaveLength(z.uebung)
      expect(s.filter((x) => x.art === 'offen')).toHaveLength(z.vorhanden - z.sicher - z.uebung)
    }
  })

  it('reiht sicher, Übungsbedarf, nicht untersucht', () => {
    expect(segmente(zeile(5, 2, 1)).map((s) => s.art)).toEqual(['sicher', 'sicher', 'uebung', 'offen', 'offen'])
  })

  it('füllt die Spur genau, mit der Lücke nach der Zahl der Segmente', () => {
    for (const [n, l] of [[16, 4], [17, 2], [30, 2], [31, 1]] as const) {
      expect(luecke(n), String(n)).toBe(l)
      const s = segmente(zeile(n))
      expect(s).toHaveLength(n)
      expect(s[1].x - s[0].x - s[0].breite, String(n)).toBeCloseTo(l)
      const letztes = s[n - 1]
      expect(letztes.x + letztes.breite, String(n)).toBeCloseTo(SPUR)
    }
  })

  it('Muster: acht Segmente sind 24,75 pt breit, Radius 3,5', () => {
    const [erstes] = segmente(zeile(8, 2, 3))
    expect(erstes.breite).toBeCloseTo(24.75)
    expect(erstes.radius).toBe(3.5)
  })

  it('Radius höchstens ein Drittel der Segmentbreite', () => {
    const [s] = segmente(zeile(40))
    expect(s.radius).toBeCloseTo(s.breite / 3)
    expect(s.radius).toBeLessThan(3.5)
  })

  it('ohne Katalogbereiche keine Segmente', () => {
    expect(segmente(zeile(0))).toEqual([])
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
