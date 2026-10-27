// L5 Teil B (docs/report/Bauauftrag-L5.md, Entscheidungen 6–7): Schreib- und Lesewege für die Mathearbeiten aus dem
// Erstgespräch und für die Admin-Ansicht je Schule und Klasse. Nur Admin (RLS bzw. Prüfung in den Funktionen der
// Migration 20261027081403). Fehlt die Migration, liefern die Lesewege null bzw. leere Listen, und die Felder bleiben
// ausgeblendet.

import { supabase } from '@/lib/supabase/client'
import { schuljahrVon } from '@/lib/report/elternbericht/kaFolge'
import type { SupabaseResult } from '@/types'

const FACH = 'mathematik'

const fehler = (err: unknown, fallback: string): string => (err instanceof Error ? err.message : fallback)

/** Schuljahr von heute (Europe/Berlin), wie ka_schuljahr(now()) in SQL. */
export function schuljahrHeute(): string {
  const tag = new Intl.DateTimeFormat('en-CA', { timeZone: 'Europe/Berlin' }).format(new Date())
  return schuljahrVon(tag)
}

/** Ein Unterrichtsvorhaben mit Thema aus dem Schulplan der Klasse. */
export type KaPlanThema = { themaKey: string; titel: string }

export async function listKaPlanThemen(schuleId: string, klasse: number): Promise<SupabaseResult<KaPlanThema[]>> {
  try {
    const { data, error } = await supabase
      .from('schul_themenplan')
      .select('position, thema_key, uv_titel')
      .eq('schule_id', schuleId)
      .eq('fach', FACH)
      .eq('klasse', klasse)
      .order('position', { ascending: true })
    if (error) return { data: null, error: error.message }
    const gesehen = new Set<string>()
    const themen: KaPlanThema[] = []
    for (const z of (data ?? []) as { thema_key: string | null; uv_titel: string }[]) {
      if (!z.thema_key || gesehen.has(z.thema_key)) continue
      gesehen.add(z.thema_key)
      themen.push({ themaKey: z.thema_key, titel: z.uv_titel })
    }
    return { data: themen, error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load school plan') }
  }
}

/** Was das Erstgespräch zu den Mathearbeiten erfasst hat; null, wenn die Migration fehlt. */
export type KaErstgespraech = { anzahl: number | null; themaKeys: string[] }

export async function ladeKaErstgespraech(leadId: string): Promise<KaErstgespraech | null> {
  try {
    const [lead, zeile] = await Promise.all([
      supabase.from('leads').select('ka_anzahl_schuljahr').eq('id', leadId).maybeSingle(),
      supabase
        .from('lead_klassenarbeiten')
        .select('thema_keys')
        .eq('lead_id', leadId)
        .eq('fach', FACH)
        .eq('schuljahr', schuljahrHeute())
        .eq('quelle', 'erstgespraech')
        .maybeSingle(),
    ])
    if (lead.error || zeile.error) {
      console.warn('ka_folge: Erstgespräch nicht lesbar — Felder ausgeblendet', (lead.error ?? zeile.error)?.message)
      return null
    }
    const anzahl = (lead.data as { ka_anzahl_schuljahr: number | null } | null)?.ka_anzahl_schuljahr ?? null
    const themaKeys = (zeile.data as { thema_keys: string[] } | null)?.thema_keys ?? []
    return { anzahl, themaKeys }
  } catch (e) {
    console.warn('ka_folge: Erstgespräch nicht lesbar — Felder ausgeblendet', e)
    return null
  }
}

export async function saveKaErstgespraech(
  leadId: string,
  werte: {
    anzahl: number | null
    status: 'bevorstehend' | 'geschrieben' | null
    datum: string | null
    themaKeys: string[]
    note: number | null
  },
): Promise<SupabaseResult<null>> {
  try {
    const { error } = await supabase.rpc('ka_erstgespraech_speichern', {
      p_lead_id: leadId,
      p_anzahl: werte.anzahl,
      p_status: werte.status,
      p_datum: werte.datum,
      p_thema_keys: werte.themaKeys,
      p_note: werte.note,
    })
    if (error) return { data: null, error: error.message }
    return { data: null, error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Klassenarbeiten konnten nicht gespeichert werden') }
  }
}

/* ─── Admin-Ansicht je Schule und Klasse ──────────────────────────────────── */

export type KaGruppe = { schuleId: string; schulname: string; klasse: number; kinder: number; bestaetigte: number }

export async function listKaGruppen(schuljahr: string): Promise<SupabaseResult<KaGruppe[]>> {
  try {
    const { data, error } = await supabase.rpc('ka_folge_uebersicht', { p_schuljahr: schuljahr })
    if (error) return { data: null, error: error.message }
    type Zeile = { schule_id: string; schulname: string; klasse: number; kinder: number; bestaetigte: number }
    return {
      data: ((data ?? []) as Zeile[]).map((z) => ({
        schuleId: z.schule_id,
        schulname: z.schulname,
        klasse: z.klasse,
        kinder: z.kinder,
        bestaetigte: z.bestaetigte,
      })),
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load Klassenarbeiten') }
  }
}

/** Eine abgeleitete Arbeit einer Schule/Klasse (ka_folge_schule). */
export type KaSchulArbeit = {
  nr: number | null
  themaKeys: string[]
  datum: string | null
  kinder: number
  bestaetigt: boolean
  gueltig: boolean
}

export async function listKaSchulFolge(
  schuleId: string,
  klasse: number,
  schuljahr: string,
): Promise<SupabaseResult<KaSchulArbeit[]>> {
  try {
    const { data, error } = await supabase.rpc('ka_folge_schule', {
      p_schule_id: schuleId,
      p_klasse: klasse,
      p_schuljahr: schuljahr,
    })
    if (error) return { data: null, error: error.message }
    type Zeile = { nr: number | null; thema_keys: string[]; datum: string | null; kinder: number; bestaetigt: boolean; gueltig: boolean }
    return {
      data: ((data ?? []) as Zeile[]).map((z) => ({
        nr: z.nr,
        themaKeys: z.thema_keys,
        datum: z.datum,
        kinder: z.kinder,
        bestaetigt: z.bestaetigt,
        gueltig: z.gueltig,
      })),
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehler(err, 'Could not load Klassenarbeiten') }
  }
}

/** Bestätigt bzw. korrigiert eine Arbeit der Schule (schul_klassenarbeiten, bestaetigt = true). */
export async function bestaetigeKaSchulArbeit(
  gruppe: { schuleId: string; klasse: number; schuljahr: string },
  arbeit: { nr: number; themaKeys: string[]; datum: string | null; vorherNr?: number | null },
  adminId: string,
): Promise<SupabaseResult<null>> {
  try {
    const schluessel = { schule_id: gruppe.schuleId, fach: FACH, klasse: gruppe.klasse, schuljahr: gruppe.schuljahr }
    if (typeof arbeit.vorherNr === 'number' && arbeit.vorherNr !== arbeit.nr) {
      const { error } = await supabase.from('schul_klassenarbeiten').delete().match({ ...schluessel, nr: arbeit.vorherNr })
      if (error) return { data: null, error: error.message }
    }
    const { error } = await supabase.from('schul_klassenarbeiten').upsert({
      ...schluessel,
      nr: arbeit.nr,
      thema_keys: arbeit.themaKeys,
      datum: arbeit.datum,
      bestaetigt: true,
      bestaetigt_von: adminId,
      bestaetigt_am: new Date().toISOString(),
    })
    if (error) return { data: null, error: error.message }
    return { data: null, error: null }
  } catch (err) {
    return { data: null, error: fehler(err, 'Klassenarbeit konnte nicht bestätigt werden') }
  }
}
