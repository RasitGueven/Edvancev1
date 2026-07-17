// Datenzugriff des Autoren-Tools (/admin/authoring).
//
// Drei Pfade, drei Rechtelagen — sie sind hier bewusst getrennt sichtbar:
//   tasks            → normale Tabelle. Lesen: authenticated. Schreiben: RLS
//                      `admin_write_tasks`, also nur Admin.
//   task_solutions   → Server-Only-Zone (P01 §4). KEIN Tabellen-Grant. Schreiben
//                      ueber task_solution_upsert, Lesen ueber task_solution_get.
//   status           → ueber task_status_set, damit reviewed_by aus auth.uid()
//                      kommt und nicht aus dem Request-Body.
//
// task_solution_get / task_status_set / tasks.curriculum_grade existieren erst
// nach docs/schema/A01-authoring.proposal.sql. Bis dahin laeuft das Tool im
// Degraded-Modus — deshalb probeAuthoringSchema(): wir raten nicht, wir fragen.

import { supabase } from '@/lib/supabase/client'
import type {
  AuthoringSchema,
  AuthoringTask,
  AuthoringTaskPatch,
  GroundingBeleg,
  SolutionAnswers,
  SupabaseResult,
  TaskSolution,
  TaskSolutionPatch,
} from '@/types'

/** PostgREST, wenn die RPC nicht existiert. */
const FN_MISSING = 'PGRST202'
/** Postgres, wenn eine Spalte nicht existiert (undefined_column). */
const COL_MISSING = '42703'

const NIL_UUID = '00000000-0000-0000-0000-000000000000'

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
  'est_duration_sec',
  'class_level',
  'parts',
  'assets',
  'needs_image',
  'question_payload',
  'source',
  'source_ref',
  'is_active',
  'created_at',
].join(',')

const A01_COLUMNS = 'curriculum_grade,reviewed_by,reviewed_at'

let schemaCache: AuthoringSchema | null = null

/**
 * Welche A01-Felder hat die DB wirklich? Einmal pro Seitenladung, dann gecached.
 * Wichtig: ein `select` auf eine fehlende Spalte laesst PostgREST die GANZE
 * Abfrage mit 42703 scheitern — die Spaltenliste muss also stimmen, bevor die
 * Liste laedt. Nicht optional, nicht "wird schon".
 */
export async function probeAuthoringSchema(): Promise<AuthoringSchema> {
  if (schemaCache) return schemaCache

  const [cols, solRead, gate] = await Promise.all([
    supabase.from('tasks').select(`id,${A01_COLUMNS}`).limit(1),
    supabase.rpc('task_solution_get', { p_task_id: NIL_UUID }),
    // NIL_UUID existiert nie → die RPC laeuft in "nicht gefunden" (P0002) und
    // schreibt nichts. Uns interessiert nur, ob sie ueberhaupt da ist.
    supabase.rpc('task_status_set', { p_task_id: NIL_UUID, p_status: 'draft' }),
  ])

  schemaCache = {
    hasStoffanker: cols.error?.code !== COL_MISSING,
    hasSolutionRead: solRead.error?.code !== FN_MISSING,
    hasStatusGate: gate.error?.code !== FN_MISSING,
  }
  return schemaCache
}

/** Nur fuer Tests — der Cache ueberlebt sonst den Rollenwechsel nicht sauber. */
export function resetAuthoringSchemaCache(): void {
  schemaCache = null
}

function columnsFor(schema: AuthoringSchema): string {
  return schema.hasStoffanker ? `${BASE_COLUMNS},${A01_COLUMNS}` : BASE_COLUMNS
}

// ── tasks lesen ─────────────────────────────────────────────────────────────

/**
 * Alle Items der Pflege. Bewusst ohne Server-Filter: 185 Zeilen sind eine
 * Handvoll KB, und die Flags (offene Pflichtfelder) lassen sich ohnehin nur im
 * Client rechnen — ein serverseitiger Statusfilter wuerde die Flag-Zaehler der
 * ausgeblendeten Items verschweigen. Gefiltert wird in der Liste.
 */
