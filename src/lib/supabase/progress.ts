import { supabase } from '@/lib/supabase/client'
import type { StudentProgress, SupabaseResult } from '@/types'

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

// Vergibt XP ueber die RPC xp_buchen (X0, Entscheidung 24): kein Client
// schreibt xp_events direkt. Der Buchungsschluessel macht die Buchung
// idempotent — derselbe Schluessel bucht genau einmal. Nur Admin oder
// Systemaufruf; ein Schuelerkonto bekommt 42501.
export async function awardXp(
  studentId: string,
  xp: number,
  reason: string,
  schluessel: string,
  taskId?: string | null,
): Promise<SupabaseResult<{ gebucht: boolean }>> {
  try {
    const { data, error } = await supabase.rpc('xp_buchen', {
      p_student_id: studentId,
      p_xp: xp,
      p_grund: reason,
      p_schluessel: schluessel,
      p_task_id: taskId ?? null,
    })
    if (error) return { data: null, error: error.message }
    return { data: { gebucht: data === true }, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'XP konnte nicht vergeben werden'
    return { data: null, error: message }
  }
}
