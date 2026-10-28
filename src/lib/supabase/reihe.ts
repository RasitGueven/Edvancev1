// Reihe 1 C1: Reihenplan für die Coach-Sicht. Coach mit laufendem Vertrag oder Admin (sonst 42501).

import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type { ReiheCoach } from '@/types/reihe'

export const reiheCoachLesen = (studentId: string): Promise<RpcResult<ReiheCoach | null>> =>
  sessionRpc('reihe_coach_lesen', { p_student_id: studentId }, 'Could not load series plan')

/** Klassenarbeitsdatum im Check-in erfassen bzw. bestätigen; legt die Reihe an oder plant neu. */
export const reiheKaSetzen = (sessionId: string, studentId: string, datum: string | null): Promise<RpcResult<ReiheCoach>> =>
  sessionRpc('reihe_ka_setzen', { p_session_id: sessionId, p_student_id: studentId, p_ka_datum: datum },
    'Could not set exam date')

export const reiheVerschieben = (reiheId: string, skillKey: string, zielDatum: string): Promise<RpcResult<ReiheCoach>> =>
  sessionRpc('reihe_coach_aendern', { p_reihe_id: reiheId, p_aktion: 'verschieben', p_skill_key: skillKey, p_ziel_datum: zielDatum },
    'Could not move skill')

export const reiheBestaetigen = (reiheId: string): Promise<RpcResult<ReiheCoach>> =>
  sessionRpc('reihe_coach_aendern', { p_reihe_id: reiheId, p_aktion: 'bestaetigen' }, 'Could not confirm plan')
