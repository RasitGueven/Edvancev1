// Aufgaben-Queue der Präsenz-Session. Ersetzt die 5 hardcodierten WARMUP_TASKS
// durch echte tasks-Zeilen aus der DB. Konsumiert ausschließlich bestehende
// lib-Funktionen (Foundation-Freeze) — kein eigener Supabase-Zugriff.

import { getClustersForStudent, getTasksByClusterOrdered } from '@/lib/supabase/tasks'
import { getCompletedTaskIds } from '@/lib/supabase/taskProgress'
import { getResumePoint } from '@/lib/supabase/resume'
import { isAnswerPayload } from '@/types'
import type { AnswerPayload, Student, SupabaseResult, Task } from '@/types'

export type SessionTask = {
  id: string
  prompt: string
  payload: AnswerPayload
}

// Wie viele Aufgaben eine Session maximal ausspielt (bisher: 5 Warmups).
export const SESSION_TASK_LIMIT = 5

// Eine tasks-Zeile ist nur dann in der Session spielbar, wenn sie eine Übung
// ist, einen Prompt hat und ein question_payload trägt, das zum kanonischen
// input_type passt. Alles andere (Video, Artikel, Payload-lose Bestandsdaten)
// fällt still heraus — die Session bleibt lauffähig.
export function toSessionTask(task: Task): SessionTask | null {
  if (task.content_type !== 'exercise') return null
  if (!task.input_type || !task.question) return null
  if (!isAnswerPayload(task.question_payload, task.input_type)) return null
  const payload = { ...task.question_payload, input_type: task.input_type } as AnswerPayload
  return { id: task.id, prompt: task.question, payload }
}

// Offene, spielbare Aufgaben in Lernreihenfolge, gedeckelt auf `limit`.
export function buildSessionQueue(
  tasks: Task[],
  completedIds: Iterable<string>,
  limit: number = SESSION_TASK_LIMIT,
): SessionTask[] {
  const done = new Set(completedIds)
  const queue: SessionTask[] = []
  for (const task of tasks) {
    if (done.has(task.id)) continue
    const sessionTask = toSessionTask(task)
    if (sessionTask) queue.push(sessionTask)
    if (queue.length === limit) break
  }
  return queue
}

// Cluster-Reihenfolge für die Session: zuerst der Wiedereinstiegs-Cluster
// (zuletzt abgeschlossene Aufgabe), danach die übrigen Cluster des/der
// Schüler:in. Neue Schüler:innen ohne Fortschritt starten beim ersten Cluster.
async function clusterOrder(student: Student): Promise<string[]> {
  const [{ data: resume }, { data: clusters }] = await Promise.all([
    getResumePoint(student.id),
    getClustersForStudent(student.id, student.class_level),
  ])
  const ids = (clusters ?? []).map((c) => c.id)
  if (!resume) return ids
  return [resume.clusterId, ...ids.filter((id) => id !== resume.clusterId)]
}

// Lädt die Session-Queue: erster Cluster, der noch offene spielbare Aufgaben
// hat, gewinnt. Leere Queue ist ein gültiges Ergebnis (alles erledigt oder
// noch kein Content) — die UI zeigt dann einen EmptyState statt Fake-Aufgaben.
export async function loadSessionQueue(
  student: Student,
): Promise<SupabaseResult<SessionTask[]>> {
  try {
    const { data: completedIds, error } = await getCompletedTaskIds(student.id)
    if (error) return { data: null, error }

    for (const clusterId of await clusterOrder(student)) {
      const { data: tasks } = await getTasksByClusterOrdered(clusterId)
      const queue = buildSessionQueue(tasks ?? [], completedIds ?? [])
      if (queue.length > 0) return { data: queue, error: null }
    }
    return { data: [], error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Session-Aufgaben konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
