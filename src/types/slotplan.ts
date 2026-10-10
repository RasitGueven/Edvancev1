// Slots (Bauauftrag Slots, Paket SL1): die Formen, die die Lese- und Schreibfunktionen liefern.
// Maßgeblich ist docs/api/DATENVERTRAG.md, Abschnitt 10. Datumswerte sind ISO-Tage ('YYYY-MM-DD',
// Berlin), Uhrzeiten 'HH:MM' (Berlin), Zeitpunkte ISO-Strings mit Zeitzone.
// Die Altlast S10 (Lead-Slots) steht in ./slots und hat mit diesen Typen nichts zu tun.

/** SL-Codes der Slot-Funktionen (Entscheidung 23). */
export type SlotsCode =
  | 'SL001' | 'SL002' | 'SL003' | 'SL004' | 'SL005' | 'SL006'
  | 'SL007' | 'SL008' | 'SL009' | 'SL010' | 'SL011' | 'SL012'

/** Gleiche Codes wie session_students.attendance. */
export type TerminZustand = 'planned' | 'present' | 'cancelled' | 'unexcused' | 'cancelled_by_us'
export type Takt = 'woechentlich' | 'a_woche' | 'b_woche'
export type TerminHerkunft = 'stammplatz' | 'zusatz'
/** stamm = Stammschicht, vertretung = anderer Coach, zusatz = Raum zusätzlich geöffnet, faellt_aus = geschlossen. */
export type RaumArt = 'stamm' | 'vertretung' | 'zusatz' | 'faellt_aus'
export type PlanbilanzArt = 'kein_stammplatz' | 'aufgebraucht' | 'reicht_bis' | 'ohne_termin' | 'passt'

export type SlotZeit = { id: string; beginn: string; ende: string }

export type KindKurz = {
  student_id: string
  name: string | null
  klasse: number | null
  /** Fach aus dem Vertrag (z. B. 'Mathematik'); null = ohne Fach. */
  fach: string | null
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
}

/** Vorschlag "wie bisher weiterführen" für einen Folgevertrag (Entscheidung 22). */
export type Weiterfuehren = {
  vertrag_id: string
  ab: string
  zeilen: { vorgaenger_id: string; wochentag: number; slot_zeit_id: string; takt: Takt; beginn: string }[]
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

// ── Dialoge ─────────────────────────────────────────────────────────────────

export type StammplatzZeile = { wochentag: number; slot_zeit_id: string; takt: Takt }

export type SlotsFrei = {
  takt: Takt
  ab: string
  zeiten: SlotZeit[]
  /** Kleinster Wert der nächsten sechs Termine; raum = alle sechs haben einen Raum mit Coach. */
  zellen: { wochentag: number; zeit_id: string; frei: number; raum: boolean; voll: boolean; termine: number }[]
}

export type Sperrgrund = { code: SlotsCode; zeile: number | null; datum?: string }

export type PlanbilanzVorschau = {
  planbilanz: Planbilanz | null
  terminzahl: number | null
  letzter_termin: string | null
  uebersprungen: string[]
  /** Leer = Speichern möglich (Abnahmefall 9). */
  gruende: Sperrgrund[]
}

export type SlotsZiel = {
  datum: string
  zeit_id: string
  beginn: string
  ende: string
  frei: number
  /** Stammplatz-Termin, der für diesen Termin wegfiele (Anforderung G 45). */
  verdraengt: string | null
}

export type SlotsZiele = {
  ab: string
  wochen: number
  /** Eingang nach 10 Uhr: die alte Einheit ist verbraucht, der neue Termin braucht eine weitere. */
  alt_verbraucht: boolean
  kein_budget: boolean
  ziele: SlotsZiel[]
}

export type SlotsKandidat = KindKurz & { offen: number; verdraengt: string | null }

// ── Coach und Eltern ────────────────────────────────────────────────────────

export type MeinEinsatz = {
  datum: string
  zeit_id: string
  beginn: string
  ende: string
  raum_id: string
  raum_name: string
  heute: boolean
  session_id: string | null
  kinder: KindKurz[]
}

export type MeineEinsaetze = { montag: string; kw: number; heute: string; einsaetze: MeinEinsatz[] }

export type NaechsterTermin = {
  beginn: string
  datum: string
  uhrzeit: string
  ende: string
  festgeschrieben: boolean
  session_id: string | null
}

// ── Ergebnisse der Schreibfunktionen ───────────────────────────────────────

export type StammplatzErgebnis = { stammplatz_ids?: string[]; stammplatz_id?: string; planbilanz: Planbilanz | null }
export type AbsageErgebnis = { termin_id: string; zustand: 'cancelled' | 'unexcused'; rechtzeitig: boolean }
export type ZusatzErgebnis = {
  termin_id: string
  verdraengt: string[]
  ausgelassen?: (KindKurz & { termin_id: string; grund: 'ZG001' })[]
}
export type UmbuchenErgebnis = { termin_id: string; alt_zustand: 'cancelled' | 'unexcused'; rechtzeitig: boolean; verdraengt: string[] }
export type SessionAnlegenErgebnis = {
  session_id: string
  neu: boolean
  /** Kinder ohne Zugang an dem Tag (ZG001): ausgelassen, Termin "ausgefallen durch uns". */
  ausgelassen: (KindKurz & { termin_id: string; grund: 'ZG001' })[]
}
