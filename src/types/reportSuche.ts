// Eltern-Report — „Wie wir gesucht haben" nach Stufen statt nach Ebenen (W2-7).
//
// fundament_tiefe ist eine Graphposition und keine Aussage, die Eltern lesen
// können. Dieser Abschnitt gliedert deshalb nach dem gewählten Thema
// (lsa_sessions.thema_key), dem Voraussetzungsabschluss seiner Einstiegsknoten
// und der Lehrplanstufe (skills.klasse_herkunft). Rechnung: src/lib/report/suche.ts.

import type { FundamentSkill } from './reportFundament'

/** Lehrplanstufe, dieselben Werte wie themen.stufe. */
export type Stufe = 'erprobung' | 'erste' | 'zweite'

/** Ein direkt geprüfter Skill mit allem, was die Gliederung braucht. */
export type SucheSkill = FundamentSkill & {
  /** skills.klasse_herkunft — daraus folgt die Stufe. */
  klasseHerkunft: number
  /** lsa_skill_urteil.offen — die Zweitprobe stand noch aus. */
  offen: boolean
}

/** Ein Skill in einer Zeile: Label, Zustand, Hinweis auf dünne Grundlage. */
export type SucheEintrag = {
  label: string
  sicher: boolean
  /** Urteil beruht auf einer einzigen Aufgabe ohne eindeutigen Treffer. */
  nurEineAufgabe: boolean
}

/**
 * Eine Zeile: ein Bereich mit „x von y sicher".
 *
 * `bereich` ist ein Schlüssel aus INHALTSBEREICHE (Anzeige über i18n) — außer
 * in Block 1, dort steht das Label des Themas und `bereich` ist null.
 */
export type SucheZeile = {
  bereich: string | null
  geprueft: number
  sicher: number
  eintraege: SucheEintrag[]
}

/** Die Zeilen einer Stufe. */
export type SucheStufe = {
  stufe: Stufe
  zeilen: SucheZeile[]
}

/**
 * Wie die Sitzung zum Thema stand.
 *
 *   thema           Thema gewählt, mindestens ein Einstiegsknoten geprüft
 *   thema_ungeprueft Thema gewählt, aber kein Einstiegsknoten geprüft
 *                   (auch: das Thema hat noch keine Einstiegsknoten)
 *   ohne_thema      alte Sitzung, thema_key NULL
 */
export type SucheFall = 'thema' | 'thema_ungeprueft' | 'ohne_thema'

export type Suchweg = {
  fall: SucheFall
  /** Label des gewählten Themas; null ohne Thema oder ohne Label. */
  themaLabel: string | null
  /** Block 1 — die geprüften Einstiegsknoten. null außer bei fall 'thema'. */
  aktuell: SucheZeile | null
  /** Block 2 — geprüfte Skills im Abschluss der Einstiegsknoten. */
  grundlagen: SucheStufe[]
  /** Block 3 — alle übrigen geprüften Skills. */
  angesehen: SucheStufe[]
  /** Liegt in Block 2 mindestens ein sicherer Skill? */
  grundlageSicher: boolean
  geprueft: number
}
