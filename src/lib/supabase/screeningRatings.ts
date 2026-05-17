import { supabase } from '@/lib/supabase/client'
import type { ScreeningRating, SupabaseResult } from '@/types'

// Coach-Bewertung zu einem Snapshot (APPEND-ONLY – separater Insert,
// damit behavior_snapshots append-only bleibt).
export async function createScreeningRating(
  behaviorSnapshotId: string,
  screeningTestId: string,
  rating: 1 | 2 | 3 | 4,
  coachId?: string | null,
): Promise<SupabaseResult<ScreeningRating>> {
  try {
    const { data, error } = await supabase
      .from('screening_ratings')
      .insert({
        behavior_snapshot_id: behaviorSnapshotId,
        screening_test_id: screeningTestId,
        rating,
        coach_id: coachId ?? null,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningRating, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Bewertung konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}

// Alle Bewertungen eines Laufs (zum Mergen mit Snapshots beim Resume).
export async function getRatingsForTest(
  screeningTestId: string,
): Promise<SupabaseResult<ScreeningRating[]>> {
  try {
    const { data, error } = await supabase
      .from('screening_ratings')
      .select('*')
      .eq('screening_test_id', screeningTestId)
      .order('created_at', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ScreeningRating[], error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Bewertungen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
