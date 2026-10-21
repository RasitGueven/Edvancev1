// Spaltenlisten des Autoren-Tools (/admin/authoring), ausgelagert aus taskAuthoring.ts (400-Zeilen-Grenze).
//
// Die optionalen Spalten kommen erst mit ihren Migrationen. probeAuthoringSchema (taskAuthoring.ts) fragt,
// welche es gibt; columnsFor und ohneFehlendeSpalten richten Lesen und Schreiben danach aus. Ein `select`
// oder `update` auf eine fehlende Spalte liesse PostgREST die ganze Anfrage scheitern (42703 / PGRST204).

import type { AuthoringSchema } from '@/types'

const BASE_COLUMNS = [
  'id',
  'title',
  'question',
  'status',
  'input_type',
  'afb',
  'competency_content',
  'competency_process',
  'cluster_id',
  'unit',
  'skill_key',
  'est_duration_sec',
  'class_level',
  'parts',
  'assets',
  'needs_image',
  'licence_text',
  'question_payload',
  'source',
  'source_ref',
  'is_active',
  'created_at',
].join(',')

export const A01_COLUMNS = 'curriculum_grade,reviewed_by,reviewed_at'
/** Vorbefuellt-Kennzeichen (20260930140000_tasks_vorbefuellt). */
export const PREFILL_COLUMNS = 'vorbefuellt,vorbefuellt_am'
/** Bruch-Angabe, bestimmt das Eingabeformat beim Kind (20261021082756_lsa_eingabeformat, LSA-Erlebnis L1). */
export const BRUCH_COLUMNS = 'bruch'

export function columnsFor(schema: AuthoringSchema): string {
  return [
    BASE_COLUMNS,
    schema.hasStoffanker && A01_COLUMNS,
    schema.hasVorbefuellt && PREFILL_COLUMNS,
    schema.hasBruch && BRUCH_COLUMNS,
  ]
    .filter(Boolean)
    .join(',')
}

/** Entfernt aus einem Update-Payload die Felder, deren Spalte es (noch) nicht gibt. */
export function ohneFehlendeSpalten(payload: Record<string, unknown>, schema: AuthoringSchema): void {
  if (!schema.hasStoffanker) delete payload.curriculum_grade
  if (!schema.hasVorbefuellt) delete payload.vorbefuellt
  if (!schema.hasBruch) delete payload.bruch
}
