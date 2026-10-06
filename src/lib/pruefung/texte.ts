// Kurztitel, Satz zum Antworttyp und Fehlerschluessel fuer das Lena-Board.
// Reine Funktionen; die Texte selbst stehen in src/i18n/locales/de/pruefen.json.

import type { PruefAufgabe, PruefFehlerInfo } from '@/types'

/** Wie pruef_kurztitel: der Titel ohne fuehrendes "AFB I · ", "AFB II · " oder "AFB III · ". */
export function kurztitel(title: string | null | undefined): string {
  return (title ?? '').replace(/^AFB (I|II|III) · /, '')
}

export type Satz = { key: string; count?: number; einheit?: string }

/**
 * Der Satz zum Antworttyp unter der Kinderansicht (Entscheidung 31), als i18n-Schluessel.
 * Danach folgt immer "In der Lernstandsanalyse bekommt es keine Rueckmeldung und keine Loesung."
 */
export function satzZumAntworttyp(aufgabe: Pick<PruefAufgabe['aufgabe'], 'input_type' | 'unit' | 'parts' | 'optionen'>): Satz {
  switch (aufgabe.input_type) {
    case 'MC':
      return { key: 'antworttyp.mc', count: aufgabe.optionen.length }
    case 'MULTI_PART':
      return { key: 'antworttyp.teile', count: aufgabe.parts.length }
    case 'TERM':
      return { key: 'antworttyp.term' }
    case 'SHORT_TEXT':
      return aufgabe.unit ? { key: 'antworttyp.text_einheit', einheit: aufgabe.unit } : { key: 'antworttyp.text' }
    default:
      return aufgabe.unit ? { key: 'antworttyp.zahl_einheit', einheit: aufgabe.unit } : { key: 'antworttyp.zahl' }
  }
}

/** ED422-Schluessel, die das Frontend uebersetzt (HINT aus pruef_fehler). */
export const BEKANNTE_HINWEISE = [
  'freigegeben',
  'ausgeschlossen',
  'mc_unbekannt',
  'options_bewertet',
  'bereich_ungueltig',
  'einheit_unzulaessig',
  'einheit_fehlt',
  'einheit_am_feld',
  'fehlbild_unbekannt',
  'fehler_wert_fehlt',
  'teil_unbekannt',
  'fertigkeit_unzulaessig',
  'afb_ungueltig',
  'regel_ungueltig',
  'aenderung_grund_fehlt',
  'antwort_fehlt',
  'gate',
  'notiz_fehlt',
  'grund_fehlt',
  'grund_unbekannt',
  'nicht_bewertet',
  'keine_rueckfrage',
  'team_beanstandet',
  'hinweis_ungueltig',
  'hinweis_zu_lang',
  'hinweis_luecke',
] as const

/** i18n-Schluessel (Namespace pruefen) zu einem Fehler aus einem pruef_*-Aufruf. */
export function fehlerSchluessel(err: PruefFehlerInfo | null): string | null {
  if (!err) return null
  if (err.code === 'ED409') return 'fehlermeldung.version'
  if (err.code === 'ED422') {
    const hint = err.hint ?? ''
    return (BEKANNTE_HINWEISE as readonly string[]).includes(hint) ? `fehlermeldung.${hint}` : 'fehlermeldung.eingabe'
  }
  if (err.code === '42501') return 'fehlermeldung.kein_recht'
  if (err.code === 'P0002') return 'fehlermeldung.nicht_gefunden'
  return 'fehlermeldung.allgemein'
}
