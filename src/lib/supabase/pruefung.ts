import { supabase } from '@/lib/supabase/client'
import { alleSeiten } from '@/lib/supabase/seitenweise'
import type {
  Fehlbild,
  PruefAdminZeile,
  PruefAufgabe,
  PruefBoardZeile,
  PruefEinstellungen,
  PruefEntscheidenAntwort,
  PruefEntscheidung,
  PruefEntwurf,
  PruefFehlerInfo,
  PruefResult,
  PruefRueckfrageAktion,
  PruefSollZeile,
  PruefSpeichernAntwort,
  PruefTaschenrechnerAntwort,
  PruefWertung,
} from '@/types'

/**
 * Lena-Board: alle Aufrufe der pruef_*-Funktionen (Migrationen 20261005071058 … 071650).
 *
 * Die Funktionen stehen noch nicht in database.ts — der Cast haelt das sichtbar, bis die Typen
 * neu generiert sind (Muster freigabe.ts). Fehler behalten SQLSTATE und HINT: ED409 heisst
 * "inzwischen geaendert", ED422 traegt im HINT den Schluessel fuer i18n (pruefung/fehler.ts).
 */

export type RpcFehler = { message: string; code?: string; hint?: string | null }
type Rpc = <T>(fn: string, args?: Record<string, unknown>) => Promise<{ data: T | null; error: RpcFehler | null }>

const rpc = supabase.rpc.bind(supabase) as unknown as Rpc

export function alsFehler(err: RpcFehler | unknown): PruefFehlerInfo {
  if (err && typeof err === 'object' && 'message' in err) {
    const e = err as RpcFehler
    return { code: e.code ?? null, hint: e.hint ?? null, message: e.message }
  }
  return { code: null, hint: null, message: err instanceof Error ? err.message : 'Unbekannter Fehler' }
}

