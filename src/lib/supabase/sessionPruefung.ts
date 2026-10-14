// Session-Rahmen A2b, Coach-Seite: die Pruefrage der Mastery-Pruefung aufs Tablet des Kindes legen und
// zuruecknehmen (Entscheidung 31). Nur der Coach der Session oder ein Admin, in der Zeitbindung wie
// mastery_entscheiden; sonst 42501 von der Datenbank. Erwartung und Kriterium liest der Coach ueber
// skill_pruefung_session (T5; ohne Session skill_pruefung_lesen), das Tablet sieht nur die Frage.

import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type { PruefungTabletAntwort, SkillPruefung } from '@/types'

/**
 * T5: Pruefragen eines Skills fuer den Coach dieser Session (oder Admin). Echte Session: nur freigegebene, wie
 * skill_pruefung_lesen. Testlauf: jede, die pruefung_aufs_tablet auflegen darf; die erste steht auf dem Tablet.
 */
export const skillPruefungSession = (sessionId: string, skillKey: string): Promise<RpcResult<SkillPruefung[]>> =>
  sessionRpc('skill_pruefung_session', { p_session_id: sessionId, p_skill_key: skillKey }, 'Could not load mastery check')

export const pruefungAufsTablet = (
  sessionId: string,
  studentId: string,
  skillKey: string,
): Promise<RpcResult<PruefungTabletAntwort>> =>
  sessionRpc('pruefung_aufs_tablet', { p_session_id: sessionId, p_student_id: studentId, p_skill_key: skillKey },
    'Could not put exam question on tablet')

export const pruefungVomTablet = (sessionId: string, studentId: string): Promise<RpcResult<PruefungTabletAntwort>> =>
  sessionRpc('pruefung_vom_tablet', { p_session_id: sessionId, p_student_id: studentId },
    'Could not take exam question back')
