import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

// Markiert eine Aufgabe als erledigt (idempotent; ersetzt localStorage
// 'edvance_task_progress_v1').
export async function markTaskCompleted(
  studentId: string,
  taskId: string,
): Promise<SupabaseResult<{ ok: true }>> {
  try {
    const { error } = await supabase
      .from('student_task_progress')
      .upsert(
        { student_id: studentId, task_id: taskId },
        { onConflict: 'student_id,task_id' },
      )
    if (error) return { data: null, error: error.message }
    return { data: { ok: true }, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Fortschritt konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}

// IDs aller erledigten Aufgaben eines Schuelers.
export async function getCompletedTaskIds(
  studentId: string,
): Promise<SupabaseResult<string[]>> {
  try {
    const { data, error } = await supabase
      .from('student_task_progress')
      .select('task_id')
      .eq('student_id', studentId)
    if (error) return { data: null, error: error.message }
    const ids = ((data ?? []) as { task_id: string }[]).map((r) => r.task_id)
    return { data: ids, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Fortschritt konnte nicht geladen werden'
    return { data: null, error: message }
  }
}
