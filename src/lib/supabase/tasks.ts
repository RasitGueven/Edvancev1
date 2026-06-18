import { supabase } from '@/lib/supabase/client'
import type {
  DiagnosticTaskInput,
  Microskill,
  SkillCluster,
  Subject,
  SupabaseResult,
  Task,
  TaskAsset,
} from '@/types'

// Alle Faecher.
export async function getSubjects(): Promise<SupabaseResult<Subject[]>> {
  try {
    const { data, error } = await supabase
      .from('subjects')
      .select('*')
      .order('name', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Subject[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Faecher konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Aufgaben fuer ein Cluster, optional auf eine Klassenstufe gefiltert.
export async function getTasksByCluster(
  clusterId: string,
  classLevel?: number,
): Promise<SupabaseResult<Task[]>> {
  try {
    let query = supabase
      .from('tasks')
      .select('*')
      .eq('cluster_id', clusterId)
      .eq('is_active', true)
    if (classLevel != null) {
      query = query.eq('class_level', classLevel)
    }
    const { data, error } = await query.order('difficulty', { ascending: true, nullsFirst: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Task[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Aufgaben konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Cluster eines Fachs, optional auf eine Klassenstufe gefiltert (Stufe muss in Range liegen).
export async function getClustersBySubject(
  subjectId: string,
  classLevel?: number,
): Promise<SupabaseResult<SkillCluster[]>> {
  try {
    let query = supabase
      .from('skill_clusters')
      .select('*')
      .eq('subject_id', subjectId)
    if (classLevel != null) {
      query = query.lte('class_level_min', classLevel).gte('class_level_max', classLevel)
    }
    const { data, error } = await query.order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as SkillCluster[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Cluster konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Alle Cluster der Fächer, die der/die Schüler:in belegt (student_subjects),
// gefiltert auf die Klassenstufe. Quelle für das Schüler-Dashboard.
export async function getClustersForStudent(
  studentId: string,
  classLevel?: number | null,
): Promise<SupabaseResult<SkillCluster[]>> {
  try {
    const { data: links, error: linkError } = await supabase
      .from('student_subjects')
      .select('subject_id')
      .eq('student_id', studentId)
    if (linkError) return { data: null, error: linkError.message }
    const subjectIds = (links ?? []).map(
      (l) => (l as { subject_id: string }).subject_id,
    )
    if (subjectIds.length === 0) return { data: [], error: null }

    let query = supabase.from('skill_clusters').select('*').in('subject_id', subjectIds)
    if (classLevel != null) {
      query = query.lte('class_level_min', classLevel).gte('class_level_max', classLevel)
    }
    const { data, error } = await query.order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as SkillCluster[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Cluster konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Microskills eines Clusters, sortiert nach sort_order.
export async function getMicroskillsByCluster(
  clusterId: string,
): Promise<SupabaseResult<Microskill[]>> {
  try {
    const { data, error } = await supabase
      .from('microskills')
      .select('*')
      .eq('cluster_id', clusterId)
      .order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Microskill[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Microskills konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Microskills nach Liste von IDs (z.B. zum Auflösen der Namen aus tasks.microskill_id).
export async function getMicroskillsByIds(
  ids: string[],
): Promise<SupabaseResult<Microskill[]>> {
  if (ids.length === 0) return { data: [], error: null }
  try {
    const { data, error } = await supabase
      .from('microskills')
      .select('*')
      .in('id', ids)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Microskill[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Microskills konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Eine einzelne Aufgabe per id.
export async function getTaskById(taskId: string): Promise<SupabaseResult<Task | null>> {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .eq('id', taskId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as Task | null) ?? null, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Aufgabe konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Ein einzelnes Cluster per id.
export async function getClusterById(
  clusterId: string,
): Promise<SupabaseResult<SkillCluster | null>> {
  try {
    const { data, error } = await supabase
      .from('skill_clusters')
      .select('*')
      .eq('id', clusterId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data as SkillCluster | null) ?? null, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Cluster konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Alle aktiven Tasks eines Clusters in didaktischer Lernreihenfolge:
// erst Erklären (video, article), dann Üben (exercise nach difficulty),
// dann Testen (exercise_group, course).
const TYPE_ORDER: Record<Task['content_type'], number> = {
  video: 1,
  article: 2,
  exercise: 3,
  exercise_group: 4,
  course: 5,
}

export async function getTasksByClusterOrdered(
  clusterId: string,
): Promise<SupabaseResult<Task[]>> {
  const { data, error } = await getTasksByCluster(clusterId)
  if (error) return { data: null, error }
  const list = data ?? []
  const sorted = [...list].sort((a, b) => {
    const typeDiff = TYPE_ORDER[a.content_type] - TYPE_ORDER[b.content_type]
    if (typeDiff !== 0) return typeDiff
    const da = a.difficulty ?? 99
    const db = b.difficulty ?? 99
    if (da !== db) return da - db
    return a.id.localeCompare(b.id)
  })
  return { data: sorted, error: null }
}

// Alle Tasks aus einer Quelle (z.B. 'mathebuch_lambacher_8_nrw'),
// sortiert nach source_ref fuer stabile Anzeige-Reihenfolge.
export async function getTasksBySource(
  source: string,
): Promise<SupabaseResult<Task[]>> {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .select('*')
      .eq('source', source)
      .order('source_ref', { ascending: true, nullsFirst: false })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as Task[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Tasks aus Quelle konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// tasks.assets ueberschreiben (z.B. nach Bild-Upload oder Asset-Remove).
// Gibt die aktualisierte Task-Reihe zurueck.
export async function updateTaskAssets(
  taskId: string,
  assets: TaskAsset[],
): Promise<SupabaseResult<Task>> {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .update({ assets })
      .eq('id', taskId)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Task, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Aufgabe konnte nicht aktualisiert werden'
    return { data: null, error: message }
  }
}

// Diagnostik-relevante Felder einer Aufgabe setzen (Admin-Seeding).
// RLS: admin_write_tasks (nur Admin).
type TaskDiagnosticPatch = Partial<
  Pick<Task, 'is_diagnostic' | 'difficulty' | 'input_type' | 'cognitive_type' | 'is_active'>
>

export async function updateTaskDiagnostic(
  taskId: string,
  patch: TaskDiagnosticPatch,
): Promise<SupabaseResult<Task>> {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .update(patch)
      .eq('id', taskId)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Task, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Aufgabe konnte nicht aktualisiert werden'
    return { data: null, error: message }
  }
}

// Neue Diagnose-Aufgabe manuell anlegen (Admin-Seeding).
export async function createDiagnosticTask(
  input: DiagnosticTaskInput,
): Promise<SupabaseResult<Task>> {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .insert({
        content_type: 'exercise',
        is_diagnostic: true,
        is_active: true,
        source: 'manual',
        microskill_id: input.microskill_id ?? null,
        cluster_id: input.cluster_id ?? null,
        class_level: input.class_level ?? null,
        question: input.question,
        solution: input.solution ?? null,
        common_errors: input.common_errors ?? null,
        coach_note: input.coach_note ?? null,
        difficulty: input.difficulty ?? null,
        input_type: input.input_type ?? null,
        cognitive_type: input.cognitive_type ?? null,
        estimated_minutes: input.estimated_minutes ?? 3,
      })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as Task, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Aufgabe konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}
