// UI-freier Auswertungs-Layer für den kanonischen Antwort-Vertrag (Foundation,
// Migration 042). Reine, deterministische Funktionen — keine Seiteneffekte,
// defensiv (unbekannte/fehlende Eingabe → false, außer FREE_TEXT → null).
//
// Vertrag:
//   evaluate(inputType, payload, studentAnswer) => { correct: boolean | null }
//   null = coach-bewertet (FREE_TEXT) bzw. nicht auto-entscheidbar.
//
// Das Kind sieht das Ergebnis NIE direkt im Screening (CLAUDE §6); FREE_TEXT
// ist im Lernpfad coach-bewertet (FernUSG). Dieser Layer liefert nur die
// Wahrheit für Report/Coach-Sicht und das neutrale Auto-Feedback im Lernpfad.

import type {
  AnswerPayload,
  CanonicalInputType,
  CoordinateAnswerPayload,
} from '@/types/answerPayload'

export type EvalResult = { correct: boolean | null }

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}

function toNumber(v: unknown): number | null {
  if (typeof v === 'number') return Number.isFinite(v) ? v : null
  if (typeof v === 'string') {
    const n = Number(v.trim().replace(/\s/g, '').replace(',', '.'))
    return Number.isFinite(n) ? n : null
  }
  return null
}

function normText(v: unknown, caseInsensitive = true): string | null {
  if (typeof v !== 'string') return null
  let s = v.trim().replace(/\s+/g, ' ').replace(',', '.')
  if (caseInsensitive) s = s.toLowerCase()
  return s
}

function asStringArray(v: unknown): string[] | null {
  if (!Array.isArray(v)) return null
  if (!v.every((x) => typeof x === 'string')) return null
  return v as string[]
}

function pairSet(raw: unknown): Set<string> | null {
  if (!Array.isArray(raw)) return null
  const set = new Set<string>()
  for (const p of raw) {
    if (!Array.isArray(p) || p.length !== 2) return null
    if (typeof p[0] !== 'string' || typeof p[1] !== 'string') return null
    set.add(`${p[0]}|||${p[1]}`)
  }
  return set
}

function asPoint(v: unknown): [number, number] | null {
  if (!Array.isArray(v) || v.length !== 2) return null
  const x = toNumber(v[0])
  const y = toNumber(v[1])
  return x === null || y === null ? null : [x, y]
}

function asPoints(v: unknown): [number, number][] | null {
  if (!Array.isArray(v)) return null
  const out: [number, number][] = []
  for (const p of v) {
    const pt = asPoint(p)
    if (!pt) return null
    out.push(pt)
  }
  return out
}

// Mengen-Gleichheit zweier Punktlisten innerhalb Toleranz (Reihenfolge egal,
// 1:1-Zuordnung via Greedy-Matching).
function pointsMatch(
  expected: [number, number][],
  given: [number, number][],
  tol: number,
): boolean {
  if (expected.length !== given.length) return false
  const used = new Array(given.length).fill(false)
  for (const e of expected) {
    let found = false
    for (let i = 0; i < given.length; i++) {
      if (used[i]) continue
      if (Math.abs(given[i][0] - e[0]) <= tol && Math.abs(given[i][1] - e[1]) <= tol) {
        used[i] = true
        found = true
        break
      }
    }
    if (!found) return false
  }
  return true
}

function lineFromPoints(
  pts: [number, number][],
): { slope: number; intercept: number } | null {
  if (pts.length < 2) return null
  const [a, b] = pts
  const dx = b[0] - a[0]
  if (Math.abs(dx) < 1e-9) return null // senkrecht: slope/intercept nicht definiert
  const slope = (b[1] - a[1]) / dx
  const intercept = a[1] - slope * a[0]
  return { slope, intercept }
}

