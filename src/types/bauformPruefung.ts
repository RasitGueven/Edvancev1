// Lena-Board fuer Bauformen (Sessionreihe 1, A5): Zeilen der Lesefunktionen bauform_pruef_liste, bauform_pruef_detail,
// bauform_auffaellig, skill_pruefung_liste (DATENVERTRAG §13.8).
import type { PreviewPayload } from './preview'

export type BauformStatus = 'entwurf' | 'zur_pruefung' | 'rueckfrage' | 'beanstandet' | 'zur_freigabe' | 'freigegeben' | 'pausiert'
export type BauformEntscheidung = 'passt' | 'unsicher' | 'passt_nicht'

export type BauformListenZeile = {
  bauform_id: string
  schluessel: string
  skill_key: string
  skill_label: string
  reihe: string
  format: string
  rollen: string[]
  version: number
  status: BauformStatus
  gruen: number
  letzte_entscheidung: string | null
  letzte_notiz: string | null
  geprueft_am: string | null
}

export type BauformFehlbild = { key: string; regel?: string; rueckmeldung: string; gilt_fuer_stufen: number[] }

export type BauformSteckbrief = {
  text?: string
  stufen?: Record<string, string>
  fehlbilder?: BauformFehlbild[]
  hinweise?: string[]
  loesungsweg?: string[]
  warum?: { bei_schritt: number; frage: string; bausteine: { id: string; text: string }[]; richtig: string } | null
  kontext?: string | null
  zeit_sek?: number
  kann_entfallen?: boolean
}

export type BauformBeispiel = {
  task_id: string
  stufe: number
  rolle: string
  payload: PreviewPayload
  loesung: Record<string, unknown> | null
  known_errors: Record<string, string> | null
  loesungsweg: string | null
  hinweise: { level: number; text: string; status?: string }[]
}

export type BauformDetail = {
  bauform_id: string
  schluessel: string
  skill_key: string
  skill_label: string
  kernidee_key: string | null
  format: string
  rollen: string[]
  version: number
  status: BauformStatus
  steckbrief: BauformSteckbrief
  pruefprotokoll: { gruen?: number; rot?: number; rot_anteil?: number; gruende?: Record<string, number>; lauf_am?: string }
  blindloeser: { geloest?: number; abweichend?: number[]; anteil?: number; bestanden?: boolean } | null
  verdacht: string | null
  fehlbild_texte: Record<string, string>
  instanzen: number
  beispiele: BauformBeispiel[]
  pruefungen: { version: number; entscheidung: string; gruende: string[]; notiz: string | null; am: string }[]
}

export type AuffaelligZeile = {
  task_id: string
  bauform_id: string | null
  schluessel: string | null
  bauform_status: BauformStatus | null
  frage: string | null
  stufe: number | null
  rolle: string | null
  status: 'auffaellig' | 'pausiert'
  grund: string | null
  bearbeitungen: number
  richtig: number
  haeufigste_unbekannte: string | null
  unbekannt: Record<string, number>
  fehlbild_zaehler: Record<string, number>
  meldungen: { grund: string; am: string; von: string | null }[]
}

export type PrueffrageZeile = {
  id: string
  skill_key: string
  skill_label: string
  frage: string
  erwartung: string
  kriterium: string
  status: 'entwurf' | 'geprueft' | 'freigegeben'
  geprueft_von: string | null
  geprueft_am: string | null
  pruef_notiz: string | null
}

/** Zeile aus bauform_pruef_plan (M1): Muster mit Session des Standard- oder Kinderplans. */
export type BauformPlanZeile = BauformListenZeile & {
  session_nr: number | null
  session_titel: string | null
  kernidee_key: string | null
  kernidee_titel: string | null
  ist_voraussetzung: boolean
}

/** Zeile aus bauform_plan_kinder (M1): Kind mit aktiver Reihe fuer den Plan-Umschalter. */
export type PlanKind = { student_id: string; name: string; ist_test: boolean; reihe_id: string }
