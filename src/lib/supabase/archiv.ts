// MSA-1 M3: Archiv der Aufgaben — lesen, zählen, wiederherstellen (nur admin, 20261112153053_msa1_archiv).
//
// Archivierte Aufgaben fehlen in allen anderen Listen (Item-Pflege, Heute, Zähler, Lena-Board, LSA-Pool). Sie
// stehen nur hier. Löschen gibt es nicht; Wiederherstellen ändert nie den Status (task_wiederherstellen).

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'
import type { ArchivZeile } from '@/types/archiv'

/** Alle archivierten Aufgaben, neueste zuerst (RPC task_archiv). */
export async function listArchiv(): Promise<SupabaseResult<ArchivZeile[]>> {
  try {
    const { data, error } = await supabase.rpc('task_archiv')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ArchivZeile[], error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Archiv konnte nicht geladen werden' }
  }
}

/** Zahl der archivierten Aufgaben für den Link „Archiv (n)“ am Fuß der Item-Pflege. */
export async function countArchiv(): Promise<SupabaseResult<number>> {
  try {
    const { count, error } = await supabase
      .from('tasks')
      .select('id', { count: 'exact', head: true })
      .not('archiviert_am', 'is', null)
    return error ? { data: null, error: error.message } : { data: count ?? 0, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Archiv-Zähler konnte nicht geladen werden' }
  }
}

/** Holt archivierte Aufgaben zurück (RPC task_wiederherstellen). Rückgabe: Zahl wiederhergestellt. */
export async function archivWiederherstellen(ids: string[]): Promise<SupabaseResult<number>> {
  try {
    const { data, error } = await supabase.rpc('task_wiederherstellen', { p_ids: ids })
    if (error) return { data: null, error: error.message }
    return { data: (data as number | null) ?? 0, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Wiederherstellen fehlgeschlagen' }
  }
}
