import { supabase } from '@/lib/supabase/client'
import type { StudentCoach, SupabaseResult } from '@/types'

// Weist einem Schueler einen Coach zu (idempotent; reaktiviert bei Bedarf).
export async function assignCoach(
  studentId: string,
  coachId: string,
): Promise<SupabaseResult<StudentCoach>> {
  try {
    const { data, error } = await supabase
      .from('student_coach')
      .upsert(
        { student_id: studentId, coach_id: coachId, active: true },
        { onConflict: 'student_id,coach_id' },
      )
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as StudentCoach, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Coach konnte nicht zugewiesen werden'
    return { data: null, error: message }
  }
}

// Aktive Coach-Zuordnung eines Schuelers (kann fehlen → null).
export async function getCoachForStudent(
  studentId: string,
): Promise<SupabaseResult<StudentCoach | null>> {
  try {
    const { data, error } = await supabase
      .from('student_coach')
      .select('*')
      .eq('student_id', studentId)
      .eq('active', true)
      .order('assigned_at', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as StudentCoach | null) ?? null, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Coach-Zuordnung konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Aktive Schueler-Zuordnungen eines Coaches.
export async function listStudentsForCoach(
  coachId: string,
): Promise<SupabaseResult<StudentCoach[]>> {
  try {
    const { data, error } = await supabase
      .from('student_coach')
      .select('*')
      .eq('coach_id', coachId)
      .eq('active', true)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as StudentCoach[], error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Schueler-Zuordnungen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Alle aktiven Zuordnungen (fuer Admin-Uebersicht student → coach).
export async function listActiveAssignments(): Promise<
  SupabaseResult<StudentCoach[]>
> {
  try {
    const { data, error } = await supabase
      .from('student_coach')
      .select('*')
      .eq('active', true)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as StudentCoach[], error: null }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'Zuordnungen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Setzt den (einzigen aktiven) Coach eines Schuelers. coachId === null
// entfernt die Zuordnung. Deaktiviert zuerst alle bestehenden aktiven
// Zuordnungen, dann ggf. Upsert des neuen Coaches (idempotent).
export async function setStudentCoach(
  studentId: string,
  coachId: string | null,
): Promise<SupabaseResult<StudentCoach | null>> {
  try {
    const { error: deErr } = await supabase
      .from('student_coach')
      .update({ active: false })
      .eq('student_id', studentId)
      .eq('active', true)
    if (deErr) return { data: null, error: deErr.message }

    if (coachId === null) return { data: null, error: null }

    const { data, error } = await supabase
      .from('student_coach')
      .upsert(
        { student_id: studentId, coach_id: coachId, active: true },
        { onConflict: 'student_id,coach_id' },
      )
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as StudentCoach, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Coach konnte nicht gesetzt werden'
    return { data: null, error: message }
  }
}
