// Slots: Formen der Dialoge, der Coach- und Eltern-Sicht und der Schreibfunktionen. Ausgelagert aus
// ./slotplan (Dateigrenze 400 Zeilen, W1); dort weiter re-exportiert, Importe bleiben '@/types/slotplan'.

import type { KindKurz, Planbilanz, SlotsCode, SlotZeit, Takt } from './slotplan'

// ── Dialoge ─────────────────────────────────────────────────────────────────

/** W1: raum_id ist für neue und geänderte Stammplätze Pflicht (sonst 22023 raum_fehlt). */
export type StammplatzZeile = { wochentag: number; slot_zeit_id: string; takt: Takt; raum_id?: string }

export type SlotsFrei = {
  takt: Takt
  ab: string
  zeiten: SlotZeit[]
  /** Kleinster Wert der nächsten sechs Termine; raum = alle sechs haben einen Raum mit Coach. */
  zellen: {
    wochentag: number
    zeit_id: string
    frei: number
    raum: boolean
    voll: boolean
    termine: number
    /** SL2b: einer der nächsten sechs Termine scheitert an einem Kind der anderen Art (SL013). */
    art_konflikt?: boolean
  }[]
}

export type Sperrgrund = { code: SlotsCode; zeile: number | null; datum?: string }

export type PlanbilanzVorschau = {
  planbilanz: Planbilanz | null
  terminzahl: number | null
  letzter_termin: string | null
  uebersprungen: string[]
  /** Leer = Speichern möglich (Abnahmefall 9). */
  gruende: Sperrgrund[]
}

export type SlotsZiel = {
  datum: string
  zeit_id: string
  beginn: string
  ende: string
  frei: number
  /** Stammplatz-Termin, der für diesen Termin wegfiele (Anforderung G 45). */
  verdraengt: string | null
}

export type SlotsZiele = {
  ab: string
  wochen: number
  /** Eingang nach 10 Uhr: die alte Einheit ist verbraucht, der neue Termin braucht eine weitere. */
  alt_verbraucht: boolean
  kein_budget: boolean
  ziele: SlotsZiel[]
}

export type SlotsKandidat = KindKurz & { offen: number; verdraengt: string | null }

// ── Coach und Eltern ────────────────────────────────────────────────────────

export type MeinEinsatz = {
  datum: string
  zeit_id: string
  beginn: string
  ende: string
  raum_id: string
  raum_name: string
  heute: boolean
  session_id: string | null
  kinder: KindKurz[]
}

export type MeineEinsaetze = { montag: string; kw: number; heute: string; einsaetze: MeinEinsatz[] }

export type NaechsterTermin = {
  beginn: string
  datum: string
  uhrzeit: string
  ende: string
  festgeschrieben: boolean
  session_id: string | null
}

// ── Ergebnisse der Schreibfunktionen ───────────────────────────────────────

export type StammplatzErgebnis = { stammplatz_ids?: string[]; stammplatz_id?: string; planbilanz: Planbilanz | null }
export type AbsageErgebnis = { termin_id: string; zustand: 'cancelled' | 'unexcused'; rechtzeitig: boolean }
export type ZusatzErgebnis = {
  termin_id: string
  verdraengt: string[]
  ausgelassen?: (KindKurz & { termin_id: string; grund: 'ZG001' })[]
}
export type UmbuchenErgebnis = { termin_id: string; alt_zustand: 'cancelled' | 'unexcused'; rechtzeitig: boolean; verdraengt: string[] }
export type SessionAnlegenErgebnis = {
  session_id: string
  neu: boolean
  /** Kinder ohne Zugang an dem Tag (ZG001): ausgelassen, Termin "ausgefallen durch uns". */
  ausgelassen: (KindKurz & { termin_id: string; grund: 'ZG001' })[]
}
