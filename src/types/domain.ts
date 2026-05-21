// Domain types: Coach, Lead, Student, Intake, Tier, Subscription, StudentCoach.

export type Coach = { id: string; full_name: string | null }

export type SchoolKind = 'Gymnasium' | 'Gesamtschule' | 'Realschule' | 'Hauptschule'

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
