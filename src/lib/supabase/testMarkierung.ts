// Testmarkierung (Bauauftrag CI-1 Teil D, Freigabe Rasit 11.11.2026, Punkt 7.5): welche Leads und
// Schüler ist_test = true tragen. Reiner Lesezugriff ohne DB-Änderung; die Admin-Listen filtern damit,
// wo ihre Quelle das Feld nicht mitliefert (board_schueler, vertraege_aktuell).
//
// Quellen (per RLS für admin lesbar): leads.ist_test, students.ist_test.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type TestMarkierung = {
  leads: ReadonlySet<string>
  schueler: ReadonlySet<string>
}

export const KEINE_TESTMARKIERUNG: TestMarkierung = { leads: new Set(), schueler: new Set() }

export async function ladeTestMarkierung(): Promise<SupabaseResult<TestMarkierung>> {
  try {
    const [leads, schueler] = await Promise.all([
      supabase.from('leads').select('id').eq('ist_test', true),
      supabase.from('students').select('id').eq('ist_test', true),
    ])
    if (leads.error) return { data: null, error: leads.error.message }
    if (schueler.error) return { data: null, error: schueler.error.message }
    return {
      data: {
        leads: new Set(((leads.data ?? []) as { id: string }[]).map((r) => r.id)),
        schueler: new Set(((schueler.data ?? []) as { id: string }[]).map((r) => r.id)),
      },
      error: null,
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Testmarkierung konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

/** Gehört ein Vertrag (über Lead oder Kind) zu Testdaten? */
export function istTestVertrag(
  v: { lead_id: string | null; student_id: string | null },
  m: TestMarkierung,
): boolean {
  return (v.lead_id !== null && m.leads.has(v.lead_id)) || (v.student_id !== null && m.schueler.has(v.student_id))
}
