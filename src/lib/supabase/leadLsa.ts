// Lead→LSA-Flow (S7): Freigabe, Konversion, Eltern-/Kind-Einschätzung.
// Dünne Wrapper um die SECURITY-DEFINER-RPCs — die Autorisierung (admin bzw.
// coach/admin) und alle Gates (DSGVO-Consent, Idempotenz) liegen in der DB.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type LeadLsaFreigabe = {
  session_id: string
  student_id: string
  total_items: number
}

// LSA-Freigabe für einen Lead (nur Admin). Legt idempotent den provisorischen
// Schüler an und startet die Session über lsa_start. Verweigert ohne
// DSGVO-Einwilligung (consent_dsgvo_at).
export async function leadLsaFreigeben(
  leadId: string,
  grade: number,
  subject: string,
): Promise<SupabaseResult<LeadLsaFreigabe>> {
  try {
    const { data, error } = await supabase.rpc('lead_lsa_freigeben', {
      p_lead_id: leadId,
      p_grade: grade,
      p_subject: subject,
    })
    if (error) return { data: null, error: error.message }
    return { data: data as LeadLsaFreigabe, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'LSA-Freigabe fehlgeschlagen'
    return { data: null, error: message }
  }
}

// Konversion Lead → Schüler (nur Admin): Datensatz-Flip des provisorischen
// Schülers. Das Anlegen des Auth-Kontos folgt separat.
export async function leadConvert(
  leadId: string,
): Promise<SupabaseResult<{ ok: boolean; student_id: string }>> {
  try {
    const { data, error } = await supabase.rpc('lead_convert', {
      p_lead_id: leadId,
    })
    if (error) return { data: null, error: error.message }
    return { data: data as { ok: boolean; student_id: string }, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Konversion fehlgeschlagen'
    return { data: null, error: message }
  }
}

// Upsert der Eltern-/Kind-Einschätzung (coach/admin) auf (lead_id, source).
// Reveal-Metadatum — nie Input für die LSA-Aufgabenauswahl (A3-Invariante).
export async function leadAssessmentUpsert(
  leadId: string,
  source: 'parent' | 'child',
  note: string | null,
  weakTopics: string[] = [],
): Promise<SupabaseResult<{ ok: boolean; assessment_id: string }>> {
  try {
    const { data, error } = await supabase.rpc('lead_assessment_upsert', {
      p_lead_id: leadId,
      p_source: source,
      p_note: note,
      p_weak_topics: weakTopics,
    })
    if (error) return { data: null, error: error.message }
    return {
      data: data as { ok: boolean; assessment_id: string },
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Einschätzung konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}
