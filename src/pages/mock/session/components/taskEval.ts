/**
 * Reine Auswertungs-Logik für die Aufgaben-Stubs (kein React).
 * Bewusst schlank — der Mock beweist den Render-/Input-Pfad, nicht den
 * vollen SerloRenderer.
 */
import type { SessionTask, SessionTaskCoordinate } from '@/lib/mocks/session'

type Point = { x: number; y: number }

export type TaskAnswer =
  | { kind: 'mc'; index: number | null }
  | { kind: 'numeric'; raw: string }
  | { kind: 'coordinate'; points: { x: number; y: number }[] }

export function initialAnswer(task: SessionTask): TaskAnswer {
  switch (task.kind) {
    case 'mc':
      return { kind: 'mc', index: null }
    case 'numeric':
      return { kind: 'numeric', raw: '' }
    case 'coordinate':
      return { kind: 'coordinate', points: task.initialPoints.map((p) => ({ ...p })) }
  }
}

/** Darf „Prüfen" gedrückt werden? */
export function answerReady(answer: TaskAnswer): boolean {
  switch (answer.kind) {
    case 'mc':
      return answer.index !== null
    case 'numeric':
      return answer.raw.trim() !== ''
    case 'coordinate':
      return answer.points.length > 0
  }
}

function parseNumeric(raw: string): number {
  return Number(raw.trim().replace(',', '.'))
}

export function evaluateTask(task: SessionTask, answer: TaskAnswer): boolean {
  if (task.kind === 'mc' && answer.kind === 'mc') {
    return answer.index === task.correctIndex
  }
  if (task.kind === 'numeric' && answer.kind === 'numeric') {
    const value = parseNumeric(answer.raw)
    if (!Number.isFinite(value)) return false
    return Math.abs(value - task.answer) <= task.tolerance
  }
  if (task.kind === 'coordinate' && answer.kind === 'coordinate') {
    return pointsLieOnShape(task, answer.points)
  }
  return false
}

function samePoint(a: Point, b: Point): boolean {
  return Math.abs(a.x - b.x) < 1e-6 && Math.abs(a.y - b.y) < 1e-6
}

/**
 * Prüft, ob die gesetzten Punkte die richtige Gerade/Parabel beschreiben —
 * nicht, ob sie exakt auf zwei vorgegebenen Stützpunkten liegen. „Zeichne
 * y = x + 1" ist mit JEDEM Paar verschiedener Punkte auf dieser Geraden korrekt.
 * Die `targetPoints` definieren die Soll-Kurve, nicht erzwungene Positionen.
 */
function pointsLieOnShape(task: SessionTaskCoordinate, points: Point[]): boolean {
  if (points.length < 2) return false
  // Zwei zusammenfallende Punkte definieren keine Gerade/Kurve.
  if (samePoint(points[0], points[1])) return false

  const [a, b] = task.targetPoints

  if (task.shape === 'line') {
    const dx = b.x - a.x
    if (Math.abs(dx) < 1e-9) {
      // Senkrechte Gerade x = a.x.
      return points.every((p) => Math.abs(p.x - a.x) <= task.tolerance)
    }
    const m = (b.y - a.y) / dx
    const c = a.y - m * a.x
    return points.every((p) => Math.abs(p.y - (m * p.x + c)) <= task.tolerance)
  }

  // Parabel in Scheitelform: a = Scheitel (h|k), b = weiterer Punkt der Kurve.
  const ddx = b.x - a.x
  if (Math.abs(ddx) < 1e-9) return false
  const coeff = (b.y - a.y) / (ddx * ddx)
  return points.every(
    (p) => Math.abs(p.y - (coeff * (p.x - a.x) * (p.x - a.x) + a.y)) <= task.tolerance,
  )
}
