// Session-Engine A2: der naechste Schritt eines Kindes (session_naechster_schritt) und die
// Felder, die A2 in coach_raum_live fuellt. grund ist ein Satz fuer den Coach aus der
// Datenbank; fuer Uebersetzungen gibt es grund_code.

import type { SessionPhase } from './sessionLive'

export type SchrittArt =
  | 'erklaerung'
  | 'beispiel'
  | 'aufgabe'
  | 'erklaerung_angebot'
  | 'exit'
  | 'termin'
  | 'fertig'
  | 'warten'

export type SchrittModus = 'gefuehrt' | 'selbststaendig'

export type SessionSchritt = {
  art: SchrittArt
  phase: SessionPhase
  skill_key: string | null
  skill_label: string | null
  task_id: string | null
  modus: SchrittModus | null
  eingemischt: boolean
  schwierigkeit: number | null
  grund: string
  grund_code: string
  hinweise_erlaubt: boolean
  /** Aufgabe ohne Loesung (lsa_question_payload) bei aufgabe, exit und beispiel. */
  aufgabe: Record<string, unknown> | null
  /** Nur bei art = beispiel. */
  loesungsweg?: string | null
  /** Bei erklaerung_angebot: erklaer_start (sequenz) oder erklaer_nachlesen. */
  erklaerung_weg?: 'sequenz' | 'nachlesen'
  /** Nur fuer Coach und Admin: die Vorschau bucht nichts. */
  vorschau?: boolean
}

export type MasteryKandidatLive = {
  skill_key: string
  label: string
  seit: string
  stand_coach: 'gemeistert' | 'vertagt' | null
  pruefung_vorhanden: boolean
}

export type ErklaersequenzLive = {
  skill_key: string
  label: string
  kernidee_nr: number
  kernidee_titel: string
  kernideen: number
  kernideen_fertig: number
  runde: number
  variante: string
  stand: 'gezeigt' | 'richtig' | 'falsch' | 'signal'
  zeit: string
  fehlbild_slug: string | null
}

export type SchrittLive = {
  art: SchrittArt
  phase: SessionPhase
  skill_key: string | null
  skill_label: string | null
  task_id: string | null
  modus: SchrittModus | null
  eingemischt: boolean
  schwierigkeit: number | null
  grund: string
  grund_code: string
  zeit: string
}
