// „Heute im Betrieb“ (Slots SL3): reine Logik über slots_tag. Raum-Termine und Sessions ohne Raum
// (Einzel-Sessions, Testläufe) kommen getrennt; jede Session erscheint genau einmal.

import { berlinLocalToIso } from '@/lib/datetime'
import type { SlotsTag, TagRaumTermin, TagSessionOhneRaum } from '@/types/slotplan'

export type BetriebZeile =
  | { art: 'raum'; key: string; sortier: number; t: TagRaumTermin }
  | { art: 'ohneRaum'; key: string; sortier: number; s: TagSessionOhneRaum }

/**
 * Raum-Termine plus Sessions ohne Raum, nach Beginn (Raum-Termine einer Zeit nach Raumnamen). Eine
 * Session-ID, die schon an einem Raum-Termin hängt, fällt aus den Sessions ohne Raum weg.
 */
export function betriebZeilen(tag: SlotsTag | null): BetriebZeile[] {
  if (!tag) return []
  const anRaum = new Set(tag.raum_termine.map((r) => r.session_id).filter(Boolean))
  const gesehen = new Set<string>()
  const ohneRaum = tag.sessions_ohne_raum.filter((s) => {
    if (anRaum.has(s.session_id) || gesehen.has(s.session_id)) return false
    gesehen.add(s.session_id)
    return true
  })
  const raeume = [...tag.raum_termine].sort((a, b) => a.raum_name.localeCompare(b.raum_name, 'de'))
  return [
    ...raeume.map((t): BetriebZeile => ({
      art: 'raum', key: `r-${t.zeit_id}-${t.raum_id}`, sortier: Date.parse(berlinLocalToIso(tag.datum, t.beginn)), t,
    })),
    ...ohneRaum.map((s): BetriebZeile => ({ art: 'ohneRaum', key: `s-${s.session_id}`, sortier: Date.parse(s.scheduled_at), s })),
  ].sort((a, b) => a.sortier - b.sortier)
}

/** Kinder im Haus: belegte Plätze der Raum-Termine plus Kinder der Sessions ohne Raum. */
export function betriebKinder(zeilen: BetriebZeile[]): number {
  return zeilen.reduce((n, z) => n + (z.art === 'raum' ? z.t.belegt : z.s.kinder), 0)
}

/** Kennzahl „Coaches heute im Einsatz“: verschiedene Coaches der geöffneten Raum-Termine. */
export function coachesImEinsatz(tag: SlotsTag | null): number {
  if (!tag) return 0
  return new Set(tag.raum_termine.filter((r) => r.art !== 'faellt_aus' && r.coach_id).map((r) => r.coach_id)).size
}
