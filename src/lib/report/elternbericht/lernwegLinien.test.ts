import { describe, expect, it } from 'vitest'

import { baueElternbericht } from '@/lib/report/elternbericht/bericht'
import { FAELLE } from '@/lib/report/elternbericht/fixtures'
import { fuehreLinien, gerundet, schneidet, type LinienEingabe, type Rechteck } from '@/lib/report/elternbericht/lernwegLinien'
import type { Lernweg } from '@/types'

const lernwegVon = (fall: string): Lernweg | null => {
  const { data } = FAELLE[fall]
  const e = data.erzaehlung
  return (
    baueElternbericht({ kompetenzen: e.kompetenzen, katalog: e.katalog, klasse: data.grade, lernweg: { erzaehlung: e, datum: data.analysedAt } })
      ?.lernweg ?? null
  )
}

/**
 * Eine vereinfachte Lage wie im Druck (eine Spalte je Zone) oder in der
 * Präsentation (bis 3 Inseln eine Spalte, sonst zwei; die nächste Klasse als
 * eigene Spalte). Höhen geschätzt: Kopf 20, je Eintrag 16, je ↳ 30.
 */
function lage(lw: Lernweg, art: 'druck' | 'praesentation'): LinienEingabe {
  const breite = art === 'druck' ? 110 : 300
  const gasse = art === 'druck' ? 14 : 40
  const oben = art === 'druck' ? 30 : 50
  const spalten: { x0: number; x1: number }[] = []
  const inseln: LinienEingabe['inseln'][number][] = []
  const eintraege: LinienEingabe['eintraege'][number][] = []
  let x = 0
  const spalte = (liste: Lernweg['zonen'][number]['inseln']): void => {
    const s = spalten.length
    spalten.push({ x0: x, x1: x + breite })
    let y = oben
    for (const i of liste) {
      let h = 20
      const start = y
      for (const e of i.eintraege) {
        eintraege.push({ id: e.id, insel: i.id, rect: { x, y: start + h, b: breite, h: 16 } })
        h += 16
        for (const u of e.unter) {
          eintraege.push({ id: u.id, insel: i.id, rect: { x, y: start + h, b: breite, h: 30 } })
          h += 30
        }
      }
      inseln.push({ id: i.id, spalte: s, rect: { x, y: start, b: breite, h: h + 8 } })
      y += h + 8 + 12
    }
    x += breite + gasse
  }
  for (const z of lw.zonen) {
    if (art === 'praesentation' && z.inseln.length > 3) {
      const haelfte = Math.ceil(z.inseln.length / 2)
      spalte(z.inseln.slice(0, haelfte))
      spalte(z.inseln.slice(haelfte))
    } else spalte(z.inseln)
  }
  if (art === 'praesentation' && lw.naechsteKlasse) spalte(lw.naechsteKlasse.inseln)
  const unten = Math.max(oben, ...inseln.map((i) => i.rect.y + i.rect.h)) + 16
  return { spalten, inseln, eintraege, linien: lw.linien, oben, unten }
}

const FAELLE_MIT_BOGEN = Object.keys(FAELLE).filter((f) => lernwegVon(f) !== null)

