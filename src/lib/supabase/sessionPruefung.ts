// Session-Rahmen A2b, Coach-Seite: die Pruefrage der Mastery-Pruefung aufs Tablet des Kindes legen und
// zuruecknehmen (Entscheidung 31). Nur der Coach der Session oder ein Admin, in der Zeitbindung wie
// mastery_entscheiden; sonst 42501 von der Datenbank. Erwartung und Kriterium liest der Coach ueber
// skill_pruefung_lesen, das Tablet sieht nur die Frage.

import { sessionRpc } from '@/lib/supabase/sessionRpc'
import type { PruefungTabletAntwort, SupabaseResult } from '@/types'

export const pruefungAufsTablet = (
  sessionId: string,
  studentId: string,
  skillKey: string,
): Promise<SupabaseResult<PruefungTabletAntwort>> =>
  sessionRpc('pruefung_aufs_tablet', { p_session_id: sessionId, p_student_id: studentId, p_skill_key: skillKey },
    'Could not put exam question on tablet')

export const pruefungVomTablet = (sessionId: string, studentId: string): Promise<SupabaseResult<PruefungTabletAntwort>> =>
  sessionRpc('pruefung_vom_tablet', { p_session_id: sessionId, p_student_id: studentId },
    'Could not take exam question back')
