// Schreibpfad des Vorbefuellt-Kennzeichens (tasks.vorbefuellt), getrennt von
// taskAuthoring.ts (Dateigroesse). Die Regeln stehen in lib/authoring/vorbefuellt.

import { hatEintraege, LOESUNGS_FELDER, ohneSpalten } from '@/lib/authoring/vorbefuellt'
import { updateAuthoringTask } from '@/lib/supabase/taskAuthoring'
import type { AuthoringTask, SupabaseResult } from '@/types'

/**
 * Nach einem erfolgreichen Loesungs-Speichern im Editor: die Kennzeichen der
 * Loesungsfelder gelten als bestaetigt. Ohne solche Eintraege kein Request.
 */
export async function bestaetigeLoesungsKennzeichen(
  taskId: string,
  task: AuthoringTask,
): Promise<SupabaseResult<AuthoringTask>> {
  if (!hatEintraege(task.vorbefuellt, LOESUNGS_FELDER)) return { data: task, error: null }
  return updateAuthoringTask(taskId, { vorbefuellt: ohneSpalten(task.vorbefuellt, LOESUNGS_FELDER) })
}