export async function rufe<T>(fn: string, args?: Record<string, unknown>): Promise<PruefResult<T>> {
  try {
    const { data, error } = await rpc<T>(fn, args)
    if (error) return { data: null, error: alsFehler(error) }
    return { data: data as T, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

/** Alle Aufgaben im Board, sortiert nach der festen Reihenfolge. */
export async function getPruefBoard(): Promise<PruefResult<PruefBoardZeile[]>> {
  const res = await rufe<PruefBoardZeile[]>('pruef_board')
  if (res.data) res.data = [...res.data].sort((a, b) => a.reihenfolge - b.reihenfolge)
  return res
}

/** Sollzahlen und Fortschritt je Knoten (P2), in der Reihenfolge von pruef_soll.sort; mit anlass nur dieser Anlass. */
export function getPruefSoll(anlass?: string): Promise<PruefResult<PruefSollZeile[]>> {
  return rufe<PruefSollZeile[]>('pruef_board_soll', anlass ? { p_anlass: anlass } : undefined)
}

/** Pruefkarte einer Aufgabe. Legt beim ersten Oeffnen die Ausgangsfassung an. */
export function getPruefAufgabe(taskId: string): Promise<PruefResult<PruefAufgabe>> {
  return rufe<PruefAufgabe>('pruef_aufgabe', { p_task_id: taskId })
}

export function pruefSpeichern(
  taskId: string,
  version: number,
  entwurf: PruefEntwurf,
): Promise<PruefResult<PruefSpeichernAntwort>> {
  return rufe('pruef_speichern', { p_task_id: taskId, p_version: version, p_entwurf: entwurf })
}

export function pruefEntscheiden(args: {
  taskId: string
  version: number
  entscheidung: PruefEntscheidung
  gruende?: string[]
  notiz?: string | null
  aenderungGrund?: string | null
  dauerSek?: number | null
}): Promise<PruefResult<PruefEntscheidenAntwort>> {
  return rufe('pruef_entscheiden', {
    p_task_id: args.taskId,
    p_version: args.version,
    p_entscheidung: args.entscheidung,
    p_gruende: args.gruende ?? null,
    p_notiz: args.notiz ?? null,
    p_aenderung_grund: args.aenderungGrund ?? null,
    p_dauer_sek: args.dauerSek ?? null,
  })
}

export function pruefRueckgaengig(
  taskId: string,
  version: number,
): Promise<PruefResult<PruefEntscheidenAntwort>> {
  return rufe('pruef_rueckgaengig', { p_task_id: taskId, p_version: version })
}

/** Antwort ausprobieren: dieselbe Wertung wie die Engine, mit dem ungespeicherten Entwurf. */
export function pruefWertungTesten(
  taskId: string,
  teil: number | null,
  antwort: string,
  entwurf: PruefEntwurf,
): Promise<PruefResult<PruefWertung>> {
  return rufe('pruef_wertung_testen', {
    p_task_id: taskId,
    p_teil: teil,
    p_antwort: antwort,
    p_entwurf: entwurf,
  })
}

type Abfrage<T> = {
  select: (cols: string) => {
    order: (col: string, opts: { ascending: boolean }) => Promise<{ data: T[] | null; error: RpcFehler | null }>
    eq: (col: string, wert: string) => Promise<{ data: T[] | null; error: RpcFehler | null }>
    limit: (n: number) => Promise<{ data: T[] | null; error: RpcFehler | null }>
    in: (col: string, werte: string[]) => Promise<{ data: T[] | null; error: RpcFehler | null }>
  }
  update: (werte: Record<string, unknown>) => {
    eq: (col: string, wert: string | boolean) => Promise<{ error: RpcFehler | null }>
  }
}
const tabelle = <T>(name: string): Abfrage<T> =>
  (supabase.from.bind(supabase) as unknown as (t: string) => Abfrage<T>)(name)

/** Die Fehlbilder, mit denen Lena typische Fehler ergaenzen darf. */
export async function getFehlbilder(): Promise<PruefResult<Fehlbild[]>> {
  try {
    const { data, error } = await tabelle<Fehlbild>('fehlbild_labels')
      .select('slug,klartext')
      .order('klartext', { ascending: true })
    if (error) return { data: null, error: alsFehler(error) }
    return { data: data ?? [], error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

const TYP_BLOCK = 200

/**
 * Aufgabentyp (tasks.input_type) je task_id fuer den Prueflauf (P4-MC): pruef_board liefert ihn nicht. Lange Listen in
 * Bloecken, damit die URL kurz bleibt; ein Fehler in einem Block gilt fuer alle (dann laeuft der Lauf ohne Typen).
 */
export async function getAufgabenTypen(taskIds: string[]): Promise<PruefResult<Record<string, string | null>>> {
  try {
    const typen: Record<string, string | null> = {}
    for (let i = 0; i < taskIds.length; i += TYP_BLOCK) {
      const { data, error } = await tabelle<{ id: string; input_type: string | null }>('tasks')
        .select('id,input_type')
        .in('id', taskIds.slice(i, i + TYP_BLOCK))
      if (error) return { data: null, error: alsFehler(error) }
      for (const r of data ?? []) typen[r.id] = r.input_type
    }
    return { data: typen, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

/** Durchschnittliche Pruefdauer des angemeldeten Menschen in Sekunden (Abschluss, G 52). */
export async function getMeineDauer(userId: string): Promise<PruefResult<number | null>> {
  try {
    const { data, error } = await tabelle<{ dauer_sek: number | null; entscheidung: string }>('task_pruefungen')
      .select('dauer_sek,entscheidung')
      .eq('geprueft_von', userId)
    if (error) return { data: null, error: alsFehler(error) }
    const werte = (data ?? [])
      .filter((r) => r.entscheidung !== 'zurueckgenommen' && r.dauer_sek !== null)
      .map((r) => r.dauer_sek as number)
    return { data: werte.length ? Math.round(werte.reduce((a, b) => a + b, 0) / werte.length) : null, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

// ── Admin ───────────────────────────────────────────────────────────────────

export function pruefRueckfrageKlaeren(
  taskId: string,
  aktion: PruefRueckfrageAktion,
  antwort: string,
  gruende?: string[],
): Promise<PruefResult<{ status: string }>> {
  return rufe('pruef_rueckfrage_klaeren', {
    p_task_id: taskId,
    p_aktion: aktion,
    p_antwort: antwort,
    p_gruende: gruende ?? null,
  })
}

type RpcSeite<T> = {
  order: (spalte: string) => { range: (von: number, bis: number) => PromiseLike<{ data: T[] | null; error: RpcFehler | null }> }
}
const rpcSeite = supabase.rpc.bind(supabase) as unknown as <T>(fn: string) => RpcSeite<T>

/** Lenas Ergebnis je Aufgabe (nur admin). Seitenweise, weil PostgREST hoechstens 1000 Zeilen je Abfrage liefert (M1). */
export async function getPruefAdminListe(): Promise<PruefResult<PruefAdminZeile[]>> {
  try {
    const { data, error } = await alleSeiten<PruefAdminZeile>((von, bis) =>
      rpcSeite<PruefAdminZeile>('pruef_admin_liste').order('task_id').range(von, bis),
    )
    if (error) return { data: null, error: alsFehler(error) }
    return { data: data ?? [], error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

export async function getPruefEinstellungen(): Promise<PruefResult<PruefEinstellungen>> {
  try {
    const { data, error } = await tabelle<PruefEinstellungen>('pruef_einstellungen')
      .select('hilfsmittel,nur_pilot,grund_pflicht')
      .limit(1)
    if (error) return { data: null, error: alsFehler(error) }
    return { data: data?.[0] ?? null, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

/** Nur admin (RLS pruef_einstellungen_admin). */
export async function setPruefEinstellungen(werte: PruefEinstellungen): Promise<PruefResult<true>> {
  try {
    const { error } = await tabelle('pruef_einstellungen').update(werte).eq('id', true)
    if (error) return { data: null, error: alsFehler(error) }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: alsFehler(err) }
  }
}

/** Schaltet den Rechner der App fuer eine Aufgabe; Lena nur vor der Freigabe, Admin auch danach. */
export function pruefTaschenrechnerSetzen(
  taskId: string, version: number, wert: boolean,
): Promise<PruefResult<PruefTaschenrechnerAntwort>> {
  return rufe<PruefTaschenrechnerAntwort>('pruef_taschenrechner_setzen', {
    p_task_id: taskId, p_version: version, p_wert: wert,
  })
}
