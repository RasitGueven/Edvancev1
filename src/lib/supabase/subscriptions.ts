import { supabase } from '@/lib/supabase/client'
import type { StudentSubscription, SupabaseResult, TierPlan } from '@/types'

// Aktiver Tarifkatalog, sortiert (ersetzt hardcodierte TIERS-Konstante).
export async function listTiers(): Promise<SupabaseResult<TierPlan[]>> {
  try {
    const { data, error } = await supabase
      .from('tiers')
      .select('*')
      .eq('active', true)
      .order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as TierPlan[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Tarife konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Aktuelles aktives Abo eines Schuelers (kann fehlen → null).
export async function getActiveSubscription(
  studentId: string,
): Promise<SupabaseResult<StudentSubscription | null>> {
  try {
    const { data, error } = await supabase
      .from('student_subscriptions')
      .select('*')
      .eq('student_id', studentId)
      .eq('status', 'active')
      .order('started_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as StudentSubscription | null) ?? null, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Abo konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Beendet bestehende aktive Abos und legt ein neues aktives Abo an.
export async function setSubscription(
  studentId: string,
  tierId: string,
): Promise<SupabaseResult<StudentSubscription>> {
  try {
    const nowIso = new Date().toISOString()
    const { error: cancelErr } = await supabase
      .from('student_subscriptions')
      .update({ status: 'cancelled', ended_at: nowIso })
      .eq('student_id', studentId)
      .eq('status', 'active')
    if (cancelErr) return { data: null, error: cancelErr.message }
    const { data, error } = await supabase
      .from('student_subscriptions')
      .insert({ student_id: studentId, tier_id: tierId, status: 'active' })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as StudentSubscription, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Abo konnte nicht gesetzt werden'
    return { data: null, error: message }
  }
}
