// Eltern-Report (R1). Reine Lese-Sicht auf eine abgeschlossene LSA-Session.
//
// BEWERTUNG: `correct` stammt aus lsa_responses.correct — das schreibt
// lsa_submit serverseitig über lsa_is_correct(). Die Lösungen selbst
// (task_solutions) werden NIE clientseitig gelesen; `correct` ist ein Urteil
// über die Antwort des Kindes, keine Lösung, und liegt für coach/admin ohnehin
// schon per RLS offen. Kein neuer Grant, keine zweite Bewertungswahrheit.

export type LsaSessionState = 'in_progress' | 'completed' | 'aborted'

// Ein Eintrag der Fertig-Liste (heutige Analysen).
export type LsaSessionListItem = {
  session_id: string
  first_name: string | null
  grade: number
  subject: string
  status: LsaSessionState
  started_at: string | null
  completed_at: string | null
  answered: number
  planned: number
}

// Ein Stoffanker der Session. `planned` zählt die zugelosten Items des Themas,
// `answered` die tatsächlich bearbeiteten — die Differenz ist „ausgelassen".
export type ReportTopic = {
  topic: string
  planned: number
  answered: number
  skipped: number
  correct: number
  avgDurationMs: number | null
}

// Die beim Lead erfasste Eltern-Einschätzung (lead_assessments, source='parent').
export type ParentAssessment = {
  note: string | null
  weakTopics: string[]
}

export type ReportData = {
  sessionId: string
  firstName: string | null
  grade: number
  subject: string
  status: LsaSessionState
  analysedAt: string | null
  topics: ReportTopic[]
  parentAssessment: ParentAssessment | null
}

// Die Pakete der Empfehlung. Bewusst eine Konstantenliste: die
// Empfehlungsregeln kommen später, in v1 wählt der Coach von Hand.
export const REPORT_PAKETE = ['basis', 'standard', 'premium'] as const
export type ReportPaket = (typeof REPORT_PAKETE)[number]

// Die zwei Coach-Freitexte + Paketwahl (Ausblick).
export type ReportNotes = {
  zielbild: string
  empfehlung: string
  paket: ReportPaket | null
}
