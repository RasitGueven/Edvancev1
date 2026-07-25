import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

/**
 * Sammelfreigabe je Skill (A21) — das Gegenstueck zu A20s Sammel-Beanstandung.
 *
 * Beide RPCs stehen noch nicht in database.ts (A21 wird separat eingespielt) —
 * der Cast haelt das sichtbar, bis die Typen neu generiert sind (CLAUDE.md §4).
 * Getrennt von taskAuthoring.ts, weil das sonst ueber die 400-Zeilen-Grenze
 * liefe (§4).
 */

type RpcZahl = (
  fn: string,
  args: Record<string, unknown>,
) => Promise<{ data: number | null; error: { message: string } | null }>

function fehlermeldung(err: unknown, fallback: string): string {
  return err instanceof Error ? err.message : fallback
}

/**
 * Gibt eine Skill-Gruppe frei: draft -> ready. Ohne taskIds alle draft-Aufgaben
 * des Skills, mit taskIds nur diese ("alle ausser diesen dreien"). Serverseitig
 * laeuft jede Freigabe durch das task_status_set-Gate; ein unvollstaendiges Item
 * bleibt draft. 'beanstandet'/'review' werden nie gehoben. Rueckgabe: Anzahl
 * tatsaechlich freigegebener Aufgaben.
 */
export async function freigabeMuster(
  skillKey: string,
  taskIds?: string[],
): Promise<SupabaseResult<number>> {
  try {
    const rpc = supabase.rpc as unknown as RpcZahl
    const { data, error } = await rpc('freigabe_muster', {
      p_skill_key: skillKey,
      ...(taskIds ? { p_task_ids: taskIds } : {}),
    })
    if (error) return { data: null, error: error.message }
    return { data: data ?? 0, error: null }
  } catch (err) {
    return { data: null, error: fehlermeldung(err, 'Freigabe fehlgeschlagen') }
  }
}

/**
 * Nimmt die Freigabe einer Skill-Gruppe zurueck: ready -> draft. 'beanstandet',
 * 'review' und 'draft' bleiben unberuehrt. Rueckgabe: Anzahl zurueckgenommener
 * Aufgaben.
 */
export async function freigabeZuruecknehmen(
  skillKey: string,
): Promise<SupabaseResult<number>> {
  try {
    const rpc = supabase.rpc as unknown as RpcZahl
    const { data, error } = await rpc('freigabe_zuruecknehmen', { p_skill_key: skillKey })
    if (error) return { data: null, error: error.message }
    return { data: data ?? 0, error: null }
  } catch (err) {
    return { data: null, error: fehlermeldung(err, 'Zuruecknehmen fehlgeschlagen') }
  }
}
