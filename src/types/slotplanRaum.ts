// Slots W1: Formen der neuen Funktionen für Wochenplan, Kinder und Coaches (Stammplatz am Raum).
// Datenvertrag: docs/api/DATENVERTRAG.md, Abschnitt 10.

import type { SlotsCode, Takt } from './slotplan'

/** stammplatz_vorschau: was an einem der nächsten sechs Termine passiert. */
export type VorschauErgebnis = 'termin' | 'ferien' | 'feiertag' | 'andere_woche' | 'voll' | 'ohne_coach' | 'ohne_budget'

export type StammplatzVorschauZeile = {
  datum: string
  ergebnis: VorschauErgebnis
  /** Name der Ferien oder des Feiertags, sonst null. */
  anlass: string | null
  /** Kinder im Raum ohne dieses Kind; null an Tagen ohne Betrieb und in der anderen Woche. */
  belegt: number | null
  coach_id: string | null
  coach_name: string | null
}

/** slots_kandidaten_alle: null = buchbar. */
export type KandidatCode = SlotsCode | 'kein_vertrag' | 'vertrag_ab'

export type KandidatStammplatz = {
  wochentag: number
  zeit_id: string
  beginn: string
  takt: Takt
  raum_id: string | null
  raum_name: string | null
}

export type SlotsKandidatAlle = {
  student_id: string
  name: string | null
  klasse: number | null
  fach: string | null
  ist_test: boolean
  /** Kurzform aller laufenden Stammplätze („Mi 16:00 · A1“), null = ohne Stammplatz. */
  stammplatz_kurz: string | null
  stammplaetze: KandidatStammplatz[]
  code: KandidatCode | null
  /** Nur bei vertrag_ab: Beginn des Vertrags. */
  datum: string | null
}

export type BlockErgebnis = { stammschicht_ids: string[]; stunden: number }

export type RaumWechselErgebnis = { stammschicht_ids: string[]; stammplatz_ids: string[]; kinder: number }
