// Bericht v2, Seite 1 „Auf einen Blick“: eine Zeile je Klassenstufe.
import { describe, expect, it } from 'vitest'

import { STUFEN_REGEL } from '@/lib/report/elternbericht/berichtKonfig'
import { baueStufen, lueckenStufe, stufeFuer } from '@/lib/report/elternbericht/stufenBlick'
import type { EbBereich, EbStufenZeile } from '@/types'

let n = 0
const b = (klasse: number, sicher: boolean): EbBereich => ({
  skillKey: `skill_${n++}`,
  label: `Bereich ${n}`,
  feld: 'zahlen',
  klasse,
  sicher,
})
/** `sicher` sichere und `uebung` unsichere Bereiche derselben Klasse. */
const viele = (klasse: number, sicher: number, uebung: number): EbBereich[] => [
  ...Array.from({ length: sicher }, () => b(klasse, true)),
  ...Array.from({ length: uebung }, () => b(klasse, false)),
]
const urteile = (z: EbStufenZeile[]): string[] => z.map((x) => `${x.stufe}:${x.urteil}`)

describe('stufeFuer', () => {
  it('ordnet die Klasse des Bereichs der Stufe des Kindes zu', () => {
    expect(stufeFuer(5, 10)).toBe('grundlagen')
    expect(stufeFuer(6, 10)).toBe('grundlagen')
    expect(stufeFuer(7, 10)).toBe('weiterfuehrend')
    expect(stufeFuer(8, 10)).toBe('weiterfuehrend')
    expect(stufeFuer(9, 10)).toBe('aktuell')
    expect(stufeFuer(10, 10)).toBe('aktuell')
  })

  it('Stoff späterer Klassen zählt zum aktuellen Stoff, nie als eigene Stufe', () => {
    expect(stufeFuer(10, 7)).toBe('aktuell')
    expect(stufeFuer(9, 5)).toBe('aktuell')
  })

  it('beim jüngsten Kind gibt es keine Grundlagen: Klasse 5/6 ist aktuell', () => {
    expect(stufeFuer(5, 6)).toBe('aktuell')
    expect(stufeFuer(6, 5)).toBe('aktuell')
  })
})

