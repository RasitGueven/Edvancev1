import { supabase } from '@/lib/supabase/client'
import type {
  ScreeningItem,
  ScreeningItemInput,
  ScreeningItemResult,
  ScreeningItemResultInput,
  ScreeningLevel,
  SupabaseResult,
} from '@/types'

// Items, optional auf Cluster / aktiv-Status gefiltert.
export async function listScreeningItems(opts?: {
  clusterId?: string
  active?: boolean
}): Promise<SupabaseResult<ScreeningItem[]>> {
  try {
    let q = supabase.from('screening_items').select('*')
    if (opts?.clusterId) q = q.eq('cluster_id', opts.clusterId)
    if (opts?.active !== undefined) q = q.eq('active', opts.active)
    const { data, error } = await q
      .order('skill_code', { ascending: true })
      .order('level', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ScreeningItem[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Items konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Items per Id-Liste (für die Coach-Rating-Inbox: prompt + Lösungsschema
// neben der Schüler-Antwort darstellen).
export async function listScreeningItemsByIds(
  ids: string[],
): Promise<SupabaseResult<ScreeningItem[]>> {
  if (ids.length === 0) return { data: [], error: null }
  try {
    const { data, error } = await supabase
      .from('screening_items')
      .select('*')
      .in('id', ids)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ScreeningItem[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Items konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Aktive Items eines Clusters auf einer Stufe (fuer den adaptiven Controller).
export async function listActiveByClusterLevel(
  clusterId: string,
  level: ScreeningLevel,
): Promise<SupabaseResult<ScreeningItem[]>> {
  try {
    const { data, error } = await supabase
      .from('screening_items')
      .select('*')
      .eq('cluster_id', clusterId)
      .eq('level', level)
      .eq('active', true)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ScreeningItem[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Items konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

export async function createScreeningItem(
  input: ScreeningItemInput,
): Promise<SupabaseResult<ScreeningItem>> {
  try {
    const { data, error } = await supabase
      .from('screening_items')
      .insert(input)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningItem, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Item konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

export async function updateScreeningItem(
  id: string,
  patch: Partial<ScreeningItemInput>,
): Promise<SupabaseResult<ScreeningItem>> {
  try {
    const { data, error } = await supabase
      .from('screening_items')
      .update(patch)
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as ScreeningItem, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Item konnte nicht aktualisiert werden'
    return { data: null, error: message }
  }
}

export async function setScreeningItemActive(
  id: string,
  active: boolean,
): Promise<SupabaseResult<ScreeningItem>> {
  return updateScreeningItem(id, { active } as Partial<ScreeningItemInput>)
}

// Append-only Auto-Grade-Ergebnis persistieren.
export async function recordScreeningItemResult(
  input: ScreeningItemResultInput,
): Promise<SupabaseResult<{ id: string }>> {
  try {
    const { data, error } = await supabase
      .from('screening_item_results')
      .insert(input)
      .select('id')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: { id: data.id as string }, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Ergebnis konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}

export async function getResultsForTest(
  screeningTestId: string,
): Promise<SupabaseResult<ScreeningItemResult[]>> {
  try {
    const { data, error } = await supabase
      .from('screening_item_results')
      .select('*')
      .eq('screening_test_id', screeningTestId)
      .order('created_at', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ScreeningItemResult[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Ergebnisse konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
