// Platz-Mechanik (S9): Frontend-Wrapper um die Kiosk-RPCs. Die Autorisierung
// (nur Admin) und alle Gates liegen in der DB (20260716110000_s9_platz_mechanik).
// Der Empfang braucht nur: freie Plaetze auflisten, einen Platz einer Session
// zuweisen, und die aktive Zuweisung je Lead fuer die Leads-Liste.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type PlatzDevice = { profile_id: string; label: string }

export type PlatzAssignResult = { assignment_id: string; expires_at: string }

// Aktive Zuweisung eines Leads (fuer die Leads-Liste): Platz-Label + Ablauf.
export type LeadPlatz = { label: string; expires_at: string }

// Freie Plaetze = platz_devices ohne aktive (nicht abgelaufene) Zuweisung.
// Beide Tabellen sind fuer den Admin per RLS voll lesbar.
export async function listFreePlaetze(): Promise<SupabaseResult<PlatzDevice[]>> {
  try {
    const [devicesRes, activeRes] = await Promise.all([
      supabase.from('platz_devices').select('profile_id, label').order('label'),
      supabase
        .from('platz_assignments')
        .select('platz_profile_id')
        .is('released_at', null)
        .gt('expires_at', new Date().toISOString()),
    ])
    if (devicesRes.error) return { data: null, error: devicesRes.error.message }
    if (activeRes.error) return { data: null, error: activeRes.error.message }

    const belegt = new Set(
      (activeRes.data ?? []).map((row) => row.platz_profile_id as string),
    )
    const frei = (devicesRes.data ?? [])
      .map((row) => ({ profile_id: row.profile_id as string, label: row.label as string }))
      .filter((device) => !belegt.has(device.profile_id))
    return { data: frei, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Plaetze konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Weist einen Platz einer LSA-Session zu (nur Admin). Die RPC verweigert bei
// aktiver Zuweisung oder wenn die Session nicht in_progress ist.
export async function assignPlatz(
  platzProfileId: string,
  sessionId: string,
): Promise<SupabaseResult<PlatzAssignResult>> {
  try {
    const { data, error } = await supabase.rpc('platz_assign', {
      p_platz_profile_id: platzProfileId,
      p_session_id: sessionId,
    })
    if (error) return { data: null, error: error.message }
    const result = data as { assignment_id: string; expires_at: string }
    return {
      data: { assignment_id: result.assignment_id, expires_at: result.expires_at },
      error: null,
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Platz-Zuweisung fehlgeschlagen'
    return { data: null, error: message }
  }
}

// Aktive Platz-Zuweisungen, aufgeloest auf ihren Lead: Zuweisung → Session →
// provisorischer Schueler → lead_id. Fuer die Platz-Spalte in der Leads-Liste.
// Defensiv: schlaegt eine Aufloesung fehl, faellt der Lead einfach ohne Platz
// aus der Map — die Liste bricht nie.
export async function listActivePlaetzeByLead(): Promise<
  SupabaseResult<Record<string, LeadPlatz>>
> {
  try {
    const { data: assignments, error: aErr } = await supabase
      .from('platz_assignments')
      .select('platz_profile_id, session_id, expires_at')
      .is('released_at', null)
      .gt('expires_at', new Date().toISOString())
    if (aErr) return { data: null, error: aErr.message }
    if (!assignments || assignments.length === 0) return { data: {}, error: null }

    const platzIds = [...new Set(assignments.map((a) => a.platz_profile_id as string))]
    const sessionIds = [...new Set(assignments.map((a) => a.session_id as string))]

    const [devicesRes, sessionsRes] = await Promise.all([
      supabase.from('platz_devices').select('profile_id, label').in('profile_id', platzIds),
      supabase.from('lsa_sessions').select('id, student_id').in('id', sessionIds),
    ])
    if (devicesRes.error) return { data: null, error: devicesRes.error.message }
    if (sessionsRes.error) return { data: null, error: sessionsRes.error.message }

    const studentIds = [
      ...new Set((sessionsRes.data ?? []).map((s) => s.student_id as string)),
    ]
    const studentsRes = await supabase
      .from('students')
      .select('id, lead_id')
      .in('id', studentIds)
    if (studentsRes.error) return { data: null, error: studentsRes.error.message }

    const labelByPlatz = new Map(
      (devicesRes.data ?? []).map((d) => [d.profile_id as string, d.label as string]),
    )
    const studentBySession = new Map(
      (sessionsRes.data ?? []).map((s) => [s.id as string, s.student_id as string]),
    )
    const leadByStudent = new Map(
      (studentsRes.data ?? []).map((s) => [s.id as string, s.lead_id as string | null]),
    )

    const byLead: Record<string, LeadPlatz> = {}
    for (const a of assignments) {
      const studentId = studentBySession.get(a.session_id as string)
      const leadId = studentId ? leadByStudent.get(studentId) : null
      const label = labelByPlatz.get(a.platz_profile_id as string)
      if (leadId && label) {
        byLead[leadId] = { label, expires_at: a.expires_at as string }
      }
    }
    return { data: byLead, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Platz-Zuweisungen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
