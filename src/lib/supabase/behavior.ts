import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'
import type { BehaviorSnapshot } from '@/types/diagnosis'

// Persistiert einen BehaviorSnapshot zu einer Aufgabe (append-only).
// Schreibt in behavior_snapshots (siehe migrations/003_behavior_snapshots.sql).
export async function persistBehaviorSnapshot(
  taskId: string,
  userId: string,
  snapshot: Omit<BehaviorSnapshot, 'coach_rating'>,
  screeningTestId?: string,
): Promise<SupabaseResult<{ id: string }>> {
  try {
    const { data, error } = await supabase
      .from('behavior_snapshots')
      .insert({
        task_id: taskId,
        user_id: userId,
        screening_test_id: screeningTestId ?? null,
        answer_text: snapshot.answer_text,
        thinking_time_ms: snapshot.thinking_time_ms,
        task_duration_ms: snapshot.task_duration_ms,
        revision_count: snapshot.revision_count,
        rewrite_count: snapshot.rewrite_count,
        hint_used: snapshot.hint_used,
        hint_request_time_ms: snapshot.hint_request_time_ms,
        answer_length: snapshot.answer_length,
        time_after_completion_ms: snapshot.time_after_completion_ms,
      })
      .select('id')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: { id: data.id as string }, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'BehaviorSnapshot konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}
