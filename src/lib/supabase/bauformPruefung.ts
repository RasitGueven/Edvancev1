import { supabase } from '@/lib/supabase/client'
import type {
  AuffaelligZeile,
  BauformDetail,
  BauformEntscheidung,
  BauformListenZeile,
  PrueffrageZeile,
} from '@/types/bauformPruefung'

/**
 * Lena-Board fuer Bauformen (Sessionreihe 1, A5): Lesen ueber bauform_pruef_liste/_detail, bauform_auffaellig,
 * skill_pruefung_liste; Schreiben ueber bauform_pruefen, bauform_freigeben, aufgabe_reaktivieren,
 * bauform_zur_ueberarbeitung, bauform_reaktivieren, skill_pruefung_entscheiden, aufgabe_melden (DATENVERTRAG §13.4–§13.8).
 * Die Funktionen stehen noch nicht in database.ts — der Cast haelt das sichtbar (Muster erklaerPruefung.ts).
 * Fehler behalten SQLSTATE und HINT.
 */

export type BauformFehler = { code: string | null; hint: string | null; message: string }
export type BauformResult<T> = { data: T | null; error: BauformFehler | null }

type RpcFehler = { message: string; code?: string; hint?: string | null }
type Rpc = <T>(fn: string, args?: Record<string, unknown>) => Promise<{ data: T | null; error: RpcFehler | null }>
const rpc = supabase.rpc.bind(supabase) as unknown as Rpc

function alsFehler(err: unknown): BauformFehler {
  if (err && typeof err === 'object' && 'message' in err) {
    const e = err as RpcFehler
    return { code: e.code ?? null, hint: e.hint ?? null, message: e.message }
  }
  return { code: null, hint: null, message: err instanceof Error ? err.message : 'unknown error' }
}

async function rufe<T>(fn: string, args?: Record<string, unknown>): Promise<BauformResult<T>> {
  try {
    const { data, error } = await rpc<T>(fn, args)
    if (error) return { data: null, error: alsFehler(error) }
    return { data: data as T, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

export const getBauformListe = (): Promise<BauformResult<BauformListenZeile[]>> => rufe('bauform_pruef_liste')

export const getBauformDetail = (bauformId: string, seed = 0): Promise<BauformResult<BauformDetail>> =>
  rufe('bauform_pruef_detail', { p_bauform: bauformId, p_seed: seed })

export const bauformPruefen = (
  bauformId: string,
  version: number,
  entscheidung: BauformEntscheidung,
  gruende: string[],
  notiz: string | null,
  dauerSek: number | null,
): Promise<BauformResult<{ status: string; version: number }>> =>
  rufe('bauform_pruefen', {
    p_bauform: bauformId, p_version: version, p_entscheidung: entscheidung, p_gruende: gruende, p_notiz: notiz,
    p_dauer_sek: dauerSek,
  })

export const bauformFreigeben = (reihe: string): Promise<BauformResult<number>> =>
  rufe('bauform_freigeben', { p_reihe: reihe })

export const getAuffaellig = (): Promise<BauformResult<AuffaelligZeile[]>> => rufe('bauform_auffaellig')

export const aufgabeReaktivieren = (taskId: string): Promise<BauformResult<null>> =>
  rufe('aufgabe_reaktivieren', { p_task: taskId })

export const bauformZurUeberarbeitung = (bauformId: string, grund: string): Promise<BauformResult<null>> =>
  rufe('bauform_zur_ueberarbeitung', { p_bauform: bauformId, p_grund: grund })

export const bauformReaktivieren = (bauformId: string, grund: string): Promise<BauformResult<string>> =>
  rufe('bauform_reaktivieren', { p_bauform: bauformId, p_grund: grund })

export const getPrueffragen = (): Promise<BauformResult<PrueffrageZeile[]>> => rufe('skill_pruefung_liste')

export const prueffrageEntscheiden = (
  id: string,
  entscheidung: 'passt' | 'passt_nicht',
  notiz: string | null,
): Promise<BauformResult<string>> =>
  rufe('skill_pruefung_entscheiden', { p_id: id, p_entscheidung: entscheidung, p_notiz: notiz })

/** Coach-Live: „Aufgabe stimmt nicht“ (aufgabe_melden pausiert die Instanz sofort). */
export const aufgabeMelden = (taskId: string, grund: string): Promise<BauformResult<null>> =>
  rufe('aufgabe_melden', { p_task: taskId, p_grund: grund })