export async function listAuthoringTasks(): Promise<SupabaseResult<AuthoringTask[]>> {
  try {
    const schema = await probeAuthoringSchema()
    const { data, error } = await supabase
      .from('tasks')
      .select(columnsFor(schema))
      .eq('content_type', 'exercise')
      .order('created_at', { ascending: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as unknown as AuthoringTask[], error: null }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Items konnten nicht geladen werden') }
  }
}

export async function getAuthoringTask(
  taskId: string,
): Promise<SupabaseResult<AuthoringTask>> {
  try {
    const schema = await probeAuthoringSchema()
    const { data, error } = await supabase
      .from('tasks')
      .select(columnsFor(schema))
      .eq('id', taskId)
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as unknown as AuthoringTask, error: null }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Item konnte nicht geladen werden') }
  }
}

// ── tasks schreiben ─────────────────────────────────────────────────────────

/**
 * Stamm, Teilaufgaben, Tags, Assets. NICHT der Status — der laeuft ueber
 * setTaskStatus, sonst umgeht die Freigabe ihr eigenes Gate.
 *
 * Der CHECK `tasks_multipart_check` prueft die parts-Struktur in der DB. Ein
 * kaputtes parts-Array kommt hier als Fehlermeldung zurueck, nicht als stille
 * Halb-Speicherung — genau so ist es gewollt.
 */
export async function updateAuthoringTask(
  taskId: string,
  patch: AuthoringTaskPatch,
): Promise<SupabaseResult<AuthoringTask>> {
  try {
    const schema = await probeAuthoringSchema()
    const payload: Record<string, unknown> = { ...patch }
    if (!schema.hasStoffanker) delete payload.curriculum_grade

    const { data, error } = await supabase
      .from('tasks')
      .update(payload)
      .eq('id', taskId)
      .select(columnsFor(schema))
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as unknown as AuthoringTask, error: null }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Item konnte nicht gespeichert werden') }
  }
}

// ── task_solutions (Server-Only-Zone) ───────────────────────────────────────

const EMPTY_SOLUTION: TaskSolution = {
  exists: false,
  correct_answers: [],
  solution: null,
  beleg: [],
  hints: [],
  coach_hints: [],
  typical_errors: [],
}

/**
 * Liest die Loesung ueber task_solution_get. Fehlt die RPC noch, liefern wir eine
 * leere Loesung mit exists=false — der Editor zeigt dann das Degraded-Banner und
 * warnt, dass Speichern ueberschreibt statt ergaenzt.
 */
export async function getTaskSolution(
  taskId: string,
): Promise<SupabaseResult<TaskSolution>> {
  try {
    const schema = await probeAuthoringSchema()
    if (!schema.hasSolutionRead) return { data: { ...EMPTY_SOLUTION }, error: null }

    const { data, error } = await supabase.rpc('task_solution_get', { p_task_id: taskId })
    if (error) return { data: null, error: error.message }

    const row = (data ?? {}) as Partial<TaskSolution>
    return {
      data: {
        exists: row.exists === true,
        correct_answers: (row.correct_answers ?? []) as SolutionAnswers,
        solution: row.solution ?? null,
        // Fehlt die Spalte noch (DB vor B01), liefert die RPC kein `beleg` — dann
        // bleibt das Panel im Editor einfach leer. Kein Sonderfall, kein Banner.
        beleg: (row.beleg ?? []) as GroundingBeleg[],
        hints: row.hints ?? [],
        coach_hints: row.coach_hints ?? [],
        typical_errors: row.typical_errors ?? [],
        updated_at: row.updated_at,
      },
      error: null,
    }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Loesung konnte nicht geladen werden') }
  }
}

