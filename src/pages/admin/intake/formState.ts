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
  // Optional. Schulen setzen Themen in unterschiedlichen Jahrgangsstufen an —
  // der Schulname hilft spaeter bei der Einordnung. Kein Einfluss auf die
  // Aufgabenwahl.
  school_name: string
  // Schule aus der Liste; null bei Freitext oder ohne Angabe.
  schule_id: string | null
  subjects: string[]
  contact_email: string
  contact_phone: string
  // Erstgespraech
  last_grade: string | null
  grade_trend: LeadGradeTrend | null
  struggling_since: LeadStrugglingSince | null
  tried_before: string[]
  // Altes Themencluster (skill_clusters), nur noch zur Anzeige bei
  // Bestandsleads. Das aktuelle Thema steht in lead_themen und wird direkt
  // dort gespeichert, nicht ueber den Lead-Payload.
  current_topic_cluster_id: string | null
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
  school_name: '',
  schule_id: null,
  subjects: [],
  contact_email: '',
  contact_phone: '',
  last_grade: null,
  grade_trend: null,
  struggling_since: null,
  tried_before: [],
  current_topic_cluster_id: null,
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
    school_name: lead.school_name ?? '',
    schule_id: lead.schule_id ?? null,
    subjects: lead.subjects ?? [],
    contact_email: lead.contact_email ?? '',
    contact_phone: lead.contact_phone ?? '',
    last_grade: lead.last_grade,
    grade_trend: lead.grade_trend,
    struggling_since: lead.struggling_since,
    tried_before: lead.tried_before ?? [],
    current_topic_cluster_id: lead.current_topic_cluster_id,
    parent_weak_topics: [],
    parent_note: '',
    notes: lead.notes ?? '',
  }
}

export type FreigabeZustand = 'gesperrt' | 'bereit' | 'bestaetigen'

/**
 * Ob die LSA freigegeben werden kann. Ohne Klasse, Fach oder Einwilligung:
 * gesperrt. Mit aktuellem Thema, altem Cluster (Bestandslead) oder fuer ein
 * Fach ohne Katalog: bereit. Sonst geht es nur mit bewusster Bestaetigung —
 * die LSA prueft dann ohne Schwerpunkt in der Breite. Gespeichert wird nichts.
 */
export function freigabeZustand(args: {
  klasse: number | null
  fach: string | null
  einwilligung: boolean
  aktuellesThema: string | null
  altesCluster: string | null
  katalogLeer: boolean
}): FreigabeZustand {
  if (args.klasse === null || args.fach === null || !args.einwilligung) return 'gesperrt'
  if (args.aktuellesThema !== null || args.altesCluster !== null || args.katalogLeer) {
    return 'bereit'
  }
  return 'bestaetigen'
}

const nullIfEmpty =(value: string): string | null => (value.trim() === '' ? null : value.trim())

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
    school_name: nullIfEmpty(form.school_name),
    schule_id: form.schule_id,
    subjects: form.subjects,
    last_grade: form.last_grade,
    grade_trend: form.grade_trend,
    struggling_since: form.struggling_since,
    tried_before: form.tried_before.length > 0 ? form.tried_before : null,
    // next_exam_date, next_exam_topic und current_topic_cluster_id werden
    // nicht mehr beschrieben; die Spalten bleiben im Schema bestehen.
    notes: nullIfEmpty(form.notes),
  }
}