describe('baueStufen', () => {
  it('ohne Bereiche keine Zeilen', () => {
    expect(baueStufen([], 10)).toEqual([])
  })

  it('eine Zeile je belegter Stufe, in der Reihenfolge Grundlagen, Weiterführend, Aktuell', () => {
    const zeilen = baueStufen([...viele(9, 1, 0), ...viele(5, 1, 0), ...viele(7, 1, 0)], 10)
    expect(zeilen.map((z) => z.stufe)).toEqual(['grundlagen', 'weiterfuehrend', 'aktuell'])
  })

  it('lässt unbelegte Stufen weg', () => {
    expect(baueStufen(viele(5, 2, 0), 10).map((z) => z.stufe)).toEqual(['grundlagen'])
  })

  it('zählt sicher und Übungsbedarf je Stufe und nennt die Klassenspanne', () => {
    const [z] = baueStufen([b(9, true), b(9, false), b(10, false)], 10)
    expect(z).toMatchObject({ stufe: 'aktuell', von: 9, bis: 10, sicher: 1, uebung: 2 })
  })

  it('Urteil „sicher“ nur, wenn gar kein Übungsbedarf', () => {
    const zeilen = baueStufen([...viele(5, 4, 0), ...viele(7, 3, 0)], 10)
    expect(urteile(zeilen)).toEqual(['grundlagen:sicher', 'weiterfuehrend:sicher'])
  })

  it('Schwellen aus berichtKonfig: weitgehend ab 75 %, gemischt ab 50 %', () => {
    expect(STUFEN_REGEL.weitgehendAnteil).toBe(0.75)
    // 3 von 4 sicher = genau an der Schwelle → weitgehend. Die Stufe daneben
    // hat mehr Übungsbedarf und ist die Lückenstufe.
    const zeilen = baueStufen([...viele(5, 3, 1), ...viele(7, 1, 3)], 10)
    expect(urteile(zeilen)).toEqual(['grundlagen:weitgehend', 'weiterfuehrend:luecken'])
    // Knapp unter 75 %: gemischt.
    const knapp = baueStufen([...viele(5, 5, 2), ...viele(7, 1, 5)], 10)
    expect(urteile(knapp)).toEqual(['grundlagen:gemischt', 'weiterfuehrend:luecken'])
  })

  it('genau die Hälfte Übungsbedarf ist die Lückenstufe, knapp darunter nicht', () => {
    expect(urteile(baueStufen(viele(9, 2, 2), 10))).toEqual(['aktuell:luecken'])
    expect(urteile(baueStufen(viele(9, 3, 2), 10))).toEqual(['aktuell:gemischt'])
  })

  it('Stufe mit weniger als der Hälfte sicher heißt auch ohne Lückenstufen-Rolle „luecken“', () => {
    const zeilen = baueStufen([...viele(5, 1, 3), ...viele(7, 0, 4)], 10)
    // 7/8 hat mehr Übungsbedarf (4 > 3) → Lückenstufe; 5/6 ist mit 25 % sicher
    // nach der Auffangregel (< 50 % sicher) ebenfalls „luecken“.
    expect(urteile(zeilen)).toEqual(['grundlagen:luecken', 'weiterfuehrend:luecken'])
  })

  it('Gleichstand beim Übungsbedarf: die tiefere Stufe ist die Lückenstufe', () => {
    const zeilen = baueStufen([...viele(5, 2, 2), ...viele(9, 0, 2), ...viele(7, 3, 2)], 10)
    expect(lueckenStufe(zeilen)).toBe('grundlagen')
    // Aktuell hat gleich viel Übungsbedarf, ist aber nicht die Lückenstufe → „luecken“ nur über die Auffangregel (0 % sicher).
    expect(zeilen.find((z) => z.stufe === 'weiterfuehrend')?.urteil).toBe('gemischt')
  })

  it('alles sicher bis auf wenig: keine Lückenstufe, Kurzsatz „weitgehend“', () => {
    const zeilen = baueStufen([...viele(5, 9, 1), ...viele(9, 4, 0)], 10)
    expect(urteile(zeilen)).toEqual(['grundlagen:weitgehend', 'aktuell:sicher'])
  })
})

describe('lueckenStufe', () => {
  const z = (stufe: EbStufenZeile['stufe'], sicher: number, uebung: number) => ({ stufe, sicher, uebung })

  it('leere Eingabe und keine Übungsbedarfe → null', () => {
    expect(lueckenStufe([])).toBeNull()
    expect(lueckenStufe([z('grundlagen', 4, 0), z('aktuell', 2, 0)])).toBeNull()
  })

  it('unter der Schwelle (weniger als die Hälfte) → null', () => {
    expect(lueckenStufe([z('aktuell', 4, 1)])).toBeNull()
  })

  it('wählt die Stufe mit dem meisten Übungsbedarf (Anzahl, nicht Anteil)', () => {
    // Grundlagen: 2 von 2 (100 %), Aktuell: 3 von 6 (50 %) → Aktuell hat mehr Übungsbedarf.
    expect(lueckenStufe([z('grundlagen', 0, 2), z('aktuell', 3, 3)])).toBe('aktuell')
  })

  it('Gleichstand: die tiefere (erste) Stufe', () => {
    expect(lueckenStufe([z('grundlagen', 1, 2), z('weiterfuehrend', 0, 2)])).toBe('grundlagen')
  })

  it('die meiste Anzahl kann unter der Schwelle liegen → null, auch wenn eine andere Stufe darüber läge', () => {
    // Aktuell: 4 von 10 (40 %) hat am meisten; Grundlagen: 1 von 1 (100 %) wird nicht gewählt.
    expect(lueckenStufe([z('grundlagen', 0, 1), z('aktuell', 6, 4)])).toBeNull()
  })
})
