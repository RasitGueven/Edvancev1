// Pure-Logik-Tests für die Registry-Hilfen (kein DOM). Lauf: tsx --test
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { emptyAnswer, isAnswerReady } from './types'
import type { AnswerPayload } from '@/types'

const mc: AnswerPayload = {
  input_type: 'MC',
  options: [{ id: 'a', label: 'A' }],
  correct: ['a'],
}
const matching: AnswerPayload = {
  input_type: 'MATCHING',
  left: [
    { id: 'l1', label: 'L1' },
    { id: 'l2', label: 'L2' },
  ],
  right: [
    { id: 'r1', label: 'R1' },
    { id: 'r2', label: 'R2' },
  ],
  pairs: [
    ['l1', 'r1'],
    ['l2', 'r2'],
  ],
}
const cloze: AnswerPayload = {
  input_type: 'CLOZE',
  text: '{{1}} und {{2}}',
  blanks: [
    { id: '1', accepted: ['a'] },
    { id: '2', accepted: ['b'] },
  ],
}
const coordinate: AnswerPayload = {
  input_type: 'COORDINATE',
  grid: { xRange: [-5, 5], yRange: [-5, 5], step: 1 },
  task: 'place_point',
  expected: { points: [[1, 1]] },
  tolerance: 0.25,
}

test('emptyAnswer liefert die passende Variante pro Typ', () => {
  assert.deepEqual(emptyAnswer(mc), { input_type: 'MC', selected: [] })
  assert.deepEqual(emptyAnswer(coordinate), { input_type: 'COORDINATE', points: [] })
  assert.deepEqual(emptyAnswer(cloze), { input_type: 'CLOZE', blanks: {} })
})

test('isAnswerReady: leer = false', () => {
  assert.equal(isAnswerReady(mc, emptyAnswer(mc)), false)
  assert.equal(isAnswerReady(matching, emptyAnswer(matching)), false)
  assert.equal(isAnswerReady(cloze, emptyAnswer(cloze)), false)
  assert.equal(isAnswerReady(coordinate, emptyAnswer(coordinate)), false)
})

test('isAnswerReady: ausgefüllt = true', () => {
  assert.equal(isAnswerReady(mc, { input_type: 'MC', selected: ['a'] }), true)
  assert.equal(
    isAnswerReady(matching, { input_type: 'MATCHING', pairs: [['l1', 'r1'], ['l2', 'r2']] }),
    true,
  )
  assert.equal(
    isAnswerReady(cloze, { input_type: 'CLOZE', blanks: { '1': 'a', '2': 'b' } }),
    true,
  )
  assert.equal(
    isAnswerReady(coordinate, { input_type: 'COORDINATE', points: [[1, 1]] }),
    true,
  )
})

test('isAnswerReady: Typ-Mismatch = false', () => {
  assert.equal(isAnswerReady(mc, { input_type: 'NUMERIC', value: '7' }), false)
})

test('isAnswerReady: MATCHING braucht alle Paare', () => {
  assert.equal(isAnswerReady(matching, { input_type: 'MATCHING', pairs: [['l1', 'r1']] }), false)
})
