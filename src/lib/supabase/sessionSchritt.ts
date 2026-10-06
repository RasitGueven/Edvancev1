// Session-Engine A2: der naechste Schritt eines Kindes. Vom Tablet gebucht (das Kind ergibt
// sich aus der Tablet-Zuweisung); Coach der Session und Admin bekommen eine Vorschau, die
// nichts bucht. Die Antwort enthaelt nie eine Loesung, ausser den Loesungsweg beim Beispiel.

import { sessionRpc } from '@/lib/supabase/sessionRpc'
import type { SessionSchritt, SupabaseResult } from '@/types'

export const naechsterSchritt = (sessionId: string): Promise<SupabaseResult<SessionSchritt>> =>
  sessionRpc('session_naechster_schritt', { p_session_id: sessionId, p_student_id: null },
    'Could not load next step')

export const schrittVorschau = (sessionId: string, studentId: string): Promise<SupabaseResult<SessionSchritt>> =>
  sessionRpc('session_naechster_schritt', { p_session_id: sessionId, p_student_id: studentId },
    'Could not load step preview')
