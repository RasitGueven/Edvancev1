import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

// Coach-Anlage via Edge Function provision_coach (service-role, Admin-only).
// Niemals direkt aus Komponenten – nur über diese Lib-Funktion.
export type CoachInput = {
  full_name: string
  email: string
  password: string
}

export async function provisionCoach(
  input: CoachInput,
): Promise<SupabaseResult<{ coach_id: string }>> {
  try {
    const { data, error } = await supabase.functions.invoke('provision_coach', {
      body: input,
    })
    if (error) {
      let msg = error.message
      try {
        const body = (await (
          error as unknown as { context: Response }
        ).context.json()) as { error?: string }
        if (body?.error) msg = body.error
      } catch {
        /* behalte generische Meldung */
      }
      return { data: null, error: msg }
    }
    const cid = (data as { coach_id?: string } | null)?.coach_id
    if (!cid) {
      const msg = (data as { error?: string } | null)?.error
      return {
        data: null,
        error: msg ?? 'Provisionierung lieferte keine coach_id',
      }
    }
    return { data: { coach_id: cid }, error: null }
  } catch (err) {
    const message =
      err instanceof Error ? err.message : 'Coach-Anlage fehlgeschlagen'
    return { data: null, error: message }
  }
}
