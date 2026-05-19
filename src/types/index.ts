// Zentrale TypeScript-Typen für das gesamte Edvance-Projekt.
// Alle Props-Interfaces, Domain-Types und Enums leben hier.

import type { ReactNode } from 'react'

// ── Auth & Rollen ─────────────────────────────────────────────────────────────

export type UserRole = 'student' | 'parent' | 'coach' | 'admin'
export type Role = UserRole | null

// ── Sessions / Students (Domain) ──────────────────────────────────────────────

export type AttendanceStatus = 'present' | 'absent' | 'unknown'
export type SessionStatus = 'upcoming' | 'active' | 'done'

// ── Theme ─────────────────────────────────────────────────────────────────────

export const THEMES = ['edvance', 'ocean', 'forest', 'sunset'] as const
export type Theme = (typeof THEMES)[number]
export type ThemeColors = { primary: string; light: string; dark: string }

// ── Onboarding-Wizard ─────────────────────────────────────────────────────────

export type SchoolType = 'Gymnasium' | 'Gesamtschule' | 'Realschule' | 'Hauptschule' | ''

export type OnboardingFormData = {
  firstName: string
  lastName: string
  email: string
  classLevel: string
  schoolName: string
  schoolType: SchoolType
  subjects: string[]
  tier: string
  coachId: string
}

export type StepProps = {
  data: OnboardingFormData
  setData: (next: OnboardingFormData) => void
}

export type SummaryStepProps = {
  data: OnboardingFormData
  coaches: Coach[]
}

export type CoachStepProps = StepProps & {
  coaches: Coach[]
  loading?: boolean
}

export type StepIndicatorProps = {
  current: number
}

// ── Komponenten-Props ─────────────────────────────────────────────────────────

export type ProtectedRouteProps = {
  allowedRoles: UserRole[]
  children: ReactNode
}

export type AvatarProps = {
  initials: string
  attendance?: AttendanceStatus
  className?: string
}

export type BadgeVariant =
  | 'active' | 'done' | 'upcoming'
  | 'success' | 'warning' | 'error' | 'info' | 'accent' | 'celebration'

export type BadgeProps = {
  variant: BadgeVariant
  className?: string
  children?: import('react').ReactNode
}

// ── Supabase-Wrapper-Result ───────────────────────────────────────────────────

export type SupabaseResult<T> = {
  data: T | null
  error: string | null
}

// ── Erstgespraech / Schueler-Domain ───────────────────────────────────────────

export type SchoolKind = 'Gymnasium' | 'Gesamtschule' | 'Realschule' | 'Hauptschule'

export type Coach = { id: string; full_name: string | null }

export type LeadStatus =
  | 'new'
  | 'contacted'
  | 'onboarding_scheduled'
  | 'converted'
  | 'rejected'

export type LeadGoal = 'IMPROVE_GRADES' | 'CLOSE_GAPS' | 'EXAM_PREP' | 'GENERAL'

export type Lead = {
  id: string
  created_at: string
  full_name: string
  contact_email: string | null
  contact_phone: string | null
  class_level: number | null
  school_type: SchoolKind | null
  school_name: string | null
  subjects: string[]
  goal: LeadGoal | null
  known_weak_topics: string[]
  source: string | null
  status: LeadStatus
  owner_id: string | null
  notes: string | null
  converted_student_id: string | null
  contacted_at: string | null
  onboarding_scheduled_at: string | null
}

export type LeadInput = {
  full_name: string
  contact_email?: string | null
  contact_phone?: string | null
  class_level?: number | null
  school_type?: SchoolKind | null
  school_name?: string | null
  subjects?: string[]
  goal?: LeadGoal | null
  known_weak_topics?: string[]
  source?: string | null
}

export type Student = {
  id: string
  profile_id: string
  class_level: number | null
  school_name: string | null
  school_type: SchoolKind | null
}

export type StudentInput = {
  profile_id: string
  class_level?: number | null
  school_name?: string | null
  school_type?: SchoolKind | null
}

export type StudentWithName = Student & { full_name: string | null }

// Laufzeit-Aufgabe der Screening-/Diagnose-Engine: Generator-Output
// (DiagnosticTask) angereichert mit echtem tasks-Content. Feldnamen
// spiegeln die fruehere Mock-Form, damit die Views minimal bleiben.
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

export type IntakeStatus = 'draft' | 'final'

export type IntakeSession = {
  id: string
  created_at: string
  student_id: string
  lead_id: string | null
  coach_id: string | null
  conducted_at: string | null
  goals: string | null
  motivation: string | null
  learning_history: string | null
  parent_expectations: string | null
  known_weak_topics: string[]
  agreed_next_steps: string | null
  notes: string | null
  status: IntakeStatus
}

