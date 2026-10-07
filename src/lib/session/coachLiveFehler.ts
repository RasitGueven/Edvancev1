// Session-Rahmen C2: Fehler der Coach-Funktionen auf die Fehler-Codes der Live-Sicht abbilden
// (offene-punkte-c1 Nr. 10). Die Seite zeigt nur i18n-Texte (coachLive:fehler.<code>), nie den
// Rohtext der Datenbank. Unbekanntes wird 'allgemein'.

import type { RpcFehler } from '@/lib/supabase/sessionRpc'
import type { SupabaseResult } from '@/types/ui'

export type CoachLiveFehler =
  | 'fehlbildPflicht'
  | 'grundPflicht'
  | 'ohneTabletOffen'
  | 'tabletBelegt'
  | 'abgeschlossen'
  | 'keinRecht'
  | 'nichtGefunden'
  | 'nichtGebucht'
  | 'keinTablet'
  | 'keinePruefung'
  | 'keinePruefungAktiv'
  | 'raumVoll'
  | 'schonZugewiesen'
  | 'tabletUnbekannt'
  | 'keinLead'
  | 'gesundheitsbegriff'
  | 'spanne'
  | 'eingabe'
  | 'zustand'
  | 'allgemein'

/** Hinweis-Codes der Coach-Funktionen (hint in der Datenbank-Meldung). */
const HINWEIS: Record<string, CoachLiveFehler> = {
  fehlbild_pflicht: 'fehlbildPflicht',
  tablet_belegt: 'tabletBelegt',
  kein_tablet: 'keinTablet',
  keine_pruefung: 'keinePruefung',
  keine_aktive_pruefung: 'keinePruefungAktiv',
  nicht_gebucht: 'nichtGebucht',
  raum_voll: 'raumVoll',
  schon_zugewiesen: 'schonZugewiesen',
  tablet_unbekannt: 'tabletUnbekannt',
  kein_lead: 'keinLead',
  gesundheitsbegriff: 'gesundheitsbegriff',
  spanne: 'spanne',
}

/** SQLSTATE ohne passenden Hinweis. */
const SQLSTATE: Record<string, CoachLiveFehler> = {
  '42501': 'keinRecht',
  P0002: 'nichtGefunden',
  '22023': 'eingabe',
  P0001: 'zustand',
}

/**
 * Hinweis vor SQLSTATE. `kontext` ueberschreibt die SQLSTATE-Zuordnung fuer eine Aktion
 * (z. B. 22023 bei „vertagen“ heisst: Grund fehlt).
 */
export function fehlerCode(f: RpcFehler, kontext: Partial<Record<string, CoachLiveFehler>> = {}): CoachLiveFehler {
  const hint = f.hint?.split(':')[0] ?? ''
  if (hint && HINWEIS[hint]) return HINWEIS[hint]
  const code = f.code ?? ''
  return kontext[code] ?? SQLSTATE[code] ?? 'allgemein'
}

/** Ergebnis einer Aktion fuer die Seite: Erfolg ohne Daten oder ein Fehler-Code. */
export function alsAktion(
  res: SupabaseResult<unknown> & RpcFehler,
  kontext?: Partial<Record<string, CoachLiveFehler>>,
): SupabaseResult<null> {
  return res.error === null ? { data: null, error: null } : { data: null, error: fehlerCode(res, kontext) }
}
