// Slots S1: Sofort-Session und Buchbarkeit mit Grund. Formen der vier Funktionen kinder_buchbar,
// sofort_session_anlegen, session_leitung und stundenplan_woche. Maßgeblich ist docs/api/DATENVERTRAG.md,
// Abschnitt 12. Datumswerte sind ISO-Tage ('YYYY-MM-DD', Berlin), Zeitpunkte ISO-Strings mit Zeitzone.

import type { TerminZustand } from './slotplan'

/**
 * Grund, warum ein Kind an einem Tag (nicht) buchbar ist. Die Vertrags-Codes greifen genau dann, wenn
 * der Platz-Trigger (ZG001) das Kind ablehnen würde; erster Treffer in dieser Reihenfolge gewinnt.
 */
export type BuchbarCode =
  | 'kein_vertrag'
  | 'widerrufen'
  | 'vertrag_ab'
  | 'vertrag_beendet'
  | 'keine_einheit'
  | 'schon_termin'
  | 'art_konflikt'
  | 'ok'

export type KindBuchbar = {
  student_id: string
  name: string | null
  klasse: number | null
  ist_test: boolean
  code: BuchbarCode
  /** widerrufen: Widerrufsdatum; vertrag_ab: nächster Vertragsbeginn; vertrag_beendet: letzter Vertragstag. */
  detail: string | null
}

export type SofortSessionErgebnis = {
  session_id: string
  /** true, wenn alle Kinder Testkonten sind. */
  testlauf: boolean
}

export type SessionLeitung = {
  id: string
  name: string
  rolle: 'coach' | 'admin'
}

export type StundenplanKind = {
  student_id: string
  name: string | null
  ist_test: boolean
  attendance: TerminZustand
}

export type StundenplanSession = {
  session_id: string
  scheduled_at: string
  room: string | null
  status: 'upcoming' | 'active' | 'done'
  testlauf: boolean
  gestartet: boolean
  coach_id: string | null
  coach_name: string | null
  coach_rolle: 'coach' | 'admin' | 'parent' | 'student' | null
  kinder: StundenplanKind[]
}

export type StundenplanWoche = {
  /** Montag der Woche (die Funktion nimmt einen beliebigen Tag). */
  montag: string
  /** Einzel-Sessions (ohne Slot-Raum) Mo–So, nach Beginn. */
  sessions: StundenplanSession[]
}
