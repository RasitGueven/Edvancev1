import { supabase } from '@/lib/supabase/client'
import type {
  AttendanceStatus,
  CoachingSession,
  SessionStudent,
  SupabaseResult,
} from '@/types'

// Legt eine Coach-Session an (ersetzt MOCK_SESSIONS).
export async function createSession(
  coachId: string,
  scheduledAt: string,
  room?: string | null,
): Promise<SupabaseResult<CoachingSession>> {
  try {
    const { data, error } = await supabase
      .from('coaching_sessions')
      .insert({ coach_id: coachId, scheduled_at: scheduledAt, room: room ?? null })
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as CoachingSession, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Session konnte nicht angelegt werden'
    return { data: null, error: message }
  }
}

// Sessions eines Coaches, naechste zuerst.
export async function listSessionsForCoach(
  coachId: string,
): Promise<SupabaseResult<CoachingSession[]>> {
  try {
    const { data, error } = await supabase
      .from('coaching_sessions')
      .select('*')
      .eq('coach_id', coachId)
      .order('scheduled_at', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as CoachingSession[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Sessions konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Teilnehmer einer Session.
export async function getSessionStudents(
  sessionId: string,
): Promise<SupabaseResult<SessionStudent[]>> {
  try {
    const { data, error } = await supabase
      .from('session_students')
      .select('*')
      .eq('session_id', sessionId)
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as SessionStudent[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Teilnehmer konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

export async function addStudentToSession(
  sessionId: string,
  studentId: string,
): Promise<SupabaseResult<SessionStudent>> {
  try {
    const { data, error } = await supabase
      .from('session_students')
      .upsert(
        { session_id: sessionId, student_id: studentId },
        { onConflict: 'session_id,student_id' },
      )
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as SessionStudent, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Teilnehmer konnte nicht ergaenzt werden'
    return { data: null, error: message }
  }
}

// Anwesenheit setzen (present/absent/unknown).
export async function setAttendance(
  sessionId: string,
  studentId: string,
  attendance: AttendanceStatus,
): Promise<SupabaseResult<SessionStudent>> {
  try {
    const { data, error } = await supabase
      .from('session_students')
      .update({ attendance })
      .eq('session_id', sessionId)
      .eq('student_id', studentId)
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as SessionStudent, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Anwesenheit konnte nicht gesetzt werden'
    return { data: null, error: message }
  }
}
