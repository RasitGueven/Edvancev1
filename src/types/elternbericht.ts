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

/** Ein Skill des Katalogs mit Herkunftsklasse und Label (skills.klasse_herkunft, skills.label). */
export type KatalogSkill = {
  skillKey: string
  klasse: number
  /** skills.label, roh; Elternbezeichnung über elternLabel (R7-9). */
  label: string
}

/** Eine Kante des Voraussetzungsgraphen (skill_kante): skillKey baut auf voraussetzt auf. */
export type LwKante = { skillKey: string; voraussetzt: string }

/** Heimat-Thema eines Skills (skill_thema): wo der Stoff im Lehrplan eingeführt wird. */
export type HeimatThema = { skillKey: string; themaKey: string }

/** Ein Eintrag im Plan der Klasse: Schulplan (schul_themenplan) oder Kernlehrplan (themen). */
export type PlanEintrag = {
  position: number
  themaKey: string | null
  titel: string
  halbjahr: 1 | 2 | null
}

/**
 * Was im Schuljahr kommt (R7-9, Entscheidung 3): der Schulplan der Schule des
 * Kindes für die Klasse der Sitzung, sonst der Kernlehrplan NRW der Stufe.
 */
export type LernPlan = {
  quelle: 'schule' | 'klp'
  /** schulen.name; null beim Kernlehrplan oder wenn die Schule nicht lesbar ist. */
  schulname: string | null
  klasse: number
  eintraege: PlanEintrag[]
  /** Nur beim Schulplan und nur, wenn es für Klasse + 1 einen gibt. */
  naechsteKlasse: { klasse: number; eintraege: Omit<PlanEintrag, 'halbjahr'>[] } | null
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
  /** Themenfeld; null beim Thema-Schwerpunkt (R7-11). */
  feld: ThemenfeldKey | null
  /**
   * Label des Themas der LSA, nur beim Thema-Schwerpunkt (R7-11, Entscheidung 2):
   * dann ist er immer Schwerpunkt 1 und `feld` ist null.
   */
  thema: string | null
  /** Im Feld gibt es Sicheres und Übungsbedarf. */
  gemischt: boolean
  /** Labels, sortiert nach Klasse und Label; beim Thema in der Thema-Reihenfolge. */
  sicher: string[]
  uebung: string[]
  /** Startstelle im Thema: der erste Bereich mit Übungsbedarf; sonst null. */
  start: string | null
  /**
   * Ein Bereich mit Übungsbedarf im Thema, der direkt auf der Startstelle
   * aufbaut (der erste in der Thema-Reihenfolge); sonst null.
   */
  naechster: string | null
}

/**
 * Das Thema der LSA (R7-11), auch wenn es kein Schwerpunkt ist: Ohne
 * Übungsbedarf im Thema zeigt Seite 1 dann ansatzThemaSicher.
 */
export type EbThema = {
  titel: string
  /** Bereiche mit Übungsbedarf im Themenraum, in der Thema-Reihenfolge. */
  uebung: string[]
}

/**
 * „Ihr Anliegen“ auf Seite 1 und in Station 01 (R7-11, Entscheidung 12):
 * Frage und Antwort. Nur fachliche Anliegen (anliegen.ts).
 */
export type EbAnliegen = {
  /** Label des Themas der LSA; null ohne Thema. */
  thema: string | null
  /** Bereiche mit Übungsbedarf im Themenraum, in der Thema-Reihenfolge. */
  themaUebung: string[]
  /** Die fachlichen Anliegen (Anzeigenamen), in der Reihenfolge der Eltern. */
  punkte: string[]
  /** Schwerpunkt 1 für „Dort setzen wir zuerst an“; null, wenn der Satz entfällt. */
  schwerpunkt: EbSchwerpunkt | null
  /** leads.next_exam_topic, nur ohne Thema der LSA. */
  naechstesThema: string | null
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
  /** Seite 1: nach Themenfeld, Klasse, Label; mit Thema die Bereiche des Themas zuerst (R7-11). */
  sicherListe: EbBereich[]
  uebungListe: EbBereich[]
  kopfFall: KopfFall
  /** Das Thema der LSA (R7-11); null ohne Thema. */
  thema: EbThema | null
  /** Der Lernweg für Seite 3 und Station 03 (R7-9); null ohne Eingabe dafür. */
  lernweg: Lernweg | null
}

/* ─── Lernweg (R7-9): Seite 3 und Station 03 ──────────────────────────────── */

/** Zonen des Lernwegs von links nach rechts. */
export type LwZoneKey = 'grundlagen' | 'weiterfuehrend' | 'aktuell' | 'kommt'

/** offen = „noch nicht geprüft“ (leerer Kreis). */
export type LwStand = 'sicher' | 'uebung' | 'offen'

/** Ein eingerückter Eintrag „↳ Ziel“ unter seiner Basis in derselben Insel. */
export type LwUnter = {
  id: string
  label: string
  stand: LwStand
  /** Die Basen derselben Insel (Kennungen), auf denen das Ziel aufbaut; eine = „baut darauf auf“. */
  basen: string[]
}

export type LwEintrag = {
  /** Eigene Kennung (e1, e2 …), nie der Skill-Schlüssel. */
  id: string
  label: string
  stand: LwStand
  /** Herkunftsklasse; null, wenn unbekannt. */
  klasse: number | null
  /** Stoff einer späteren Klasse als der des Kindes (steht in Aktuell). */
  spaeter: boolean
  unter: LwUnter[]
}

export type LwInsel = {
  /** Eigene Kennung (i1, i2 …). */
  id: string
  zone: LwZoneKey
  /** Themenfeld; null bei Inseln aus dem Plan (Kommt noch). */
  feld: ThemenfeldKey | null
  /** Titel aus dem Plan; null bei Themenfeld-Inseln. */
  titel: string | null
  eintraege: LwEintrag[]
  /** Mindestens 2 mit Übungsbedarf und mehr Übungsbedarf als sicher. */
  broeckelt: boolean
}

export type LwZone = { key: LwZoneKey; inseln: LwInsel[] }

/** Eine goldene Linie: von einer sicheren Basis zu einem Ziel in einer anderen Insel. */
export type LwLinie = { von: string; zu: string }

export type Lernweg = {
  /** Klasse der Sitzung. */
  klasse: number
  zonen: LwZone[]
  linien: LwLinie[]
  /** Nur beim Schulplan mit Plan für Klasse + 1; nur die Präsentation zeigt sie. */
  naechsteKlasse: { klasse: number; inseln: LwInsel[] } | null
  quelle: 'schule' | 'klp'
  schulname: string | null
  /** Label des Themas der Sitzung; null ohne Thema. */
  thema: string | null
  /** Datum der Sitzung (ISO, wie im Kopf von Seite 1) für „Sie sind hier · Monat“. */
  datum: string | null
  /** Was die Grenzen weggelassen haben (Entscheidung 8 und 18) — erscheint nicht. */
  weggelassen: { linien: number; offen: number; kommt: number }
}
