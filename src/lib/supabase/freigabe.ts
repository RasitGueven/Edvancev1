import { supabase } from '@/lib/supabase/client'
import type { BeanstandungsKategorie, SupabaseResult } from '@/types'

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

// ── Pruefrecht und zweistufige Freigabe (20260922100000) ────────────────────

/** Die Rueckweisungsgruende in Anzeige-Reihenfolge (task_reviews.kategorie). */
export const BEANSTANDUNGS_KATEGORIEN: BeanstandungsKategorie[] = [
  'formulierung',
  'loesung_passt_nicht',
  'didaktisch',
  'zahlen_unguenstig',
  'kontext',
  'fehlbild_falsch',
  'fehlbild_unrealistisch',
]

type RpcWert<T> = (
  fn: string,
  args?: Record<string, unknown>,
) => Promise<{ data: T | null; error: { message: string } | null }>

/**
 * Darf der angemeldete Mensch Aufgaben pruefen (admin, oder coach mit
 * profiles.darf_pruefen)? Die DB entscheidet — die Oberflaeche schaltet nur um.
 */
export async function getDarfPruefen(): Promise<SupabaseResult<boolean>> {
  try {
    const rpc = supabase.rpc as unknown as RpcWert<boolean>
    const { data, error } = await rpc('darf_pruefen')
    if (error) return { data: null, error: error.message }
    return { data: data === true, error: null }
  } catch (err) {
    return { data: null, error: fehlermeldung(err, 'Pruefrecht konnte nicht gelesen werden') }
  }
}

/**
 * Weist eine Aufgabe zurueck: status 'beanstandet' plus task_reviews-Zeile mit
 * Grund und optionaler Ergaenzung. Eine freigegebene Aufgabe weist nur admin zurueck.
 */
export async function beanstandeAufgabe(
  taskId: string,
  kategorie: BeanstandungsKategorie,
  notiz: string | null,
): Promise<SupabaseResult<true>> {
  try {
    const rpc = supabase.rpc as unknown as RpcZahl
    const { error } = await rpc('lena_beanstande', {
      p_task_id: taskId,
      p_kategorie: kategorie,
      p_notiz: notiz,
    })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: fehlermeldung(err, 'Zurueckweisen fehlgeschlagen') }
  }
}

/**
 * Gibt alle Aufgaben eines Clusters frei, die auf 'review' ("Zur Freigabe")
 * stehen. Nur admin. Jede laeuft durch das task_status_set-Gate; unvollstaendige
 * bleiben liegen. Rueckgabe: Anzahl tatsaechlich freigegebener Aufgaben.
 */
export async function freigabeCluster(clusterId: string): Promise<SupabaseResult<number>> {
  try {
    const rpc = supabase.rpc as unknown as RpcZahl
    const { data, error } = await rpc('freigabe_cluster', { p_cluster_id: clusterId })
    if (error) return { data: null, error: error.message }
    return { data: data ?? 0, error: null }
  } catch (err) {
    return { data: null, error: fehlermeldung(err, 'Freigabe fehlgeschlagen') }
  }
}
