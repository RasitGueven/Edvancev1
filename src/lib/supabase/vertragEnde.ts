// Vertragsende und Widerrufsfrist kommen ausschliesslich aus der Datenbank
// (vertrag_ende_berechnen / vertrag_widerruf_bis, Migration 20260925120000).
//
// Auch fuer die Vorschau in Schritt 1. Eine zweite Rechnung im Frontend waere
// eine zweite Wahrheit — und die, die dem Elternteil auf dem Bildschirm
// angezeigt wird, waere nicht die, die im Vertrag landet.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type VertragEnde = {
  nominal: string
  ferientage: number
  ende: string
  /** Namen der Ferien, die das Ende geschoben haben. */
  ferien: string[]
}

export async function berechneVertragsende(
  beginn: string,
  laufzeitMonate: number,
): Promise<SupabaseResult<VertragEnde>> {
  try {
    const { data, error } = await supabase
      .rpc('vertrag_ende_berechnen', {
        p_beginn: beginn,
        p_laufzeit_monate: laufzeitMonate,
      })
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    if (!data) return { data: null, error: null }
    const row = data as VertragEnde
    return {
      data: {
        nominal: row.nominal,
        ferientage: row.ferientage,
        ende: row.ende,
        ferien: row.ferien ?? [],
      },
      error: null,
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Vertragsende konnte nicht berechnet werden'
    return { data: null, error: message }
  }
}

export async function berechneWiderrufBis(beginn: string): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.rpc('vertrag_widerruf_bis', { p_beginn: beginn })
    if (error) return { data: null, error: error.message }
    return { data: data as string, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Widerrufsfrist konnte nicht berechnet werden'
    return { data: null, error: message }
  }
}
