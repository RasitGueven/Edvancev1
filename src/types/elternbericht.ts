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
 * Bericht v2: der halbe Satz „weil …“ zu einem Schwerpunkt. Jede Art ist aus
 * den Daten belegt (schwerpunkte.ts, grundVon), nichts ist frei formuliert.
 */
export type EbGrund =
  /** Thema, die Klassenarbeit dazu steht bevor. */
  | { art: 'klassenarbeit' }
  /** Thema, Stand der Klassenarbeit unbekannt. */
  | { art: 'thema' }
  /** Thema, die Klassenarbeit ist geschrieben. */
  | { art: 'themaGeschrieben' }
  /**
   * Ein kommendes Schulthema baut laut Voraussetzungsgraph direkt darauf auf.
   * Bei mehreren Feldern zum selben Thema aus verschiedenen Klassenbändern dazu
   * das Band und die Stelle („zuerst“ bzw. „danach“, Regel in schwerpunkte.ts).
   */
  | { art: 'naechstesThema'; titel: string; stufe?: Stufe; reihe?: 'zuerst' | 'danach' }
  /** Thema mit geschriebener Klassenarbeit: Ein kommendes Thema baut auf der Lücke auf. */
  | { art: 'spaeterGebraucht'; titel: string }
  /** Übungsbedarf schon im Stoff von Klasse 5/6. */
  | { art: 'grundlagen' }
  /** Sonst: so viele Bereiche mit Übungsbedarf. */
  | { art: 'anzahl'; count: number }

/** Bericht v2, Seite 1: Klassenstufen in „Auf einen Blick“. */
export type EbStufeKey = 'grundlagen' | 'weiterfuehrend' | 'aktuell'
export type EbStufenUrteil = 'sicher' | 'weitgehend' | 'gemischt' | 'luecken'
export type EbStufenZeile = {
  stufe: EbStufeKey
  /** Kleinste und größte Herkunftsklasse der Bereiche dieser Zeile. */
  von: number
  bis: number
  sicher: number
  uebung: number
  urteil: EbStufenUrteil
}

/**
 * Bericht v3, Seite 3: ein Bereich in genau einem Themenblock. `auch` nennt die
 * übrigen kommenden Themen, die ebenfalls direkt darauf aufbauen („betrifft auch …“).
 */
export type EbZuordnung = { label: string; auch: string[] }

/** Bericht v3, Seite 3: ein kommendes Schulthema mit dem, worauf es direkt aufbaut. */
export type EbKommtThema = {
  titel: string
  halbjahr: 1 | 2 | null
  /** Sichere Bereiche, deren Block dieses Thema ist. */
  sitzt: EbZuordnung[]
  /** Bereiche mit Übungsbedarf, deren Block dieses Thema ist. */
  fehlt: EbZuordnung[]
  /** Nur nach dem Ausdünnen: so viele stehen nicht mehr in `sitzt` bzw. `fehlt`. */
  restSitzt?: number
  restFehlt?: number
}

/** Bericht v2, Seite 3: Lücken ohne direkten Bezug zu einem kommenden Thema, je Gruppe. */
export type EbLueckenGruppe = {
  /** Themenfeld; null für das Thema der LSA. */
  feld: ThemenfeldKey | null
  thema: string | null
  /** Nur nach dem Ausdünnen: Lücken, auf denen spätere Themen ohne eigene Zeile aufbauen. */
  spaeter?: boolean
  labels: string[]
  /** Nur nach dem Ausdünnen: so viele Bereiche stehen nicht mehr in `labels`. */
  rest?: number
}

/** Bericht v3, Seite 3: erst was sitzt, dann was fehlt, je kommendem Thema. */
export type EbLueckenweg = {
  /** Kommende Themen mit mindestens einem eigenen Bereich, in Plan-Reihenfolge. */
  themen: EbKommtThema[]
  /** Sichere Bereiche ohne kommendes Thema („Weitere Stärken“). */
  weitereStaerken: string[]
  /** Nur nach dem Ausdünnen: so viele weitere Stärken stehen nicht mehr in der Liste. */
  weitereStaerkenRest?: number
  /** Bereiche mit Übungsbedarf ohne kommendes Thema, je Gruppe („Weitere Bereiche …“). */
  weitere: EbLueckenGruppe[]
  quelle: 'schule' | 'klp'
  schulname: string | null
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
  /** Bericht v2: je Schwerpunkt (gleiche Reihenfolge) der Grund „weil …“. */
  gruende?: EbGrund[]
  /** Bericht v2, Seite 1: eine Zeile je Klassenstufe mit geprüften Bereichen. */
  stufen?: EbStufenZeile[]
  /** Bericht v2, Seite 3; null ohne Lernweg-Quelle. */
  lueckenweg?: EbLueckenweg | null
}

/* ─── Lernweg (R7-9): Seite 3 und Station 03 ──────────────────────────────── */

/** Zonen des Lernwegs von links nach rechts. */
export type LwZoneKey = 'grundlagen' | 'weiterfuehrend' | 'aktuell' | 'kommt'

/**
 * offen = „noch nicht geprüft“ (leerer Kreis); vorgriff = geprüft, aber noch
 * nicht behandelt und noch nicht sicher (LSA-V2, leerer Kreis in Kommt noch).
 */
export type LwStand = 'sicher' | 'uebung' | 'offen' | 'vorgriff'

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
  /** Nur nach dem Kürzen (R7-12): die Zeile „+ n weitere“. */
  weitere?: LwWeitere
}

/**
 * „+ n weitere“ als letzte Zeile einer gekürzten Insel (R7-12, Entscheidung 4):
 * kein Eintrag, kein Punkt, keine Linie. Labels in der Reihenfolge der Insel.
 */
export type LwWeitere = { uebung: number; sicher: number; offen: number; vorgriff: number; labels: string[] }

/** Eine Zählzeile einer zusammengefassten Zone: „<Themenfeld>: n sicher · m Übungsbedarf“. */
export type LwZaehlzeile = { feld: ThemenfeldKey; sicher: number; uebung: number }

/**
 * Eine zusammengefasste Zone (R7-12, Entscheidung 5): keine Inseln, je
 * Themenfeld eine Zählzeile. Linien, die in der Zone beginnen, beginnen an `id`.
 */
export type LwZusammen = { id: string; zeilen: LwZaehlzeile[] }

export type LwZone = {
  key: LwZoneKey
  inseln: LwInsel[]
  /** Nur nach dem Kürzen (R7-12); dann ist `inseln` leer. */
  zusammen?: LwZusammen
}

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
  /**
   * Was die Grenzen weggelassen haben (Entscheidung 8 und 18) — erscheint nicht.
   * R7-12: `eintraege` = Zeilen hinter „+ n weitere“, `zonen` = zusammengefasste Zonen.
   */
  weggelassen: { linien: number; offen: number; kommt: number; eintraege: number; zonen: number }
}
