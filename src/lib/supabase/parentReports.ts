import { supabase } from '@/lib/supabase/client'
import type { ParentReport, ParentReportInput, SupabaseResult } from '@/types'

// Legt einen Elternreport an (Status 'draft'; Eltern sehen ihn erst
// nach publishReport).
export async function createParentReport(
  input: ParentReportInput,
): Promise<SupabaseResult<ParentReport>> {
  try {
    const { data, error } = await supabase
      .from('parent_reports')
      .insert({
        student_id: input.student_id,
        period_start: input.period_start,
        period_end: input.period_end,
        summary: input.summary ?? null,
        coach_note: input.coach_note ?? null,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ParentReport, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Report konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

// Reports eines Schuelers, neueste zuerst (RLS filtert nach Rolle).
export async function listReportsForStudent(
  studentId: string,
): Promise<SupabaseResult<ParentReport[]>> {
  try {
    const { data, error } = await supabase
      .from('parent_reports')
      .select('*')
      .eq('student_id', studentId)
      .order('period_end', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ParentReport[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Reports konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Veroeffentlicht einen Report (draft → published).
export async function publishReport(
  id: string,
): Promise<SupabaseResult<ParentReport>> {
  try {
    const { data, error } = await supabase
      .from('parent_reports')
      .update({ status: 'published', published_at: new Date().toISOString() })
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ParentReport, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Report konnte nicht veroeffentlicht werden'
    return { data: null, error: message }
  }
}
