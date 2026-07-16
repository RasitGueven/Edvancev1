import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

// Aggregierte Kennzahlen fuer das Admin-Dashboard (nur Counts, keine Rohdaten).
export type AdminStats = {
  students: number
  leadsTotal: number
  leadsNew: number
  leadsOpen: number
  coaches: number
  tiersActive: number
  tiersTotal: number
  screeningItems: number
}

const OPEN_LEAD_STATUS = ['new', 'contacted', 'onboarding_scheduled']

// Fuehrt eine count-Query (head: true) robust aus – ein Fehler in einer
// Einzelkennzahl darf das gesamte Dashboard nicht blockieren.
async function safeCount(query: PromiseLike<unknown>): Promise<number> {
  try {
    const res = (await query) as { count: number | null; error: unknown }
    return res.error ? 0 : res.count ?? 0
  } catch {
    return 0
  }
}

function countOf(table: string) {
  return supabase.from(table).select('*', { count: 'exact', head: true })
}

// Laedt alle Dashboard-Kennzahlen parallel. data ist immer gesetzt –
// einzelne fehlgeschlagene Counts fallen auf 0 zurueck.
export async function getAdminStats(): Promise<SupabaseResult<AdminStats>> {
  try {
    const [
      students,
      leadsTotal,
      leadsNew,
      leadsOpen,
      coaches,
      tiersActive,
      tiersTotal,
      screeningItems,
    ] = await Promise.all([
      // S7: provisorische Lead-Schüler (A1 Option 1) zählen NIE als Schüler.
      safeCount(countOf('students').eq('is_provisional', false)),
      safeCount(countOf('leads')),
      safeCount(countOf('leads').eq('status', 'new')),
      safeCount(countOf('leads').in('status', OPEN_LEAD_STATUS)),
      safeCount(countOf('profiles').eq('role', 'coach')),
      safeCount(countOf('tiers').eq('active', true)),
      safeCount(countOf('tiers')),
      safeCount(countOf('screening_items')),
    ])
    return {
      data: {
        students,
        leadsTotal,
        leadsNew,
        leadsOpen,
        coaches,
        tiersActive,
        tiersTotal,
        screeningItems,
      },
      error: null,
    }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Kennzahlen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
