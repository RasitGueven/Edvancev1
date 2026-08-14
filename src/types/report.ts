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

// Ein wiederkehrender Denkschritt aus lsa_fehlbild_auswertung (AF2/AF3/AF4/AF5).
//
// `slug` und `familie` sind interne Schlüssel und dürfen NIE gerendert werden —
// beide sind snake_case und keine Sätze für Eltern (INV-4.3). Angezeigt wird
// ausschließlich `familieElterntext`, und nur wenn er da ist.
//
// Kein `klartext` mehr: das war bis AF3 der Elternsatz zum einzelnen Slug, ab
// AF4 der Coach-Satz — den die RPC des Eltern-Pfads nicht mehr herausgibt. Mit
// der Bündelung (AF5) trägt der Elternsatz die Familie, nicht den Slug; das
// Feld wäre dauerhaft null und die einzige Frage daran, wann es doch jemand
// rendert.
export type ReportFehlbild = {
  slug: string
  /**
   * Bündelschlüssel (fehlbild_familien.schluessel), null wenn der Slug keiner
   * Familie zugeordnet ist. Zum Gruppieren, nicht zum Anzeigen.
   */
  familie: string | null
  /**
   * Der eine Satz, den der Report für die ganze Familie vorliest. null, solange
   * fehlbild_familien.freigegeben_am null ist (AF4-Abnahme-Schranke) oder der
   * Slug keine Familie hat.
   */
  familieElterntext: string | null
  anzahl: number
  aufgaben: number
  skillUebergreifend: boolean
  einstufung: 'befund' | 'beobachtung'
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
  /** Nur Einstufung 'befund' — Beobachtungen tragen für ein Elterngespräch zu wenig. */
  fehlbilder: ReportFehlbild[]
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
