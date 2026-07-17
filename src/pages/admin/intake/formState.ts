// Der gemeinsame Formularzustand des Erstgespraechs. Die Sektionen lesen/schreiben
// ihn, der Orchestrator leitet daraus die Lead-Payloads ab.
import type {
  Lead,
  LeadGradeTrend,
  LeadInput,
  LeadStrugglingSince,
  SchoolKind,
} from '@/types'

export type IntakeFormState = {
  // Stammdaten
  first_name: string
  full_name: string
  birth_date: string
  class_level: number | null
  school_type: SchoolKind | null
  subjects: string[]
  contact_email: string
  contact_phone: string
  // Erstgespraech
  last_grade: string | null
  grade_trend: LeadGradeTrend | null
  struggling_since: LeadStrugglingSince | null
  tried_before: string[]
  next_exam_date: string
  next_exam_topic: string
  // Eltern-Einschaetzung (Gespraechskontext, nie Auswertungs-Input)
  parent_weak_topics: string[]
  parent_note: string
  // Das EINE Freitextfeld
  notes: string
}

export const EMPTY_INTAKE: IntakeFormState = {
  first_name: '',
  full_name: '',
  birth_date: '',
  class_level: null,
  school_type: null,
  subjects: [],
  contact_email: '',
  contact_phone: '',
  last_grade: null,
  grade_trend: null,
  struggling_since: null,
  tried_before: [],
  next_exam_date: '',
  next_exam_topic: '',
  parent_weak_topics: [],
  parent_note: '',
  notes: '',
}

// Bestehenden Lead in den Formularzustand laden (Weiterpflegen aus der Liste).
export function intakeFromLead(lead: Lead): IntakeFormState {
  return {
    first_name: lead.first_name ?? '',
    full_name: lead.full_name,
    birth_date: lead.birth_date ?? '',
    class_level: lead.class_level,
    school_type: lead.school_type,
    subjects: lead.subjects ?? [],
    contact_email: lead.contact_email ?? '',
    contact_phone: lead.contact_phone ?? '',
    last_grade: lead.last_grade,
    grade_trend: lead.grade_trend,
    struggling_since: lead.struggling_since,
    tried_before: lead.tried_before ?? [],
    next_exam_date: lead.next_exam_date ?? '',
    next_exam_topic: lead.next_exam_topic ?? '',
    parent_weak_topics: [],
    parent_note: '',
    notes: lead.notes ?? '',
  }
}

const nullIfEmpty = (value: string): string | null => (value.trim() === '' ? null : value.trim())

// Stammdaten + Erstgespraech-Felder als Lead-Payload (fuer create und update).
export function intakeToLeadInput(form: IntakeFormState): LeadInput {
  return {
    full_name: form.full_name.trim(),
    first_name: nullIfEmpty(form.first_name),
    birth_date: form.birth_date || null,
    contact_email: nullIfEmpty(form.contact_email),
    contact_phone: nullIfEmpty(form.contact_phone),
    class_level: form.class_level,
    school_type: form.school_type,
    subjects: form.subjects,
    last_grade: form.last_grade,
    grade_trend: form.grade_trend,
    struggling_since: form.struggling_since,
    tried_before: form.tried_before.length > 0 ? form.tried_before : null,
    next_exam_date: form.next_exam_date || null,
    next_exam_topic: nullIfEmpty(form.next_exam_topic),
  }
}
