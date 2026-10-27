// Reihe 1 C1: Reihenplan für die Coach-Sicht. Coach mit laufendem Vertrag oder Admin (sonst 42501).

import { sessionRpc, type RpcResult } from '@/lib/supabase/sessionRpc'
import type { ReiheCoach } from '@/types/reihe'

/** Nur eine Antwort mit wirksamem Plan gilt als Reihe; alles andere ist „keine Reihe“. */
const istReihe = (d: unknown): d is ReiheCoach => {
  const plan = (d as { plan?: { sessions?: unknown } } | null)?.plan
  return Array.isArray(plan?.sessions)
}

export const reiheCoachLesen = async (studentId: string): Promise<RpcResult<ReiheCoach | null>> => {
  const r = await sessionRpc<unknown>('reihe_coach_lesen', { p_student_id: studentId }, 'Could not load series plan')
  return r.error ? { ...r, data: null } : { data: istReihe(r.data) ? r.data : null, error: null }
}

/** Klassenarbeitsdatum im Check-in erfassen bzw. bestätigen; legt die Reihe an oder plant neu. */
export const reiheKaSetzen = (sessionId: string, studentId: string, datum: string | null): Promise<RpcResult<ReiheCoach>> =>
  sessionRpc('reihe_ka_setzen', { p_session_id: sessionId, p_student_id: studentId, p_ka_datum: datum },
    'Could not set exam date')

export const reiheVerschieben = (reiheId: string, skillKey: string, zielDatum: string): Promise<RpcResult<ReiheCoach>> =>
  sessionRpc('reihe_coach_aendern', { p_reihe_id: reiheId, p_aktion: 'verschieben', p_skill_key: skillKey, p_ziel_datum: zielDatum },
    'Could not move skill')

export const reiheBestaetigen = (reiheId: string): Promise<RpcResult<ReiheCoach>> =>
  sessionRpc('reihe_coach_aendern', { p_reihe_id: reiheId, p_aktion: 'bestaetigen' }, 'Could not confirm plan')

export type GpSkill = { skill_key: string; label: string; sicher: boolean | null; offen: boolean }

/** C4: Generalprobe-Ergebnis je Skill (Coach der Session oder Admin). */
export const gpErgebnisLesen = async (sessionId: string, studentId: string): Promise<RpcResult<GpSkill[]>> => {
  const r = await sessionRpc<unknown>('session_gp_ergebnis', { p_session_id: sessionId, p_student_id: studentId },
    'Could not load dress rehearsal')
  return r.error ? { ...r, data: null } : { data: Array.isArray(r.data) ? (r.data as GpSkill[]) : [], error: null }
}
