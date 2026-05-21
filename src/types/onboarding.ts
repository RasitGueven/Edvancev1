import type { Coach } from './domain'
import type { TierPlan } from './domain'

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

export type TierStepProps = {
  data: OnboardingFormData
  setData: (next: OnboardingFormData) => void
  tiers: TierPlan[]
  loading?: boolean
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
