// Session, attendance, XP, interventions, and parent reports.

export type AttendanceStatus = 'present' | 'absent' | 'unknown'
export type SessionStatus = 'upcoming' | 'active' | 'done'

export type CoachingSession = {
  id: string
  created_at: string
  coach_id: string
  room: string | null
  scheduled_at: string
  status: SessionStatus
}

export type SessionStudent = {
  session_id: string
  student_id: string
  attendance: AttendanceStatus
}

export type Intervention = {
  id: string
  created_at: string
  session_id: string
  student_id: string
  coach_id: string
  started_at: string
  resolved_at: string | null
  note: string | null
}

export type StudentTaskProgress = {
  student_id: string
  task_id: string
  completed_at: string
}

export type StudentProgress = {
  student_id: string
  xp_total: number
  streak_days: number
  level: number
  last_activity: string | null
}

export type XpRule = {
  content_type: string
  base_xp: number
  difficulty_multiplier: number
  updated_at: string
}

export type XpEvent = {
  id: string
  created_at: string
  student_id: string
  task_id: string | null
  xp: number
  reason: string | null
}

export type ParentReportStatus = 'draft' | 'published'

export type ParentReport = {
  id: string
  created_at: string
  student_id: string
  period_start: string
  period_end: string
  summary: Record<string, unknown> | null
  coach_note: string | null
  status: ParentReportStatus
  published_at: string | null
}

export type ParentReportInput = {
  student_id: string
  period_start: string
  period_end: string
  summary?: Record<string, unknown> | null
  coach_note?: string | null
}

// Struktur des KI-Entwurfs (= parent_reports.summary). coach_notiz wird
// beim Speichern in parent_reports.coach_note abgelegt.
export type ParentReportDraft = {
  lernfortschritt: string
  anwesenheit: string
  eingriffe: string
  empfehlung: string
  coach_notiz: string
}
