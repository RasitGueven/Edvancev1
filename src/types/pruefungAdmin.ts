// Admin-Pruefansicht (Migrationen 20261005131059, 20261005131220, 20261005131306).
// Die Formen spiegeln die Antworten von pruef_sammel und die Zeilen der neuen Tabellen.

import type { PruefAenderung, PruefEntscheidung } from './pruefung'

/** Aktionen von pruef_sammel (G7). */
export type SammelAktion =
  | 'freigeben'
  | 'an_lena'
  | 'pilot_an'
  | 'pilot_aus'
  | 'ausschliessen'
  | 'aufnehmen'
  | 'fertigkeit'
  | 'afb'

/** Feste Auslass-Schluessel von pruef_sammel; die Texte uebersetzt das Frontend (pruefenAdmin.ausgelassen.*). */
export type SammelGrund =
  | 'schon_freigegeben'
  | 'vera8'
  | 'rueckfrage_offen'
  | 'team_beanstandet'
  | 'lena_passt_nicht'
  | 'noch_nicht_bewertet'
  | 'geaendert'
  | 'befund'
  | 'freigegeben'
  | 'nicht_bei_lena'
  | 'schon_offen'
  | 'schon_im_pilot'
  | 'nicht_im_pilot'
  | 'schon_ausgeschlossen'
  | 'nicht_von_hand'
  | 'schon_drin'
  | 'ausgeschlossen'
  | 'schon_gesetzt'
  | 'nicht_erlaubt'
  | 'nicht_gefunden'
  | 'fehler'

export type SammelAusgelassen = { task_id: string; grund: SammelGrund | string; text: string | null }

/** Antwort von pruef_sammel: Vorschau und Ausfuehrung haben dieselbe Form. */
export type SammelErgebnis = { betrifft: string[]; ausgelassen: SammelAusgelassen[] }

/** Eingaben einer Sammelaktion (p_werte). */
export type SammelWerte = {
  grund?: string
  nachricht?: string
  skill_key?: string
  afb?: 'I' | 'II' | 'III'
}

export type AdminProtokollAktion =
  | SammelAktion
  | 'zurueckweisen'
  | 'freigabe_zurueck'
  | 'rueckfrage_freigeben'
  | 'rueckfrage_an_lena'
  | 'rueckfrage_zurueckweisen'

/** Eine Zeile aus task_admin_protokoll, mit dem Namen statt der ID. */
export type AdminProtokollZeile = {
  id: string
  aktion: AdminProtokollAktion
  aenderungen: PruefAenderung[]
  grund: string | null
  sammel: boolean
  von: string | null
  am: string
}

/** Lenas juengste Zeile aus task_pruefungen, fuer "Lenas Ergebnis". */
export type LenaEntscheidung = {
  entscheidung: PruefEntscheidung | 'zurueckgenommen'
  gruende: string[]
  notiz: string | null
  aenderungen: PruefAenderung[]
  aenderung_grund: string | null
  dauer_sek: number | null
  geprueft_von: string | null
  geprueft_am: string
  antwort: string | null
  beantwortet_von: string | null
  beantwortet_am: string | null
}

/** Die letzte Beanstandung durch das Team (task_reviews eines Admins). */
export type TeamBeanstandung = { gruende: string[]; notiz: string | null; von: string | null; am: string }

/** Von Hand aus Lenas Liste genommen (task_pruef_ausschluss). */
export type HandAusschluss = { grund: string; von: string | null; am: string }

/** Alles, was die Admin-Pruefansicht ueber pruef_aufgabe hinaus braucht. */
export type AdminPruefKontext = {
  /** Gab es je eine Lena-Entscheidung? Ohne sie ist "Nachricht an Lena" gesperrt. */
  lena: LenaEntscheidung | null
  team: TeamBeanstandung | null
  hand: HandAusschluss | null
  protokoll: AdminProtokollZeile[]
  /** Freigabe: wer, wann (tasks.reviewed_by/at). */
  freigabe: { von: string | null; am: string } | null
}
