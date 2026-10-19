// Eltern-Bericht R7 — der Druckbogen nach Muster E7.
//
// Reine Ergebnistypen der Rechnung in src/lib/report/elternbericht/. Keine
// Datenbank, kein Text: Anzeige läuft über den i18n-Namespace `elternbericht`.
// skillKey und die Schlüssel der Themenfelder sind interne Werte und werden
// NIE gerendert (INV-4.3) — nur als React-key und zum Nachschlagen in i18n.

import type { Stufe } from './themen'

/**
 * Die acht Themenfelder des Berichts plus `weitere` (nur, falls belegt).
 * Reihenfolge und Zuordnung: THEMENFELDER in themenfelder.ts.
 */
export type ThemenfeldKey =
  | 'brueche'
  | 'prozent'
  | 'terme'
  | 'geometrie'
  | 'groessen'
  | 'zahlen'
  | 'funktionen'
  | 'zufall'
  | 'weitere'

/** Ebene der Pyramide, von oben nach unten. Nie aus fundament_tiefe. */
export type EbeneKey = 'spaeter' | 'aktuell' | 'weiterfuehrend' | 'grundlagen'

/** Fall der Überschrift auf Seite 1 (report_bausteine, slot 'kopf'). */
export type KopfFall = 'gemischt' | 'sicher' | 'uebung'

/** Ein Skill des Katalogs mit seiner Herkunftsklasse (skills.klasse_herkunft). */
export type KatalogSkill = {
  skillKey: string
  klasse: number
}

/** Ein direkt geprüfter Bereich (= Skill), eingeordnet. */
export type EbBereich = {
  skillKey: string
  label: string
  feld: ThemenfeldKey
  /** skills.klasse_herkunft */
  klasse: number
  /** zustand = 'traegt'. Alles andere ist Übungsbedarf. */
  sicher: boolean
}

/** Die Zahlen für Seite 1 und 2. */
export type EbZaehlung = {
  untersucht: number
  sicher: number
  uebung: number
  /** Skills bis Klasse `bisKlasse`, vereinigt mit allen untersuchten. */
  katalog: number
  /** katalog − untersucht, nie negativ. */
  offen: number
  /** min(Klasse der Sitzung, höchste klasse_herkunft im Katalog). */
  bisKlasse: number
}

/** Eine Zeile des Kompetenzprofils (Seite 2). Nur Felder mit vorhanden > 0. */
export type EbProfilZeile = {
  feld: ThemenfeldKey
  /** Katalogbereiche des Felds — Summe über alle Zeilen = katalog. */
  vorhanden: number
  sicher: number
  uebung: number
}

/** Ein Themenfeld innerhalb einer Ebene: erst sicher, dann Übungsbedarf. */
export type EbGruppe = {
  feld: ThemenfeldKey
  eintraege: EbBereich[]
}

export type EbEbene = {
  ebene: EbeneKey
  /** Die enthaltenen Lehrplanstufen, aufsteigend (für die Klassenangabe). */
  stufen: Stufe[]
  sicher: number
  uebung: number
  gruppen: EbGruppe[]
}

export type EbSchwerpunkt = {
  feld: ThemenfeldKey
  /** Im Feld gibt es Sicheres und Übungsbedarf. */
  gemischt: boolean
  /** Labels, sortiert nach Klasse und Label. */
  sicher: string[]
  uebung: string[]
}

/** Alles, was die fünf Seiten aus den Kompetenzen rechnen. */
export type Elternbericht = {
  zaehlung: EbZaehlung
  profil: EbProfilZeile[]
  /** Ebenen von oben nach unten, nur nicht leere. */
  pyramide: EbEbene[]
  /** Höchstens vier, in der Reihenfolge aus Entscheidung 7. */
  schwerpunkte: EbSchwerpunkt[]
  /** Die übrigen Felder mit Übungsbedarf, in derselben Reihenfolge. */
  danach: ThemenfeldKey[]
  /** Seite 1: nach Themenfeld, Klasse, Label. */
  sicherListe: EbBereich[]
  uebungListe: EbBereich[]
  kopfFall: KopfFall
}
