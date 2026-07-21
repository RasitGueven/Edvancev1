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
        // Intake-Felder (S7): direkt beim Anlegen, damit das Erstgespraech in
        // einem Rutsch am Empfang erfasst werden kann.
        first_name: input.first_name ?? null,
        birth_date: input.birth_date ?? null,
        last_grade: input.last_grade ?? null,
        grade_trend: input.grade_trend ?? null,
        struggling_since: input.struggling_since ?? null,
        tried_before: input.tried_before ?? null,
        next_exam_date: input.next_exam_date ?? null,
        next_exam_topic: input.next_exam_topic ?? null,
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

type LeadPatch = Partial<
  Pick<
    Lead,
    | 'status'
    | 'owner_id'
    | 'notes'
    | 'contacted_at'
    | 'onboarding_scheduled_at'
    | 'converted_student_id'
    // Intake-Felder (S7, Erstgespraech) — beim Weiterpflegen eines Leads.
    | 'full_name'
    | 'first_name'
    | 'birth_date'
    | 'contact_email'
    | 'contact_phone'
    | 'class_level'
    | 'school_type'
    | 'school_name'
    | 'subjects'
    | 'last_grade'
    | 'grade_trend'
    | 'struggling_since'
    | 'tried_before'
    | 'next_exam_date'
    | 'next_exam_topic'
    | 'consent_dsgvo_at'
    | 'consent_dsgvo_by'
  >
>

// Dokumentiert die DSGVO-Einwilligung der Eltern: Zeitpunkt + der bestaetigende
// Admin. PFLICHT-Gate vor der LSA-Freigabe (lead_lsa_freigeben verweigert ohne).
export async function setLeadConsent(
  id: string,
  adminProfileId: string,
): Promise<SupabaseResult<Lead>> {
  return updateLead(id, {
    consent_dsgvo_at: new Date().toISOString(),
    consent_dsgvo_by: adminProfileId,
  })
}

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
