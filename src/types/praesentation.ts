// Tablet-Präsentation der Lernstandsanalyse (T1–T4).
//
// Reine Ergebnistypen der Rechnung in src/lib/report/praesentation/. Die Zahlen
// kommen aus baueElternbericht (R7) und werden nur nach „übersprungen" weiter
// aufgeteilt. skillKey und Feldschlüssel werden nie gerendert, nur als React-key
// und zum Nachschlagen in i18n.

import type { EbAnliegen, EbBereich, EbeneKey, KopfFall, Lernweg, ThemenfeldKey } from './elternbericht'
import type { Stufe } from './themen'

/** Zählweise „übersprungen" (Entscheidung 4 der Anforderung). */
export type TpAnzeige = 'kombiniert' | 'getrennt'

/** Die Zahlen für Station 02. */
export type TpZahlen = {
  sicher: number
  /** OHNE übersprungen. R7-uebung = uebung + uebersprungen. */
  uebung: number
  uebersprungen: number
  untersucht: number
  katalog: number
  bisKlasse: number
}

/** Eine Zeile des Kompetenzprofils. Listen nach Klasse, dann Label. */
export type TpZeile = {
  feld: ThemenfeldKey
  vorhanden: number
  sicher: EbBereich[]
  /** OHNE übersprungen. */
  uebung: EbBereich[]
  uebersprungen: EbBereich[]
}

/** Eine Ebene der Pyramide, von oben nach unten. */
export type TpEbene = {
  ebene: EbeneKey
  stufen: Stufe[]
  sicher: number
  /** OHNE übersprungen. */
  uebung: number
  uebersprungen: number
}

export type TpSchwerpunkt = {
  /** null beim Thema-Schwerpunkt (R7-11); dann steht das Thema in `thema`. */
  feld: ThemenfeldKey | null
  /** Label des Themas der LSA, nur beim Thema-Schwerpunkt (EbSchwerpunkt.thema). */
  thema: string | null
  gemischt: boolean
  /** Stufen der Übungsbedarf-Bereiche des Felds (inkl. übersprungen), aufsteigend. */
  stufen: Stufe[]
  /** Labels wie R7. `uebung` enthält übersprungene Bereiche. */
  sicher: string[]
  uebung: string[]
}

/** Die zwei Karten in Station 01. */
export type TpUeberblick = {
  gelungen: ThemenfeldKey[]
  ueben: ThemenfeldKey[]
  beispielSicher: { label: string; anzahl: number } | null
  beispielUebung: { label: string; anzahl: number } | null
}

/** Die Empfehlungszeile in Station 04. Nie ein Preis. */
export type TpEmpfehlung = {
  paket: string
  /** Name des ersten Pakets, außer das empfohlene ist schon das erste. */
  basis: string | null
}

/** Seite der Beschriftung an einem Kurvenpunkt. */
export type TpSeite = 'unten' | 'links' | 'linksOben'

/** Ein Punkt auf der Logo-Kurve, Lage in Prozent der viewBox. */
export type TpKurvenPunkt = {
  /** Anteil der Kurvenlänge, 0…1. */
  anteil: number
  x: number
  y: number
  seite: TpSeite
}

/** Drei Zahlen, wie sie je Zählweise erscheinen. */
export type TpAnzeigeZahlen = {
  sicher: number
  uebung: number
  dritte: { wert: number; art: 'davon' | 'eigen' } | null
}

export type PraesentationDaten = {
  name: string | null
  wessen: string | null
  fach: string
  klasse: number
  naechstesThema: string | null
  testlauf: boolean
  laeuftNoch: boolean
  kopfFall: KopfFall
  ueberblick: TpUeberblick
  zahlen: TpZahlen
  zeilen: TpZeile[]
  pyramide: TpEbene[]
  /** Derselbe Lernweg wie bericht.lernweg (R7-9), für Station 03. */
  lernweg: Lernweg | null
  schwerpunkte: TpSchwerpunkt[]
  danach: ThemenfeldKey[]
  empfehlung: TpEmpfehlung | null
  /** „Ihr Anliegen“ wie auf Seite 1 (R7-11, anliegen.ts); null, wenn nichts zu sagen ist. */
  anliegen: EbAnliegen | null
}
