import { supabase } from '@/lib/supabase/client'
import type { IntakeInput, IntakeSession, SupabaseResult } from '@/types'

// Legt ein Erstgespraech-Protokoll an (Stufe B). Status defaultet 'draft'.
export async function createIntakeSession(
  input: IntakeInput,
): Promise<SupabaseResult<IntakeSession>> {
  try {
    const { data, error } = await supabase
      .from('intake_sessions')
      .insert({
        student_id: input.student_id,
        lead_id: input.lead_id ?? null,
        coach_id: input.coach_id ?? null,
        conducted_at: input.conducted_at ?? null,
        goals: input.goals ?? null,
        motivation: input.motivation ?? null,
        learning_history: input.learning_history ?? null,
        parent_expectations: input.parent_expectations ?? null,
        known_weak_topics: input.known_weak_topics ?? [],
        agreed_next_steps: input.agreed_next_steps ?? null,
        notes: input.notes ?? null,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as IntakeSession, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Erstgespraech konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

// Alle Protokolle eines Schuelers, neueste zuerst.
export async function getIntakeByStudent(
  studentId: string,
): Promise<SupabaseResult<IntakeSession[]>> {
  try {
    const { data, error } = await supabase
      .from('intake_sessions')
      .select('*')
      .eq('student_id', studentId)
      .order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as IntakeSession[], error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Erstgespraeche konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

type IntakePatch = Partial<Omit<IntakeInput, 'student_id'>> & {
  status?: IntakeSession['status']
}

// Aktualisiert ein Protokoll (Felder + Status draft→final).
export async function updateIntakeSession(
  id: string,
  patch: IntakePatch,
): Promise<SupabaseResult<IntakeSession>> {
  try {
    const { data, error } = await supabase
      .from('intake_sessions')
      .update(patch)
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as IntakeSession, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Erstgespraech konnte nicht aktualisiert werden'
    return { data: null, error: message }
  }
}
