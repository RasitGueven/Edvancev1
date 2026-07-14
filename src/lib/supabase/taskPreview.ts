// Der Lesepfad der Schueler-Vorschau — und der einzige, den es geben darf.
//
// Diese Datei baut KEIN Payload. Sie holt eins. Das ist der ganze Unterschied zur
// alten Vorschau, die aus dem FormState nachbaute, was das Kind angeblich sieht —
// und dabei still divergierte, sobald sich lsa_question_payload aenderte (F01: die
// Aufgaben-Tabelle kam serverseitig an und in der Vorschau nie).
//
// task_preview_payload ruft intern lsa_question_payload auf. Dieselbe Funktion,
// dieselbe Whitelist. Wenn hier ein Feld fehlt, fehlt es auch dem Kind.
//
// FALLBACK: Es gibt keinen. Fehlt die RPC (DB noch ohne A02-Migration), liefert
// diese Datei einen Fehler — und die Vorschau sagt das. Ein Client-seitiger
// Notnagel waere exakt die zweite Wahrheit, die A02 abschafft.

import { supabase } from '@/lib/supabase/client'
import type { AuthoringTaskPatch, PreviewPayload, SupabaseResult } from '@/types'

/** PostgREST, wenn die RPC nicht existiert (DB vor der A02-Migration). */
const FN_MISSING = 'PGRST202'

/** Fehlercode fuer den Editor: "die RPC ist noch nicht da" ist kein Bug, sondern ein Zustand. */
export const PREVIEW_RPC_MISSING = 'PREVIEW_RPC_MISSING'

/**
 * Holt das Payload eines Items — so, wie das Kind es bekommt.
 *
 * @param draft Der ungespeicherte Formularstand (genau das Objekt, das ein
 *   Speichern schreiben WUERDE — `toPatch(state)`). Der Server spielt ihn in einer
 *   Subtransaktion ein, baut daraus und rollt zurueck; die Zeile bleibt unberuehrt.
 *   Ohne `draft` kommt der gespeicherte Stand.
 *
 * Ein Entwurf, der nicht speicherbar waere (kaputte parts, kaputte Tabelle), faellt
 * hier in denselben DB-CHECK wie beim Speichern — die Fehlermeldung ist dieselbe.
 * Das ist gewollt: eine Vorschau, die mehr zeigt als speicherbar ist, luegt.
 */
export async function getTaskPreview(
  taskId: string,
  draft?: AuthoringTaskPatch | null,
): Promise<SupabaseResult<PreviewPayload>> {
  try {
    const { data, error } = await supabase.rpc('task_preview_payload', {
      p_task_id: taskId,
      p_draft: draft ?? null,
    })
    if (error) {
      return { data: null, error: error.code === FN_MISSING ? PREVIEW_RPC_MISSING : error.message }
    }
    // Der Server liefert null nur, wenn `tasks` die Zeile nicht mehr hat — und das
    // wirft er als P0002. Kommt hier trotzdem nichts, ist das kein leeres Item.
    if (!data) return { data: null, error: 'Vorschau: leeres Payload' }
    return { data: data as PreviewPayload, error: null }
  } catch (err) {
    return {
      data: null,
      error: err instanceof Error ? err.message : 'Vorschau konnte nicht geladen werden',
    }
  }
}
