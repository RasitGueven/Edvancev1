// Datenzugriff für die Zwei-Achsen-Kompetenz-Matrix (Migrationen 038 + 040).
// Lese-Funktionen filtern NICHT zusätzlich nach Rolle — das Scoping macht RLS
// (scm_student_read / scm_parent_read / scm_coach_admin_read). Schreiben
// validiert zusätzlich der Gate-Trigger trg_enforce_mastery_gate (FernUSG).

import { supabase } from '@/lib/supabase/client'
import type {
  ProcessCompetency,
  StudentCompetencyMastery,
  SupabaseResult,
} from '@/types'

// Die 6 Prozesskompetenzen (Referenzdaten), sortiert nach sort_order.
export async function listProcessCompetencies(): Promise<
  SupabaseResult<ProcessCompetency[]>
> {
  try {
    const { data, error } = await supabase
      .from('process_competencies')
      .select('*')
      .order('sort_order', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as ProcessCompetency[], error: null }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'Prozesskompetenzen konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

// Mastery-Matrix eines Schülers. Ohne studentId: eigene Zeilen (RLS begrenzt
// auf get_my_student_id()). Mit studentId: gezielt für Coach/Parent — RLS
// validiert die Berechtigung, hier wird NICHT zusätzlich nach Rolle gefiltert.
export async function getStudentMasteryMatrix(
  studentId?: string,
): Promise<SupabaseResult<StudentCompetencyMastery[]>> {
  try {
    let q = supabase.from('student_competency_mastery').select('*')
    if (studentId !== undefined) q = q.eq('student_id', studentId)
    const { data, error } = await q
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as StudentCompetencyMastery[], error: null }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'Kompetenz-Matrix konnte nicht geladen werden'
    return { data: null, error: message }
  }
}

// Setzt mastered=true für eine (Schüler × Mikroskill × Prozesskompetenz)-Zelle
// (Coach-Pfad). mastered_by / mastered_at vergibt der Gate-Trigger
// serverseitig; er wirft, wenn die Rolle nicht coach/admin ist (FernUSG).
// Idempotent über den Primärschlüssel.
export async function grantMastery(args: {
  studentId: string
  microskillId: string
  competencyId: string
}): Promise<SupabaseResult<StudentCompetencyMastery>> {
  try {
    const { data, error } = await supabase
      .from('student_competency_mastery')
      .upsert(
        {
          student_id: args.studentId,
          microskill_id: args.microskillId,
          competency_id: args.competencyId,
          mastered: true,
        },
        {
          onConflict: 'student_id,microskill_id,competency_id',
          ignoreDuplicates: false,
        },
      )
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as StudentCompetencyMastery, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Mastery konnte nicht gewährt werden'
    return { data: null, error: message }
  }
}
