// Supabase-Storage-Wrapper fuer Task-Assets.
// Bucket-Konvention: 'task-assets' (public read), Pfad: tasks/<task_id>/<timestamp>-<sanitized-name>
// RLS-Setup siehe migrations/010_task_assets_storage_rls.sql.

import { supabase } from './client'
import { cropObjectPath } from '@/lib/authoring/crop'
import type { SupabaseResult } from '@/types'

export const TASK_ASSETS_BUCKET = 'task-assets'

export type UploadedAsset = { url: string; path: string }

function sanitizeFilename(name: string): string {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9.\-_]+/g, '_')
    .slice(0, 80)
}

export async function uploadTaskAssetFile(
  taskId: string,
  file: File,
): Promise<SupabaseResult<UploadedAsset>> {
  try {
    const safeName = sanitizeFilename(file.name)
    const path = `tasks/${taskId}/${Date.now()}-${safeName}`
    const { error: uploadError } = await supabase.storage
      .from(TASK_ASSETS_BUCKET)
      .upload(path, file, {
        cacheControl: '3600',
        upsert: false,
        contentType: file.type || undefined,
      })
    if (uploadError) return { data: null, error: uploadError.message }
    const { data } = supabase.storage.from(TASK_ASSETS_BUCKET).getPublicUrl(path)
    return { data: { url: data.publicUrl, path }, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Bild-Upload fehlgeschlagen'
    return { data: null, error: message }
  }
}

/**
 * Listet die vorbereiteten Kandidatenbilder einer Aufgabe.
 *
 * Pfad-Konvention: kandidaten/<task_id>/<bildname> — dorthin laedt
 * scripts/kandidaten_upload.py die Nicht-Deko-Bilder der VERA-Quelle hoch.
 * Der Pfleger waehlt daraus aus, statt das Bild von Hand zu suchen.
 *
 * Diese Funktion selbst legt nichts an und loescht nichts. Der Prefix ist aber
 * NICHT unveraenderlich: cropObjectPath leitet den Schluessel eines Zuschnitts
 * aus dem Ordner des Originals ab — schneidet der Pfleger einen Kandidaten zu,
 * landet das Ergebnis als …-crop-<stamp>.png daneben. Solche Zuschnitte gehoeren
 * nicht in die Auswahl: sie sind kein Quellmaterial, und beides nebeneinander
 * als "Kandidat" zu zeigen (noch dazu beides als uebernommen markiert) waere
 * nur verwirrend. Deshalb fliegen sie hier raus.
 *
 * Eine leere Liste ist kein Fehler — sie heisst nur, dass fuer dieses Item
 * nichts vorbereitet wurde.
 */
export async function listCandidateAssets(
  taskId: string,
): Promise<SupabaseResult<UploadedAsset[]>> {
  try {
    const prefix = `kandidaten/${taskId}`
    // Ohne limit deckelt Supabase still bei 100. Ein Item hat eine Handvoll
    // Kandidaten — die Grenze ist ein Sicherheitsnetz, kein erwarteter Fall.
    const { data, error } = await supabase.storage
      .from(TASK_ASSETS_BUCKET)
      .list(prefix, { limit: 1000 })
    if (error) return { data: null, error: error.message }
    const files = (data ?? [])
      // Ordner haben keine id, und Supabase legt beim Anlegen eines Prefix
      // einen unsichtbaren Platzhalter ab — beides ist kein Kandidatenbild.
      .filter((entry) => entry.id !== null && entry.name !== '.emptyFolderPlaceholder')
      // Zuschnitte, die neben ihrem Original gelandet sind (siehe oben).
      .filter((entry) => !/-crop-\d+\.png$/.test(entry.name))
      .map((entry) => {
        const path = `${prefix}/${entry.name}`
        const { data: pub } = supabase.storage.from(TASK_ASSETS_BUCKET).getPublicUrl(path)
        return { url: pub.publicUrl, path }
      })
    return { data: files, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'candidate list failed'
    return { data: null, error: message }
  }
}

/**
 * Laedt einen Zuschnitt als NEUE Datei hoch. Das Original wird nicht angefasst.
 *
 * Drei Dinge halten dieses Versprechen, und alle drei sind Absicht:
 *   1. cropObjectPath baut einen anderen Schluessel als den des Originals
 *      (…-crop-<stamp>.png) — wir schreiben also nie auf das Original.
 *   2. upsert: false — selbst wenn der Pfad wider Erwarten schon existierte,
 *      wuerde der Upload fehlschlagen statt still zu ueberschreiben.
 *   3. Es gibt hier kein remove(). Ein Fehlschnitt kostet ein totes Objekt im
 *      Bucket, kein verlorenes Original. Das ist der richtige Tausch: der
 *      Pfleger kommt ueber original_url jederzeit auf das Original zurueck.
 *
 * Die Rechte liegen nicht hier, sondern in der Storage-RLS: nur role = 'admin'
 * darf in task-assets schreiben. Ein Coach bekommt hier eine Fehlermeldung.
 */
export async function uploadTaskAssetCrop(
  taskId: string,
  sourceUrl: string,
  blob: Blob,
  stamp: number = Date.now(),
): Promise<SupabaseResult<UploadedAsset>> {
  try {
    const path = cropObjectPath(sourceUrl, TASK_ASSETS_BUCKET, taskId, stamp)
    const { error: uploadError } = await supabase.storage
      .from(TASK_ASSETS_BUCKET)
      .upload(path, blob, {
        cacheControl: '3600',
        upsert: false,
        contentType: 'image/png',
      })
    if (uploadError) return { data: null, error: uploadError.message }
    const { data } = supabase.storage.from(TASK_ASSETS_BUCKET).getPublicUrl(path)
    return { data: { url: data.publicUrl, path }, error: null }
  } catch (err) {
    // Englisch und roh: das hier ist die Server-/Debug-Ursache, die der Editor
    // nur als Detail in eine uebersetzte Meldung einsetzt (§12).
    const message = err instanceof Error ? err.message : 'crop upload failed'
    return { data: null, error: message }
  }
}
