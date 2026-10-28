import { supabase } from '@/lib/supabase/client'
import type { PruefErgebnis, Skript } from '@/studio/skript/typen'
import type { StudioErgebnis, StudioSequenz, StudioStatus, StudioWeltStand } from '@/types/studio'

/**
 * Studio (Reihe 1, Bauauftrag B1): Sequenzen lesen (RLS: nur Studio-Beteiligte) und ein geprüftes Skript
 * über studio_skript_speichern schreiben. Die Studio-Funktionen stehen noch nicht in database.ts — der Cast
 * hält das sichtbar (Muster erklaerPruefung.ts).
 */
type RpcFehler = { message: string; code?: string; hint?: string | null }
type Rpc = <T>(fn: string, args?: Record<string, unknown>) => Promise<{ data: T | null; error: RpcFehler | null }>
const rpc = supabase.rpc.bind(supabase) as unknown as Rpc

function fehler(e: unknown): NonNullable<StudioErgebnis<never>['error']> {
  if (e && typeof e === 'object' && 'message' in e) {
    const f = e as RpcFehler
    return { code: f.code ?? null, message: f.message, hint: f.hint ?? null }
  }
  return { code: null, message: e instanceof Error ? e.message : 'unknown error', hint: null }
}

type SequenzRow = {
  id: string
  skill_key: string
  titel: string
  autor_id: string
  status: StudioStatus
  welten: string[]
  version: number
  skript: Skript
  geaendert_am: string
}

const alsSequenz = (r: SequenzRow): StudioSequenz => ({
  id: r.id,
  skillKey: r.skill_key,
  titel: r.titel,
  autorId: r.autor_id,
  status: r.status,
  welten: r.welten,
  version: r.version,
  skript: r.skript,
  geaendertAm: r.geaendert_am,
})

export async function listeStudioSequenzen(): Promise<StudioErgebnis<StudioSequenz[]>> {
  try {
    const { data, error } = await supabase
      .from('studio_sequenz')
      .select('id, skill_key, titel, autor_id, status, welten, version, skript, geaendert_am')
      .order('geaendert_am', { ascending: false })
    if (error) return { data: null, error: fehler(error) }
    return { data: ((data ?? []) as unknown as SequenzRow[]).map(alsSequenz), error: null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

export async function ladeStudioWelten(sequenzId: string): Promise<StudioErgebnis<StudioWeltStand[]>> {
  try {
    const { data, error } = await supabase
      .from('studio_welt')
      .select('welt, version, gesperrt, befunde')
      .eq('sequenz_id', sequenzId)
    if (error) return { data: null, error: fehler(error) }
    return { data: (data ?? []) as unknown as StudioWeltStand[], error: null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

/** Fehlbild-Katalog der LSA (fehlbild_labels.slug) für die Importprüfung. */
export async function ladeFehlbildKatalog(): Promise<StudioErgebnis<Set<string>>> {
  try {
    const { data, error } = await supabase.from('fehlbild_labels').select('slug')
    if (error) return { data: null, error: fehler(error) }
    return { data: new Set(((data ?? []) as { slug: string }[]).map((r) => r.slug)), error: null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

/** Speichert ein geprüftes Skript (neu: sequenzId null). Gibt die Sequenz-ID zurück. */
export async function speichereStudioSkript(
  sequenzId: string | null,
  skript: Skript,
  pruefung: Pick<PruefErgebnis, 'gesperrteWelten' | 'befunde'>,
): Promise<StudioErgebnis<string>> {
  try {
    const { data, error } = await rpc<string>('studio_skript_speichern', {
      p_sequenz_id: sequenzId,
      p_skript: skript,
      p_pruefung: { gesperrteWelten: pruefung.gesperrteWelten, befunde: pruefung.befunde },
    })
    if (error) return { data: null, error: fehler(error) }
    return { data, error: null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

/** Audio-Bedarf je Beat und Welt (studio_stimme_bedarf). */
export type StimmeBedarf = { beatKey: string; welt: string; fingerabdruck: string; vorhanden: boolean; platzhalter: boolean }

export async function ladeStimmeBedarf(sequenzId: string): Promise<StudioErgebnis<StimmeBedarf[]>> {
  try {
    const { data, error } = await rpc<{ beat_key: string; welt: string; fingerabdruck: string; vorhanden: boolean; platzhalter: boolean }[]>(
      'studio_stimme_bedarf',
      { p_sequenz_id: sequenzId },
    )
    if (error) return { data: null, error: fehler(error) }
    return {
      data: (data ?? []).map((r) => ({ beatKey: r.beat_key, welt: r.welt, fingerabdruck: r.fingerabdruck, vorhanden: r.vorhanden, platzhalter: r.platzhalter })),
      error: null,
    }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

export type StimmeLauf = { erzeugt: number; offen: number; platzhalter: boolean; fehler: string[] }

/** Ein Durchgang „Fehlende erzeugen“ über die Server-Route (Vercel Function api/studio/stimme). */
export async function erzeugeFehlendeStimmen(sequenzId: string): Promise<StudioErgebnis<StimmeLauf>> {
  try {
    const { data: s } = await supabase.auth.getSession()
    const token = s.session?.access_token
    if (!token) return { data: null, error: { code: '401', message: 'ohne_anmeldung', hint: null } }
    const res = await fetch('/api/studio/stimme', {
      method: 'POST',
      headers: { 'content-type': 'application/json', authorization: `Bearer ${token}` },
      body: JSON.stringify({ sequenzId }),
    })
    const body = (await res.json().catch(() => ({}))) as Partial<StimmeLauf> & { fehler?: unknown }
    if (!res.ok) return { data: null, error: { code: String(res.status), message: String(body.fehler ?? res.status), hint: null } }
    return { data: body as StimmeLauf, error: null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

/** Stimme, Modell oder Wörterbuch setzen (nur Admin). */
export async function setzeStudioEinstellung(schluessel: 'stimme_id' | 'modell' | 'aussprache', wert: unknown): Promise<StudioErgebnis<null>> {
  try {
    const { error } = await rpc<null>('studio_einstellung_setzen', { p_schluessel: schluessel, p_wert: wert })
    return { data: null, error: error ? fehler(error) : null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}

export async function ladeStudioEinstellungen(): Promise<StudioErgebnis<Record<string, unknown>>> {
  try {
    const { data, error } = await supabase.from('studio_einstellung').select('schluessel, wert')
    if (error) return { data: null, error: fehler(error) }
    return { data: Object.fromEntries(((data ?? []) as { schluessel: string; wert: unknown }[]).map((r) => [r.schluessel, r.wert])), error: null }
  } catch (e) {
    return { data: null, error: fehler(e) }
  }
}
