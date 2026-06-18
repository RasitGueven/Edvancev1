/**
 * Reine, testbare Zustandsmaschine der Vor-Ort-Session (`/mock/session`).
 *
 * Kein React, kein Netzwerk, keine Persistenz — nur Übergänge im Speicher
 * (Build-Auftrag §8). Die Navigations-Invarianten leben hier, damit sie sich
 * mit `node:test` (via tsx) leicht prüfen lassen.
 */
import { masteryStage, type MasteryStage } from '@/lib/mastery'

export const XP_PER_LEVEL = 500

/* ─── Reine Helfer ────────────────────────────────────────────────────────────── */

export function levelFromXp(xp: number): number {
  return Math.floor(xp / XP_PER_LEVEL) + 1
}

export function xpInLevel(xp: number): number {
  return ((xp % XP_PER_LEVEL) + XP_PER_LEVEL) % XP_PER_LEVEL
}

export function xpToNextLevel(xp: number): number {
  return XP_PER_LEVEL - xpInLevel(xp)
}

/** Presence-Streak-Multiplikator: 3 Wo ×1.1, 5 Wo ×1.2, 8 Wo ×1.3. */
export function presenceMultiplier(weeks: number): number {
  if (weeks >= 8) return 1.3
  if (weeks >= 5) return 1.2
  if (weeks >= 3) return 1.1
  return 1.0
}

/**
 * Hard Rule §6: „Mastered" darf nie automatisch aus dem Score entstehen —
 * nur der Coach gewährt es. Ohne `coachGranted` wird bei Score ≥ 85 auf
 * „proficient" gedeckelt.
 */
export function displayStage(score: number, coachGranted: boolean): MasteryStage {
  const raw = masteryStage(score)
  if (raw === 'mastered' && !coachGranted) return 'proficient'
  return raw
}

/* ─── Screen- & Action-Typen ──────────────────────────────────────────────────── */

export type SessionScreen =
  | 'checkin' // 1
  | 'hub' // 2
  | 'goal' // 3
  | 'task' // 4 (+ Hint 5 / Feedback 6 als Sub-State im Screen)
  | 'mastery' // 7
  | 'complete' // 11
  | 'progress' // 9
  | 'trophies' // 10

/** Boss (8) und Level-Up sind Modal-Overlays über dem Abschluss, keine Screens. */
export type SessionOverlay = 'none' | 'boss' | 'levelup' | 'streak-repair'

export type TaskResult = 'pending' | 'correct' | 'wrong'

export interface SessionState {
  screen: SessionScreen
  overlay: SessionOverlay
  xp: number
  /** Level zu Session-Beginn — Referenz für die Level-Up-Erkennung. */
  startLevel: number
  presenceMultiplier: number
  taskCount: number
  taskIndex: number
  results: TaskResult[]
  /** Anzahl aufgedeckter Hinweise pro Aufgabe (Hint-Nutzung). */
  hintLevel: number[]
  bossChallengeShown: boolean
  levelUpShown: boolean
  repairTokens: number
  /** Ursprüngliche Konfiguration — erlaubt einen sauberen Demo-Neustart. */
  config: SessionConfig
}

export type SessionAction =
  | { type: 'CHECK_IN' }
  | { type: 'START_SESSION' }
  | { type: 'OPEN_PROGRESS' }
  | { type: 'OPEN_TROPHIES' }
  | { type: 'BACK_TO_HUB' }
  | { type: 'START_TASKS' }
  | { type: 'ANSWER'; correct: boolean; baseXp: number }
  | { type: 'REVEAL_HINT' }
  | { type: 'NEXT_TASK' }
  | { type: 'CONTINUE_FROM_MASTERY' }
  | { type: 'DISMISS_BOSS' }
  | { type: 'DISMISS_LEVELUP' }
  | { type: 'OPEN_STREAK_REPAIR' }
  | { type: 'USE_REPAIR_TOKEN' }
  | { type: 'CLOSE_STREAK_REPAIR' }
  | { type: 'RESTART' }

export interface SessionConfig {
  startXp: number
  presenceWeeks: number
  taskCount: number
  repairTokens: number
}

/* ─── Selektoren ──────────────────────────────────────────────────────────────── */

export function correctCount(state: SessionState): number {
  return state.results.filter((r) => r === 'correct').length
}

/** Anteil korrekt gelöster Aufgaben (0–1) über alle Aufgaben der Session. */
export function sessionCorrectRate(state: SessionState): number {
  if (state.taskCount === 0) return 0
  return correctCount(state) / state.taskCount
}

/** Boss-Challenge: reguläre Aufgaben > 80 %, genau 1× pro Session. */
export function bossEligible(state: SessionState): boolean {
  return !state.bossChallengeShown && sessionCorrectRate(state) > 0.8
}

