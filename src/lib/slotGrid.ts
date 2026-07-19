// Reine Layout- und Sortier-Logik des Slot-Kalenders — kein Supabase, testbar.
//
// Betriebsziel der Gruenderrunde: bestehende Slots auffuellen ist besser als
// neue oeffnen. Deshalb ist die Reihenfolge NICHT chronologisch neutral, sondern
// stellt vollere (aber noch freie) Slots zuerst attraktiv dar.

import type { SlotWithLoad, Weekday } from '@/types'

// Mo–Fr; Wochenende ist im Zeitraster moeglich (weekday 0..6), aber der
// Kalender zeigt die Betriebstage.
export const CALENDAR_WEEKDAYS: Weekday[] = [0, 1, 2, 3, 4]

// 'HH:MM:SS' oder 'HH:MM' → 'HH:MM'. Postgres liefert `time` mit Sekunden.
export function formatSlotTime(startTime: string): string {
  return startTime.slice(0, 5)
}

export function isFull(slot: SlotWithLoad): boolean {
  return slot.belegt >= slot.capacity
}

// Auslastungs-Stufe fuer die optische Hervorhebung im Kalender.
export type SlotFillLevel = 'empty' | 'filling' | 'almost' | 'full'

export function fillLevel(slot: SlotWithLoad): SlotFillLevel {
  if (isFull(slot)) return 'full'
  if (slot.belegt === 0) return 'empty'
  // Ein Platz frei: der attraktivste Slot ueberhaupt (Auffuellen).
  if (slot.belegt >= slot.capacity - 1) return 'almost'
  return 'filling'
}

// Die Zeitzeilen des Rasters: alle vorkommenden Startzeiten, aufsteigend.
export function timeRows(slots: SlotWithLoad[]): string[] {
  const times = new Set(slots.map((slot) => formatSlotTime(slot.start_time)))
  return [...times].sort()
}

// Sortierung innerhalb einer Zelle: freie Slots zuerst, davon die volleren
// zuerst (Auffuellen), ausgebuchte ans Ende. Bei Gleichstand nach Raum, damit
// die Reihenfolge zwischen zwei Renderings stabil bleibt.
export function sortByFillFirst(slots: SlotWithLoad[]): SlotWithLoad[] {
  return [...slots].sort((a, b) => {
    const aFull = isFull(a)
    const bFull = isFull(b)
    if (aFull !== bFull) return aFull ? 1 : -1
    if (a.belegt !== b.belegt) return b.belegt - a.belegt
    return a.room.localeCompare(b.room)
  })
}

// Slots einer Zelle (Wochentag × Uhrzeit), bereits sortiert.
export function slotsAt(
  slots: SlotWithLoad[],
  weekday: Weekday,
  time: string,
): SlotWithLoad[] {
  return sortByFillFirst(
    slots.filter(
      (slot) => slot.weekday === weekday && formatSlotTime(slot.start_time) === time,
    ),
  )
}
