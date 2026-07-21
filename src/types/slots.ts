// Slot-System (S10): Wochen-Zeitraster, Favoriten und feste Zuweisung.
//
// Die Tabellen haengen an `leads`, nicht an `students` — vor Vertragsabschluss
// existiert der Lead, nicht das Kind. Siehe Kopfkommentar der Migration
// 20260719100000_s10_slot_system.sql (Architektur-Branchpoint).

// 0 = Montag … 6 = Sonntag (Konvention der Migration, CHECK weekday 0..6).
export type Weekday = 0 | 1 | 2 | 3 | 4 | 5 | 6

export type Slot = {
  id: string
  created_at: string
  weekday: Weekday
  /** Postgres `time` — kommt als 'HH:MM:SS' zurueck. */
  start_time: string
  room: string
  capacity: number
  active: boolean
}

export type SlotInput = {
  weekday: Weekday
  start_time: string
  room: string
  capacity?: number
}

export type SlotWish = {
  id: string
  created_at: string
  lead_id: string
  slot_id: string
  /** 1 = liebster Favorit, 3 = dritte Wahl. */
  rang: 1 | 2 | 3
}

export type SlotAssignment = {
  id: string
  slot_id: string
  lead_id: string
  assigned_at: string
  released_at: string | null
  created_by: string | null
}

/** Slot samt aktueller Auslastung — was der Wochenkalender je Karte braucht. */
export type SlotWithLoad = Slot & {
  belegt: number
}
