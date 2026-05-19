import { supabase } from '@/lib/supabase/client'
import { getClusterById, getTasksByClusterOrdered } from '@/lib/supabase/tasks'
import { getCompletedTaskIds } from '@/lib/supabase/taskProgress'
import type { SupabaseResult } from '@/types'

export type ResumePoint = {
  clusterId: string
  clusterName: string
  taskId: string | null
}

// DB-abgeleiteter Wiedereinstieg (ersetzt das frühere localStorage
// 'edvance_last_cluster'): zuletzt abgeschlossene Aufgabe → deren Cluster →
// erste noch offene Aufgabe in diesem Cluster (in Lernreihenfolge). Ist der
// Cluster fertig, zeigt taskId=null auf die Cluster-Übersicht.
export async function getResumePoint(
  studentId: string,
): Promise<SupabaseResult<ResumePoint | null>> {
  try {
    const { data, error } = await supabase
      .from('student_task_progress')
      .select('task_id, completed_at, tasks(cluster_id)')
      .eq('student_id', studentId)
      .order('completed_at', { ascending: false })
      .limit(1)
    if (error) return { data: null, error: error.message }

    const row = (data ?? [])[0] as
      | { tasks: { cluster_id: string } | null }
      | undefined
    const clusterId = row?.tasks?.cluster_id
    if (!clusterId) return { data: null, error: null }

    const { data: cluster } = await getClusterById(clusterId)
    if (!cluster) return { data: null, error: null }

    const { data: tasks } = await getTasksByClusterOrdered(clusterId)
    const { data: completedIds } = await getCompletedTaskIds(studentId)
    const done = new Set(completedIds ?? [])
    const nextTask = (tasks ?? []).find((t) => !done.has(t.id))

    return {
      data: {
        clusterId,
        clusterName: cluster.name,
        taskId: nextTask?.id ?? null,
      },
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'Wiedereinstieg konnte nicht ermittelt werden'
    return { data: null, error: message }
  }
}
