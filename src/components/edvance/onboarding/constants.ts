import type { OnboardingFormData, SchoolType } from '@/types'

export const SUBJECTS = ['Mathematik', 'Deutsch', 'Englisch'] as const

export const SCHOOL_TYPES: SchoolType[] = ['Gymnasium', 'Gesamtschule', 'Realschule', 'Hauptschule']

const FIRST_CLASS_LEVEL = 5
const LAST_CLASS_LEVEL = 13
export const CLASS_LEVELS = Array.from(
  { length: LAST_CLASS_LEVEL - FIRST_CLASS_LEVEL + 1 },
  (_, index) => String(index + FIRST_CLASS_LEVEL),
)

export const MAX_SUBJECTS_PER_STUDENT = 2

export const STEP_LABELS = ['Stammdaten', 'Fächer', 'Tarif', 'Coach', 'Abschluss'] as const

export const EMPTY_FORM: OnboardingFormData = {
  firstName: '',
  lastName: '',
  email: '',
  classLevel: '',
  schoolName: '',
  schoolType: '',
  subjects: [],
  tier: '',
  coachId: '',
}
