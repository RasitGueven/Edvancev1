// Session-Rahmen C2: Regeln der Stellschrauben-Seite, wie session_einstellung_gueltig in der
// Datenbank (20261007110100_session_einstellungen.sql). Die Datenbank prueft ein zweites Mal
// (einstellung_setzen: 22023); die Seite laesst Speichern gar nicht erst zu.

import type { Stellschraube, StellschraubeWert } from '@/types/sessionLive'

/** Eingabe aus dem Formular in einen Wert des Typs der Stellschraube; null = keine gueltige Zahl. */
export function wertAusEingabe(s: Stellschraube, roh: string | boolean): StellschraubeWert | null {
  if (s.typ === 'schalter') return typeof roh === 'boolean' ? roh : roh === 'true'
  if (s.typ === 'auswahl') return typeof roh === 'string' && roh !== '' ? roh : null
  const text = String(roh).trim().replace(',', '.')
  if (text === '') return null
  const n = Number(text)
  return Number.isFinite(n) ? n : null
}

export function wertGueltig(s: Stellschraube, wert: StellschraubeWert | null): boolean {
  if (wert === null) return false
  if (s.typ === 'schalter') return typeof wert === 'boolean'
  if (s.typ === 'auswahl') return typeof wert === 'string' && (s.werte ?? []).includes(wert)
  if (typeof wert !== 'number' || s.min === null || s.max === null) return false
  if (wert < s.min || wert > s.max) return false
  return !s.ganzzahl || Number.isInteger(wert)
}

export type SpeichernSperre = 'grundFehlt' | 'ausserhalb' | 'unveraendert'

/** null = Speichern moeglich; sonst der Grund, warum nicht (fuer den Tooltip am Knopf). */
export function speichernSperre(s: Stellschraube, wert: StellschraubeWert | null, grund: string): SpeichernSperre | null {
  if (!wertGueltig(s, wert)) return 'ausserhalb'
  if (wert === s.wert) return 'unveraendert'
  if (grund.trim() === '') return 'grundFehlt'
  return null
}
