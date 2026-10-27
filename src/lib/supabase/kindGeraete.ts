// Reihe 1 · D1 — Geräte der Home-App und Zugangscode in der Schülerakte (nur Admin).
// Lesen und Schreiben über die RPCs aus 20261027130748_reihe1_d1_geraete; den Code liest der Admin aus
// vertraege (RLS: nur Admin).

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type KindGeraet = {
  id: string
  name: string
  plattform: 'ios' | 'android' | 'web'
  angemeldet_am: string
  zuletzt_gesehen: string
  abgemeldet_am: string | null
  abmelde_grund: 'admin' | 'neu_angemeldet' | 'abbruch' | null
}

export type KindZugang = {
  vertrag_id: string
  zugangscode: string | null
  zugangscode_erzeugt_am: string | null
  zugangscode_gesperrt_am: string | null
}

const fehlertext = (err: unknown, fallback: string): string => (err instanceof Error ? err.message : fallback)

export async function listKindGeraete(studentId: string): Promise<SupabaseResult<KindGeraet[]>> {
  try {
    const { data, error } = await supabase.rpc('kind_geraete_liste', { p_student: studentId })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as KindGeraet[], error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'kind_geraete_liste failed') }
  }
}

/** Der jüngste abgeschlossene Vertrag des Kindes mit seinem Zugangscode, sonst null. */
export async function getKindZugang(studentId: string): Promise<SupabaseResult<KindZugang | null>> {
  try {
    const { data, error } = await supabase
      .from('vertraege')
      .select('id, zugangscode, zugangscode_erzeugt_am, zugangscode_gesperrt_am')
      .eq('student_id', studentId)
      .eq('status', 'abgeschlossen')
      .order('vertragsbeginn', { ascending: false })
      .limit(1)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    if (!data) return { data: null, error: null }
    const { id, ...rest } = data as { id: string } & Omit<KindZugang, 'vertrag_id'>
    return { data: { vertrag_id: id, ...rest }, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'vertraege failed') }
  }
}

async function aufruf<T>(name: string, args: Record<string, unknown>): Promise<SupabaseResult<T>> {
  try {
    const { data, error } = await supabase.rpc(name, args)
    if (error) return { data: null, error: error.message }
    return { data: data as T, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, `${name} failed`) }
  }
}

export const kindGeraetAbmelden = (geraetId: string): Promise<SupabaseResult<null>> =>
  aufruf('kind_geraet_abmelden', { p_geraet: geraetId })

/** Bestand (Verträge-Menü): lehnt widerrufene, gesperrte oder ausgelaufene Verträge ab. */
export const zugangscodeNeu = (vertragId: string): Promise<SupabaseResult<string>> =>
  aufruf('vertrag_zugangscode_neu', { p_vertrag_id: vertragId })

export const zugangscodeFreischalten = (vertragId: string): Promise<SupabaseResult<null>> =>
  aufruf('zugangscode_freischalten', { p_vertrag: vertragId })
