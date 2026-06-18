/**
 * Tests für die Aufgaben-Auswertung — insbesondere die Geraden-Aufgabe:
 * korrekt ist JEDES Paar verschiedener Punkte auf der Soll-Geraden, nicht nur
 * zwei feste Stützpunkte.
 * Lauf: `npm run test:mock`.
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import { evaluateTask, answerReady, type TaskAnswer } from './taskEval'
import {
  MOCK_SESSION_TASKS,
  type SessionTaskMC,
  type SessionTaskNumeric,
  type SessionTaskCoordinate,
} from '@/lib/mocks/session'

const lineTask = MOCK_SESSION_TASKS.find((t) => t.id === 'lf-6') as SessionTaskCoordinate
const mcTask = MOCK_SESSION_TASKS.find((t) => t.id === 'lf-1') as SessionTaskMC
const numTask = MOCK_SESSION_TASKS.find((t) => t.id === 'lf-2') as SessionTaskNumeric

function coord(points: { x: number; y: number }[]): TaskAnswer {
  return { kind: 'coordinate', points }
}

test('Gerade y=x+1: jedes Paar verschiedener Punkte auf der Geraden ist korrekt', () => {
  // Der gemeldete Fall: P(0|1), Q(1|2) — beide auf y=x+1.
  assert.equal(evaluateTask(lineTask, coord([{ x: 0, y: 1 }, { x: 1, y: 2 }])), true)
  // Andere gültige Punkte auf derselben Geraden.
  assert.equal(evaluateTask(lineTask, coord([{ x: -1, y: 0 }, { x: 2, y: 3 }])), true)
  // Auch in umgekehrter Reihenfolge.
  assert.equal(evaluateTask(lineTask, coord([{ x: 3, y: 4 }, { x: 0, y: 1 }])), true)
})

test('Gerade: ein Punkt neben der Geraden ist falsch', () => {
  assert.equal(evaluateTask(lineTask, coord([{ x: 0, y: 1 }, { x: 1, y: 3 }])), false)
})

test('Gerade: zwei zusammenfallende Punkte sind falsch', () => {
  assert.equal(evaluateTask(lineTask, coord([{ x: 0, y: 1 }, { x: 0, y: 1 }])), false)
})

test('MC: richtige Option korrekt, andere falsch', () => {
  assert.equal(evaluateTask(mcTask, { kind: 'mc', index: mcTask.correctIndex }), true)
  const wrong = (mcTask.correctIndex + 1) % mcTask.options.length
  assert.equal(evaluateTask(mcTask, { kind: 'mc', index: wrong }), false)
  assert.equal(answerReady({ kind: 'mc', index: null }), false)
})

test('Numerisch: Wert in Toleranz korrekt, außerhalb falsch, Komma erlaubt', () => {
  assert.equal(evaluateTask(numTask, { kind: 'numeric', raw: String(numTask.answer) }), true)
  assert.equal(evaluateTask(numTask, { kind: 'numeric', raw: '999' }), false)
  const decimal: SessionTaskNumeric = {
    id: 'x',
    kind: 'numeric',
    afb: 'I',
    prompt: '',
    hints: [],
    xp: 10,
    answer: 1.5,
    tolerance: 0.01,
  }
  assert.equal(evaluateTask(decimal, { kind: 'numeric', raw: '1,5' }), true)
})
