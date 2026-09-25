// Vertragsprozess (Migration 20260922120000). Spiegel der Tabellen vertraege,
// vertrag_dokumente, vertrag_zustimmungen, vertrag_unterschriften, vertrag_versand.

import type { Lead, RejectionReason } from './domain'

export type VertragStatus =
  | 'in_vorbereitung'
  | 'unterschrift_ausstehend'
  | 'abgeschlossen'
  | 'abgelehnt'

/** 'vor_ort' = Canvas-Unterschrift, 'papier' = unterschrieben zurueckerhalten. */
export type VertragAbschlussWeg = 'vor_ort' | 'papier'

/**
 * Das Leben NACH dem Abschluss (Migration 20260925120000). Null, solange
 * `status` noch nicht 'abgeschlossen' ist — ein Check erzwingt beides.
 */
export type VertragLebenStatus =
  | 'im_widerruf'
  | 'aktiv'
  | 'gekuendigt'
  | 'ausgelaufen'
  | 'widerrufen'

export type Zahlungsstatus =
  | 'in_ordnung'
  | 'zahlung_offen'
  | 'mahnung_1'
  | 'mahnung_2'
  | 'inkasso'

export type VerlaengerungStatus =
  | 'offen'
  | 'kontaktiert'
  | 'gespraech_vereinbart'
  | 'verlaengert'
  | 'keine_verlaengerung'

export type Vertrag = {
  id: string
  created_at: string
  lead_id: string
  status: VertragStatus
  in_vorbereitung_at: string
  unterschrift_ausstehend_at: string | null
  abgeschlossen_at: string | null
  abgelehnt_at: string | null
  abgelehnt_grund: RejectionReason | null
  abgelehnt_notiz: string | null
  abschluss_weg: VertragAbschlussWeg | null
  unterschrieben_am: string | null

  eltern_vorname: string | null
  eltern_nachname: string | null
  strasse: string | null
  hausnummer: string | null
  plz: string | null
  ort: string | null
  eltern_telefon: string | null
  eltern_email: string | null

  kind_vorname: string | null
  kind_nachname: string | null
  kind_geburtsdatum: string | null
  klasse: number | null
  fach: string | null
  schule: string | null

  laufzeit_monate: 6 | 12 | null
  tier_id: string | null
  /** Monatsbeitrag, vom Trigger aus tier_laufzeiten gesetzt — nie aus dem Formular. */
  preis_cents: number | null
  /** Zugesagte Einheiten, vom Trigger aus tier_laufzeiten gesetzt. */
  einheiten: number | null
  vertragsbeginn: string | null

  kontoinhaber: string | null
  /** DE** **** 1234 — die volle IBAN liegt in vertrag_bankdaten. */
  iban_masked: string | null
  mandatsreferenz: string
  glaeubiger_id: string | null

  // --- Vorgang nach dem Abschluss (P1/P2) ---------------------------------
  student_id: string | null
  schule_id: string | null
  vorgaenger_id: string | null
  vertrag_status: VertragLebenStatus | null
  /** Fachlicher Abschlusstag. Nicht abgeschlossen_at, dem Systemzeitpunkt. */
  abgeschlossen_am: string | null
  eingang_datum: string | null
  /** Beim Abschluss eingefroren — eine spaetere Ferienkorrektur aendert ihn nicht. */
  vertrag_ende: string | null
  ferientage: number | null
  widerruf_bis: string | null
  widerrufen_am: string | null
  gekuendigt_zum: string | null
  kuendigung_grund: string | null
  zahlungsstatus: Zahlungsstatus
  zahlungsstatus_seit: string | null
  offener_betrag_cents: number | null
  verlaengerung_status: VerlaengerungStatus | null
  verlaengerung_grund: string | null
  wiedervorlage_am: string | null
  rueckmeldung_bis: string | null
  abweichung_vermerk: string | null
  /** Anzeigeform EDV-XXXX-XXXX. Erst ab Abschluss gesetzt. */
  zugangscode: string | null
  zugangscode_erzeugt_am: string | null
  zugangscode_gesperrt_am: string | null
  /** Pfad des Ruecklauf-Scans im Bucket "vertraege". */
  scan_pfad: string | null
}

/** Vertrag mit dem Lead, aus dem er entstanden ist (Board + Konversion). */
export type VertragMitLead = Vertrag & { lead: Lead }

/** Was das Formular schreiben darf — solange der Vertrag in Vorbereitung ist. */
export type VertragPatch = Partial<
  Pick<
    Vertrag,
    | 'eltern_vorname'
    | 'eltern_nachname'
    | 'strasse'
    | 'hausnummer'
    | 'plz'
    | 'ort'
    | 'eltern_telefon'
    | 'eltern_email'
    | 'kind_vorname'
    | 'kind_nachname'
    | 'kind_geburtsdatum'
    | 'klasse'
    | 'fach'
    | 'schule'
    | 'schule_id'
    | 'laufzeit_monate'
    | 'tier_id'
    | 'vertragsbeginn'
    | 'kontoinhaber'
  >
>

export type VertragDokument = {
  schluessel: string
  version: string
  titel: string
  pflicht: boolean
  sort_order: number
}

export type VertragZustimmung = {
  dokument_schluessel: string
  dokument_version: string
  akzeptiert_at: string
}

export type VertragUnterschrift = {
  art: 'vertrag' | 'sepa_mandat'
  signatur: string
  unterschrieben_at: string
}

export type VertragVersand = {
  id: string
  weg: 'email' | 'druck'
  anlass: 'unterlagen' | 'bestaetigung'
  empfaenger: string | null
  erfolgt_at: string
}
