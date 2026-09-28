// Erzeugen, ablegen, festhalten — in dieser Reihenfolge und ohne Umweg.
//
// Die Reihenfolge ist nicht beliebig. Erst der Upload mit upsert:false, dann
// der Datenbankeintrag. Faellt die Funktion dazwischen aus, liegt eine Datei
// ohne Eintrag im Bucket: sichtbar, erkennbar, von Hand zu bereinigen. Umge-
// kehrt gaebe es einen Eintrag mit Pruefsumme auf eine Datei, die es nicht
// gibt — ein Archiv, das etwas behauptet, was nicht da ist.

import type { SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { markdownZuPdf } from './markdown_pdf.ts'
import { vertragDokument } from './vertrag_dokument.ts'

export const BUCKET = 'vertraege'

export type ErzeugteDatei = { art: string; pfad: string; sha256: string; bytes: number }

async function sha256Hex(bytes: Uint8Array): Promise<string> {
  // Kopie in einen frischen ArrayBuffer: crypto.subtle nimmt keine Sicht auf
  // einen SharedArrayBuffer, und genau das ist der Typ, den pdf.save() liefert.
  const hash = await crypto.subtle.digest('SHA-256', new Uint8Array(bytes))
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
}

async function ablegen(
  admin: SupabaseClient,
  rpc: SupabaseClient,
  vertragId: string,
  art: string,
  dateiname: string,
  bytes: Uint8Array,
  contentType: string,
): Promise<ErzeugteDatei> {
  const pfad = `${vertragId}/${dateiname}`
  const sha256 = await sha256Hex(bytes)

  // upsert:false ist die eigentliche Zusage: ein archiviertes Dokument wird
  // nicht ersetzt. Der Unique-Constraint in vertrag_dateien sagt dasselbe noch
  // einmal — zwei Schloesser an derselben Tuer, weil eine Datei im Bucket und
  // ein Eintrag in der Tabelle getrennt entstehen koennen.
  const { error: upErr } = await admin.storage
    .from(BUCKET)
    .upload(pfad, bytes, { upsert: false, contentType })
  if (upErr) throw new Error(`Upload ${pfad}: ${upErr.message}`)

  const { error: rpcErr } = await rpc.rpc('vertrag_datei_eintragen', {
    p_vertrag_id: vertragId,
    p_art: art,
    p_pfad: pfad,
    p_sha256: sha256,
    p_bytes: bytes.length,
  })
  if (rpcErr) {
    // Der Eintrag fehlt — dann soll auch die Datei nicht liegen bleiben, sonst
    // blockiert sie beim naechsten Versuch den Upload mit upsert:false.
    await admin.storage.from(BUCKET).remove([pfad])
    throw new Error(`Eintrag ${pfad}: ${rpcErr.message}`)
  }

  return { art, pfad, sha256, bytes: bytes.length }
}

/**
 * Das Vertrags-PDF und — wenn vor Ort unterschrieben wurde — das
 * Unterschriftsbild als eigene Datei.
 *
 * Die Unterschrift steht damit zweimal da: als Spalte in
 * vertrag_unterschriften und als PNG im Archiv. Das ist Absicht. Die Spalte
 * ist der Beleg, die Datei ist das, was man jemandem zeigen kann, ohne ihm
 * Datenbankzugriff zu geben.
 *
 * `rpc` traegt das JWT des Admins, `admin` den Service-Key: der Eintrag
 * bekommt einen Urheber, der Upload in den privaten Bucket funktioniert.
 */
export async function vertragPdfErzeugen(
  admin: SupabaseClient,
  rpc: SupabaseClient,
  vertragId: string,
): Promise<ErzeugteDatei[]> {
  const dok = await vertragDokument(admin, vertragId)
  const pdf = await markdownZuPdf({
    markdown: dok.markdown,
    fusszeile: dok.fusszeile,
    unterschrift: dok.unterschrift,
  })

  const raus: ErzeugteDatei[] = []
  raus.push(await ablegen(admin, rpc, vertragId, 'vertrag', 'vertrag.pdf', pdf, 'application/pdf'))

  if (dok.unterschrift) {
    raus.push(
      await ablegen(
        admin, rpc, vertragId, 'unterschrift', 'unterschrift.png',
        dok.unterschrift.png, 'image/png',
      ),
    )
  }
  return raus
}

/** Liegt fuer diesen Vertrag schon ein vertrag.pdf im Archiv? */
export async function hatVertragPdf(admin: SupabaseClient, vertragId: string): Promise<boolean> {
  const { data } = await admin
    .from('vertrag_dateien')
    .select('id')
    .eq('vertrag_id', vertragId)
    .eq('art', 'vertrag')
    .maybeSingle()
  return data !== null && data !== undefined
}
