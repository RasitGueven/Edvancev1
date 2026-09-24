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
  /** Vom Trigger aus tiers gesetzt — nie aus dem Formular. */
  preis_cents: number | null
  vertragsbeginn: string | null

  kontoinhaber: string | null
  /** DE** **** 1234 — die volle IBAN liegt in vertrag_bankdaten. */
  iban_masked: string | null
  mandatsreferenz: string
  glaeubiger_id: string | null
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
