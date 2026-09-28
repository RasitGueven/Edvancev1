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

/** Ein Vertrag aus der Sicht. null, wenn er nicht (mehr) abgeschlossen ist. */
export async function getVertragAktuell(id: string): Promise<SupabaseResult<VertragAktuell | null>> {
  try {
    const { data, error } = await supabase
      .from('vertraege_aktuell')
      .select('*')
      .eq('id', id)
      .maybeSingle()
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: (data as VertragAktuell | null) ?? null, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Vertrag konnte nicht geladen werden'
    return { data: null, error: msg }
  }
}

/** Alle abgeschlossenen Vertraege eines Kindes — juengster zuerst. */
export async function listVertragHistorie(
  studentId: string,
): Promise<SupabaseResult<VertragAktuell[]>> {
  try {
    const { data, error } = await supabase
      .from('vertraege_aktuell')
      .select('*')
      .eq('student_id', studentId)
      .order('vertragsbeginn', { ascending: false })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: (data ?? []) as VertragAktuell[], error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Historie konnte nicht geladen werden'
    return { data: null, error: msg }
  }
}

/**
 * Die vollstaendige IBAN. Der Aufruf wird protokolliert (Entscheidung 17) —
 * die RPC schreibt den audit_log-Eintrag, bevor sie die Zahl herausgibt.
 *
 * Bewusst keine Speicherung im Zustand der Seite ueber das Aufdecken hinaus und
 * nie in der Adresszeile: eine IBAN, die im Verlauf des Browsers steht, ist
 * aufgedeckt geblieben.
 */
export async function vertragIbanAnzeigen(vertragId: string): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.rpc('vertrag_iban_anzeigen', {
      p_vertrag_id: vertragId,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: data as string, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'IBAN konnte nicht angezeigt werden'
    return { data: null, error: msg }
  }
}

export async function vertragZugangscodeNeu(vertragId: string): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.rpc('vertrag_zugangscode_neu', {
      p_vertrag_id: vertragId,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: data as string, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Zugangscode konnte nicht erzeugt werden'
    return { data: null, error: msg }
  }
}

export async function vertragWiderrufErfassen(
  vertragId: string,
  datum: string,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('vertrag_widerruf_erfassen', {
      p_vertrag_id: vertragId,
      p_datum: datum,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: true, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Widerruf konnte nicht erfasst werden'
    return { data: null, error: msg }
  }
}

export async function vertragSonderkuendigungErfassen(
  vertragId: string,
  zum: string,
  grund: string,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('vertrag_sonderkuendigung_erfassen', {
      p_vertrag_id: vertragId,
      p_zum: zum,
      p_grund: grund,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: true, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Kündigung konnte nicht erfasst werden'
    return { data: null, error: msg }
  }
}

/** Neuer Antrag aus einem bestehenden Vertrag. Idempotent. */
export async function vertragFolgevertragStarten(
  vorgaengerId: string,
): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.rpc('vertrag_folgevertrag_starten', {
      p_vorgaenger_id: vorgaengerId,
    })
    if (error) return { data: null, error: lesbar(error.message) }
    return { data: data as string, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Folgevertrag konnte nicht gestartet werden'
    return { data: null, error: msg }
  }
}
