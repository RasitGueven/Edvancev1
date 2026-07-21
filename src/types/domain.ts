// Domain types: Coach, Lead, Student, Intake, Tier, Subscription, StudentCoach.

export type Coach = { id: string; full_name: string | null }

export type SchoolKind = 'Gymnasium' | 'Gesamtschule' | 'Realschule' | 'Hauptschule'

export type LeadStatus =
  | 'new'
  | 'contacted'
  | 'onboarding_scheduled'
  | 'converted'
  | 'rejected'
  | 'lsa_freigegeben'
  | 'lsa_fertig'

export type LeadGoal = 'IMPROVE_GRADES' | 'CLOSE_GAPS' | 'EXAM_PREP' | 'GENERAL'

export type LeadGradeTrend = 'besser' | 'stabil' | 'schlechter'

export type LeadStrugglingSince =
  | 'dieses_halbjahr'
  | 'letztes_schuljahr'
  | 'laenger'

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
  // Intake-Felder (S7, Erstgespräch) — bewusst KEINE Diagnose-Felder.
  first_name: string | null
  birth_date: string | null
  last_grade: string | null
  grade_trend: LeadGradeTrend | null
  struggling_since: LeadStrugglingSince | null
  tried_before: string[] | null
  next_exam_date: string | null
  next_exam_topic: string | null
  consent_dsgvo_at: string | null
  consent_dsgvo_by: string | null
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
  first_name?: string | null
  birth_date?: string | null
  last_grade?: string | null
  grade_trend?: LeadGradeTrend | null
  struggling_since?: LeadStrugglingSince | null
  tried_before?: string[] | null
  next_exam_date?: string | null
  next_exam_topic?: string | null
  consent_dsgvo_at?: string | null
  consent_dsgvo_by?: string | null
}

export type Student = {
  id: string
  // NULL bei provisorischen Schülern (A1 Option 1: kein Auth-Konto vor Vertrag).
  profile_id: string | null
  class_level: number | null
  school_name: string | null
  school_type: SchoolKind | null
  // Provisorischer Lead-Schüler — zählt NIRGENDS als Schüler (S7).
  is_provisional: boolean
  lead_id: string | null
}

export type StudentInput = {
  profile_id: string
  class_level?: number | null
  school_name?: string | null
  school_type?: SchoolKind | null
}

export type StudentWithName = Student & { full_name: string | null }

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
