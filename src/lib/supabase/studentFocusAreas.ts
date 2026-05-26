// Coach-/Admin-Schwerpunkte pro Schüler:in. Fließen in den Adaptive-
// Engine als gewichtete Cluster (weightedTopics) — passender Filter:
// active = true.

import { supabase } from '@/lib/supabase/client'
import type { StudentFocusArea, SupabaseResult } from '@/types'

export async function listFocusAreasForStudent(
  studentId: string,
  opts?: { active?: boolean },
): Promise<SupabaseResult<StudentFocusArea[]>> {
  try {
    let q = supabase
      .from('student_focus_areas')
      .select('*')
      .eq('student_id', studentId)
    if (opts?.active !== undefined) q = q.eq('active', opts.active)
    const { data, error } = await q.order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as StudentFocusArea[], error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Schwerpunkte konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
