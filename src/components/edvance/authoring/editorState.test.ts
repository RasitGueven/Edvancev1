// toPatch baut question_payload bei JEDEM Speichern neu. Das ist Absicht (Whitelist
// statt Durchreichen — dieselbe Zusage wie lsa_question_payload), hatte aber einen
// Preis: alles im Payload, was der Editor nicht kennt, war nach dem ersten Speichern
// weg. Die F01-Tabelle ist genau so ein Feld — 54 Items der VERA-Extraktion haben
// eine, und kein Editor-Feld zeigt sie an. Diese Suite haelt die Tabelle fest.

import { describe, expect, it } from 'vitest'
import { fromTask, toPatch, toSolution } from './editorState'
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
  needs_image: null,
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
  beleg: [{ feld: 'part1.correct_answers', quelle: 'Auswertung.docx', zitat: '16' }],
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

// A08: Die Bild-Notwendigkeit ist eine Beurteilung mit drei Zuständen. NULL =
// nicht beurteilt muss NULL bleiben (kein Automatismus), und in tasks.parts wird
// "nicht beurteilt" als FEHLENDES Feld geschrieben, nicht als needs_image:null.
describe('toPatch — needs_image (A08)', () => {
  it('trägt die Item-Beurteilung durch — true und null', () => {
    expect(toPatch(fromTask(task({ needs_image: true }), solution)).needs_image).toBe(true)
    expect(toPatch(fromTask(task({ needs_image: null }), solution)).needs_image).toBeNull()
  })

  it('schreibt parts[].needs_image nur als echte Beurteilung — null lässt das Feld weg', () => {
    const state = fromTask(
      task({
        input_type: 'MULTI_PART',
        est_duration_sec: 300,
        parts: [
          { nr: 1, kind: 'short_input', prompt: 'a', needs_image: true },
          { nr: 2, kind: 'short_input', prompt: 'b', needs_image: null },
        ],
      }),
      solution,
    )
    const parts = toPatch(state).parts ?? []
    expect(parts[0].needs_image).toBe(true)
    expect('needs_image' in parts[1]).toBe(false)
  })
})

// B01: Der Quellenbeleg ist die Quelle, gegen die gepflegt wird. Waere er Teil des
// Formulars, koennte ein Speichern ihn ueberschreiben — genau das war der Defekt,
// solange er im Loesungsfeld wohnte. Er geht rein, er kommt nie raus.
describe('toSolution — der Beleg ist unzerstoerbar', () => {
  it('nimmt den Beleg nicht in den FormState auf', () => {
    const state = fromTask(task(), solution)
    expect(JSON.stringify(state)).not.toContain('Auswertung.docx')
  })

  it('schickt den Beleg nicht an task_solution_upsert zurueck', () => {
    const written = toSolution(fromTask(task(), solution))
    expect(written).not.toHaveProperty('beleg')
    expect(JSON.stringify(written)).not.toContain('Auswertung.docx')
  })
})
