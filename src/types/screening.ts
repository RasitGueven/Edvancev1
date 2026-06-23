// Adaptive Screening-Item-Bank types.

export type ScreeningStatus = 'in_progress' | 'completed' | 'aborted'

export type ScreeningTest = {
  id: string
  created_at: string
  student_id: string
  subject: string
  status: ScreeningStatus
  coach_id: string | null
  coach_note: string | null
  generated_test: import('./content').DiagnosticTest | null
  generated_test_version: number
  result_summary: Record<string, unknown> | null
  estimated_total_minutes: number | null
  started_at: string | null
  completed_at: string | null
}

export type ScreeningTestInput = {
  student_id: string
  subject: string
  generated_test: import('./content').DiagnosticTest
  estimated_total_minutes?: number | null
  coach_id?: string | null
}

export type ScreeningRating = {
  id: string
  created_at: string
  behavior_snapshot_id: string
  screening_test_id: string
  rating: 1 | 2 | 3 | 4
  coach_id: string | null
}

export type ScreeningLevel = 1 | 2 | 3
export type ScreeningAfb = 'I' | 'II' | 'III'
export type ScreeningPhase = 'sprint' | 'tiefe'
// Kanonischer input_type-Enum (Migration 042) — identisch zu content.InputType,
// eine Quelle: answerPayload.ts. Legacy STEPS_FINAL/OPEN→FREE_TEXT,
// CLOZE_DND→CLOZE, TABLE_LABEL→MATCHING.
export type ScreeningInputType = import('./answerPayload').CanonicalInputType
export type ScreeningCheckType =
  | 'mc_index'
  | 'numeric'
  | 'matching_set'
  | 'normalized'
  | 'manual'
  | 'slot_map'

export type ScreeningItem = {
  id: string
  created_at: string
  cluster_id: string
  class_level: number
  topic: string
  skill_code: string
  skill_label: string
  level: ScreeningLevel
  curriculum_seq: number | null
  input_type: ScreeningInputType
  prompt: string
  payload: unknown
  canonical: unknown
  check_type: ScreeningCheckType
  tolerance: number | null
  typical_errors: string[]
  explanation: string | null
  source: string
  active: boolean
  afb: ScreeningAfb | null
  phase: ScreeningPhase | null
  // VERA-8 (Migration 029) — optional, nicht-VERA-Items lassen die Felder null.
  kontext?: string | null
  teilaufgaben?: ScreeningTeilaufgabe[] | null
  akzeptierte_antworten?: string[] | null
}

// Eine Teilaufgabe eines mehrteiligen Items (z. B. „1a", „1b"). Antwort-Format
// pro Teilaufgabe wird über `input_type` gesteuert — analog zum Top-Level-Item,
// aber ohne eigene check_type-Logik: die Auswertung läuft über das Eltern-Item.
export type ScreeningTeilaufgabe = {
  key: string
  prompt: string
  input_type?: 'NUMERIC' | 'FREE_TEXT' | null
  accepted?: string[] | null
}

export type ScreeningItemInput = Omit<
  ScreeningItem,
  'id' | 'created_at' | 'source' | 'active'
> & { source?: string; active?: boolean }

export type ScreeningItemResult = {
  id: string
  created_at: string
  screening_test_id: string
  screening_item_id: string
  cluster_id: string
  level: ScreeningLevel
  correct: boolean | null
  answer: unknown
  duration_ms: number | null
}

export type ScreeningItemResultInput = Omit<
  ScreeningItemResult,
  'id' | 'created_at'
>

export type ScreeningItemRating = {
  id: string
  created_at: string
  screening_item_result_id: string
  coach_id: string | null
  reached_afb: ScreeningAfb | null
  note: string | null
}

export type ScreeningItemRatingInput = Omit<
  ScreeningItemRating,
  'id' | 'created_at'
>

// Coach-/Admin-Schwerpunkt pro Schüler:in (Tabelle student_focus_areas).
// Fließt gewichtet in die Adaptive-Engine (weightedTopics).
export type StudentFocusArea = {
  id: string
  created_at: string
  student_id: string
  cluster_id: string
  coach_id: string | null
  source: string
  note: string | null
  active: boolean
}
