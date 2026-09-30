// Kennzahlen des Coach-Dashboards (S2b).

import { berlinYMD } from '@/lib/datetime'
import type { CoachingSession } from '@/types'

/**
 * Die naechste Session ab jetzt, die nicht erledigt ist. Vorher zaehlte jede
 * Session mit Status 'upcoming' — auch vergangene, deren Status nie
 * weitergesetzt wurde (Prod am 30.09.2026: 3 von 4). Die Kachel zeigte dann die
 * Uhrzeit einer alten Session ohne Datum, waehrend "Sessions heute" 0 war.
 */
export function naechsteSession(sessions: CoachingSession[], nowMs: number): CoachingSession | null {
  return (
    sessions
      .filter((s) => s.status !== 'done' && new Date(s.scheduled_at).getTime() >= nowMs)
      .sort((a, b) => a.scheduled_at.localeCompare(b.scheduled_at))[0] ?? null
  )
}

/** Liegt der Zeitpunkt am selben Berliner Kalendertag wie `jetzt`? */
export function amSelbenBerlinerTag(iso: string, jetztIso: string): boolean {
  const a = berlinYMD(iso)
  const b = berlinYMD(jetztIso)
  return a.y === b.y && a.m === b.m && a.d === b.d
}