function evaluateCoordinate(
  payload: CoordinateAnswerPayload,
  answer: unknown,
): EvalResult {
  if (!isObj(answer)) return { correct: false }
  const tol = Number.isFinite(payload.tolerance) ? payload.tolerance : 0
  const expected = payload.expected

  if (payload.task === 'draw_segment' || expected.line) {
    if (!expected.line) return { correct: false }
    let line = isObj(answer.line)
      ? {
          slope: toNumber(answer.line.slope),
          intercept: toNumber(answer.line.intercept),
        }
      : null
    if (!line || line.slope === null || line.intercept === null) {
      const pts = asPoints(answer.points)
      const derived = pts ? lineFromPoints(pts) : null
      line = derived ? { slope: derived.slope, intercept: derived.intercept } : null
    }
    if (!line || line.slope === null || line.intercept === null) {
      return { correct: false }
    }
    return {
      correct:
        Math.abs(line.slope - expected.line.slope) <= tol &&
        Math.abs(line.intercept - expected.line.intercept) <= tol,
    }
  }

  // place_point / place_points
  const pts = asPoints(answer.points)
  if (!pts || !expected.points) return { correct: false }
  return { correct: pointsMatch(expected.points, pts, tol) }
}

// Zentrale Auswertung. `payload` ist das kanonische AnswerPayload (oder rohes
// JSONB, defensiv geparst). `studentAnswer` ist die strukturierte Eingabe der
// Renderer-Registry. Diskriminator-Mismatch oder Schrott → false (außer
// FREE_TEXT → null).
export function evaluate(
  inputType: CanonicalInputType,
  payload: AnswerPayload | unknown,
  studentAnswer: unknown,
): EvalResult {
  // FREE_TEXT ist immer coach-bewertet — kein Auto-Check, egal welche Eingabe.
  if (inputType === 'FREE_TEXT') return { correct: null }

  if (!isObj(payload)) return { correct: false }
  const ans = isObj(studentAnswer) ? studentAnswer : {}

  switch (inputType) {
    case 'MC': {
      const correct = asStringArray(payload.correct)
      const selected = asStringArray(ans.selected)
      if (!correct || !selected) return { correct: false }
      if (correct.length !== selected.length) return { correct: false }
      const want = new Set(correct)
      return { correct: selected.every((id) => want.has(id)) }
    }
    case 'NUMERIC': {
      const accepted = Array.isArray(payload.accepted)
        ? payload.accepted.map(toNumber)
        : null
      const value = toNumber(ans.value)
      if (!accepted || value === null) return { correct: false }
      const tol = toNumber(payload.tolerance) ?? 0
      return {
        correct: accepted.some(
          (a) => a !== null && Math.abs(value - a) <= Math.abs(tol),
        ),
      }
    }
    case 'SHORT_TEXT': {
      const ci = payload.caseInsensitive !== false
      const accepted = asStringArray(payload.accepted)
      const text = normText(ans.text, ci)
      if (!accepted || text === null || text === '') return { correct: false }
      return {
        correct: accepted.some((a) => normText(a, ci) === text),
      }
    }
    case 'TRUE_FALSE': {
      if (typeof payload.correct !== 'boolean') return { correct: false }
      if (typeof ans.value !== 'boolean') return { correct: false }
      return { correct: ans.value === payload.correct }
    }
    case 'MATCHING': {
      const c = pairSet(payload.pairs)
      const a = pairSet(ans.pairs)
      if (!c || !a || c.size !== a.size) return { correct: false }
      for (const k of c) if (!a.has(k)) return { correct: false }
      return { correct: true }
    }
    case 'CLOZE': {
      const blanks = Array.isArray(payload.blanks) ? payload.blanks : null
      const given = isObj(ans.blanks) ? ans.blanks : null
      if (!blanks || blanks.length === 0 || !given) return { correct: false }
      for (const b of blanks) {
        if (!isObj(b) || typeof b.id !== 'string') return { correct: false }
        const accepted = asStringArray(b.accepted)
        const a = normText(given[b.id])
        if (!accepted || a === null || a === '') return { correct: false }
        if (!accepted.some((cand) => normText(cand) === a)) {
          return { correct: false }
        }
      }
      return { correct: true }
    }
    case 'COORDINATE': {
      return evaluateCoordinate(payload as CoordinateAnswerPayload, ans)
    }
    default:
      return { correct: false }
  }
}
