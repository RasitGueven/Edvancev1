// Eltern: die nächste Session eines Kindes (Slots SL3, Entscheidung 14). Quelle ist naechste_termine,
// damit ein Slot-Termin schon vor dem Festschreiben dasteht. Den Raum kennt erst die festgeschriebene
// Session; ohne sie bleibt er weg.

import type { CoachingSession } from '@/types'
import type { NaechsterTermin } from '@/types/slotplan'

export type NaechsteSessionEltern = { beginn: string; room: string | null }

export function naechsteSessionEltern(
  termine: NaechsterTermin[] | null,
  sessions: CoachingSession[],
): NaechsteSessionEltern | null {
  // Scheitert naechste_termine (null), bleibt es bei der bisherigen Quelle.
  if (termine === null) return sessions[0] ? { beginn: sessions[0].scheduled_at, room: sessions[0].room } : null
  const termin = termine[0]
  if (!termin) return null
  const session = termin.session_id ? sessions.find((s) => s.id === termin.session_id) : undefined
  return { beginn: termin.beginn, room: session?.room ?? null }
}
