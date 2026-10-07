// Session-Rahmen A2b: was das Tablet des Kindes liest (Vertrag: docs/api/DATENVERTRAG.md, "Session am Tablet").
// Keine Loesung, kein grund, keine Stufe, keine Quoten (Entscheidungen 29 bis 36).

import type { SessionFall } from './sessionLive'

/** tablet_stand().pruefung: nur Label und Frage, nie Erwartung oder Kriterium (Entscheidung 31). */
export type TabletPruefung = { skill_label: string; frage: string | null }

/** tablet_stand().bestaetigt: in dieser Session vom Coach als gemeistert gebucht (Entscheidung 34). */
export type TabletBestaetigt = { skill_key: string; skill_label: string; am: string }

export type SessionKindKontext = {
  vorname: string | null
  coach_vorname: string | null
  schulthema: { thema_key: string; label: string | null } | null
  /** null, solange home_quests_aktiv aus ist. Tage als ISO-Datum (YYYY-MM-DD). */
  quest_termine: { quest_a: [string, string]; quest_b: string | null } | null
}

/** Je Fertigkeit nur label, aktuell, neu: kein Stand, kein Prozent, keine Farbe (Entscheidung 35). */
export type KindZielFertigkeit = { label: string; aktuell: boolean; neu: boolean }

export type SessionZielKind = {
  /** null, solange der Coach den Fall nicht gewaehlt hat. */
  fall: SessionFall | null
  thema_label: string | null
  klassenarbeit_datum: string | null
  /** hoechstens drei, ab dem aktuellen Skill */
  fertigkeiten: KindZielFertigkeit[]
}

export type SessionAbschlussKind = {
  /** hoechstens drei Skill-Labels aus der Kernarbeit, ohne eingemischte */
  geuebt: string[]
  /** XP dieser Session (gebucht, sonst 0) */
  xp: number
  naechste_session: string | null
}

/** coach_raum_live: Pruefrage, die gerade auf dem Tablet des Kindes steht. */
export type PruefungAufTablet = { skill_key: string; seit: string }

export type PruefungTabletAntwort = { skill_key: string; aktiv: boolean }
