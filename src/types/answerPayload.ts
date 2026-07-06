// Kanonischer Antwort-Vertrag (Foundation, Migration 042).
//
// EINE Quelle der Wahrheit für „wie sieht die Antwort-Struktur pro input_type
// aus" — geteilt von QS-Tool, DB-Payload (tasks.question_payload /
// screening_items.payload + .canonical), Renderer-Registry und Evaluator.
//
// `AnswerPayload` beschreibt Aufgabe + erwartete Lösung (Konstruktions-/Frage-
// struktur). `StudentAnswer` beschreibt die strukturierte Eingabe der Schüler:in,
// die die Renderer-Registry liefert und der Evaluator (src/lib/answer/evaluators.ts)
// auswertet. Beide sind auf `input_type` diskriminiert.
//
// MVP-Enum (genau diese 8): MC | NUMERIC | SHORT_TEXT | TRUE_FALSE | FREE_TEXT |
// MATCHING | CLOZE | COORDINATE. FREE_TEXT ist coach-bewertet (kein Auto-Check).

export type AnswerOption = { id: string; label: string }

// ── AnswerPayload: Aufgaben-/Lösungsstruktur pro input_type ──────────────────

export type MCAnswerPayload = {
  input_type: 'MC'
  options: AnswerOption[]
  correct: string[] // Option-ids; mehrere = Multiple-Select
}

export type NumericAnswerPayload = {
  input_type: 'NUMERIC'
  accepted: number[]
  tolerance?: number
}

export type ShortTextAnswerPayload = {
  input_type: 'SHORT_TEXT'
  accepted: string[]
  caseInsensitive?: boolean
}

export type TrueFalseAnswerPayload = {
  input_type: 'TRUE_FALSE'
  correct: boolean
}

// Offen, coach-bewertet — KEIN Auto-Check (FernUSG, CLAUDE §6).
export type FreeTextAnswerPayload = {
  input_type: 'FREE_TEXT'
  rubric?: string
}

export type MatchingAnswerPayload = {
  input_type: 'MATCHING'
  left: AnswerOption[]
  right: AnswerOption[]
  pairs: [string, string][] // [leftId, rightId]
}

export type ClozeBlank = { id: string; accepted: string[] }

export type ClozeAnswerPayload = {
  input_type: 'CLOZE'
  text: string // Lücken-Marker {{1}}, {{2}} … referenzieren blanks[].id
  blanks: ClozeBlank[]
}

export type CoordinateGrid = {
  xRange: [number, number]
  yRange: [number, number]
  step: number
}

export type CoordinateExpected = {
  points?: [number, number][]
  line?: { slope: number; intercept: number }
}

export type CoordinateAnswerPayload = {
  input_type: 'COORDINATE'
  grid: CoordinateGrid
  given?: unknown
  task: 'place_point' | 'place_points' | 'draw_segment'
  expected: CoordinateExpected
  tolerance: number
}

export type AnswerPayload =
  | MCAnswerPayload
  | NumericAnswerPayload
  | ShortTextAnswerPayload
  | TrueFalseAnswerPayload
  | FreeTextAnswerPayload
  | MatchingAnswerPayload
  | ClozeAnswerPayload
  | CoordinateAnswerPayload

// Der kanonische Enum — abgeleitet aus dem Vertrag, damit Enum und Payload nie
// auseinanderlaufen. Identisch zu content.InputType / screening.ScreeningInputType.
export type CanonicalInputType = AnswerPayload['input_type']

// ── StudentAnswer: strukturierte Eingabe aus der Renderer-Registry ───────────

export type StudentAnswer =
  | { input_type: 'MC'; selected: string[] }
  | { input_type: 'NUMERIC'; value: string }
  | { input_type: 'SHORT_TEXT'; text: string }
  | { input_type: 'TRUE_FALSE'; value: boolean | null }
  | { input_type: 'FREE_TEXT'; text: string }
  | { input_type: 'MATCHING'; pairs: [string, string][] }
  | { input_type: 'CLOZE'; blanks: Record<string, string> }
  | {
      input_type: 'COORDINATE'
      points?: [number, number][]
      line?: { slope: number; intercept: number }
    }

// ── Laufzeit-Guards (defensiv, JSONB ist `unknown`) ──────────────────────────

function isObj(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null
}

// Prüft, ob ein rohes JSONB-Payload zum erwarteten input_type passt. Nutzt das
// Diskriminator-Feld `input_type` im Payload; fehlt es, wird tolerant der
// erwartete Typ unterstellt (Bestandsdaten ohne Diskriminator).
export function isAnswerPayload(
  raw: unknown,
  expected: CanonicalInputType,
): raw is AnswerPayload {
  if (!isObj(raw)) return false
  if (typeof raw.input_type === 'string' && raw.input_type !== expected) {
    return false
  }
  return true
}