describe('fuehreLinien (Entscheidung 11)', () => {
  for (const art of ['druck', 'praesentation'] as const) {
    it(`keine Linie schneidet eine Insel — alle Fälle, Lage ${art}`, () => {
      for (const fall of FAELLE_MIT_BOGEN) {
        const e = lage(lernwegVon(fall)!, art)
        const pfade = fuehreLinien(e)
        expect(pfade, fall).toHaveLength(e.linien.length)
        for (const p of pfade) {
          for (let i = 1; i < p.punkte.length; i++) {
            const [a, b] = [p.punkte[i - 1], p.punkte[i]]
            // Achsparallel: kein Stück läuft quer über die Fläche.
            expect(a.x === b.x || a.y === b.y, `${fall} ${p.von}→${p.zu} schräg`).toBe(true)
            for (const insel of e.inseln) {
              expect(schneidet(a, b, insel.rect), `${fall} ${p.von}→${p.zu} durch ${insel.id}`).toBe(false)
            }
          }
        }
      }
    })
  }

  it('abgestuft: ein Stamm von „Bruch in Dezimalzahl“, die Abzweige gehen dort ab, wo das Ziel liegt', () => {
    const lw = lernwegVon('abgestuft')!
    const pfade = fuehreLinien(lage(lw, 'druck'))
    expect(pfade).toHaveLength(4)
    expect(new Set(pfade.map((p) => p.von)).size).toBe(1)
    // Alle beginnen am selben Punkt (rechte Kante der Basis) und teilen das erste Stück.
    const [s] = pfade.map((p) => p.punkte[0])
    for (const p of pfade) {
      expect(p.punkte[0]).toEqual(s)
      expect(p.punkte[1].y).toBe(pfade[0].punkte[1].y)
    }
    // Die Abzweige zu Kommt noch (Spalte 4) gehen weiter rechts ab als der zu Rationale Zahlen (Spalte 3):
    // Abzweig = x des letzten senkrechten Stücks vor der Spitze.
    const e = lage(lw, 'druck')
    const abzweig = (p: (typeof pfade)[number]) => p.punkte.at(-3)!.x
    const nachKommt = pfade.filter((p) => p.punkte.at(-1)!.x === e.spalten[3].x0)
    const nachAktuell = pfade.filter((p) => p.punkte.at(-1)!.x === e.spalten[2].x0)
    expect(nachKommt.length).toBe(2)
    expect(nachAktuell.length).toBe(1)
    for (const k of nachKommt) expect(abzweig(k)).toBeGreaterThan(abzweig(nachAktuell[0]))
    expect(abzweig(nachAktuell[0])).toBeGreaterThan(e.spalten[1].x1)
  })

  it('Ziel in derselben Spalte: um die Gasse herum, Spitze von rechts', () => {
    const rect = (y: number): Rechteck => ({ x: 0, y, b: 100, h: 30 })
    const [p] = fuehreLinien({
      spalten: [{ x0: 0, x1: 100 }, { x0: 120, x1: 220 }],
      inseln: [
        { id: 'a', spalte: 0, rect: rect(10) },
        { id: 'b', spalte: 0, rect: rect(60) },
      ],
      eintraege: [
        { id: 'e1', insel: 'a', rect: { x: 0, y: 15, b: 100, h: 16 } },
        { id: 'e2', insel: 'b', rect: { x: 0, y: 65, b: 100, h: 16 } },
      ],
      linien: [{ von: 'e1', zu: 'e2' }],
      oben: 0,
      unten: 120,
    })
    expect(p.punkte[0].x).toBe(100)
    expect(p.punkte.at(-1)).toEqual({ x: 100, y: 73 })
    expect(Math.max(...p.punkte.map((q) => q.x))).toBeGreaterThan(100)
  })

  it('wählt einen freien Gang, wenn die Höhe der Basis versperrt ist', () => {
    const pfade = fuehreLinien({
      spalten: [{ x0: 0, x1: 100 }, { x0: 120, x1: 220 }, { x0: 240, x1: 340 }],
      inseln: [
        { id: 'a', spalte: 0, rect: { x: 0, y: 10, b: 100, h: 30 } },
        { id: 'm', spalte: 1, rect: { x: 120, y: 0, b: 100, h: 60 } },
        { id: 'z', spalte: 2, rect: { x: 240, y: 10, b: 100, h: 30 } },
      ],
      eintraege: [
        { id: 'e1', insel: 'a', rect: { x: 0, y: 15, b: 100, h: 16 } },
        { id: 'e2', insel: 'z', rect: { x: 240, y: 15, b: 100, h: 16 } },
      ],
      linien: [{ von: 'e1', zu: 'e2' }],
      oben: 0,
      unten: 100,
    })
    const waagrecht = pfade[0].punkte.filter((q, i, a) => i > 0 && a[i - 1].y === q.y && Math.abs(a[i - 1].x - q.x) > 50)
    expect(waagrecht[0].y).toBeGreaterThanOrEqual(65)
  })

  it('rundet Ecken (Q) und lässt gerade Stücke gerade', () => {
    expect(gerundet([{ x: 0, y: 0 }, { x: 10, y: 0 }], 6)).toBe('M0 0 L10 0')
    expect(gerundet([{ x: 0, y: 0 }, { x: 20, y: 0 }, { x: 20, y: 20 }], 6)).toBe('M0 0 L14 0 Q20 0 20 6 L20 20')
  })
})
