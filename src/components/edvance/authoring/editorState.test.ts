// toPatch baut question_payload bei JEDEM Speichern neu. Das ist Absicht (Whitelist
// statt Durchreichen — dieselbe Zusage wie lsa_question_payload), hatte aber einen
// Preis: alles im Payload, was der Editor nicht kennt, war nach dem ersten Speichern
// weg. Die F01-Tabelle ist genau so ein Feld — 54 Items der VERA-Extraktion haben
// eine, und kein Editor-Feld zeigt sie an. Diese Suite haelt die Tabelle fest.

import { describe, expect, it } from 'vitest'
import { fromTask, toPatch } from './editorState'
import type { AuthoringTask, TaskSolution } from '@/types'

const TABLE = { headers: ['Bestandteil', 'gering'], rows: [['Fett', '< 3 g']] }

const task = (over: Partial<AuthoringTask> = {}): AuthoringTask => ({
  id: 't1',
  title: 'Nährwerttabelle',
  question: 'Lies die Tabelle.',
  status: 'draft',
  input_type: 'SHORT_TEXT',
  afb: 'I',
  competency_content: 'arithmetik_algebra',
  competency_process: 'ope',
  cluster_id: 'c1',
  unit: null,
  est_duration_sec: null,
  class_level: 8,
  curriculum_grade: null,
  parts: [],
  assets: [],
  question_payload: { table: TABLE },
  source: 'VERA8_IQB',
  source_ref: 'abc',
  is_active: true,
  created_at: '2026-07-01T00:00:00Z',
  ...over,
})

const solution: TaskSolution = {
  exists: true,
  correct_answers: ['16'],
  solution: null,
  hints: [],
  coach_hints: [],
  typical_errors: [],
}

describe('toPatch — question_payload', () => {
  it('haelt die Tabelle fest, obwohl der Editor sie nicht bearbeiten kann', () => {
    const patch = toPatch(fromTask(task(), solution))
    expect(patch.question_payload).toEqual({ table: TABLE })
  })

  it('haelt Tabelle UND MC-Optionen nebeneinander', () => {
    const state = fromTask(
      task({
        input_type: 'MC',
        question_payload: { input_type: 'MC', options: [{ id: 'a', label: 'A' }], table: TABLE },
      }),
      solution,
    )
    expect(toPatch(state).question_payload).toEqual({
      input_type: 'MC',
      options: [{ id: 'a', label: 'A' }],
      table: TABLE,
    })
  })

  it('bleibt null, wenn es weder Optionen noch Tabelle gibt', () => {
    const patch = toPatch(fromTask(task({ question_payload: null }), solution))
    expect(patch.question_payload).toBeNull()
  })

  it('traegt nie eine Loesung ins Payload — der CHECK wuerde sie abweisen', () => {
    const patch = toPatch(fromTask(task(), solution))
    expect(JSON.stringify(patch.question_payload)).not.toContain('16')
    expect(Object.keys(patch.question_payload ?? {})).not.toContain('correct')
  })
})
