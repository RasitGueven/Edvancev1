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

// Atomarer, idempotenter Abschluss via RPC complete_task (SECURITY DEFINER).
// Server ermittelt student_id (get_my_student_id) und XP (xp_rules + tasks);
// XP wird nur beim Erst-Abschluss vergeben. Ersetzt das separate
// markTaskCompleted+awardXp-Paar fuer den Abschluss-Pfad.
export async function completeTask(
  taskId: string,
): Promise<SupabaseResult<{ newly_completed: boolean; awarded_xp: number }>> {
  try {
    const { data, error } = await supabase.rpc('complete_task', {
      p_task_id: taskId,
    })
    if (error) return { data: null, error: error.message }
    const row = (
      (data ?? []) as { newly_completed: boolean; awarded_xp: number }[]
    )[0]
    return {
      data: {
        newly_completed: row?.newly_completed ?? false,
        awarded_xp: row?.awarded_xp ?? 0,
      },
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'Abschluss konnte nicht gespeichert werden'
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
