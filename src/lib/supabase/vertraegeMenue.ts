// Datenzugriff des Menues "Vertraege".
//
// Gelesen wird aus der Sicht vertraege_aktuell, geschrieben ueber die RPCs aus
// P3a. Beides liegt hinter RLS bzw. einem Admin-Gate; das Frontend prueft keine
// Rollen nach, es zeigt nur, was zurueckkommt.

import { supabase } from '@/lib/supabase/client'
import type {
  SupabaseResult,
  VertragAktuell,
  VerlaengerungStatus,
  Zahlungsstatus,
} from '@/types'

/** Postgres-Meldungen sind fuer Entwickler geschrieben, nicht fuer den Empfang. */
function lesbar(roh: string): string {
  // Die RPCs melden "funktionsname: Klartext" — davor steht nichts, was am
  // Empfang hilft.
  const m = /^[a-z_]+:\s*(.+)$/s.exec(roh)
  return m ? m[1] : roh
}

export async function listVertraegeAktuell(): Promise<SupabaseResult<VertragAktuell[]>> {
  try {
    const { data, error } = await supabase
      .from('vertraege_aktuell')
      .select('*')
      .order('vertragsbeginn', { ascending: false })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: (data ?? []) as VertragAktuell[], error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Vertraege konnten nicht geladen werden'
    return { data: null, error: msg }
  }
}

export async function vertragVerlaengerungSetzen(
  vertragId: string,
  status: Exclude<VerlaengerungStatus, 'verlaengert'>,
  grund: string | null = null,
  wiedervorlageAm: string | null = null,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('vertrag_verlaengerung_setzen', {
      p_vertrag_id: vertragId,
      p_status: status,
      p_grund: grund,
      p_wiedervorlage_am: wiedervorlageAm,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: true, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Verlängerung konnte nicht gesetzt werden'
    return { data: null, error: msg }
  }
}

export async function vertragZahlungsstatusSetzen(
  vertragId: string,
  status: Zahlungsstatus,
  offenerBetragCents: number | null = null,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('vertrag_zahlungsstatus_setzen', {
      p_vertrag_id: vertragId,
      p_status: status,
      p_offener_betrag_cents: offenerBetragCents,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: true, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Zahlungsstatus konnte nicht gesetzt werden'
    return { data: null, error: msg }
  }
}
