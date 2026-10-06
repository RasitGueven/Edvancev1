// Testmodus (Session-Rahmen P1, Entscheidung 27): Testkonten und Testlaeufe.
// Duenne Wrapper um die SECURITY-DEFINER-RPCs; die Rechte (nur Admin) und
// die Regel "Testlauf nur mit Testkonto" prueft die Datenbank.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type TestkontoArt = 'student' | 'lead'

/** Setzt den Testkonto-Haken an Kind oder Lead (Lead: auch das zugehoerige Kind). */
export async function testkontoSetzen(
  art: TestkontoArt,
  id: string,
  wert: boolean,
): Promise<SupabaseResult<true>> {
  try {
    const { error } = await supabase.rpc('testkonto_setzen', { p_art: art, p_id: id, p_wert: wert })
    if (error) return { data: null, error: error.message }
    return { data: true, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Testkonto konnte nicht gesetzt werden' }
  }
}

/** Ist das Kind ein Testkonto? (Lesen darf students nur Admin bzw. Coach bei aktiver Akte.) */
export async function getStudentIstTest(studentId: string): Promise<SupabaseResult<boolean>> {
  try {
    const { data, error } = await supabase
      .from('students')
      .select('ist_test')
      .eq('id', studentId)
      .maybeSingle()
    if (error) return { data: null, error: error.message }
    return { data: (data?.ist_test as boolean | undefined) === true, error: null }
  } catch (err) {
    return { data: null, error: err instanceof Error ? err.message : 'Testkonto konnte nicht geladen werden' }
  }
}
