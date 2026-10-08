// Session-Rahmen C2: Antworten der Coach-Funktionen, die C2 dazubringt (Migrationen 20261010110100–110400).
// Werte sind Datenbank-Konstanten bzw. Inhalte; Anzeige-Texte kommen ueber i18n.

import type { KindLive, PfadEntscheidung, SessionFall } from './sessionLive'

/** coach_raum_live.kinder[].abschluss: Check-out je Kind (null, solange nichts gespeichert ist). */
export type KindAbschlussLive = {
  satz_text: string | null
  satz_gesagt: boolean
  notiz: string | null
  flag_eltern: boolean
  flag_pfad: boolean
  exit_ergebnis: { richtig: number; gesamt: number } | null
  quest_termin: string | null
  quest_von: 'kind' | 'coach' | null
}

/** coach_raum_live.kinder[].mastery_heute: Entscheidungen dieser Session (lernpfad_protokoll). */
export type MasteryHeute = {
  skill_key: string
  label: string
  stand_coach: 'gemeistert' | 'vertagt'
  grund: string | null
  am: string
  von: string | null
}

/** Ein Kind in coach_raum_live ab C2. */
export type KindRaum = KindLive & {
  abschluss: KindAbschlussLive | null
  /** Tag vor der naechsten gebuchten Session (YYYY-MM-DD), nur mit Home Quests. */
  quest_b: string | null
  eingriffe: { stufe: 1 | 2 | 3 | 4; zeit: string }[]
  pfad_entscheidung: { entscheidung: PfadEntscheidung; zeit: string } | null
  mastery_heute: MasteryHeute[]
  /** F1 (Migration 20261011140000): juengster Phasenwechsel; fehlt vor F1. */
  phase_seit?: string | null
  /** F1: Warm-up entfallen (kein Warm-up-Schritt, aber Kernarbeit/Check-out); fehlt vor F1. */
  warmup_entfallen?: 'kein_stoff' | 'zeit' | null
}

/** session_briefing: je gebuchtes Kind mit laufendem Vertrag. */
export type BriefingKind = {
  student_id: string
  name: string | null
  klasse: number | null
  letzte_session: {
    session_id: string
    am: string
    fall: SessionFall | null
    ziel_thema_key: string | null
    ziel_thema_label: string | null
    exit_ergebnis: { richtig: number; gesamt: number } | null
    notiz: string | null
    coach_name: string | null
    signale: number
  } | null
  schulthema: { thema_key: string; label: string | null; seit: string; tage: number; nachfragen: boolean } | null
  klassenarbeit: { datum: string; thema_key: string | null; label: string | null } | null
  pruefungen_faellig: { skill_key: string; label: string }[]
  flags_offen: { flag: 'eltern' | 'pfad'; session_id: string; am: string }[]
  /** Nur Zahlen, nie Inhalte (FernUSG). */
  quests_woche: { erledigt: number; offen: number }
  naechste_luecke: { skill_key: string; label: string; quelle: 'lsa' | 'lernpfad' } | null
  erste_session: boolean
}

export type SatzAnlass =
  | 'mastery'
  | 'erklaerung'
  | 'dran_geblieben'
  | 'hinweise'
  | 'selbststaendig'
  | 'exit'
  | 'geuebt'
  | 'allgemein'

/** satz_vorschlaege: zwei Saetze aus dem Bausteinkatalog. */
export type SatzVorschlag = { baustein_id: string; anlass: SatzAnlass; text: string }

/** sessions_offen: gestartet und nach scheduled_at + 60 + 30 Minuten nicht abgeschlossen. */
export type OffeneSession = {
  session_id: string
  scheduled_at: string
  room: string | null
  status: 'active'
  coach_id: string | null
  coach_name: string | null
  testlauf: boolean
  kinder: number
}

/** sessions_nicht_gestartet (nur Admin): vergangen, nie gestartet; nur als Zahl gezeigt, keine Aktion. */
export type NichtGestarteteSession = {
  session_id: string
  scheduled_at: string
  room: string | null
  testlauf: boolean
  kinder: number
}
