/**
 * Leichte Tests für Navigation + State-Übergänge der Vor-Ort-Session.
 * Lauf: `npm run test:mock` (node:test über tsx, kein Browser, kein Netz).
 */
import { test } from 'node:test'
import assert from 'node:assert/strict'
import {
  initSessionState,
  sessionReducer,
  bossEligible,
  levelUpEligible,
  presenceMultiplier,
  levelFromXp,
  xpToNextLevel,
  displayStage,
  correctCount,
  type SessionState,
  type SessionAction,
  type SessionConfig,
} from './sessionMachine'

const CONFIG: SessionConfig = {
  startXp: 1340,
  presenceWeeks: 4,
  taskCount: 7,
  repairTokens: 2,
}

function run(state: SessionState, actions: SessionAction[]): SessionState {
  return actions.reduce(sessionReducer, state)
}

/** Bringt die Session bis in den Mastery-Screen mit `correct` richtigen Aufgaben. */
function playThrough(correct: number): SessionState {
  let state = run(initSessionState(CONFIG), [
    { type: 'CHECK_IN' },
    { type: 'START_SESSION' },
    { type: 'START_TASKS' },
  ])
  for (let i = 0; i < CONFIG.taskCount; i++) {
    state = sessionReducer(state, {
      type: 'ANSWER',
      correct: i < correct,
      baseXp: 30,
    })
    state = sessionReducer(state, { type: 'NEXT_TASK' })
  }
  return state
}

/* ─── Pure Helfer ─────────────────────────────────────────────────────────────── */

test('presenceMultiplier hält die Stufen 1.0/1.1/1.2/1.3 ein', () => {
  assert.equal(presenceMultiplier(1), 1.0)
  assert.equal(presenceMultiplier(3), 1.1)
  assert.equal(presenceMultiplier(5), 1.2)
  assert.equal(presenceMultiplier(8), 1.3)
})

test('levelFromXp und xpToNextLevel rechnen über 500er-Grenzen', () => {
  assert.equal(levelFromXp(0), 1)
  assert.equal(levelFromXp(1340), 3)
  assert.equal(levelFromXp(1500), 4)
  assert.equal(xpToNextLevel(1340), 160)
})

test('displayStage deckelt Mastered ohne Coach-Freigabe auf proficient (Hard Rule §6)', () => {
  assert.equal(displayStage(90, false), 'proficient')
  assert.equal(displayStage(90, true), 'mastered')
  assert.equal(displayStage(70, false), 'progressing')
})

/* ─── Navigation ──────────────────────────────────────────────────────────────── */

test('Start im Check-in, dann CHECK_IN → Hub', () => {
  const s0 = initSessionState(CONFIG)
  assert.equal(s0.screen, 'checkin')
  assert.equal(sessionReducer(s0, { type: 'CHECK_IN' }).screen, 'hub')
})

test('Hub-Absprünge: START_SESSION → goal, OPEN_PROGRESS/OPEN_TROPHIES möglich', () => {
  const hub = sessionReducer(initSessionState(CONFIG), { type: 'CHECK_IN' })
  assert.equal(sessionReducer(hub, { type: 'START_SESSION' }).screen, 'goal')
  assert.equal(sessionReducer(hub, { type: 'OPEN_PROGRESS' }).screen, 'progress')
  assert.equal(sessionReducer(hub, { type: 'OPEN_TROPHIES' }).screen, 'trophies')
})

test('INVARIANTE: Fortschritt/Trophäen aus dem Task-Flow NICHT erreichbar', () => {
  const inTask = run(initSessionState(CONFIG), [
    { type: 'CHECK_IN' },
    { type: 'START_SESSION' },
    { type: 'START_TASKS' },
  ])
  assert.equal(inTask.screen, 'task')
  assert.equal(sessionReducer(inTask, { type: 'OPEN_PROGRESS' }).screen, 'task')
  assert.equal(sessionReducer(inTask, { type: 'OPEN_TROPHIES' }).screen, 'task')
})

test('In-Session-Flow ist linear bis Mastery', () => {
  const state = playThrough(7)
  assert.equal(state.screen, 'mastery')
})

