import { supabase } from '@/lib/supabase/client'
import type {
  ScreeningTest,
  ScreeningTestInput,
  SupabaseResult,
} from '@/types'
import type { BehaviorSnapshot } from '@/types/diagnosis'

// Startet einen Screening-Lauf (Aggregat). status defaultet DB-seitig
// 'in_progress'; partial-unique-Index verhindert doppelte aktive Tests
// pro (Schueler, Fach).
export async function createScreeningTest(
  input: ScreeningTestInput,
): Promise<SupabaseResult<ScreeningTest>> {
  try {
    const { data, error } = await supabase
      .from('screening_tests')
      .insert({
        student_id: input.student_id,
        subject: input.subject,
        generated_test: input.generated_test,
        estimated_total_minutes: input.estimated_total_minutes ?? null,
        coach_id: input.coach_id ?? null,
        started_at: new Date().toISOString(),
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningTest, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Screening konnte nicht gestartet werden'
    return { data: null, error: message }
  }
}

// Aktiver Test eines Schuelers in einem Fach (fuer Resume; kann fehlen).
export async function getActiveScreeningTest(
  studentId: string,
  subject: string,
): Promise<SupabaseResult<ScreeningTest | null>> {
  try {
    const { data, error } = await supabase
      .from('screening_tests')
      .select('*')
      .eq('student_id', studentId)
      .eq('subject', subject)
      .eq('status', 'in_progress')
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as ScreeningTest | null) ?? null, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Screening konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

export async function getScreeningTestById(
  id: string,
): Promise<SupabaseResult<ScreeningTest | null>> {
  try {
    const { data, error } = await supabase
      .from('screening_tests')
      .select('*')
      .eq('id', id)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as ScreeningTest | null) ?? null, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Screening konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Schliesst den Lauf ab: Ergebnis-Aggregat + optionale Coach-Notiz.
export async function completeScreeningTest(
  id: string,
  resultSummary: Record<string, unknown>,
  coachNote?: string | null,
): Promise<SupabaseResult<ScreeningTest>> {
  try {
    const { data, error } = await supabase
      .from('screening_tests')
      .update({
        status: 'completed',
        completed_at: new Date().toISOString(),
        result_summary: resultSummary,
        coach_note: coachNote ?? null,
      })
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningTest, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Screening konnte nicht abgeschlossen werden'
    return { data: null, error: message }
  }
}

export async function abortScreeningTest(
  id: string,
): Promise<SupabaseResult<ScreeningTest>> {
  try {
    const { data, error } = await supabase
      .from('screening_tests')
      .update({ status: 'aborted', completed_at: new Date().toISOString() })
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningTest, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Screening konnte nicht abgebrochen werden'
    return { data: null, error: message }
  }
}

// Resume: bereits persistierte Snapshots eines Laufs (in Submit-Reihenfolge).
// coach_rating wird separat via getRatingsForTest (screeningRatings.ts) gemerged.
export async function getScreeningSnapshots(
  screeningTestId: string,
): Promise<SupabaseResult<(Omit<BehaviorSnapshot, 'coach_rating'> & { id: string })[]>> {
  try {
    const { data, error } = await supabase
      .from('behavior_snapshots')
      .select('*')
      .eq('screening_test_id', screeningTestId)
      .order('submitted_at', { ascending: true })
    if (error) return { data: null, error: error.message }
    return {
      data: (data ?? []) as (Omit<BehaviorSnapshot, 'coach_rating'> & {
        id: string
      })[],
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Snapshots konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
