// Reine Logik des Menues "Vertraege": Summen, Filter, Mahnstufen.
//
// Hier wird NICHTS gerechnet, was die Datenbank schon gerechnet hat. Die
// Summenzeile addiert Werte aus vertraege_aktuell, sie leitet sie nicht ab —
// der Status eines Vertrags und sein Monatsbeitrag stehen fertig in der Zeile.

import type { VertragAktuell, WirksamerStatus, Zahlungsstatus } from '@/types'

/** Was in der Uebersicht als "laufend" zaehlt. */
export const LAUFEND: WirksamerStatus[] = ['aktiv', 'im_widerruf']

export type Summen = {
  laufend: number
  abbuchungCents: number
  imWiderruf: number
}

/**
 * Die Zeile ueber der Uebersicht.
 *
 * "Abbuchung diesen Monat" summiert ueber GENAU die laufenden Vertraege — ein
 * ausgelaufener Vertrag traegt seinen letzten Beitrag sonst ewig weiter.
 */
export function summen(vertraege: VertragAktuell[]): Summen {
  const laufend = vertraege.filter((v) => LAUFEND.includes(v.wirksamer_status))
  return {
    laufend: laufend.length,
    abbuchungCents: laufend.reduce((s, v) => s + v.beitrag_diesen_monat_cents, 0),
    imWiderruf: vertraege.filter((v) => v.wirksamer_status === 'im_widerruf').length,
  }
}

/** Die Mahnstufen in ihrer Reihenfolge — dieselbe wie in der RPC. */
export const ZAHLUNGSSTUFEN: Zahlungsstatus[] = [
  'in_ordnung',
  'zahlung_offen',
  'mahnung_1',
  'mahnung_2',
  'inkasso',
]

/** Die naechste Stufe, oder null am Ende der Leiter. */
export function naechsteStufe(status: Zahlungsstatus): Zahlungsstatus | null {
  const i = ZAHLUNGSSTUFEN.indexOf(status)
  return i >= 0 && i < ZAHLUNGSSTUFEN.length - 1 ? ZAHLUNGSSTUFEN[i + 1] : null
}

export type UebersichtFilter = {
  suche: string
  status: WirksamerStatus | null
  tierId: string | null
  laufzeit: number | null
  zahlungsstatus: Zahlungsstatus | null
  /** false zeigt auch Vorgaengervertraege. */
  nurAktuelle: boolean
}

export const LEERER_FILTER: UebersichtFilter = {
  suche: '',
  status: null,
  tierId: null,
  laufzeit: null,
  zahlungsstatus: null,
  nurAktuelle: true,
}

export function vertragspartner(v: VertragAktuell): string {
  return [v.eltern_vorname, v.eltern_nachname].filter(Boolean).join(' ').trim()
}

export function kind(v: VertragAktuell): string {
  return [v.kind_vorname, v.kind_nachname].filter(Boolean).join(' ').trim()
}

/** Suche ueber Vertragspartner und Kind, Filter ueber die Spaltenwerte. */
export function passtZumFilter(v: VertragAktuell, f: UebersichtFilter): boolean {
  if (f.nurAktuelle && !v.ist_aktueller_vertrag) return false
  const suche = f.suche.trim().toLowerCase()
  if (suche !== '' && !`${vertragspartner(v)} ${kind(v)}`.toLowerCase().includes(suche)) {
    return false
  }
  if (f.status !== null && v.wirksamer_status !== f.status) return false
  if (f.tierId !== null && v.tier_id !== f.tierId) return false
  if (f.laufzeit !== null && v.laufzeit_monate !== f.laufzeit) return false
  if (f.zahlungsstatus !== null && v.zahlungsstatus !== f.zahlungsstatus) return false
  return true
}

/** Auslaufend: Ende innerhalb von acht Wochen, naechstes zuerst. */
export function auslaufende(vertraege: VertragAktuell[]): VertragAktuell[] {
  return vertraege
    .filter(
      (v) =>
        v.endet_in_tagen !== null &&
        v.endet_in_tagen >= 0 &&
        v.endet_in_tagen <= 56 &&
        v.verlaengerung_status !== 'keine_verlaengerung' &&
        v.verlaengerung_status !== 'verlaengert',
    )
    .sort((a, b) => (a.endet_in_tagen ?? 0) - (b.endet_in_tagen ?? 0))
}

/** Zahlungsverzug: alles, was nicht in Ordnung ist. */
export function imVerzug(vertraege: VertragAktuell[]): VertragAktuell[] {
  return vertraege
    .filter((v) => v.zahlungsstatus !== 'in_ordnung')
    .sort((a, b) => (a.zahlungsstatus_seit ?? '').localeCompare(b.zahlungsstatus_seit ?? ''))
}