/**
 * Schreibt die Loesung — OHNE den Quellenbeleg.
 *
 * task_solution_upsert patcht seit B01 pro Feld: ein Parameter, der nicht
 * mitgeschickt wird, bleibt in der DB unveraendert. Genau deshalb steht `beleg`
 * hier nicht — das Tool kann ihn anzeigen, aber strukturell nicht zerstoeren.
 *
 * `p_solution` geht bewusst als Leerstring statt als null raus: null hiesse
 * "unveraendert", und der Pfleger koennte einen Loesungsweg nie wieder leeren.
 */
export async function upsertTaskSolution(
  taskId: string,
  solution: TaskSolutionPatch,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('task_solution_upsert', {
      p_task_id: taskId,
      p_correct_answers: solution.correct_answers,
      p_solution: solution.solution ?? '',
      p_hints: solution.hints,
      p_coach_hints: solution.coach_hints,
      p_typical_errors: solution.typical_errors,
    })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Loesung konnte nicht gespeichert werden') }
  }
}

// ── Freigabe-Gate ───────────────────────────────────────────────────────────

/**
 * Statuswechsel. Ueber task_status_set, damit der Pruefer serverseitig gestempelt
 * wird. Fehlt die RPC, faellt es auf ein direktes Update zurueck — dann ohne
 * Audit-Stempel, und die Liste zeigt das an. Nicht schoen, aber ehrlich: lieber
 * kein Stempel als ein selbst ausgestellter.
 */
export async function setTaskStatus(
  taskId: string,
  status: 'draft' | 'review' | 'ready',
): Promise<SupabaseResult<true>> {
  try {
    const schema = await probeAuthoringSchema()
    if (schema.hasStatusGate) {
      const { error } = await supabase.rpc('task_status_set', {
        p_task_id: taskId,
        p_status: status,
      })
      if (error) return { data: null, error: error.message }
      return { data: true, error: null }
    }

    const { error } = await supabase.from('tasks').update({ status }).eq('id', taskId)
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Status konnte nicht gesetzt werden') }
  }
}

// ── Cluster/Fach ────────────────────────────────────────────────────────────

export type AuthoringCluster = {
  id: string
  name: string
  subject_id: string
  subject_name: string
}

/**
 * Alle Cluster mit ihrem Fach. Fuer den Fach-Filter der Liste und die
 * Cluster-Zuordnung im Editor. `cluster_id` ist kein Kosmetikfeld: lsa_start
 * joint INNER auf skill_clusters — ein Item ohne Cluster landet nie im Pool.
 */
export async function listClustersWithSubject(): Promise<
  SupabaseResult<AuthoringCluster[]>
> {
  try {
    const { data, error } = await supabase
      .from('skill_clusters')
      .select('id,name,subject_id,subjects(name)')
      .order('name', { ascending: true })
    if (error) return { data: null, error: error.message }

    const rows = (data ?? []) as unknown as {
      id: string
      name: string
      subject_id: string
      subjects: { name: string } | { name: string }[] | null
    }[]

    return {
      data: rows.map((r) => ({
        id: r.id,
        name: r.name,
        subject_id: r.subject_id,
        subject_name: Array.isArray(r.subjects)
          ? (r.subjects[0]?.name ?? '')
          : (r.subjects?.name ?? ''),
      })),
      error: null,
    }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Cluster konnten nicht geladen werden') }
  }
}

/** Namen der Pruefer:innen fuer die Anzeige ("freigegeben von …"). */
export async function getReviewerNames(
  ids: string[],
): Promise<SupabaseResult<Map<string, string>>> {
  try {
    const unique = [...new Set(ids.filter(Boolean))]
    if (unique.length === 0) return { data: new Map(), error: null }
    const { data, error } = await supabase
      .from('profiles')
      .select('id,full_name,email')
      .in('id', unique)
    if (error) return { data: null, error: error.message }
    const map = new Map<string, string>()
    for (const p of data ?? []) {
      map.set(p.id as string, (p.full_name as string) || (p.email as string))
    }
    return { data: map, error: null }
  } catch (err) {
    return { data: null, error: toMessage(err, 'Pruefer konnten nicht geladen werden') }
  }
}

function toMessage(err: unknown, fallback: string): string {
  return err instanceof Error ? err.message : fallback
}
