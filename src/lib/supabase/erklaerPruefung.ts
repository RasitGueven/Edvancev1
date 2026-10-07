import { supabase } from '@/lib/supabase/client'
import type {
  ErklaerAntwort,
  ErklaerArt,
  ErklaerBild,
  ErklaerDetail,
  ErklaerEntscheidung,
  ErklaerFehler,
  ErklaerFehlt,
  ErklaerGrund,
  ErklaerListenZeile,
  ErklaerResult,
  ErklaerVariante,
} from '@/types/erklaerPruefung'

/**
 * Erklaersequenzen pruefen (L6): Aufrufe von erklaer_pruef_liste, erklaer_pruef_detail, erklaer_pruefen,
 * erklaer_freigeben, erklaer_freigabe_zuruecknehmen, erklaer_rueckfrage_beantworten und der Pflegefunktion
 * erklaer_schritt_speichern (E1). Die Funktionen stehen noch nicht in database.ts — der Cast haelt das
 * sichtbar, bis die Typen neu generiert sind (Muster pruefung.ts). Fehler behalten SQLSTATE, HINT und bei
 * „freigabe_unvollstaendig“ die Liste aus DETAIL.
 */

type RpcFehler = { message: string; code?: string; hint?: string | null; details?: string | null }
type Rpc = <T>(fn: string, args?: Record<string, unknown>) => Promise<{ data: T | null; error: RpcFehler | null }>

const rpc = supabase.rpc.bind(supabase) as unknown as Rpc

function fehltAus(details: string | null | undefined): ErklaerFehlt[] | null {
  if (!details) return null
  try {
    const liste: unknown = JSON.parse(details)
    return Array.isArray(liste) ? (liste as ErklaerFehlt[]) : null
  } catch {
    return null
  }
}

export function alsErklaerFehler(err: unknown): ErklaerFehler {
  if (err && typeof err === 'object' && 'message' in err) {
    const e = err as RpcFehler
    return { code: e.code ?? null, hint: e.hint ?? null, message: e.message, fehlt: fehltAus(e.details) }
  }
  return { code: null, hint: null, message: err instanceof Error ? err.message : 'unknown error', fehlt: null }
}

async function rufe<T>(fn: string, args?: Record<string, unknown>): Promise<ErklaerResult<T>> {
  try {
    const { data, error } = await rpc<T>(fn, args)
    if (error) return { data: null, error: alsErklaerFehler(error) }
    return { data: data as T, error: null }
  } catch (err) {
    return { data: null, error: alsErklaerFehler(err) }
  }
}

/** Alle Kernideen mit Stand, offen zuerst (Reihenfolge vom Server). */
export function getErklaerListe(): Promise<ErklaerResult<ErklaerListenZeile[]>> {
  return rufe<ErklaerListenZeile[]>('erklaer_pruef_liste')
}

export function getErklaerDetail(kernideeId: string): Promise<ErklaerResult<ErklaerDetail>> {
  return rufe<ErklaerDetail>('erklaer_pruef_detail', { p_kernidee_id: kernideeId })
}

export function erklaerPruefen(args: {
  kernideeId: string
  version: number
  entscheidung: ErklaerEntscheidung
  gruende?: ErklaerGrund[]
  notiz?: string | null
}): Promise<ErklaerResult<ErklaerAntwort>> {
  return rufe('erklaer_pruefen', {
    p_kernidee_id: args.kernideeId,
    p_entscheidung: args.entscheidung,
    p_gruende: args.gruende ?? null,
    p_notiz: args.notiz?.trim() || null,
    p_pruef_version: args.version,
  })
}

/** Lena bessert einen Schritt im Entwurf nach (E1-Pflegefunktion; Bild bleibt, wie es ist). */
export function erklaerSchrittSpeichern(args: {
  kernideeId: string
  variante: ErklaerVariante
  art: ErklaerArt
  inhalt: string
  bild: ErklaerBild | null
  fehlbildSlugs: string[]
}): Promise<ErklaerResult<string>> {
  return rufe('erklaer_schritt_speichern', {
    p_kernidee_id: args.kernideeId,
    p_variante: args.variante,
    p_art: args.art,
    p_inhalt: args.inhalt,
    p_bild: args.bild,
    p_fehlbild_slugs: args.fehlbildSlugs,
  })
}

export function erklaerFreigeben(kernideeId: string, version: number): Promise<ErklaerResult<ErklaerAntwort>> {
  return rufe('erklaer_freigeben', { p_kernidee_id: kernideeId, p_pruef_version: version })
}

export function erklaerFreigabeZuruecknehmen(
  kernideeId: string,
  grund: string,
  version: number,
): Promise<ErklaerResult<ErklaerAntwort>> {
  return rufe('erklaer_freigabe_zuruecknehmen', { p_kernidee_id: kernideeId, p_grund: grund.trim(), p_pruef_version: version })
}

export function erklaerRueckfrageBeantworten(kernideeId: string, antwort: string): Promise<ErklaerResult<ErklaerAntwort>> {
  return rufe('erklaer_rueckfrage_beantworten', { p_kernidee_id: kernideeId, p_antwort: antwort.trim() })
}