test('Fortschritt/Trophäen sind aus dem Abschluss erreichbar', () => {
  const done = sessionReducer(playThrough(7), { type: 'CONTINUE_FROM_MASTERY' })
  // Overlay schließen, dann browsen.
  const clear = sessionReducer(sessionReducer(done, { type: 'DISMISS_BOSS' }), {
    type: 'DISMISS_LEVELUP',
  })
  assert.equal(clear.screen, 'complete')
  assert.equal(sessionReducer(clear, { type: 'OPEN_PROGRESS' }).screen, 'progress')
})

/* ─── XP & Aufgaben-State ─────────────────────────────────────────────────────── */

test('ANSWER zählt nur richtige Antworten und vergibt XP genau einmal', () => {
  let s = run(initSessionState(CONFIG), [
    { type: 'CHECK_IN' },
    { type: 'START_SESSION' },
    { type: 'START_TASKS' },
  ])
  const xp0 = s.xp
  // Falsch: kein XP.
  s = sessionReducer(s, { type: 'ANSWER', correct: false, baseXp: 30 })
  assert.equal(s.xp, xp0)
  // Richtig: +round(30 * 1.1) = 33.
  s = sessionReducer(s, { type: 'ANSWER', correct: true, baseXp: 30 })
  assert.equal(s.xp, xp0 + 33)
  // Erneut richtig auf derselben Aufgabe: kein doppeltes XP.
  s = sessionReducer(s, { type: 'ANSWER', correct: true, baseXp: 30 })
  assert.equal(s.xp, xp0 + 33)
  assert.equal(correctCount(s), 1)
})

test('REVEAL_HINT erhöht die Hint-Nutzung der aktuellen Aufgabe', () => {
  const inTask = run(initSessionState(CONFIG), [
    { type: 'CHECK_IN' },
    { type: 'START_SESSION' },
    { type: 'START_TASKS' },
  ])
  const hinted = sessionReducer(inTask, { type: 'REVEAL_HINT' })
  assert.equal(hinted.hintLevel[0], 1)
})

/* ─── Boss & Level-Up (max 1× pro Session) ────────────────────────────────────── */

test('Boss-Challenge nur bei > 80 % korrekt, genau 1×', () => {
  // 5 von 7 ≈ 71 % → kein Boss.
  assert.equal(bossEligible(playThrough(5)), false)
  // 7 von 7 = 100 % → Boss.
  const strong = playThrough(7)
  assert.equal(bossEligible(strong), true)
  const afterBoss = sessionReducer(strong, { type: 'CONTINUE_FROM_MASTERY' })
  assert.equal(afterBoss.overlay, 'boss')
  assert.equal(afterBoss.bossChallengeShown, true)
  // Flag verhindert ein zweites Auslösen.
  assert.equal(bossEligible(afterBoss), false)
})

test('Abschluss-Sequenz: Boss → Level-Up → stiller Abschluss, je 1×', () => {
  const done = sessionReducer(playThrough(7), { type: 'CONTINUE_FROM_MASTERY' })
  assert.equal(done.overlay, 'boss')
  const lvl = sessionReducer(done, { type: 'DISMISS_BOSS' })
  assert.equal(lvl.overlay, 'levelup')
  assert.equal(lvl.levelUpShown, true)
  assert.equal(levelUpEligible(lvl), false)
  const clear = sessionReducer(lvl, { type: 'DISMISS_LEVELUP' })
  assert.equal(clear.overlay, 'none')
})

/* ─── Streak-Repair-Demo ──────────────────────────────────────────────────────── */

test('Streak-Repair-Demo: öffnen, Token einsetzen, schließen', () => {
  const hub = sessionReducer(initSessionState(CONFIG), { type: 'CHECK_IN' })
  const open = sessionReducer(hub, { type: 'OPEN_STREAK_REPAIR' })
  assert.equal(open.overlay, 'streak-repair')
  const used = sessionReducer(open, { type: 'USE_REPAIR_TOKEN' })
  assert.equal(used.overlay, 'none')
  assert.equal(used.repairTokens, 1)
})

/* ─── Restart ─────────────────────────────────────────────────────────────────── */

test('RESTART setzt die Session zurück und landet im Hub', () => {
  const done = sessionReducer(playThrough(7), { type: 'CONTINUE_FROM_MASTERY' })
  const restarted = sessionReducer(done, { type: 'RESTART' })
  assert.equal(restarted.screen, 'hub')
  assert.equal(restarted.xp, CONFIG.startXp)
  assert.equal(restarted.bossChallengeShown, false)
  assert.equal(restarted.levelUpShown, false)
  assert.equal(correctCount(restarted), 0)
})
