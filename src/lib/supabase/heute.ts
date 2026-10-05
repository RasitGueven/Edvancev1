// Startseite „Heute“ (Bauauftrag Admin-Hülle H3): die Lesefunktionen, die es
// anderswo nicht gibt. Alles andere liest die Seite über die bestehenden
// Wrapper (leads, platz, leadLsa, vertraegeMenue, akte, themen, lsaReport).
// Nur Lesen — geschrieben wird ausschliesslich über bestehende Funktionen.

import { supabase } from '@/lib/supabase/client'
import { berlinLocalToIso, berlinToday } from '@/lib/datetime'
import type { SupabaseResult } from '@/types'

/** Eine Session von heute mit ihren belegten Plätzen. */
export type SessionHeute = {
  id: string
  scheduled_at: string
  room: string | null
  coach_id: string | null
  coach_name: string | null
  /** Kinder mit Platz, ohne Absagen (cancelled, cancelled_by_us). */
  belegt: number
}

/** Abgesagte Plätze zählen nicht als belegt. */
const ABGESAGT = ['cancelled', 'cancelled_by_us']

/** Beginn des Berliner Kalendertags und des Folgetags als ISO-Strings (UTC). */
export function berlinTagesGrenzen(now: Date = new Date()): { von: string; bis: string } {
  const heute = berlinToday(now)
  const [y, m, d] = heute.split('-').map(Number)
  const morgen = new Date(Date.UTC(y, m - 1, d + 1)).toISOString().slice(0, 10)
  return { von: berlinLocalToIso(heute, '00:00'), bis: berlinLocalToIso(morgen, '00:00') }
}

/**
 * Die Sessions des heutigen Berliner Tags, früheste zuerst. Eine Abfrage:
 * Coach und Teilnehmer kommen eingebettet mit (kein N+1).
 */
export async function listSessionsHeute(now: Date = new Date()): Promise<SupabaseResult<SessionHeute[]>> {
  try {
    const { von, bis } = berlinTagesGrenzen(now)
    const { data, error } = await supabase
      .from('coaching_sessions')
      .select('id, scheduled_at, room, coach_id, coach:profiles!coaching_sessions_coach_id_fkey(full_name), session_students(attendance)')
      .gte('scheduled_at', von)
      .lt('scheduled_at', bis)
      .order('scheduled_at', { ascending: true })
    if (error) return { data: null, error: error.message }
    type Coach = { full_name: string | null }
    type Zeile = {
      id: string
      scheduled_at: string
      room: string | null
      coach_id: string | null
      coach: Coach | Coach[] | null
      session_students: { attendance: string }[] | null
    }
    return {
      data: ((data ?? []) as unknown as Zeile[]).map((z) => {
        const coach = Array.isArray(z.coach) ? z.coach[0] : z.coach
        return {
          id: z.id,
          scheduled_at: z.scheduled_at,
          room: z.room,
          coach_id: z.coach_id,
          coach_name: coach?.full_name ?? null,
          belegt: (z.session_students ?? []).filter((s) => !ABGESAGT.includes(s.attendance)).length,
        }
      }),
      error: null,
    }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Sessions von heute konnten nicht geladen werden'
    return { data: null, error: message }
  }
}

/** Eine Aufgabe, die auf die Freigabe wartet. */
export type AufgabeInReview = { id: string; skill_key: string | null }

/**
 * Aufgaben im Status review — dieselbe Menge wie countTasksInReview() (Zähler
 * der Leiste), hier mit skill_key für die Gruppierung nach Thema.
 */
export async function listAufgabenInReview(): Promise<SupabaseResult<AufgabeInReview[]>> {
  try {
    const { data, error } = await supabase
      .from('tasks')
      .select('id, skill_key')
      .eq('content_type', 'exercise')
      .eq('status', 'review')
    if (error) return { data: null, error: error.message }
    return { data: (data ?? []) as AufgabeInReview[], error: null }
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Aufgaben zur Freigabe konnten nicht geladen werden'
    return { data: null, error: message }
  }
}
