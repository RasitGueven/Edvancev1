// Schulen als Auswahlliste (Entscheidung 15). RLS laesst nur Admins lesen und
// schreiben; der Unique-Index auf (lower(name), coalesce(ort,'')) verhindert,
// dass dieselbe Schule beim Erfassen zweimal entsteht.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type Schule = { id: string; name: string; ort: string | null }

export async function listSchulen(): Promise<SupabaseResult<Schule[]>> {
  try {
    const { data, error } = await supabase
      .from('schulen')
      .select('id, name, ort')
      .order('name', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Schule[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Schulen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

/** Legt eine Schule an. Gibt es sie schon, kommt die bestehende zurueck. */
export async function schuleAnlegen(
  name: string,
  ort: string | null,
): Promise<SupabaseResult<Schule>> {
  const sauber = name.trim()
  const ortSauber = ort?.trim() ? ort.trim() : null
  try {
    const { data, error } = await supabase
      .from('schulen')
      .insert({ name: sauber, ort: ortSauber })
      .select('id, name, ort')
      .single()
    if (!error) return { data: data as Schule, error: null }

    // 23505 = der Unique-Index hat zugeschlagen. Dann ist die Schule schon da,
    // und der Admin soll sie bekommen statt einer Fehlermeldung.
    if (error.code === '23505') {
      const { data: vorhanden, error: leseFehler } = await supabase
        .from('schulen')
        .select('id, name, ort')
        .ilike('name', sauber)
        .limit(50)
      if (leseFehler) return { data: null, error: leseFehler.message }
      const treffer = (vorhanden ?? []).find(
        (s) => (s.ort ?? '') === (ortSauber ?? ''),
      ) as Schule | undefined
      if (treffer) return { data: treffer, error: null }
    }
    return { data: null, error: error.message }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Schule konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}
