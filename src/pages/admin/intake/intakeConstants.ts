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

// Anzeige ueber i18n (admin: intake.optionen.*); hier stehen nur die Werte
// fuer die DB und die semantischen Keys.
export const GRADE_TRENDS: LeadGradeTrend[] = ['besser', 'stabil', 'schlechter']

export const STRUGGLING_SINCE: LeadStrugglingSince[] = [
  'dieses_halbjahr',
  'letztes_schuljahr',
  'laenger',
]

// tried_before ist eine offene text[]-Liste (kein DB-CHECK) — Codes speichern.
export const TRIED_BEFORE: string[] = ['nachhilfe', 'lernvideos', 'lern_app', 'elternhilfe', 'nichts']

// Eltern-Einschaetzung „Wo vermuten Sie die Schwierigkeiten?" — Gespraechskontext
// fuer den Coach, fliesst NIE in die LSA-Auswertung (A3-Invariante). Der Wert
// wird so gespeichert (lead_assessments); die Anzeige laeuft ueber den Key.
export const PARENT_WEAK_TOPICS: { value: string; key: string }[] = [
  { value: 'Grundlagen fehlen', key: 'grundlagen' },
  { value: 'Textverständnis', key: 'textverstaendnis' },
  { value: 'Rechenwege', key: 'rechenwege' },
  { value: 'Konzentration', key: 'konzentration' },
  { value: 'Prüfungsangst', key: 'pruefungsangst' },
  { value: 'Zeiteinteilung', key: 'zeiteinteilung' },
]
