// Slots (Bauauftrag Slots, Paket SL1): die Formen, die die Lese- und Schreibfunktionen liefern.
// Maßgeblich ist docs/api/DATENVERTRAG.md, Abschnitt 10. Datumswerte sind ISO-Tage ('YYYY-MM-DD',
// Berlin), Uhrzeiten 'HH:MM' (Berlin), Zeitpunkte ISO-Strings mit Zeitzone.
// Die Altlast S10 (Lead-Slots) steht in ./slots und hat mit diesen Typen nichts zu tun.

import type { Vertragsart } from './vertrag'

/** SL-Codes der Slot-Funktionen (Entscheidung 23). */
export type SlotsCode =
  | 'SL001' | 'SL002' | 'SL003' | 'SL004' | 'SL005' | 'SL006'
  | 'SL007' | 'SL008' | 'SL009' | 'SL010' | 'SL011' | 'SL012'
  /** SL2b: Testkonto und echtes Kind im selben Termin. */
  | 'SL013'

/** Gleiche Codes wie session_students.attendance. */
export type TerminZustand = 'planned' | 'present' | 'cancelled' | 'unexcused' | 'cancelled_by_us'
export type Takt = 'woechentlich' | 'a_woche' | 'b_woche'
export type TerminHerkunft = 'stammplatz' | 'zusatz'
/**
 * stamm = Stammschicht, vertretung = anderer Coach, zusatz = Raum zusätzlich geöffnet, faellt_aus = geschlossen.
 * W1: ohne_schicht = Raum ohne Schicht und ohne Abweichung, in dem trotzdem Kinder fest sitzen (offen = false).
 */
export type RaumArt = 'stamm' | 'vertretung' | 'zusatz' | 'faellt_aus' | 'ohne_schicht'
export type PlanbilanzArt = 'kein_stammplatz' | 'aufgebraucht' | 'reicht_bis' | 'ohne_termin' | 'passt'

export type SlotZeit = { id: string; beginn: string; ende: string }

export type KindKurz = {
  student_id: string
  name: string | null
  klasse: number | null
  /** Fach aus dem Vertrag (z. B. 'Mathematik'); null = ohne Fach. */
  fach: string | null
  /** SL2b: Testkonto (Kennzeichen „Test“, zählt in den Kennzahlen nicht). */
  ist_test?: boolean
}

/** Planbilanz (Entscheidung 12), gerechnet, nie gespeichert. */
export type Planbilanz = {
  art: PlanbilanzArt
  einheiten: number
  verbraucht: number
  /** Geplant, auch vergangene Termine ohne Anwesenheit. */
  geplant: number
  /** O = Einheiten − verbraucht − geplant. */
  ohne_termin: number
  /** U = Stammplatz-Termine bis zum Stichtag ohne Budget. */
  ohne_einheit: number
  /** Alle Stammplatz-Termine bis zum Stichtag (gespeicherte und U), Anforderung K 60. */
  terminzahl: number
  letzter_termin: string | null
  /** Nur bei reicht_bis: das Datum des letzten Termins. */
  datum: string | null
  /** ohne_termin: O; reicht_bis: U; sonst null. */
  zahl: number | null
  /** Bei passt: Abweichung innerhalb der Toleranz, sonst null. */
  abweichung: { art: 'ohne_termin' | 'ohne_einheit'; zahl: number } | null
  /** Stammplatz-Daten ohne freien Platz oder Raum (Entscheidung 11); fehlt in Listen. */
  uebersprungen?: string[]
  jenseits_ferientabelle: boolean
  hinweis: 'SL012' | null
  toleranz: number
}

// ── Wochenplan ──────────────────────────────────────────────────────────────

export type WocheTag = {
  datum: string
  wochentag: number
  betrieb: boolean
  /** Nur ohne Betrieb: "Osterferien", "Christi Himmelfahrt". */
  anlass: string | null
  heute: boolean
  vergangen: boolean
}

export type ZelleRaum = {
  raum_id: string
  name: string
  offen: boolean
  art: RaumArt
  coach_id: string | null
  /** W1. */
  coach_name: string | null
  /** W1: mit offen = false und belegt > 0 ein Raum mit Kindern, aber ohne Coach („kein Coach“). */
  belegt: number
}

