// Der eingescannte Ruecklauf. Privater Bucket "vertraege" (P1, Entscheidung 16),
// Zugriff nur fuer Admins — deshalb Signed URL statt oeffentlicher Adresse.
//
// Pfad: <vertrag_id>/ruecklauf-<zeitstempel>.<ext>. Das erste Segment ist die
// Vertrags-ID, damit ein Scan ohne Umweg ueber eine Tabelle dem Vertrag
// zuzuordnen ist.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export const VERTRAEGE_BUCKET = 'vertraege'
const SIGNED_URL_TTL = 60 * 60

function endung(datei: File): string {
  const teile = datei.name.split('.')
  const ext = teile.length > 1 ? teile.pop()! : 'pdf'
  return ext.toLowerCase().replace(/[^a-z0-9]/g, '') || 'pdf'
}

export async function uploadScan(
  vertragId: string,
  datei: File,
): Promise<SupabaseResult<string>> {
  try {
    const pfad = `${vertragId}/ruecklauf-${Date.now()}.${endung(datei)}`
    const { error } = await supabase.storage
      .from(VERTRAEGE_BUCKET)
      .upload(pfad, datei, { upsert: false, contentType: datei.type || undefined })
    if (error) return { data: null, error: error.message }
    return { data: pfad, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Scan konnte nicht hochgeladen werden'
    return { data: null, error: message }
  }
}

export async function scanUrl(pfad: string): Promise<SupabaseResult<string>> {
  try {
    const { data, error } = await supabase.storage
      .from(VERTRAEGE_BUCKET)
      .createSignedUrl(pfad, SIGNED_URL_TTL)
    if (error) return { data: null, error: error.message }
    return { data: data.signedUrl, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Scan konnte nicht geoeffnet werden'
    return { data: null, error: message }
  }
}
