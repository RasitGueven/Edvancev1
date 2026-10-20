// Eltern-Bericht R7 · Seite 2 — reine Rechnung für das Kompetenzprofil und
// „Was die Grafik zeigt“ (Bauauftrag R7-3, Entscheidung 1).
//
// Die Kästchen sind ANZAHLEN, keine Quote: Jeder geprüfte Bereich ist ein
// Kästchen fester Breite, linksbündig; Nicht-Geprüftes bekommt keins (R7-6,
// Entscheidung 3). Seit R7-8 haben alle Zeilen einen Maßstab, und bei
// abgestufter LSA stehen die abgeleiteten Bereiche des Themas als Umriss
// dahinter. Gerechnet wird nur Breite und Lage in pt, nie ein Anteil.

import type { AbgeleiteterBereich } from '@/lib/report/elternbericht/themaAbdeckung'
import { THEMENFELDER } from '@/lib/report/elternbericht/themenfelder'
import type { EbBereich, EbProfilZeile, ThemenfeldKey } from '@/types'

/** Breite der Spur (Maßblatt, Seite 2: x 229–455). */
export const SPUR = 226

/**
 * Spur, sobald das Profil abgeleitete Bereiche hat (R7-8): Die rechte Zeile
 * „12 geprüft · 14 abgeleitet“ braucht rund 89 pt; mit 206 pt endet die Spur
 * mindestens 6 pt davor. Gilt dann für alle Zeilen, damit der Maßstab gleich bleibt.
 */
export const SPUR_MIT_ABGELEITETEN = 206

/** Höchstbreite eines Kästchens — auch die längste Zeile bleibt so ruhig (R7-8). */
export const KAESTCHEN_MAX = 28

/** Farbig für direkt Geprüftes; `abgeleitet` ist nur ein Umriss ohne Zustand (R7-8). */
export type SegmentArt = 'sicher' | 'uebung' | 'abgeleitet'

export type Segment = {
  art: SegmentArt
  /** Linke Kante relativ zur Spur, in pt. */
  x: number
  breite: number
  radius: number
}

/** Ein Maßstab für alle Zeilen: gleiche Kästchen, gleiche Lücke. */
export type Massstab = { breite: number; luecke: number; radius: number }

/** Eine Zeile des Profils: direkt geprüfte Bereiche, abgeleitete, Klassenspanne. */
export type ProfilZeile = {
  feld: ThemenfeldKey
  sicher: number
  uebung: number
  /** Abgeleitete Bereiche des Themas in diesem Feld (nur abgestufte LSA). */
  abgeleitet: number
  /** Kleinste und größte Klasse der Kästchen; null, wenn keins eine Klasse hat. */
  klasse: { von: number; bis: number } | null
}

/** Lücke zwischen zwei Kästchen: 4 pt bis 16 Kästchen, 2 pt bis 30, darüber 1 pt. */
export function luecke(n: number): number {
  if (n <= 16) return 4
  return n <= 30 ? 2 : 1
}

/**
 * Der gemeinsame Maßstab bei höchstens `nMax` Kästchen in einer Zeile:
 * Breite min(28, (Spur − (nMax − 1) · Lücke) / nMax), Radius min(3,5, Breite / 3).
 */
export function massstab(nMax: number, spur = SPUR): Massstab {
  const n = Math.max(1, nMax)
  const l = luecke(n)
  const breite = Math.min(KAESTCHEN_MAX, (spur - (n - 1) * l) / n)
  return { breite, luecke: l, radius: Math.min(3.5, breite / 3) }
}

/** Kästchen einer Zeile (farbig und Umriss). */
export const kaestchen = (z: Pick<ProfilZeile, 'sicher' | 'uebung' | 'abgeleitet'>): number =>
  z.sicher + z.uebung + z.abgeleitet

/**
 * Der Maßstab für ein ganzes Profil: nach der Zeile mit den meisten Kästchen,
 * auf 206 pt Spur, sobald eine Zeile abgeleitete Bereiche hat, sonst 226 pt.
 */
export const massstabFuer = (zeilen: readonly ProfilZeile[]): Massstab =>
  massstab(
    Math.max(1, ...zeilen.map(kaestchen)),
    zeilen.some((z) => z.abgeleitet > 0) ? SPUR_MIT_ABGELEITETEN : SPUR,
  )

/** Je Bereich ein Kästchen: erst sicher, dann Übungsbedarf, dahinter die Umrisse. */
export function segmente(
  zeile: Pick<ProfilZeile, 'sicher' | 'uebung' | 'abgeleitet'>,
  m: Massstab,
): Segment[] {
  const arten: SegmentArt[] = [
    ...Array<SegmentArt>(zeile.sicher).fill('sicher'),
    ...Array<SegmentArt>(zeile.uebung).fill('uebung'),
    ...Array<SegmentArt>(zeile.abgeleitet).fill('abgeleitet'),
  ]
  return arten.map((art, i) => ({ art, x: i * (m.breite + m.luecke), breite: m.breite, radius: m.radius }))
}

/**
 * Die Zeilen des Profils (R7-8), in der Reihenfolge der Themenfelder: jedes
 * Feld mit direkt geprüften oder abgeleiteten Bereichen. Direkt geprüft zählt
 * wie bisher aus `profil` (zaehle bleibt unverändert); `abgeleitet` sind genau
 * die Bereiche aus themaAbdeckung (abgeleiteteBereiche), leer ohne Thema-Satz.
 * Die Klassenspanne nimmt alle Kästchen der Zeile; ein abgeleiteter Bereich
 * ohne Klasse im Katalog zählt für sie nicht.
 */
export function profilZeilen({
  profil,
  bereiche,
  abgeleitet,
}: {
  profil: readonly EbProfilZeile[]
  bereiche: readonly EbBereich[]
  abgeleitet: readonly AbgeleiteterBereich[]
}): ProfilZeile[] {
  return THEMENFELDER.flatMap(({ key }) => {
    const direkt = profil.find((z) => z.feld === key)
    const sicher = direkt?.sicher ?? 0
    const uebung = direkt?.uebung ?? 0
    const abg = abgeleitet.filter((a) => a.feld === key)
    if (sicher + uebung + abg.length === 0) return []
    const klassen = [
      ...bereiche.filter((b) => b.feld === key).map((b) => b.klasse),
      ...abg.map((a) => a.klasse).filter((k): k is number => k !== null),
    ]
    const klasse =
      klassen.length > 0 ? { von: Math.min(...klassen), bis: Math.max(...klassen) } : null
    return [{ feld: key, sicher, uebung, abgeleitet: abg.length, klasse }]
  })
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
export function deutung(profil: readonly Pick<EbProfilZeile, 'feld' | 'sicher' | 'uebung'>[]): Deutung {
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