export type IntakeInput = {
  student_id: string
  lead_id?: string | null
  coach_id?: string | null
  conducted_at?: string | null
  goals?: string | null
  motivation?: string | null
  learning_history?: string | null
  parent_expectations?: string | null
  known_weak_topics?: string[]
  agreed_next_steps?: string | null
  notes?: string | null
}

export type TierPlan = {
  id: string
  name: string
  price_cents: number
  features: string[]
  sort_order: number
  active: boolean
}

export type TierInput = {
  name: string
  price_cents: number
  features: string[]
  sort_order?: number
  active?: boolean
}

export type TierStepProps = {
  data: OnboardingFormData
  setData: (next: OnboardingFormData) => void
  tiers: TierPlan[]
  loading?: boolean
}

export type SubscriptionStatus = 'active' | 'paused' | 'cancelled'

export type StudentSubscription = {
  id: string
  created_at: string
  student_id: string
  tier_id: string
  status: SubscriptionStatus
  started_at: string | null
  ended_at: string | null
}

export type StudentCoach = {
  student_id: string
  coach_id: string
  assigned_at: string
  active: boolean
}

export type ScreeningStatus = 'in_progress' | 'completed' | 'aborted'

export type ScreeningTest = {
  id: string
  created_at: string
  student_id: string
  subject: string
  status: ScreeningStatus
  coach_id: string | null
  coach_note: string | null
  generated_test: DiagnosticTest | null
  generated_test_version: number
  result_summary: Record<string, unknown> | null
  estimated_total_minutes: number | null
  started_at: string | null
  completed_at: string | null
}

export type ScreeningTestInput = {
  student_id: string
  subject: string
  generated_test: DiagnosticTest
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

// ── Adaptive Screening-Item-Bank (Migration 022) ──────────────────────────────

export type ScreeningLevel = 1 | 2 | 3
export type ScreeningInputType = 'MC' | 'NUMERIC' | 'MATCHING' | 'STEPS_FINAL'
export type ScreeningCheckType =
  | 'mc_index'
  | 'numeric'
  | 'matching_set'
  | 'normalized'

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
  correct: boolean
  answer: unknown
  duration_ms: number | null
}

export type ScreeningItemResultInput = Omit<
  ScreeningItemResult,
  'id' | 'created_at'
>

export type CoachingSession = {
  id: string
  created_at: string
  coach_id: string
  room: string | null
  scheduled_at: string
  status: SessionStatus
}

export type SessionStudent = {
  session_id: string
  student_id: string
  attendance: AttendanceStatus
}

export type Intervention = {
  id: string
  created_at: string
  session_id: string
  student_id: string
  coach_id: string
  started_at: string
  resolved_at: string | null
  note: string | null
}

export type StudentTaskProgress = {
  student_id: string
  task_id: string
  completed_at: string
}

export type StudentProgress = {
  student_id: string
  xp_total: number
  streak_days: number
  level: number
  last_activity: string | null
}

export type XpEvent = {
  id: string
  created_at: string
  student_id: string
  task_id: string | null
  xp: number
  reason: string | null
}

export type ParentReportStatus = 'draft' | 'published'

export type ParentReport = {
  id: string
  created_at: string
  student_id: string
  period_start: string
  period_end: string
  summary: Record<string, unknown> | null
  coach_note: string | null
  status: ParentReportStatus
  published_at: string | null
}

export type ParentReportInput = {
  student_id: string
  period_start: string
  period_end: string
  summary?: Record<string, unknown> | null
  coach_note?: string | null
}

// Struktur des KI-Entwurfs (= parent_reports.summary). coach_notiz wird
// beim Speichern in parent_reports.coach_note abgelegt.
export type ParentReportDraft = {
  lernfortschritt: string
  anwesenheit: string
  eingriffe: string
  empfehlung: string
  coach_notiz: string
}

// ── Content / Aufgaben-Schema ─────────────────────────────────────────────────

export type ContentType = 'exercise' | 'exercise_group' | 'article' | 'video' | 'course'

export type CognitiveType = 'FACT' | 'TRANSFER' | 'ANALYSIS'

export type InputType = 'MC' | 'FREE_INPUT' | 'STEPS' | 'MATCHING' | 'DRAW'

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

export type OnboardingData = {
  student_id: string
  grade: number
  school_type: 'GESAMTSCHULE' | 'GYMNASIUM' | 'REALSCHULE' | 'HAUPTSCHULE'
  subject: 'MATH' | 'GERMAN' | 'ENGLISH'
  goal: 'IMPROVE_GRADES' | 'CLOSE_GAPS' | 'EXAM_PREP' | 'GENERAL'
  known_weak_topics?: string[]
  last_grade_in_subject?: number
}

export type TaskCoachMetadata = {
  id: string
  task_id: string
  typical_errors: string | null
  observation_hints: string | null
  intervention_triggers: string | null
}
