import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult, TierInput, TierPlan } from '@/types'

// Alle Tarife inkl. inaktive (Admin-Verwaltung). Katalog fuer Kunden:
// listTiers() in subscriptions.ts (nur active).
export async function listAllTiers(): Promise<SupabaseResult<TierPlan[]>> {
  try {
    const { data, error } = await supabase
      .from('tiers')
      .select('*')
      .order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as TierPlan[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Tarife konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

export async function createTier(
  input: TierInput,
): Promise<SupabaseResult<TierPlan>> {
  try {
    const { data, error } = await supabase
      .from('tiers')
      .insert({
        name: input.name,
        price_cents: input.price_cents,
        features: input.features,
        sort_order: input.sort_order ?? 0,
        active: input.active ?? true,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as TierPlan, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Tarif konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

export async function updateTier(
  id: string,
  patch: Partial<TierInput>,
): Promise<SupabaseResult<TierPlan>> {
  try {
    const { data, error } = await supabase
      .from('tiers')
      .update(patch)
      .eq('id', id)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as TierPlan, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Tarif konnte nicht aktualisiert werden'
    return { data: null, error: message }
  }
}
