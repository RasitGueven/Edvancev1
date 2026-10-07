// Session-Rahmen R1: Typen der Server-Funktionen (Migrationen 20261007110100–110800).
// Werte sind Datenbank-Konstanten; Anzeige-Texte kommen in P2 ueber i18n.

import type { ErklaersequenzLive, MasteryKandidatLive, SchrittLive } from './sessionSchritt'
import type { PruefungAufTablet, TabletBestaetigt, TabletPruefung } from './sessionTablet'

export type SessionPhase = 'checkin' | 'warmup' | 'kern' | 'checkout'
export type SessionFall = 'klassenarbeit' | 'schulthema' | 'lernpfad'
export type Stimmung = 'gut' | 'geht_so' | 'angespannt'
export type ThemaAntwort = 'noch_dran' | 'neu'
export type AntwortErgebnis = 'richtig' | 'teilweise' | 'falsch'
export type SignalArt = 'kandidat' | 'entscheidung' | 'haengt' | 'hinweis'
export type KindStatus = SignalArt | 'laeuft'
export type EingriffStufe = 1 | 2 | 3 | 4
export type PfadEntscheidung = 'tiefer' | 'plan'
export type SessionFlag = 'eltern' | 'pfad'

export type StellschraubeTyp = 'zahl' | 'auswahl' | 'schalter'
export type StellschraubeEinheit = 'minuten' | 'anzahl' | 'stufen' | 'anteil' | 'tage' | 'sessions' | 'xp'
export type StellschraubeWert = number | string | boolean

export type Stellschraube = {
  schluessel: string
  beschreibung: string
  typ: StellschraubeTyp
  wert: StellschraubeWert
  startwert: StellschraubeWert
  min: number | null
  max: number | null
  ganzzahl: boolean
  werte: string[] | null
  einheit: StellschraubeEinheit | null
  geaendert_am: string | null
}

export type StellschraubeProtokoll = {
  id: string
  schluessel: string
  alt: StellschraubeWert
  neu: StellschraubeWert
  grund: string
  von: string | null
  am: string
}

export type RaumSignal = {
  student_id: string
  art: SignalArt
  rang: number
  grund: string
  seit: string
  details: Record<string, unknown>
}

/** Antwort aus der Ergebnisfolge (eine Zeile je Versuch). */
export type ErgebnisPunkt = {
  task_id: string
  teil: number | null
  versuch_nr: number
  ergebnis: AntwortErgebnis
  hinweisstufe_max: number
  phase: SessionPhase | null
  eingemischt: boolean
  zeit: string
}

export type LiveAufgabe = {
  task_id: string
  seit: string
  eingemischt: boolean
  phase: SessionPhase | null
  nr_in_phase: number
  skill_key: string | null
  /** lsa_question_payload: ohne Loesung. */
  payload: Record<string, unknown>
}

export type KindLive = {
  student_id: string
  name: string | null
  klasse: number | null
  anwesenheit: string
  tablet_nr: number | null
  /** Zuweisung des Tablets = Ankunft im Raum. */
  tablet_seit: string | null
  phase: SessionPhase | null
  stimmung: Stimmung | null
  klassenarbeit_datum: string | null
  thema_antwort: ThemaAntwort | null
  thema_stichwort: string | null
  schulthema_key: string | null
  fall_vorschlag: SessionFall | null
  fall_coach: SessionFall | null
  fall: SessionFall | null
  ziel_thema_key: string | null
  ziel_thema_label: string | null
  checkin_fertig: boolean
  aufgabe: LiveAufgabe | null
  ergebnisfolge: ErgebnisPunkt[]
  hinweise_genutzt: number
  letzte_eingabe_am: string | null
  status: KindStatus
  signale: RaumSignal[]
  /** A2: signalisierter, zur Pruefung faelliger Mastery-Kandidat (A1). */
  mastery_kandidat: MasteryKandidatLive | null
  /** A2: Stand der Erklaersequenz in dieser Session (E1). */
  erklaersequenz: ErklaersequenzLive | null
  /** A2: letzter Schritt der Engine mit Grund. */
  schritt: SchrittLive | null
  /** A2b: Pruefrage auf dem Tablet des Kindes. */
  pruefung_auf_tablet: PruefungAufTablet | null
}

export type RaumLive = {
  session: {
    id: string
    status: 'upcoming' | 'active' | 'done'
    scheduled_at: string
    gestartet_am: string | null
    beendet_am: string | null
    room: string | null
    coach_name: string | null
    einstellungen: Record<string, StellschraubeWert>
    mastery_bestaetigt: number
  }
  stand: string
  kinder: KindLive[]
  signale: RaumSignal[]
}

export type KindVersuch = {
  task_id: string
  teil: number | null
  versuch_nr: number
  eingabe: unknown
  ergebnis: AntwortErgebnis
  fehlbild_slug: string | null
  fehlbild_klartext: string | null
  hinweisstufe_max: number
  phase: SessionPhase | null
  dauer_ms: number | null
  zeit: string
}

export type KindDetail = Omit<KindLive, 'status'> & {
  aufgabe_detail: {
    task_id: string
    payload: Record<string, unknown>
    musterloesung: string | null
    correct_answers: unknown
    letzte_eingabe: unknown
  } | null
  versuche: KindVersuch[]
  hinweise: { task_id: string; stufe: number; zeit: string; text: string | null }[]
  eingriffe: { stufe: EingriffStufe; fehlbild_slug?: string; fehlbild_klartext: string | null; zeit: string; von: string | null }[]
  entscheidungen: { entscheidung: PfadEntscheidung; quelle: string; skill_key?: string; zeit: string; von: string | null }[]
}

export type TabletStand =
  | { zugewiesen: false }
  | {
      zugewiesen: true
      session_id: string
      tablet_nr: number
      vorname: string | null
      phase: SessionPhase | null
      checkin_fertig: boolean
      /** Nicht zur Anzeige: die App nimmt den Schritt aus session_naechster_schritt. */
      aufgabe: Record<string, unknown> | null
      pruefung: TabletPruefung | null
      bestaetigt: TabletBestaetigt[]
    }

export type AntwortRueckmeldung = {
  ergebnis: AntwortErgebnis
  versuch_nr: number
  fehlbild_klartext: string | null
}

export type HinweisAntwort = { stufe: number; text: string | null; verfuegbar: boolean }

export type CheckinKind = {
  stimmung: Stimmung
  klassenarbeitDatum: string | null
  klassenarbeitThemaKey: string | null
  themaAntwort: ThemaAntwort
  themaStichwort?: string | null
}

export type AbschlussEingabe = {
  satzText?: string
  satzGesagt?: boolean
  notiz?: string
  flagEltern?: boolean
  flagPfad?: boolean
  exitErgebnis?: { richtig: number; gesamt: number }
}

export type SessionAbschlussErgebnis = { kinder: number; anwesend: number; einheit_verbraucht: number }

export type OffenesFlag = {
  session_id: string
  student_id: string
  name: string | null
  flag: SessionFlag
  scheduled_at: string
  notiz: string | null
}
