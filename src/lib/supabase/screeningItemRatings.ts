// Append-only Item-level Coach-Bewertungen für offene Screening-Antworten
// (Migration 028, Tabelle screening_item_ratings). Schüler/Eltern lesen NICHT
// direkt — RLS lässt nur coach/admin durch.

import { supabase } from '@/lib/supabase/client'
import type {
  ScreeningItemRating,
  ScreeningItemRatingInput,
  SupabaseResult,
} from '@/types'

export async function createScreeningItemRating(
  input: ScreeningItemRatingInput,
): Promise<SupabaseResult<ScreeningItemRating>> {
  try {
    const { data, error } = await supabase
      .from('screening_item_ratings')
      .insert(input)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningItemRating, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Bewertung konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}

// Letzte Bewertung pro Result (append-only → DESC + erstes Vorkommen gewinnt).
export async function listItemRatingsForResults(
  resultIds: string[],
): Promise<SupabaseResult<Map<string, ScreeningItemRating>>> {
  if (resultIds.length === 0) return { data: new Map(), error: null }
  try {
    const { data, error } = await supabase
      .from('screening_item_ratings')
      .select('*')
      .in('screening_item_result_id', resultIds)
      .order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    const latest = new Map<string, ScreeningItemRating>()
    for (const r of (data ?? []) as ScreeningItemRating[]) {
      if (!latest.has(r.screening_item_result_id)) {
        latest.set(r.screening_item_result_id, r)
      }
    }
    return { data: latest, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Bewertungen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
