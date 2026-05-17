import { supabase } from '@/lib/supabase/client'
import type { Lead, LeadInput, LeadStatus, SupabaseResult } from '@/types'

// Legt einen Lead an (Erstgespraech Stufe A). Status defaultet DB-seitig 'new'.
export async function createLead(input: LeadInput): Promise<SupabaseResult<Lead>> {
  try {
    const { data, error } = await supabase
      .from('leads')
      .insert({
        full_name: input.full_name,
        contact_email: input.contact_email ?? null,
        contact_phone: input.contact_phone ?? null,
        class_level: input.class_level ?? null,
        school_type: input.school_type ?? null,
        school_name: input.school_name ?? null,
        subjects: input.subjects ?? [],
        goal: input.goal ?? null,
        known_weak_topics: input.known_weak_topics ?? [],
        source: input.source ?? null,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Lead, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Lead konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

// Leads, optional auf einen Status gefiltert, neueste zuerst.
export async function listLeads(status?: LeadStatus): Promise<SupabaseResult<Lead[]>> {
  try {
    let query = supabase.from('leads').select('*')
    if (status) query = query.eq('status', status)
    const { data, error } = await query.order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Lead[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Leads konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Einzelner Lead per id (kann fehlen → null).
export async function getLeadById(id: string): Promise<SupabaseResult<Lead | null>> {
  try {
    const { data, error } = await supabase
      .from('leads')
      .select('*')
      .eq('id', id)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as Lead | null) ?? null, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Lead konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

type LeadPatch = Partial<
  Pick<
    Lead,
    | 'status'
    | 'owner_id'
    | 'notes'
    | 'contacted_at'
    | 'onboarding_scheduled_at'
    | 'converted_student_id'
  >
>

// Aktualisiert Status/Owner/Notizen/Termine eines Leads.
export async function updateLead(
  id: string,
  patch: LeadPatch,
): Promise<SupabaseResult<Lead>> {
  try {
    const { data, error } = await supabase
      .from('leads')
      .update(patch)
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Lead, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Lead konnte nicht aktualisiert werden'
    return { data: null, error: message }
  }
}
