// Lena-Board "Aufgaben pruefen" (Migrationen 20261005071058 … 20261005071650).
// Die Formen spiegeln die jsonb-Antworten der pruef_*-Funktionen.

import type { Stufe } from './themen'
import type { Afb } from './authoring'

/** Lenas Sicht auf tasks.status (pruef_lena_status). */
export type LenaStatus = 'offen' | 'passt' | 'unsicher' | 'passt_nicht' | 'freigegeben'

export type PruefEntscheidung = 'passt' | 'unsicher' | 'passt_nicht'

/** Gruende fuer "Passt nicht" (task_reviews.kategorie, Migration 1). */
export type PasstNichtGrund =
  | 'aufgabe_fehlerhaft'
  | 'aufgabe_unklar'
  | 'bild_falsch'
  | 'sprache_zu_schwer'
  | 'tablet_umbauen'
  | 'passt_nicht_in_lsa'
  | 'sonstiges'

/** Eine Zeile aus pruef_board(), in der Reihenfolge aus Entscheidung 14. */
export type PruefBoardZeile = {
  task_id: string
  stufe: Stufe
  thema_key: string
  thema_label: string
  thema_sort: number | null
  skill_key: string | null
  skill_label: string | null
  kurztitel: string
  reihenfolge: number
  lena_status: LenaStatus
  geaendert: boolean
  letzte_dauer_sek: number | null
}

export type PruefWert = { wert: string; schreibweisen: string[] }

/** Richtige Werte eines Teils; teil null = einteilige Aufgabe. */
export type PruefWerteTeil = { teil: number | null; werte: PruefWert[] }

export type PruefRegel = {
  art: 'wert' | 'bereich'
  mitte: string | null
  toleranz: number | null
  einheit_pflicht: boolean
  einheit: string | null
  einheit_am_feld: boolean
}

export type PruefFehlerWert = { teil: number | null; wert: string }

/** Ein typischer Fehler (Fehlbild) mit den Werten, die ihn ausloesen. */
export type PruefFehler = {
  slug: string
  werte: PruefFehlerWert[]
  text: string | null
  klartext?: string | null
}

export type PruefHinweis = { error: string; socratic_question?: string }

/** pruef_sicht: eine Fassung so, wie Lena sie sieht. */
export type PruefSicht = {
  werte: PruefWerteTeil[]
  mc: string | null
  regel: PruefRegel | null
  fehler: PruefFehler[]
  weitere_hinweise: PruefHinweis[]
  skill_key: string | null
  afb: Afb | null
  flach_regel: boolean
  ohne_erkennung: boolean
}

export type PruefAenderungFeld =
  | 'richtige_antwort'
  | 'wertung'
  | 'einheit_pflicht'
  | 'typischer_fehler'
  | 'fertigkeit'
  | 'anforderungsbereich'

/** Ein Eintrag aus task_pruefungen.aenderungen. vorher/nachher je nach Feld. */
export type PruefAenderung = {
  feld: PruefAenderungFeld
  teil: number | null
  vorher: unknown
  nachher: unknown
}

export type PruefAuffaelligkeitCode =
  | 'fehler_als_richtig'
  | 'werte_widersprechen'
  | 'mc_richtig_ist_fehler'
  | 'mc_ablenker_ohne_fehlbild'
  | 'teil_fehler_ist_richtig'
  | 'loesungsweg_endet_falsch'

export type PruefAuffaelligkeit = {
  code: PruefAuffaelligkeitCode
  teil: number | null
  wert: string
  stufe?: 'teilweise' | 'nicht'
}

export type PruefOption = { id: string; label: string }

export type PruefTeil = {
  nr: number
  kind: 'short_input' | 'mc'
  prompt: string
  unit: string | null
  options: PruefOption[]
}

export type PruefFertigkeitOption = { key: string; label: string; gruppe: 'thema' | 'voraussetzung' }