export type WocheZelle = {
  datum: string
  zeit_id: string
  kapazitaet: number
  belegt: number
  ohne_raum: number
  /** Räume mit Stammschicht, deren Coach in diesem Termin ausfällt. */
  coach_fehlt: number
  raeume: ZelleRaum[]
  faecher: { fach: string | null; zahl: number }[]
  vergangen: boolean
  /** W1: Die Stunde läuft gerade. */
  laeuft: boolean
  /** SL2b: davon Testkonten (in belegt enthalten, im Kopf nicht). */
  test?: number
  /** SL2b: davon Testkonten ohne Raum. */
  test_ohne_raum?: number
}

export type SlotsWoche = {
  montag: string
  kw: number
  a_woche: boolean
  heute: string
  tage: WocheTag[]
  zeiten: SlotZeit[]
  /** Nur Tage mit Betrieb, je aktiver Uhrzeit eine Zelle. */
  zellen: WocheZelle[]
  kopf: {
    plaetze: number
    belegt: number
    auslastung: number | null
    ohne_raum: number
    erster_ohne_raum: { datum: string; zeit_id: string } | null
    ohne_stammplatz: number
    ohne_stammplatz_laufend: number
    /** W1 (Entscheidung 7): Testkonten sichtbar daneben; belegt und auslastung bleiben ohne Testkonten. */
    belegt_test: number
    auslastung_mit_test: number | null
    ohne_stammplatz_test: number
    /** W1: Raum-Zellen der Woche mit Kindern, aber ohne Coach. */
    raeume_ohne_coach: number
  }
}

// ── Termin ──────────────────────────────────────────────────────────────────

export type TerminKind = KindKurz & {
  termin_id: string
  herkunft: TerminHerkunft
  zustand: TerminZustand
  raum_fest: boolean
  session_id: string | null
  umgebucht_von: { termin_id: string; datum: string; beginn: string } | null
}

export type TerminRaum = {
  raum_id: string
  name: string
  offen: boolean
  art: RaumArt
  coach_id: string | null
  coach_name: string | null
  stamm_coach_id: string | null
  stamm_coach_name: string | null
  vertretung: boolean
  gemischt: boolean
  session_id: string | null
  gestartet: boolean
  kinder: TerminKind[]
}

export type NichtDabei = KindKurz & {
  termin_id: string
  zustand: Exclude<TerminZustand, 'planned' | 'present'>
  herkunft: TerminHerkunft
  absage_eingang: string | null
  /** Nur mit Absage: abgesagt (rechtzeitig) oder unentschuldigt (nach 10 Uhr). */
  rechtzeitig: boolean | null
  zuruecknehmbar: boolean
}

export type SlotsTermin = {
  datum: string
  kw: number
  zeit: SlotZeit
  betrieb: boolean
  anlass: string | null
  heute: boolean
  vergangen: boolean
  begonnen: boolean
  /** W1: Die Stunde läuft gerade. */
  laeuft: boolean
  festgeschrieben: boolean
  kapazitaet: number
  belegt: number
  raeume: TerminRaum[]
  ohne_raum: TerminKind[]
  nicht_dabei: NichtDabei[]
  /** Vergangen und noch Kinder ohne Anwesenheit (geplant). */
  anwesenheit_fehlt: boolean
  /** Aktive Räume, die in diesem Termin nicht geöffnet sind (für "Raum öffnen"). */
  raeume_schliessbar: { raum_id: string; name: string }[]
  /** Alle Coaches; raum_id = Raum, in dem der Coach in diesem Termin schon ist. */
  coaches: { id: string; name: string | null; raum_id: string | null }[]
}

// ── Heute (slots_tag) ───────────────────────────────────────────────────────

export type TagRaumTermin = {
  zeit_id: string
  beginn: string
  ende: string
  raum_id: string
  raum_name: string
  coach_id: string | null
  coach_name: string | null
  art: RaumArt
  /** W1: false = kein Coach (Kinder sitzen fest im Raum, belegt zählt sie). */
  offen: boolean
  kapazitaet: number
  belegt: number
  session_id: string | null
  gestartet: boolean
  status: 'upcoming' | 'active' | 'done' | null
}

export type TagSessionOhneRaum = {
  session_id: string
  scheduled_at: string
  room: string | null
  status: 'upcoming' | 'active' | 'done'
  coach_id: string | null
  coach_name: string | null
  testlauf: boolean
  gestartet: boolean
  kinder: number
}

export type TagAbsage = KindKurz & {
  termin_id: string
  beginn: string
  zustand: 'cancelled' | 'unexcused'
  absage_eingang: string
  rechtzeitig: boolean
}

export type SlotsTag = {
  datum: string
  betrieb: boolean
  anlass: string | null
  raum_termine: TagRaumTermin[]
  sessions_ohne_raum: TagSessionOhneRaum[]
  absagen: TagAbsage[]
}

