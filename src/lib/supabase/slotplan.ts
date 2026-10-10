// Slots (Bauauftrag Slots, Paket SL1): Aufrufe der Slot-Funktionen. Die Tabellen sind für Clients
// nur lesbar (Admin) und werden nie direkt beschrieben; alles geht über diese RPCs (Entscheidung 24).
// Im Fehlerfall gehen SQLSTATE (code, z. B. 'SL001') und Hinweis (hint) mit; die Oberfläche übersetzt
// sie über src/lib/slots/fehler.ts. p_jetzt (nur für Tests) wird nie übergeben (Entscheidung 17).
// Datenvertrag: docs/api/DATENVERTRAG.md, Abschnitt 10.

import { sessionRpc as rpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type {
  AbsageErgebnis, MeineEinsaetze, NaechsterTermin, PlanbilanzVorschau, SessionAnlegenErgebnis, SlotsCoaches,
  SlotsEinstellungen, SlotsFrei, SlotsKandidat, SlotsKind, SlotsKinderZeile, SlotsTag, SlotsTermin, SlotsWoche,
  SlotsZaehler, SlotsZiele, StammplatzErgebnis, StammplatzZeile, Takt, UmbuchenErgebnis, ZusatzErgebnis,
} from '@/types/slotplan'

export type SlotsResult<T> = RpcResult<T>

// ── Lesen (je Bildschirm eine Funktion) ─────────────────────────────────────

/** Wochenplan; p_montag darf ein beliebiger Tag der Woche sein. */
export function ladeWoche(montag: string): Promise<SlotsResult<SlotsWoche>> {
  return rpc('slots_woche', { p_montag: montag }, 'Wochenplan konnte nicht geladen werden')
}

export function ladeTermin(datum: string, zeitId: string): Promise<SlotsResult<SlotsTermin>> {
  return rpc('slots_termin', { p_datum: datum, p_zeit_id: zeitId }, 'Termin konnte nicht geladen werden')
}

/** Für "Heute im Betrieb" und "Absagen heute". */
export function ladeTag(datum: string): Promise<SlotsResult<SlotsTag>> {
  return rpc('slots_tag', { p_datum: datum }, 'Tag konnte nicht geladen werden')
}

export function ladeZaehler(): Promise<SlotsResult<SlotsZaehler>> {
  return rpc('slots_zaehler', {}, 'Zähler konnte nicht geladen werden')
}

export function ladeCoaches(montag: string): Promise<SlotsResult<SlotsCoaches>> {
  return rpc('slots_coaches', { p_montag: montag }, 'Coaches konnten nicht geladen werden')
}

export function ladeEinstellungen(): Promise<SlotsResult<SlotsEinstellungen>> {
  return rpc('slots_einstellungen', {}, 'Einstellungen konnten nicht geladen werden')
}

export function ladeKinder(): Promise<SlotsResult<SlotsKinderZeile[]>> {
  return rpc('slots_kinder', {}, 'Kinder konnten nicht geladen werden')
}

export function ladeKind(studentId: string): Promise<SlotsResult<SlotsKind>> {
  return rpc('slots_kind', { p_student_id: studentId }, 'Kind konnte nicht geladen werden')
}

/** Raster freier Plätze; studentId zählt die eigenen Termine des Kindes nicht als belegt. */
export function ladeFrei(takt: Takt, ab: string, studentId: string | null = null): Promise<SlotsResult<SlotsFrei>> {
  return rpc('slots_frei', { p_takt: takt, p_ab: ab, p_student_id: studentId }, 'Freie Plätze konnten nicht geladen werden')
}

/**
 * Planbilanz ohne zu speichern. zeilen = alle Stammplätze ab `ab`; ersetzt = Stammplätze, die mit `ab`
 * enden (Ändern); null = alle, die an `ab` noch gelten.
 */
export function ladePlanbilanzVorschau(
  studentId: string, zeilen: StammplatzZeile[], ab: string, ersetzt: string[] | null = null,
): Promise<SlotsResult<PlanbilanzVorschau>> {
  return rpc('slots_planbilanz_vorschau', { p_student_id: studentId, p_zeilen: zeilen, p_ab: ab, p_ersetzt: ersetzt },
    'Vorschau konnte nicht geladen werden')
}

/**
 * Gültige Ziele für Umbuchen (ausserTerminId + eingang) und Zusatztermin (beide null). Der Eingang
 * entscheidet nach der 10-Uhr-Regel, ob die alte Einheit verbraucht ist — das rechnet der Server.
 */
export function ladeZiele(
  studentId: string, ausserTerminId: string | null, eingang: string | null, ab: string, wochen = 4,
): Promise<SlotsResult<SlotsZiele>> {
  return rpc('slots_ziele', {
    p_student_id: studentId, p_ausser_termin_id: ausserTerminId, p_eingang: eingang, p_ab: ab, p_wochen: wochen,
  }, 'Ziele konnten nicht geladen werden')
}

export function ladeKandidaten(datum: string, zeitId: string): Promise<SlotsResult<SlotsKandidat[]>> {
  return rpc('slots_kandidaten', { p_datum: datum, p_zeit_id: zeitId }, 'Kandidaten konnten nicht geladen werden')
}

/** Nur Coach: eigene Raum-Termine der Woche. */
export function ladeMeineEinsaetze(montag: string): Promise<SlotsResult<MeineEinsaetze>> {
  return rpc('meine_einsaetze', { p_montag: montag }, 'Einsätze konnten nicht geladen werden')
}

/** Admin und Eltern des Kindes: die nächsten Termine, auch vor dem Festschreiben. */
export function ladeNaechsteTermine(studentId: string, anzahl = 3): Promise<SlotsResult<NaechsterTermin[]>> {
  return rpc('naechste_termine', { p_student_id: studentId, p_anzahl: anzahl }, 'Nächste Termine konnten nicht geladen werden')
}

// ── Stammplätze ─────────────────────────────────────────────────────────────

export function stammplatzVergeben(studentId: string, zeilen: StammplatzZeile[], ab: string): Promise<SlotsResult<StammplatzErgebnis>> {
  return rpc('stammplatz_vergeben', { p_student_id: studentId, p_zeilen: zeilen, p_ab: ab }, 'Stammplatz konnte nicht vergeben werden')
}

export function stammplatzAendern(id: string, ab: string, zeile: StammplatzZeile): Promise<SlotsResult<StammplatzErgebnis>> {
  return rpc('stammplatz_aendern', {
    p_id: id, p_ab: ab, p_wochentag: zeile.wochentag, p_slot_zeit_id: zeile.slot_zeit_id, p_takt: zeile.takt,
  }, 'Stammplatz konnte nicht geändert werden')
}

export function stammplatzBeenden(id: string, ab: string): Promise<SlotsResult<StammplatzErgebnis>> {
  return rpc('stammplatz_beenden', { p_id: id, p_ab: ab }, 'Stammplatz konnte nicht beendet werden')
}

export function stammplaetzeWeiterfuehren(studentId: string): Promise<SlotsResult<StammplatzErgebnis>> {
  return rpc('stammplaetze_weiterfuehren', { p_student_id: studentId }, 'Stammplätze konnten nicht weitergeführt werden')
}

// ── Termine ─────────────────────────────────────────────────────────────────

/** eingang: Zeitpunkt der Absage (ISO). Ob rechtzeitig, entscheidet der Server (10-Uhr-Regel). */
export function terminAbsagen(terminId: string, eingang: string): Promise<SlotsResult<AbsageErgebnis>> {
  return rpc('termin_absagen', { p_termin_id: terminId, p_eingang: eingang }, 'Absage konnte nicht gespeichert werden')
}

export function terminUmbuchen(
  terminId: string, eingang: string, zielDatum: string, zielZeitId: string,
): Promise<SlotsResult<UmbuchenErgebnis>> {
  return rpc('termin_umbuchen', {
    p_termin_id: terminId, p_eingang: eingang, p_ziel_datum: zielDatum, p_ziel_zeit_id: zielZeitId,
  }, 'Umbuchung konnte nicht gespeichert werden')
}

export function absageZuruecknehmen(terminId: string): Promise<SlotsResult<{ termin_id: string }>> {
  return rpc('absage_zuruecknehmen', { p_termin_id: terminId }, 'Absage konnte nicht zurückgenommen werden')
}

export function zusatzterminBuchen(studentId: string, datum: string, zeitId: string): Promise<SlotsResult<ZusatzErgebnis>> {
  return rpc('zusatztermin_buchen', { p_student_id: studentId, p_datum: datum, p_zeit_id: zeitId }, 'Zusatztermin konnte nicht gebucht werden')
}

/** Ausgefallen (durch uns): Einheit bleibt offen. */
export function terminAusgefallen(terminId: string): Promise<SlotsResult<{ termin_id: string }>> {
  return rpc('termin_ausgefallen', { p_termin_id: terminId }, 'Ausfall konnte nicht gespeichert werden')
}

/** Ganzer Termin fällt aus; liefert die Zahl der betroffenen Kinder. */
export function terminFaelltAus(datum: string, zeitId: string): Promise<SlotsResult<{ betroffen: number }>> {
  return rpc('termin_faellt_aus', { p_datum: datum, p_zeit_id: zeitId }, 'Ausfall konnte nicht gespeichert werden')
}

/** raumId null = Raum-Stift lösen (die Zuteilung entscheidet wieder). */
export function terminRaumSetzen(terminId: string, raumId: string | null): Promise<SlotsResult<{ termin_id: string }>> {
  return rpc('termin_raum_setzen', { p_termin_id: terminId, p_raum_id: raumId }, 'Raum konnte nicht gesetzt werden')
}

/** coachId null = Coach fällt aus (Raum geschlossen); Stamm-Coach = Abweichung zurücknehmen. */
export function terminCoachSetzen(datum: string, zeitId: string, raumId: string, coachId: string | null): Promise<SlotsResult<{ art: string | null }>> {
  return rpc('termin_coach_setzen', { p_datum: datum, p_zeit_id: zeitId, p_raum_id: raumId, p_coach_id: coachId },
    'Coach konnte nicht gesetzt werden')
}

export function terminRaumOeffnen(datum: string, zeitId: string, raumId: string, coachId: string): Promise<SlotsResult<{ art: string | null }>> {
  return rpc('termin_raum_oeffnen', { p_datum: datum, p_zeit_id: zeitId, p_raum_id: raumId, p_coach_id: coachId },
    'Raum konnte nicht geöffnet werden')
}

/** Admin oder Coach (eigener Raum, nur am Tag): schreibt den Raum-Termin als Session fest. */
export function terminSessionAnlegen(datum: string, zeitId: string, raumId: string): Promise<SlotsResult<SessionAnlegenErgebnis>> {
  return rpc('termin_session_anlegen', { p_datum: datum, p_zeit_id: zeitId, p_raum_id: raumId }, 'Session konnte nicht geöffnet werden')
}

// ── Stammdaten ──────────────────────────────────────────────────────────────

export function stammschichtAnlegen(
  coachId: string, wochentag: number, zeitId: string, raumId: string, gueltigAb: string | null = null,
): Promise<SlotsResult<string>> {
  return rpc('stammschicht_anlegen', {
    p_coach_id: coachId, p_wochentag: wochentag, p_slot_zeit_id: zeitId, p_raum_id: raumId, p_gueltig_ab: gueltigAb,
  }, 'Stammschicht konnte nicht angelegt werden')
}

export function stammschichtBeenden(id: string, ab: string): Promise<SlotsResult<null>> {
  return rpc('stammschicht_beenden', { p_id: id, p_ab: ab }, 'Stammschicht konnte nicht beendet werden')
}

export function raumAnlegen(name: string, aktivAb: string | null = null): Promise<SlotsResult<string>> {
  return rpc('raum_anlegen', { p_name: name, p_aktiv_ab: aktivAb }, 'Raum konnte nicht angelegt werden')
}

export function raumDeaktivieren(id: string, ab: string): Promise<SlotsResult<null>> {
  return rpc('raum_deaktivieren', { p_id: id, p_ab: ab }, 'Raum konnte nicht deaktiviert werden')
}

/** beginn: 'HH:MM' (Berlin), Dauer immer 60 Minuten. */
export function slotZeitAnlegen(beginn: string, aktivAb: string | null = null): Promise<SlotsResult<string>> {
  return rpc('slot_zeit_anlegen', { p_beginn: beginn, p_aktiv_ab: aktivAb }, 'Uhrzeit konnte nicht angelegt werden')
}

export function slotZeitDeaktivieren(id: string, ab: string): Promise<SlotsResult<null>> {
  return rpc('slot_zeit_deaktivieren', { p_id: id, p_ab: ab }, 'Uhrzeit konnte nicht deaktiviert werden')
}
