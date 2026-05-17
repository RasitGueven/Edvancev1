import { supabase } from '@/lib/supabase/client'
import type { StudentProgress, SupabaseResult, XpEvent } from '@/types'

// XP/Streak/Level eines Schuelers (kann fehlen, bevor das erste xp_event
// existiert → null).
export async function getStudentProgress(
  studentId: string,
): Promise<SupabaseResult<StudentProgress | null>> {
  try {
    const { data, error } = await supabase
      .from('student_progress')
      .select('*')
      .eq('student_id', studentId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as StudentProgress | null) ?? null, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Fortschritt konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Vergibt XP (append-only). Der Trigger apply_xp_event aktualisiert
// student_progress serverseitig – Client kann Totals nicht faelschen.
export async function awardXp(
  studentId: string,
  xp: number,
  reason: string,
  taskId?: string | null,
): Promise<SupabaseResult<{ id: string }>> {
  try {
    const { data, error } = await supabase
      .from('xp_events')
      .insert({
        student_id: studentId,
        xp,
        reason,
        task_id: taskId ?? null,
      })
      .select('id')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: { id: data.id as string }, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'XP konnte nicht vergeben werden'
    return { data: null, error: message }
  }
}

// XP-Verlauf eines Schuelers, neueste zuerst.
export async function listXpEvents(
  studentId: string,
  limit = 50,
): Promise<SupabaseResult<XpEvent[]>> {
  try {
    const { data, error } = await supabase
      .from('xp_events')
      .select('*')
      .eq('student_id', studentId)
      .order('created_at', { ascending: false })
      .limit(limit)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as XpEvent[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'XP-Verlauf konnte nicht geladen werden'
    return { data: null, error: message }
  }
}