export type SlotsZaehler = { ohne_stammplatz: number; ohne_raum: number; gesamt: number }

// ── Coaches, Einstellungen ─────────────────────────────────────────────────

export type Stammschicht = {
  id: string
  wochentag: number
  zeit_id: string
  beginn: string
  raum_id: string
  raum_name: string
  gueltig_ab: string
  gueltig_bis: string | null
  /** W1: Kinder mit Stammplatz in diesem Raum zu dieser Zeit. */
  kinder: number
}

export type CoachAbweichung = {
  datum: string
  zeit_id: string
  beginn: string
  raum_id: string
  raum_name: string
  art: Exclude<RaumArt, 'stamm'>
}

export type SlotsCoaches = {
  montag: string
  kw: number
  coaches: {
    id: string
    name: string | null
    stammschichten: Stammschicht[]
    stunden_pro_woche: number
    abweichungen: CoachAbweichung[]
  }[]
  raeume: { id: string; name: string }[]
  zeiten: SlotZeit[]
}

export type SlotsEinstellungen = {
  heute: string
  schuljahr_bis: string
  planungsgrenze: string
  raeume: { id: string; name: string; aktiv_ab: string; inaktiv_ab: string | null; stammschichten: number }[]
  zeiten: (SlotZeit & { aktiv_ab: string; inaktiv_ab: string | null })[]
  ferien: { art: string; name: string; von: string; bis: string }[]
  feiertage: { datum: string; name: string; art: 'feiertag' | 'pfingstferien' }[]
}

// ── Kinder und Kind ─────────────────────────────────────────────────────────

export type Stammplatz = {
  id: string
  wochentag: number
  zeit_id: string
  beginn: string
  takt: Takt
  gueltig_ab: string
  /** null = bis zum Stichtag. */
  gueltig_bis: string | null
  vorgaenger_id: string | null
  /** W1: null = Altbestand ohne Raum (das System verteilt je Termin). */
  raum_id: string | null
  raum_name: string | null
  /** W1: Coach der Schicht dieses Raums am ersten Tag (heute oder gültig ab); null = keine Schicht. */
  coach_id: string | null
  coach_name: string | null
}

export type Rhythmus = { woechentlich: number; vierzehntaeglich: number }

export type VertragAuszug = {
  vertrag_id: string
  paket: string | null
  laufzeit_monate: number | null
  einheiten: number
  beginn: string
  stichtag: string
  gekuendigt_zum: string | null
  rhythmus: Rhythmus | null
  /** V5: 'pilot' = Pilotvereinbarung, ohne Paket und Laufzeit. */
  vertragsart?: Vertragsart
}

/** Vorschlag "wie bisher weiterführen" für einen Folgevertrag (Entscheidung 22). */
export type Weiterfuehren = {
  vertrag_id: string
  ab: string
  zeilen: { vorgaenger_id: string; wochentag: number; slot_zeit_id: string; takt: Takt; beginn: string; raum_id: string | null }[]
} | null

export type SlotsKinderZeile = KindKurz & VertragAuszug & {
  vertrag_laeuft: boolean
  ohne_stammplatz: boolean
  stammplaetze: Stammplatz[]
  verbraucht: number
  geplant: number
  planbilanz: Omit<Planbilanz, 'uebersprungen'>
  folgevertrag_ab: string | null
  weiterfuehren: Weiterfuehren
}

export type KindNaechsterTermin = {
  termin_id: string
  datum: string
  zeit_id: string
  beginn: string
  ende: string
  zustand: TerminZustand
  herkunft: TerminHerkunft
  umgebucht_von: string | null
  absage_eingang: string | null
  festgeschrieben: boolean
}

export type KindLetzterTermin = {
  /** null bei einer Einzel-Session ohne Kind-Termin. */
  termin_id: string | null
  datum: string
  beginn: string
  zustand: TerminZustand
  herkunft: TerminHerkunft | 'einzel'
  session_id: string | null
}

export type SlotsKind = {
  kind: KindKurz
  zugelassen: boolean
  vertrag: VertragAuszug | null
  vertrag_laeuft: boolean | null
  stammplaetze: Stammplatz[]
  fruehere_stammplaetze: Stammplatz[]
  naechste: KindNaechsterTermin[]
  letzte: KindLetzterTermin[]
  einheiten: { gesamt: number; verbraucht: number; geplant: number } | null
  planbilanz: Planbilanz | null
  weiterfuehren: Weiterfuehren
}

export * from './slotplanDialoge'
export * from './slotplanRaum'
