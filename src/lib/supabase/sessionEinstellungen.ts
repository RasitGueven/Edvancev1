// Session-Rahmen R1: Stellschrauben (lesen authenticated, setzen nur Admin mit
// Grund und Spannen-Pruefung) und offene Flags aus dem Check-out (nur Admin).

import { supabase } from '@/lib/supabase/client'
import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type {
  OffenesFlag,
  SessionFlag,
  Stellschraube,
  StellschraubeProtokoll,
  StellschraubeWert,
  SupabaseResult,
} from '@/types'

export async function listStellschrauben(): Promise<SupabaseResult<Stellschraube[]>> {
  try {
    const { data, error } = await supabase
      .from('session_einstellungen')
      .select('schluessel, beschreibung, typ, wert, startwert, min, max, ganzzahl, werte, einheit, geaendert_am')
      .order('schluessel', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Stellschraube[], error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Could not load settings' }
  }
}

export async function listStellschraubenProtokoll(schluessel?: string): Promise<SupabaseResult<StellschraubeProtokoll[]>> {
  try {
    let q = supabase
      .from('session_einstellungen_protokoll')
      .select('id, schluessel, alt, neu, grund, von, am')
      .order('am', { ascending: false })
    if (schluessel) q = q.eq('schluessel', schluessel)
    const { data, error } = await q
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as StellschraubeProtokoll[], error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Could not load settings log' }
  }
}

/** Ausserhalb der Spanne oder ohne Grund: 22023 von der Datenbank. */
export const stellschraubeSetzen = (
  schluessel: string,
  wert: StellschraubeWert,
  grund: string,
): Promise<RpcResult<null>> =>
  sessionRpc('einstellung_setzen', { p_schluessel: schluessel, p_wert: wert, p_grund: grund },
    'Could not save setting')

export const listOffeneFlags = (): Promise<RpcResult<OffenesFlag[]>> =>
  sessionRpc('session_flags_offen', {}, 'Could not load open flags')

export const flagErledigen = (sessionId: string, studentId: string, flag: SessionFlag): Promise<RpcResult<null>> =>
  sessionRpc('session_flag_erledigen', { p_session_id: sessionId, p_student_id: studentId, p_flag: flag },
    'Could not resolve flag')
