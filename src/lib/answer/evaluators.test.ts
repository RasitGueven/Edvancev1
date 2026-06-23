// node:test-Suite für den kanonischen Evaluator. Lauf: npx tsx --test <file>
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { evaluate } from './evaluators'
import type { AnswerPayload } from '@/types/answerPayload'

test('MC: exakte id-Menge korrekt, Teilmenge/Abweichung falsch', () => {
  const p: AnswerPayload = {
    input_type: 'MC',
    options: [
      { id: 'a', label: 'A' },
      { id: 'b', label: 'B' },
    ],
    correct: ['a'],
  }
  assert.equal(evaluate('MC', p, { selected: ['a'] }).correct, true)
  assert.equal(evaluate('MC', p, { selected: ['b'] }).correct, false)
  assert.equal(evaluate('MC', p, { selected: [] }).correct, false)
})

test('NUMERIC: Toleranz + Komma-Eingabe', () => {
  const p: AnswerPayload = { input_type: 'NUMERIC', accepted: [42], tolerance: 0.5 }
  assert.equal(evaluate('NUMERIC', p, { value: '42' }).correct, true)
  assert.equal(evaluate('NUMERIC', p, { value: '42,4' }).correct, true)
  assert.equal(evaluate('NUMERIC', p, { value: '43' }).correct, false)
})

test('SHORT_TEXT: case-insensitive default', () => {
  const p: AnswerPayload = { input_type: 'SHORT_TEXT', accepted: ['Parabel'] }
  assert.equal(evaluate('SHORT_TEXT', p, { text: 'parabel' }).correct, true)
  assert.equal(evaluate('SHORT_TEXT', p, { text: 'Gerade' }).correct, false)
})

test('TRUE_FALSE: bool-Gleichheit', () => {
  const p: AnswerPayload = { input_type: 'TRUE_FALSE', correct: true }
  assert.equal(evaluate('TRUE_FALSE', p, { value: true }).correct, true)
  assert.equal(evaluate('TRUE_FALSE', p, { value: false }).correct, false)
  assert.equal(evaluate('TRUE_FALSE', p, { value: null }).correct, false)
})

test('FREE_TEXT: immer null (coach-bewertet)', () => {
  const p: AnswerPayload = { input_type: 'FREE_TEXT', rubric: 'Begründung' }
  assert.equal(evaluate('FREE_TEXT', p, { text: 'irgendwas' }).correct, null)
  assert.equal(evaluate('FREE_TEXT', p, {}).correct, null)
})

test('MATCHING: Paar-Menge reihenfolge-unabhängig', () => {
  const p: AnswerPayload = {
    input_type: 'MATCHING',
    left: [{ id: 'l1', label: 'L1' }],
    right: [{ id: 'r1', label: 'R1' }],
    pairs: [['l1', 'r1']],
  }
  assert.equal(evaluate('MATCHING', p, { pairs: [['l1', 'r1']] }).correct, true)
  assert.equal(evaluate('MATCHING', p, { pairs: [['l1', 'rX']] }).correct, false)
})

test('CLOZE: alle Lücken müssen passen', () => {
  const p: AnswerPayload = {
    input_type: 'CLOZE',
    text: '{{1}} ist {{2}}',
    blanks: [
      { id: '1', accepted: ['2'] },
      { id: '2', accepted: ['gerade'] },
    ],
  }
  assert.equal(evaluate('CLOZE', p, { blanks: { '1': '2', '2': 'gerade' } }).correct, true)
  assert.equal(evaluate('CLOZE', p, { blanks: { '1': '2', '2': 'ungerade' } }).correct, false)
  assert.equal(evaluate('CLOZE', p, { blanks: { '1': '2' } }).correct, false)
})

test('COORDINATE: Punkt in Toleranz + Segment via Steigung', () => {
  const point: AnswerPayload = {
    input_type: 'COORDINATE',
    grid: { xRange: [-5, 5], yRange: [-5, 5], step: 1 },
    task: 'place_point',
    expected: { points: [[2, 3]] },
    tolerance: 0.25,
  }
  assert.equal(evaluate('COORDINATE', point, { points: [[2, 3]] }).correct, true)
  assert.equal(evaluate('COORDINATE', point, { points: [[2, 4]] }).correct, false)

  const seg: AnswerPayload = {
    input_type: 'COORDINATE',
    grid: { xRange: [-5, 5], yRange: [-5, 5], step: 1 },
    task: 'draw_segment',
    expected: { line: { slope: 2, intercept: 1 } },
    tolerance: 0.1,
  }
  // zwei Punkte auf y = 2x + 1
  assert.equal(evaluate('COORDINATE', seg, { points: [[0, 1], [1, 3]] }).correct, true)
  assert.equal(evaluate('COORDINATE', seg, { points: [[0, 0], [1, 1]] }).correct, false)
})

test('Schrott/Diskriminator-Mismatch → false (außer FREE_TEXT)', () => {
  assert.equal(evaluate('MC', null, { selected: ['a'] }).correct, false)
  assert.equal(evaluate('NUMERIC', { input_type: 'NUMERIC', accepted: [1] }, {}).correct, false)
})
