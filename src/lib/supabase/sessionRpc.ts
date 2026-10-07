// Gemeinsamer Aufruf fuer die Session-RPCs aus R1. Alle Session-Tabellen sind
// fuer Clients gesperrt (RLS ohne Policies); gelesen und geschrieben wird nur
// ueber diese Funktionen. supabase.rpc wird direkt aufgerufen (gebunden).
//
// C2: Im Fehlerfall gehen SQLSTATE (code) und Hinweis (hint) mit, damit die
// Coach-Live-Sicht sie auf ihre Fehler-Codes abbilden kann (nie den Rohtext zeigen).

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type RpcFehler = { code?: string | null; hint?: string | null }
export type RpcResult<T> = SupabaseResult<T> & RpcFehler

export async function sessionRpc<T>(
  fn: string,
  args: Record<string, unknown>,
  fallback: string,
): Promise<RpcResult<T>> {
  try {
    const { data, error } = await supabase.rpc(fn, args)
    if (error) {
      // code/hint nur, wenn die Datenbank sie liefert (bestehende Aufrufer vergleichen das Ergebnis exakt).
      return { data: null, error: error.message, ...(error.code ? { code: error.code } : {}), ...(error.hint ? { hint: error.hint } : {}) }
    }
    return { data: data as T, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : fallback }
  }
}
