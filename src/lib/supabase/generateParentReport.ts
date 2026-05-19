import { supabase } from '@/lib/supabase/client'
import type { ParentReportDraft, SupabaseResult } from '@/types'

// KI-Entwurf via Edge Function generate_parent_report. Schreibt NICHT in
// die DB — Aufrufer editiert und speichert via parentReports-Lib.
export type GenerateInput = {
  student_id: string
  period_start: string
  period_end: string
  coach_context?: string | null
}

export async function generateParentReport(
  input: GenerateInput,
): Promise<SupabaseResult<ParentReportDraft>> {
  try {
    const { data, error } = await supabase.functions.invoke(
      'generate_parent_report',
      { body: input },
    )
    if (error) {
      let msg = error.message
      try {
        const b = (await (
          error as unknown as { context: Response }
        ).context.json()) as { error?: string }
        if (b?.error) msg = b.error
      } catch {
        /* generische Meldung behalten */
      }
      return { data: null, error: msg }
    }
    const draft = (data as { draft?: ParentReportDraft } | null)?.draft
    if (!draft) {
      const msg = (data as { error?: string } | null)?.error
      return { data: null, error: msg ?? 'Kein Entwurf erhalten' }
    }
    return { data: draft, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Report-Generierung fehlgeschlagen'
    return { data: null, error: message }
  }
}
