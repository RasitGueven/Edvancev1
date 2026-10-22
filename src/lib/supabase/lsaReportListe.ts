// Liste „LSA-Reports“ (Bauauftrag LR-1) — Lesezugriff, nur Admin.
//
// Quellen (per RLS für admin lesbar, geprüft am 22.10.2026):
//   lsa_sessions — nur status 'completed', Testläufe eingeschlossen
//   students     — ist_test des Kindes (über lsa_sessions.student_id)
//   themen       — label über thema_key
//   lsa_lead_kontext (RPC, über loadNames) — Rufname

import { supabase } from '@/lib/supabase/client'
import { loadNames } from '@/lib/supabase/lsaReport'
import type { SupabaseResult } from '@/types'
import type { LsaReportListItem } from '@/types/report'

type Row = {
  id: string
  student_id: string
  subject: string
  grade: number
  completed_at: string
  testlauf: boolean | null
  modus: string | null
  thema_key: string | null
  // Zwei Fremdschlüssel zeigen auf students; der Hinweis nimmt student_id.
  students: { ist_test: boolean | null } | null
  themen: { label: string | null } | null
}

const COLS =
  'id, student_id, subject, grade, completed_at, testlauf, modus, thema_key, ' +
  'students!lsa_sessions_student_id_fkey(ist_test), themen(label)'

export async function listLsaReports(): Promise<SupabaseResult<LsaReportListItem[]>> {
  try {
    const { data, error } = await supabase
      .from('lsa_sessions')
      .select(COLS)
      .eq('status', 'completed')
      .order('completed_at', { ascending: false })
    if (error) return { data: null, error: error.message }

    const rows = (data ?? []) as unknown as Row[]
    if (rows.length === 0) return { data: [], error: null }

    // Ohne Rufname bleibt das Kind in der Liste (first_name null).
    const names = await loadNames([...new Set(rows.map((r) => r.student_id))])

    const liste = rows.map((r) => ({
      session_id: r.id,
      first_name: names[r.student_id]?.trim() || null,
      grade: r.grade,
      subject: r.subject,
      completed_at: r.completed_at,
      testlauf: r.testlauf === true,
      ist_test: r.students?.ist_test === true,
      modus: r.modus,
      thema_key: r.thema_key,
      thema_label: r.themen?.label?.trim() || null,
    }))
    // Neueste oben — auch, falls der Server die Reihenfolge nicht hält.
    liste.sort((a, b) => b.completed_at.localeCompare(a.completed_at))
    return { data: liste, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'LSA-Reports konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
