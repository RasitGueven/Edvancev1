import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult, XpRule } from '@/types'

// Admin-konfigurierbare XP-Gewichtung pro content_type. RLS: nur Staff lesen,
// nur Admin schreiben. Effektive XP = base_xp + difficulty_multiplier *
// task.difficulty (server-seitig in der RPC complete_task berechnet).
export async function listXpRules(): Promise<SupabaseResult<XpRule[]>> {
  try {
    const { data, error } = await supabase
      .from('xp_rules')
      .select('*')
      .order('content_type', { ascending: true })
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as XpRule[], error: null }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'XP-Regeln konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

export async function updateXpRule(
  contentType: string,
  baseXp: number,
  difficultyMultiplier: number,
): Promise<SupabaseResult<XpRule>> {
  try {
    const { data, error } = await supabase
      .from('xp_rules')
      .upsert(
        {
          content_type: contentType,
          base_xp: baseXp,
          difficulty_multiplier: difficultyMultiplier,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'content_type' },
      )
      .select('*')
      .single()
    if (error) return { data: null, error: error.message }
    return { data: data as XpRule, error: null }
  } catch (err) {
    const message =
      err instanceof Error
        ? err.message
        : 'XP-Regel konnte nicht gespeichert werden'
    return { data: null, error: message }
  }
}
