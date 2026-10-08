// Session, attendance, XP, interventions, and parent reports.

// Spiegelt session_students_attendance_check. In der Session setzt der Coach
// nur 'present' oder 'unexcused'; 'cancelled' und 'cancelled_by_us' setzt das
// Slots-Feature. Was eine Einheit verbraucht, entscheidet die DB-Funktion
// einheit_verbraucht() — nicht das Frontend.
export type AttendanceStatus =
  | 'planned'
  | 'present'
  | 'cancelled'
  | 'unexcused'
  | 'cancelled_by_us'
export type SessionAttendance = Extract<AttendanceStatus, 'present' | 'unexcused'>
export type SessionStatus = 'upcoming' | 'active' | 'done'

export type CoachingSession = {
  id: string
  created_at: string
  coach_id: string
  room: string | null
  scheduled_at: string
  status: SessionStatus
  /** X0: Testlauf (nur Testkonten, nie in Akten). */
  testlauf?: boolean
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
  level: number
  last_activity: string | null
  // v2 — Zwei-Streak-Modell (Migration 032). streak_days bleibt optional bis Migration 036 in prod.
  streak_days?: number
  presence_streak_weeks: number
  presence_streak_last_week_start: string | null
  presence_streak_multiplier: number
  home_streak_sessions: number
  home_streak_last_completed_at: string | null
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
