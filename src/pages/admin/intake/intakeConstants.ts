// Vorausgewaehlte Klick-Optionen fuer das Erstgespraech am Empfang. Alles zum
// Anklicken — keine Textwuesten. Werte fuer die DB, Labels fuer das UI.
import type { LeadGradeTrend, LeadStrugglingSince, SchoolKind } from '@/types'

export const CLASS_LEVELS: number[] = Array.from({ length: 9 }, (_, i) => i + 5) // 5–13

export const SCHOOL_TYPES: SchoolKind[] = [
  'Gymnasium',
  'Gesamtschule',
  'Realschule',
  'Hauptschule',
]

export const SUBJECTS = ['Mathematik', 'Deutsch', 'Englisch'] as const

// Letzte Zeugnisnote — Klick-Auswahl 1–6. In der DB als Text (last_grade).
export const GRADES = ['1', '2', '3', '4', '5', '6'] as const

export const GRADE_TRENDS: { value: LeadGradeTrend; label: string }[] = [
  { value: 'besser', label: 'Besser geworden' },
  { value: 'stabil', label: 'Stabil' },
  { value: 'schlechter', label: 'Schlechter geworden' },
]

export const STRUGGLING_SINCE: { value: LeadStrugglingSince; label: string }[] = [
  { value: 'dieses_halbjahr', label: 'Dieses Halbjahr' },
  { value: 'letztes_schuljahr', label: 'Letztes Schuljahr' },
  { value: 'laenger', label: 'Schon länger' },
]

// tried_before ist eine offene text[]-Liste (kein DB-CHECK) — Codes speichern.
export const TRIED_BEFORE: { value: string; label: string }[] = [
  { value: 'nachhilfe', label: 'Nachhilfe' },
  { value: 'lernvideos', label: 'Lernvideos' },
  { value: 'lern_app', label: 'Lern-App' },
  { value: 'elternhilfe', label: 'Elternhilfe' },
  { value: 'nichts', label: 'Noch nichts' },
]

// Eltern-Einschaetzung „Wo vermuten Sie die Schwierigkeiten?" — Gespraechskontext
// fuer den Coach, fliesst NIE in die LSA-Auswertung (A3-Invariante).
export const PARENT_WEAK_TOPICS: string[] = [
  'Grundlagen fehlen',
  'Textverständnis',
  'Rechenwege',
  'Konzentration',
  'Prüfungsangst',
  'Zeiteinteilung',
]
