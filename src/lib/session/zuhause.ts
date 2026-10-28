// Reihe 1 · D2 — Kachel „Zuhause geübt“ im Coach-Check-in. Nur Funktionen aus 20261027134914 und Skill-Namen.

import { supabase } from '@/lib/supabase/client'
import type { SupabaseResult } from '@/types'

export type ZuhauseSkill = { skill_key: string; label: string; quests: number; aufgaben: number; dauer_sek: number }
export type ZeigsMir = { skill_key: string; label: string; entscheidung: 'uebernehmen' | 'nicht_heute' | null }
export type CoachFrage = { id: string; text: string; am: string }
export type ZuhauseStand = { skills: ZuhauseSkill[]; vorschlag: ZeigsMir | null; fragen: CoachFrage[] }

const fehlertext = (err: unknown, fallback: string): string => (err instanceof Error ? err.message : fallback)

async function labels(keys: string[]): Promise<Map<string, string>> {
  if (keys.length === 0) return new Map()
  const { data } = await supabase.from('skills').select('skill_key, label').in('skill_key', keys)
  return new Map(((data ?? []) as { skill_key: string; label: string }[]).map((s) => [s.skill_key, s.label]))
}

export async function getZuhauseStand(kindId: string, sessionId: string): Promise<SupabaseResult<ZuhauseStand>> {
  try {
    const [kurz, zeigs, fragen] = await Promise.all([
      supabase.rpc('home_uebung_kurz', { p_kind: kindId }),
      supabase.rpc('zeigs_mir_offen', { p_kind: kindId, p_session: sessionId }),
      supabase.rpc('coach_fragen_offen', { p_kind: kindId }),
    ])
    const fehler = kurz.error ?? zeigs.error ?? fragen.error
    if (fehler) return { data: null, error: fehler.message }
    const zeilen = (kurz.data ?? []) as Omit<ZuhauseSkill, 'label'>[]
    const z = ((zeigs.data ?? []) as { skill_key: string; entscheidung: ZeigsMir['entscheidung'] }[])[0] ?? null
    const namen = await labels([...zeilen.map((r) => r.skill_key), ...(z ? [z.skill_key] : [])])
    const name = (k: string): string => namen.get(k) ?? k
    return {
      data: {
        skills: zeilen.map((r) => ({ ...r, label: name(r.skill_key) })),
        vorschlag: z ? { skill_key: z.skill_key, label: name(z.skill_key), entscheidung: z.entscheidung } : null,
        fragen: (fragen.data ?? []) as CoachFrage[],
      },
      error: null,
    }
  } catch (err) {
    return { data: null, error: fehlertext(err, 'zuhause failed') }
  }
}

async function aufruf(name: string, args: Record<string, unknown>): Promise<SupabaseResult<null>> {
  try {
    const { error } = await supabase.rpc(name, args)
    return error ? { data: null, error: error.message } : { data: null, error: null }
  } catch (err) {
    return { data: null, error: fehlertext(err, `${name} failed`) }
  }
}

export const zeigsMirEntscheiden = (kindId: string, sessionId: string, skillKey: string, entscheidung: 'uebernehmen' | 'nicht_heute') =>
  aufruf('zeigs_mir_entscheiden', { p_kind: kindId, p_session: sessionId, p_skill: skillKey, p_entscheidung: entscheidung })

export const coachFrageErledigt = (frageId: string) => aufruf('coach_frage_erledigt', { p_frage: frageId })
