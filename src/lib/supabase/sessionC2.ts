// Session-Rahmen C2, Coach-Seite: Briefing („Vorher“), Satzvorschlaege fuer den Check-out und
// offene Sessions. Nur ueber RPCs; Rechte prueft die Datenbank (42501).

import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type { BriefingKind, NichtGestarteteSession, OffeneSession, SatzVorschlag } from '@/types'

export const sessionBriefing = (sessionId: string): Promise<RpcResult<BriefingKind[]>> =>
  sessionRpc('session_briefing', { p_session_id: sessionId }, 'Could not load briefing')

export const satzVorschlaege = (sessionId: string, studentId: string): Promise<RpcResult<SatzVorschlag[]>> =>
  sessionRpc('satz_vorschlaege', { p_session_id: sessionId, p_student_id: studentId }, 'Could not load sentence proposals')

/** Gestartet und nicht abgeschlossen. Admin: alle; Coach: die eigenen. */
export const sessionsOffen = (): Promise<RpcResult<OffeneSession[]>> =>
  sessionRpc('sessions_offen', {}, 'Could not load open sessions')

/** Nur Admin: vergangen und nie gestartet (Rasit 07.10.: nur Zahl, keine Aktion). */
export const sessionsNichtGestartet = (): Promise<RpcResult<NichtGestarteteSession[]>> =>
  sessionRpc('sessions_nicht_gestartet', {}, 'Could not load sessions that never started')
