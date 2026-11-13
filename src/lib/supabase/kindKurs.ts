// SF-1: Verlauf von Mathe-Kurs und Abschlussziel am Kind (public.kind_kurs, Migration 20261113082727).
// Nur anhängen: Eine Änderung in der Schülerakte ist eine neue Zeile mit Datum, nie ein Update.
// RLS: Admin liest und schreibt, Coach liest aktive Kinder, Kinder nie.

import { supabase } from '@/lib/supabase/client'
import type { Abschlussziel, KursMathe, SupabaseResult } from '@/types'

export type KindKursZeile = {
  id: string
  fach: string
  kurs: KursMathe | null
  abschlussziel: Abschlussziel | null
  ab_datum: string
  erfasst_am: string
}

export type KindKursNeu = {
  kurs: KursMathe | null
  abschlussziel: Abschlussziel | null
  /** YYYY-MM-DD */
  ab_datum: string
}

const SPALTEN = 'id, fach, kurs, abschlussziel, ab_datum, erfasst_am'

/** Verlauf eines Kindes für ein Fach, neueste Zeile zuerst. */
export async function listKindKurs(
  studentId: string,
  fach = 'mathematik',
): Promise<SupabaseResult<KindKursZeile[]>> {
  try {
    const { data, error } = await supabase
      .from('kind_kurs')
      .select(SPALTEN)
      .eq('student_id', studentId)
      .eq('fach', fach)
      .order('ab_datum', { ascending: false })
      .order('erfasst_am', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as KindKursZeile[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'kind_kurs could not be loaded'
    return { data: null, error: message }
  }
}

/** Neue Verlaufszeile; erfasst_von setzt die Datenbank (auth.uid()). */
export async function kindKursAnlegen(
  studentId: string,
  neu: KindKursNeu,
  fach = 'mathematik',
): Promise<SupabaseResult<KindKursZeile>> {
  try {
    const { data, error } = await supabase
      .from('kind_kurs')
      .insert({ student_id: studentId, fach, ...neu })
      .select(SPALTEN)
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as KindKursZeile, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'kind_kurs could not be saved'
    return { data: null, error: message }
  }
}
