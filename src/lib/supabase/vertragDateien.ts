// Die erzeugten Dokumente eines Vertrags: was im Archiv liegt und wie es
// dahin kam. Gegenstueck zu vertragScan.ts, das nur den Bucket kennt.
//
// Der Bucket weiss, dass unter <vertrag_id>/vertrag.pdf etwas liegt — nicht,
// ob es aus diesem Vertragsstand stammt, wann und von wem. Das steht in
// vertrag_dateien, und nur deshalb gibt es beide Abfragen.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type VertragDatei = {
  art: 'vertrag' | 'unterschrift' | 'unterlagen_versand' | 'sepa_mandat'
  pfad: string
  sha256: string
  bytes: number | null
  erzeugtAm: string
}

/**
 * Eine der Unterlagen, die fuer alle gleich sind. Der Schluessel ist (art,
 * fassung) und nicht der Vertrag: AGB und Widerrufsbelehrung enthalten keinen
 * Platzhalter, es gibt sie einmal je Fassung. Welcher Fassung ein Vertrag
 * zugestimmt hat, steht in vertrag_zustimmungen.
 */
export type DokumentFassung = {
  art: string
  fassung: string
  pfad: string
  erzeugtAm: string
}

export async function listDokumentFassungen(): Promise<SupabaseResult<DokumentFassung[]>> {
  try {
    const { data, error } = await supabase
      .from('dokument_fassungen')
      .select('art, fassung, pfad, erzeugt_am')
    if (error) return { data: null, error: error.message }
    const fassungen = (data ?? []).map((d) => ({
      art: d.art as string,
      fassung: d.fassung as string,
      pfad: d.pfad as string,
      erzeugtAm: d.erzeugt_am as string,
    }))
    return { data: fassungen, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Fassungen konnten nicht geladen werden'
    return { data: null, error: msg }
  }
}

export async function listVertragDateien(vertragId: string): Promise<SupabaseResult<VertragDatei[]>> {
  try {
    const { data, error } = await supabase
      .from('vertrag_dateien')
      .select('art, pfad, sha256, bytes, erzeugt_am')
      .eq('vertrag_id', vertragId)
      .order('erzeugt_am', { ascending: true })
    if (error) return { data: null, error: error.message }
    const dateien = (data ?? []).map((d) => ({
      art: d.art as VertragDatei['art'],
      pfad: d.pfad as string,
      sha256: d.sha256 as string,
      bytes: (d.bytes as number | null) ?? null,
      erzeugtAm: d.erzeugt_am as string,
    }))
    return { data: dateien, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Archiv konnte nicht geladen werden'
    return { data: null, error: msg }
  }
}

/**
 * Das Vertrags-PDF nachtraeglich erzeugen.
 *
 * Normalerweise entsteht es beim Abschluss. Bleibt es dabei aus — die Edge
 * Function meldet das als pdf_fehler, ohne den Abschluss zurueckzunehmen —,
 * ist das hier der Weg zurueck zu einem vollstaendigen Archiv.
 */
export async function vertragPdfErzeugen(
  vertragId: string,
  art: 'buendel' | 'unterlagen' = 'buendel',
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.functions.invoke('vertrag_pdf', {
      body: { vertrag_id: vertragId, art },
    })
    if (error) {
      // Die Edge Function antwortet mit {error: "..."} im Body; die generische
      // Meldung von invoke() ("non-2xx status code") hilft am Empfang nicht.
      let msg = error.message
      try {
        const antwort = (await (error as unknown as { context: Response }).context.json()) as {
          error?: string
        }
        if (antwort?.error) msg = antwort.error
      } catch {
        /* generische Meldung behalten */
      }
      return { data: null, error: msg }
    }
    return { data: true, error: null }
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'PDF konnte nicht erzeugt werden'
    return { data: null, error: msg }
  }
}
