import type { SkillCluster, Subject, Task } from '@/types'

// Test-Fixtures für die Diagnostik-Admin-Tests. Bewusst lokal im Feature-Ordner
// (kein src/lib), damit die Extraktion keinen Shared-Baustein erzwingt.

export function makeTask(overrides: Partial<Task> = {}): Task {
  return {
    id: 'task-1',
    microskill_id: null,
    cluster_id: 'cluster-1',
    source: 'manual',
    source_ref: null,
    content_type: 'exercise',
    title: null,
    question: 'Wie viel ist 2 + 2?',
    solution: '4',
    hint: null,
    common_errors: null,
    coach_note: null,
    difficulty: 3,
    estimated_minutes: 3,
    class_level: 7,
    is_active: true,
    created_at: '2026-01-01T00:00:00.000Z',
    cognitive_type: 'FACT',
    input_type: 'NUMERIC',
    is_diagnostic: true,
    curriculum_ref: null,
    question_payload: null,
    typical_errors: null,
    assets: [],
    ...overrides,
  }
}

export function makeSubject(overrides: Partial<Subject> = {}): Subject {
  return { id: 'subject-1', name: 'Mathematik', ...overrides }
}

export function makeCluster(overrides: Partial<SkillCluster> = {}): SkillCluster {
  return {
    id: 'cluster-1',
    subject_id: 'subject-1',
    name: 'Bruchrechnung',
    class_level_min: 5,
    class_level_max: 7,
    sort_order: 1,
    ...overrides,
  }
}