/** Level-Up: aktuelles Level über dem Startlevel, genau 1× pro Session. */
export function levelUpEligible(state: SessionState): boolean {
  return !state.levelUpShown && levelFromXp(state.xp) > state.startLevel
}

/** Screens 9/10 sind nur aus Hub oder Abschluss erreichbar (Schutz der 60 Min). */
function canBrowse(screen: SessionScreen): boolean {
  return screen === 'hub' || screen === 'complete'
}

/* ─── Initialer Zustand ───────────────────────────────────────────────────────── */

export function initSessionState(cfg: SessionConfig): SessionState {
  return {
    screen: 'checkin',
    overlay: 'none',
    xp: cfg.startXp,
    startLevel: levelFromXp(cfg.startXp),
    presenceMultiplier: presenceMultiplier(cfg.presenceWeeks),
    taskCount: cfg.taskCount,
    taskIndex: 0,
    results: Array.from({ length: cfg.taskCount }, () => 'pending'),
    hintLevel: Array.from({ length: cfg.taskCount }, () => 0),
    bossChallengeShown: false,
    levelUpShown: false,
    repairTokens: cfg.repairTokens,
    config: cfg,
  }
}

/**
 * Beim Eintritt in den Abschluss das richtige erste Overlay wählen:
 * Boss (falls verdient) vor Level-Up vor stillem Abschluss.
 */
function enterComplete(state: SessionState): SessionState {
  if (bossEligible(state)) {
    return { ...state, screen: 'complete', overlay: 'boss', bossChallengeShown: true }
  }
  if (levelUpEligible(state)) {
    return { ...state, screen: 'complete', overlay: 'levelup', levelUpShown: true }
  }
  return { ...state, screen: 'complete', overlay: 'none' }
}

/* ─── Reducer ─────────────────────────────────────────────────────────────────── */

export function sessionReducer(state: SessionState, action: SessionAction): SessionState {
  switch (action.type) {
    case 'CHECK_IN':
      return state.screen === 'checkin' ? { ...state, screen: 'hub' } : state

    case 'START_SESSION':
      return state.screen === 'hub' ? { ...state, screen: 'goal' } : state

    case 'OPEN_PROGRESS':
      // Invariante: aus dem Task-Flow NICHT erreichbar.
      return canBrowse(state.screen) ? { ...state, screen: 'progress' } : state

    case 'OPEN_TROPHIES':
      return canBrowse(state.screen) ? { ...state, screen: 'trophies' } : state

    case 'BACK_TO_HUB':
      return { ...state, screen: 'hub', overlay: 'none' }

    case 'START_TASKS':
      return state.screen === 'goal'
        ? { ...state, screen: 'task', taskIndex: 0 }
        : state

    case 'ANSWER': {
      if (state.screen !== 'task') return state
      const already = state.results[state.taskIndex] === 'correct'
      const results = [...state.results]
      results[state.taskIndex] = action.correct ? 'correct' : 'wrong'
      const gained =
        action.correct && !already
          ? Math.round(action.baseXp * state.presenceMultiplier)
          : 0
      return { ...state, results, xp: state.xp + gained }
    }

    case 'REVEAL_HINT': {
      if (state.screen !== 'task') return state
      const hintLevel = [...state.hintLevel]
      hintLevel[state.taskIndex] = hintLevel[state.taskIndex] + 1
      return { ...state, hintLevel }
    }

    case 'NEXT_TASK': {
      if (state.screen !== 'task') return state
      if (state.taskIndex < state.taskCount - 1) {
        return { ...state, taskIndex: state.taskIndex + 1 }
      }
      return { ...state, screen: 'mastery' }
    }

    case 'CONTINUE_FROM_MASTERY':
      return state.screen === 'mastery' ? enterComplete(state) : state

    case 'DISMISS_BOSS': {
      if (state.overlay !== 'boss') return state
      if (levelUpEligible(state)) {
        return { ...state, overlay: 'levelup', levelUpShown: true }
      }
      return { ...state, overlay: 'none' }
    }

    case 'DISMISS_LEVELUP':
      return state.overlay === 'levelup' ? { ...state, overlay: 'none' } : state

    case 'OPEN_STREAK_REPAIR':
      // Demo-Trigger: nur am Hub sinnvoll.
      return state.screen === 'hub'
        ? { ...state, overlay: 'streak-repair' }
        : state

    case 'USE_REPAIR_TOKEN':
      return state.overlay === 'streak-repair'
        ? {
            ...state,
            overlay: 'none',
            repairTokens: Math.max(0, state.repairTokens - 1),
          }
        : state

    case 'CLOSE_STREAK_REPAIR':
      return state.overlay === 'streak-repair'
        ? { ...state, overlay: 'none' }
        : state

    case 'RESTART':
      // Vollständiger, wiederholbarer Demo-Reset aus der Originalkonfiguration,
      // landet aber direkt im Hub statt im Check-in.
      return { ...initSessionState(state.config), screen: 'hub' }

    default:
      return state
  }
}