export type PruefLetzte = {
  entscheidung: PruefEntscheidung | 'zurueckgenommen'
  gruende: string[]
  notiz: string | null
  antwort: string | null
  beantwortet_am: string | null
  geprueft_am: string
}

/** pruef_aufgabe(task_id): alles fuer die Pruefkarte. */
export type PruefAufgabe = {
  task_id: string
  kopf: {
    kurztitel: string
    stufe: Stufe | null
    thema_key: string | null
    thema_label: string | null
    hilfsmittel: string | null
  }
  aufgabe: {
    input_type: 'MC' | 'NUMERIC' | 'SHORT_TEXT' | 'MULTI_PART' | 'TERM'
    unit: string | null
    status: string
    lena_status: LenaStatus
    pruef_version: number
    ausschluss: string | null
    pilot: boolean
    parts: PruefTeil[]
    optionen: PruefOption[]
    bild_vorhanden: boolean
  }
  werte: PruefWerteTeil[]
  mc: string | null
  regel: PruefRegel | null
  fehler: PruefFehler[]
  weitere_hinweise: PruefHinweis[]
  flach_regel: boolean
  ohne_erkennung: boolean
  loesungsweg: string | null
  fertigkeit: {
    key: string
    label: string
    thema_key: string | null
    thema_label: string | null
    stufe: Stufe | null
    voraussetzungen: string[]
  } | null
  fertigkeit_optionen: PruefFertigkeitOption[]
  afb: Afb | null
  afb_sicher: string | null
  ausgang: PruefSicht | null
  aenderungen: PruefAenderung[]
  letzte_pruefung: PruefLetzte | null
  auffaelligkeiten: PruefAuffaelligkeit[]
}

/** Was pruef_speichern und pruef_wertung_testen bekommen (Entscheidung 16). */
export type PruefEntwurf = {
  werte: { teil: number | null; werte: string[] }[]
  mc: string | null
  regel: { art: 'wert' | 'bereich'; mitte: string | null; toleranz: string | null; einheit_pflicht: boolean } | null
  fehler: { slug: string; werte: PruefFehlerWert[]; text: string | null }[]
  skill_key: string | null
  afb: Afb | null
}

export type PruefSpeichernAntwort = {
  pruef_version: number
  auffaelligkeiten: PruefAuffaelligkeit[]
  aenderungen: PruefAenderung[]
}

export type PruefEntscheidenAntwort = { pruef_version: number; lena_status: LenaStatus }

export type PruefWertung = {
  stufe: 'voll' | 'teilweise' | 'nicht' | null
  fehlbild_slug?: string | null
  fehlbild_klartext?: string | null
  fehler?: string
}

/** Fehler eines pruef_*-Aufrufs: SQLSTATE und HINT bleiben fuer die Uebersetzung erhalten. */
export type PruefFehlerInfo = { code: string | null; hint: string | null; message: string }

export type PruefResult<T> = { data: T | null; error: PruefFehlerInfo | null }

export type PruefEinstellungen = { hilfsmittel: string; nur_pilot: boolean; grund_pflicht: boolean }

export type PruefRueckfrageAktion = 'freigeben' | 'zurueckweisen' | 'an_lena'

/** Eine Zeile aus pruef_admin_liste() fuer Item-Pflege und Expertenliste. */
export type PruefAdminZeile = {
  task_id: string
  lena_status: LenaStatus
  ausschluss: string | null
  pilot: boolean
  entscheidung: PruefEntscheidung | 'zurueckgenommen' | null
  gruende: string[] | null
  notiz: string | null
  aenderungen: PruefAenderung[] | null
  aenderung_grund: string | null
  dauer_sek: number | null
  geprueft_von: string | null
  geprueft_am: string | null
  antwort: string | null
  beantwortet_am: string | null
  geaendert: boolean
}

export type Fehlbild = { slug: string; klartext: string | null }
