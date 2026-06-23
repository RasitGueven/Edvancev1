// Content, tasks, microskills, clusters.

import type { CanonicalInputType } from './answerPayload'

export type ContentType = 'exercise' | 'exercise_group' | 'article' | 'video' | 'course'
export type CognitiveType = 'FACT' | 'TRANSFER' | 'ANALYSIS'
// Kanonischer input_type-Enum (Migration 042) — eine Quelle: answerPayload.ts.
export type InputType = CanonicalInputType

export type Subject = {
  id: string
  name: string
}

export type SkillCluster = {
  id: string
  subject_id: string
  name: string
  class_level_min: number
  class_level_max: number
  sort_order: number
}

export type Microskill = {
  id: string
  cluster_id: string
  code: string
  name: string
  description: string | null
  class_level: number
  prerequisite_ids: string[]
  sort_order: number
  cognitive_type: CognitiveType | null
  estimated_minutes: number | null
  curriculum_ref: string | null
}

export type TaskAsset = {
  url: string
  alt: string
  caption?: string
}

export type Task = {
  id: string
  microskill_id: string | null
  cluster_id: string | null
  source: string
  source_ref: string | null
  content_type: ContentType
  title: string | null
  question: string | null
  solution: string | null
  hint: string | null
  common_errors: string | null
  coach_note: string | null
  difficulty: number | null
  estimated_minutes: number
  class_level: number | null
  is_active: boolean
  created_at: string
  cognitive_type: CognitiveType | null
  input_type: InputType | null
  is_diagnostic: boolean
  curriculum_ref: string | null
  question_payload: unknown | null
  typical_errors: string[] | null
  assets: TaskAsset[]
}

// Eingabe fuer manuell angelegte Diagnose-Aufgaben (Admin-Seeding).
export type DiagnosticTaskInput = {
  question: string
  solution?: string | null
  common_errors?: string | null
  coach_note?: string | null
  microskill_id?: string | null
  cluster_id?: string | null
  class_level?: number | null
  difficulty?: number | null
  input_type?: InputType | null
  cognitive_type?: CognitiveType | null
  estimated_minutes?: number | null
}

// Laufzeit-Aufgabe der Screening-/Diagnose-Engine: Generator-Output
// (DiagnosticTask) angereichert mit echtem tasks-Content.
export type RunTask = {
  id: string
  skill_id: string
  skill_cluster: string
  question: string
  solution: string
  common_errors: string
  coach_hint: string
  estimated_minutes: number
}

// Diagnostic-Generator Output-Typen (siehe src/lib/diagnostic/generator.ts).
export type DiagnosticTask = {
  sequence: number
  task_id: string
  topic_id: string
  topic_label: string
  input_type: InputType
  competency_level: 1 | 2 | 3
  estimated_minutes: number
  coach_hint: string
  typical_errors: string[]
}

export type DiagnosticTest = {
  student_id: string
  subject: string
  grade: number
  generated_at: string
  estimated_total_minutes: number
  coverage: { topic_id: string; topic_label: string; task_id: string }[]
  tasks: DiagnosticTask[]
}

export type TaskCoachMetadata = {
  id: string
  task_id: string
  typical_errors: string | null
  observation_hints: string | null
  intervention_triggers: string | null
}
