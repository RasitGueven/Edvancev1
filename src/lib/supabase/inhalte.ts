import { rufe } from '@/lib/supabase/pruefung'
import type { PruefResult } from '@/types'
import type {
  InhalteKompetenz,
  InhaltePruefzielBereich,
  InhalteReihe,
  InhalteSession,
  InhalteThema,
  InhalteThemaOhneReihe,
} from '@/types/inhalte'

/**
 * IU-1: Inhalte-Übersicht (Migration 20261113082550_iu1_inhalte). Alle Funktionen nur für Admins; die Datenbank
 * prüft das. Nicht in database.ts — rufe() hält den Cast an einer Stelle (Muster lsaAbdeckung.ts).
 */

/** Rechnet die Zwischenspeicher neu, wenn nötig (FR-2-Pakete und Stand je Skill). */
export function frischeInhalte(): Promise<PruefResult<boolean>> {
  return rufe<boolean>('inhalte_auffrischen')
}

export function getLsaThemen(klasse: number | null): Promise<PruefResult<InhalteThema[]>> {
  return rufe<InhalteThema[]>('inhalte_lsa_themen', { p_klasse: klasse })
}

export function getLsaThema(themaKey: string): Promise<PruefResult<InhalteKompetenz[]>> {
  return rufe<InhalteKompetenz[]>('inhalte_lsa_thema', { p_thema_key: themaKey })
}

export function getLsaPruefziel(key: string): Promise<PruefResult<InhaltePruefzielBereich[]>> {
  return rufe<InhaltePruefzielBereich[]>('inhalte_lsa_pruefziel', { p_key: key })
}

export function getSessionReihen(klasse: number | null): Promise<PruefResult<InhalteReihe[]>> {
  return rufe<InhalteReihe[]>('inhalte_session_reihen', { p_klasse: klasse })
}

export function getSessionReihe(reihe: string): Promise<PruefResult<InhalteSession[]>> {
  return rufe<InhalteSession[]>('inhalte_session_reihe', { p_reihe: reihe })
}

export function getThemenOhneReihe(klasse: number | null): Promise<PruefResult<InhalteThemaOhneReihe[]>> {
  return rufe<InhalteThemaOhneReihe[]>('inhalte_themen_ohne_reihe', { p_klasse: klasse })
}
