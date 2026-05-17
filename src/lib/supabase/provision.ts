import { supabase } from '@/lib/supabase/client'
import type { SchoolKind, SupabaseResult } from '@/types'

// Lead -> Student Conversion via Edge Function provision_student
// (service-role, atomar). Niemals direkt aus Komponenten aufrufen –
// nur ueber diese Lib-Funktion.
export type ProvisionInput = {
  lead_id?: string | null
  full_name: string
  student_email?: string | null
  parent_email?: string | null
  class_level?: number | null
  school_type?: SchoolKind | null
  school_name?: string | null
  subjects?: string[]
  coach_id?: string | null
  tier_id?: string | null
}

export async function provisionStudent(
  input: ProvisionInput,
): Promise<SupabaseResult<{ student_id: string }>> {
  try {
    const { data, error } = await supabase.functions.invoke(
      'provision_student',
      { body: input },
    )
    if (error) return { data: null, error: error.message }
    const sid = (data as { student_id?: string } | null)?.student_id
    if (!sid) {
      const msg = (data as { error?: string } | null)?.error
      return { data: null, error: msg ?? 'Provisionierung lieferte keine student_id' }
    }
    return { data: { student_id: sid }, error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Provisionierung fehlgeschlagen'
    return { data: null, error: message }
  }
}
