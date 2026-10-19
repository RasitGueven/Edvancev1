// Eltern-Bericht R7 · Seite 2 — reine Rechnung für das Kompetenzprofil und
// „Was die Grafik zeigt“ (Bauauftrag R7-3, Entscheidung 1).
//
// Die Segmente sind ANZAHLEN, keine Quote: Jede Kompetenz des Felds ist ein
// gleich breites Stück der Spur. Gerechnet wird nur Breite und Lage in pt,
// nie ein Anteil.

import type { EbProfilZeile, ThemenfeldKey } from '@/types'

/** Breite der Spur (Maßblatt, Seite 2: x 229–455). */
export const SPUR = 226

export type SegmentArt = 'sicher' | 'uebung' | 'offen'

export type Segment = {
  art: SegmentArt
  /** Linke Kante relativ zur Spur, in pt. */
  x: number
  breite: number
  radius: number
}

/** Lücke zwischen zwei Segmenten: 4 pt bis 16, 2 pt bis 30, darüber 1 pt. */
export function luecke(anzahl: number): number {
  if (anzahl <= 16) return 4
  if (anzahl <= 30) return 2
  return 1
}

/** Ein Segment je Kompetenz: erst sicher, dann Übungsbedarf, dann nicht untersucht. */
export function segmente(zeile: Pick<EbProfilZeile, 'vorhanden' | 'sicher' | 'uebung'>): Segment[] {
  const n = zeile.vorhanden
  if (n <= 0) return []
  const l = luecke(n)
  const breite = (SPUR - (n - 1) * l) / n
  const radius = Math.min(3.5, breite / 3)
  const arten: SegmentArt[] = [
    ...Array<SegmentArt>(zeile.sicher).fill('sicher'),
    ...Array<SegmentArt>(zeile.uebung).fill('uebung'),
  ]
  while (arten.length < n) arten.push('offen')
  return arten.slice(0, n).map((art, i) => ({ art, x: i * (breite + l), breite, radius }))
}

/**
 * Zeilenabstand der Profilzeilen: 40,8 pt bis sechs Zeilen, ab sieben 33,4 pt.
 * Ab neun Zeilen (acht Themenfelder plus „Weitere Bereiche“) 30 pt — sonst
 * liefe die Seite über; im Auftrag nicht vorgesehen, siehe offene-punkte-r7-3.md.
 */
export function zeilenAbstand(zeilen: number): number {
  if (zeilen <= 6) return 40.8
  return zeilen <= 8 ? 33.4 : 30
}

/** Lage der Trennlinie unter der Spur-Oberkante, passend zum Zeilenabstand. */
export function linienLage(abstand: number): number {
  if (abstand === 40.8) return 31.8
  return abstand === 33.4 ? 27.6 : 25.8
}

/** Die Teile der rechten Unterzeile, nur die von null verschiedenen. */
export function teile(zeile: Pick<EbProfilZeile, 'sicher' | 'uebung'>): { art: 'sicher' | 'uebung'; anzahl: number }[] {
  return [
    { art: 'sicher' as const, anzahl: zeile.sicher },
    { art: 'uebung' as const, anzahl: zeile.uebung },
  ].filter((t) => t.anzahl > 0)
}

export type Deutung = {
  /** Felder mit mehr sicheren als Übungsbedarf-Bereichen, höchstens zwei. */
  sicher: ThemenfeldKey[]
  /** Übrige Felder mit Übungsbedarf, höchstens zwei. */
  uebung: ThemenfeldKey[]
}

/**
 * „Was die Grafik zeigt“: welche Felder in welchem Satz stehen.
 *
 * Jedes Feld zählt für höchstens einen Satz. Je Satz nach der jeweiligen Anzahl
 * absteigend, Gleichstand nach der Reihenfolge der Felder (= Reihenfolge des
 * Profils), höchstens zwei.
 */
export function deutung(profil: readonly EbProfilZeile[]): Deutung {
  const sicher: { feld: ThemenfeldKey; n: number; i: number }[] = []
  const uebung: { feld: ThemenfeldKey; n: number; i: number }[] = []
  profil.forEach((z, i) => {
    if (z.sicher > z.uebung) sicher.push({ feld: z.feld, n: z.sicher, i })
    else if (z.uebung > 0) uebung.push({ feld: z.feld, n: z.uebung, i })
  })
  const auswahl = (liste: typeof sicher): ThemenfeldKey[] =>
    [...liste]
      .sort((a, b) => b.n - a.n || a.i - b.i)
      .slice(0, 2)
      .map((x) => x.feld)
  return { sicher: auswahl(sicher), uebung: auswahl(uebung) }
}
