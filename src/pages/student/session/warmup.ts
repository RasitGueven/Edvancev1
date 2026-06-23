// Aufwärm-Aufgaben der Präsenz-Session — bewusst als kanonisches AnswerPayload,
// damit die Renderer-Registry + Evaluator end-to-end im echten Flow laufen.
// Aufgaben-Prompts sind Content (kein i18n, vgl. CLAUDE §12) und stehen hier als
// Platzhalter, bis tasks.question_payload ein AnswerPayload trägt
// (Adapter-Lücke, siehe docs/INPUT_TYPE_CANON.md §5.5).

import type { AnswerPayload } from '@/types'

export type WarmupTask = {
  id: string
  prompt: string
  payload: AnswerPayload
}

export const WARMUP_TASKS: WarmupTask[] = [
  {
    id: 'w1',
    prompt: 'Welche Steigung hat die Gerade $y = 2x + 3$?',
    payload: {
      input_type: 'MC',
      options: [
        { id: 'a', label: '2' },
        { id: 'b', label: '3' },
        { id: 'c', label: '−2' },
        { id: 'd', label: '½' },
      ],
      correct: ['a'],
    },
  },
  {
    id: 'w2',
    prompt: 'Berechne $f(2)$ für $f(x) = 2x + 3$.',
    payload: { input_type: 'NUMERIC', accepted: [7], tolerance: 0 },
  },
  {
    id: 'w3',
    prompt: 'Wahr oder falsch: Die Gerade $y = 2x + 3$ schneidet die $y$-Achse bei $3$.',
    payload: { input_type: 'TRUE_FALSE', correct: true },
  },
  {
    id: 'w4',
    prompt: 'Setze den Punkt $P(2\\,|\\,3)$ in das Koordinatensystem.',
    payload: {
      input_type: 'COORDINATE',
      grid: { xRange: [-5, 5], yRange: [-5, 5], step: 1 },
      task: 'place_point',
      expected: { points: [[2, 3]] },
      tolerance: 0.25,
    },
  },
  {
    id: 'w5',
    prompt: 'Erkläre in einem Satz, was die Steigung einer Geraden über ihren Verlauf aussagt.',
    payload: { input_type: 'FREE_TEXT', rubric: 'Steigung = Änderung in y pro Schritt in x' },
  },
]
