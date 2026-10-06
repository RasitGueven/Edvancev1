// Gemeinsamer Aufruf fuer die Session-RPCs aus R1. Alle Session-Tabellen sind
// fuer Clients gesperrt (RLS ohne Policies); gelesen und geschrieben wird nur
// ueber diese Funktionen. supabase.rpc wird direkt aufgerufen (gebunden).

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export async function sessionRpc<T>(
  fn: string,
  args: Record<string, unknown>,
  fallback: string,
): Promise<SupabaseResult<T>> {
  try {
    const { data, error } = await supabase.rpc(fn, args)
    if (error) return { data: null, error: error.message }
    return { data: data as T, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : fallback }
  }
}
