import { beforeEach, describe, expect, it, vi } from 'vitest'
import { getClustersForStudent, getTasksByClusterOrdered } from '@/lib/supabase/tasks'
import { getCompletedTaskIds } from '@/lib/supabase/taskProgress'
import { getResumePoint } from '@/lib/supabase/resume'
import { buildSessionQueue, loadSessionQueue, toSessionTask } from './sessionQueue'
import type { SkillCluster, Student, Task } from '@/types'

// Keine echten Supabase-Calls: die Queue konsumiert die lib nur, sie ändert sie
// nicht (Foundation-Freeze). Gespiegelt wird exakt die konsumierte Oberfläche.
vi.mock('@/lib/supabase/tasks', () => ({
  getClustersForStudent: vi.fn(),
  getTasksByClusterOrdered: vi.fn(),
}))
vi.mock('@/lib/supabase/taskProgress', () => ({ getCompletedTaskIds: vi.fn() }))
vi.mock('@/lib/supabase/resume', () => ({ getResumePoint: vi.fn() }))

const clustersMock = vi.mocked(getClustersForStudent)
const tasksMock = vi.mocked(getTasksByClusterOrdered)
const completedMock = vi.mocked(getCompletedTaskIds)
const resumeMock = vi.mocked(getResumePoint)

const STUDENT: Student = {
  id: 's1',
  profile_id: 'p1',
  class_level: 8,
  school_name: null,
  school_type: null,
}

function cluster(id: string): SkillCluster {
  return { id } as SkillCluster
}

// Minimal-Task: nur die Felder, die die Queue-Logik liest.
function task(patch: Partial<Task> = {}): Task {
  return {
    id: 't1',
    microskill_id: null,
    cluster_id: 'c1',
    source: 'test',
    source_ref: null,
    content_type: 'exercise',
    title: null,
    question: 'Welche Steigung hat $y = 2x + 3$?',
    solution: null,
    hint: null,
    common_errors: null,
    coach_note: null,
    difficulty: 1,
    estimated_minutes: 3,
    class_level: 8,
    is_active: true,
    created_at: '2026-01-01T00:00:00.000Z',
    cognitive_type: null,
    input_type: 'NUMERIC',
    is_diagnostic: false,
    curriculum_ref: null,
    question_payload: { input_type: 'NUMERIC', accepted: [2], tolerance: 0 },
    typical_errors: null,
    assets: [],
    ...patch,
  }
}

describe('toSessionTask', () => {
  it('macht aus einer vollständigen exercise-Zeile eine spielbare Aufgabe', () => {
    const result = toSessionTask(task())
    expect(result).toEqual({
      id: 't1',
      prompt: 'Welche Steigung hat $y = 2x + 3$?',
      payload: { input_type: 'NUMERIC', accepted: [2], tolerance: 0 },
    })
  })

  it('setzt input_type aus der Spalte, wenn das Payload ihn nicht trägt', () => {
    const result = toSessionTask(
      task({ question_payload: { accepted: [2], tolerance: 0 } }),
    )
    expect(result?.payload.input_type).toBe('NUMERIC')
  })

  it.each([
    ['video statt exercise', { content_type: 'video' as const }],
    ['kein input_type', { input_type: null }],
    ['kein question', { question: null }],
    ['kein question_payload', { question_payload: null }],
    ['Payload widerspricht input_type', { question_payload: { input_type: 'MC' } }],
  ])('verwirft nicht spielbare Zeile: %s', (_label, patch) => {
    expect(toSessionTask(task(patch))).toBeNull()
  })
})

describe('buildSessionQueue', () => {
  it('überspringt bereits abgeschlossene Aufgaben', () => {
    const queue = buildSessionQueue(
      [task({ id: 'done' }), task({ id: 'open' })],
      ['done'],
    )
    expect(queue.map((q) => q.id)).toEqual(['open'])
  })

  it('behält die übergebene Lernreihenfolge bei und deckelt auf das Limit', () => {
    const tasks = ['a', 'b', 'c'].map((id) => task({ id }))
    expect(buildSessionQueue(tasks, [], 2).map((q) => q.id)).toEqual(['a', 'b'])
  })

  it('filtert nicht spielbare Zeilen still heraus statt zu werfen', () => {
    const queue = buildSessionQueue(
      [task({ id: 'clip', content_type: 'video' }), task({ id: 'ok' })],
      [],
    )
    expect(queue.map((q) => q.id)).toEqual(['ok'])
  })

  it('liefert eine leere Queue, wenn alles erledigt ist', () => {
    expect(buildSessionQueue([task({ id: 'x' })], ['x'])).toEqual([])
  })
})

describe('loadSessionQueue', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    completedMock.mockResolvedValue({ data: [], error: null })
    resumeMock.mockResolvedValue({ data: null, error: null })
    clustersMock.mockResolvedValue({ data: [cluster('c1')], error: null })
    tasksMock.mockResolvedValue({ data: [task({ id: 't1' })], error: null })
  })

  it('lädt echte DB-Aufgaben des Schüler-Clusters', async () => {
    const { data } = await loadSessionQueue(STUDENT)
    expect(data?.map((q) => q.id)).toEqual(['t1'])
    expect(completedMock).toHaveBeenCalledWith('s1')
    expect(clustersMock).toHaveBeenCalledWith('s1', 8)
  })

  it('startet beim Wiedereinstiegs-Cluster, wenn es einen gibt', async () => {
    resumeMock.mockResolvedValue({
      data: { clusterId: 'c9', clusterName: 'Lineare Funktionen', taskId: null },
      error: null,
    })
    await loadSessionQueue(STUDENT)
    expect(tasksMock).toHaveBeenNthCalledWith(1, 'c9')
  })

  it('geht zum nächsten Cluster, wenn der erste keine offenen Aufgaben hat', async () => {
    clustersMock.mockResolvedValue({ data: [cluster('c1'), cluster('c2')], error: null })
    tasksMock
      .mockResolvedValueOnce({ data: [task({ id: 'done' })], error: null })
      .mockResolvedValueOnce({ data: [task({ id: 'open' })], error: null })
    completedMock.mockResolvedValue({ data: ['done'], error: null })

    const { data } = await loadSessionQueue(STUDENT)
    expect(data?.map((q) => q.id)).toEqual(['open'])
  })

  it('liefert eine leere Queue statt Fake-Aufgaben, wenn nichts offen ist', async () => {
    tasksMock.mockResolvedValue({ data: [], error: null })
    const { data, error } = await loadSessionQueue(STUDENT)
    expect(data).toEqual([])
    expect(error).toBeNull()
  })

  it('reicht einen Fortschritts-Ladefehler durch', async () => {
    completedMock.mockResolvedValue({ data: null, error: 'RLS denied' })
    const { data, error } = await loadSessionQueue(STUDENT)
    expect(data).toBeNull()
    expect(error).toBe('RLS denied')
  })
})
