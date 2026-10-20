// Eltern-Bericht R7 — wie das Thema der Sitzung abgedeckt ist (R7-6,
// Entscheidungen 6 und 7).
//
// Nur bei der abgestuften LSA (modus 'adaptiv') mit Thema: Für jeden Bereich des
// Themenraums gibt es dort ein Urteil, einen Teil direkt geprüft, den Rest aus
// dem Voraussetzungsgraphen abgeleitet. Abgeleitete Urteile werden hier nur
// GEZÄHLT — nie als sicher oder Übungsbedarf gezeigt (Gründer, 20.10.2026).
// Alle anderen Zahlen des Bogens rechnen weiter nur mit belegt_direkt.
//
// Abweichend von Entscheidung 6 zählt nur ein Raum mit herkunft 'abschluss'
// (Rasit, 20.10.2026): Nur ein beim Abschluss gespeicherter Raum belegt, dass
// die LSA wirklich mit Thema gelaufen ist. modus allein ist für alte Sitzungen
// nicht verlässlich — Ilkays Sitzung steht in Prod auf 'adaptiv', war aber
// nicht abgestuft; ihr Raum ist nachgetragen.

import type { ReportErzaehlung, Themenraum } from '@/types'

export type ThemaAbdeckungEingabe = {
  modus: 'fest' | 'adaptiv' | null
  raum: Themenraum | null
  /** Suchweg.themaLabel — dieselbe Quelle wie im R6-Abschnitt „Wie wir gesucht haben“. */
  themaLabel: string | null
  /** Schlüssel der direkt geprüften Bereiche (ReportErzaehlung.kompetenzen). */
  direkt: readonly string[]
  /** ReportErzaehlung.abgeleitet */
  abgeleitet: readonly string[]
}

export type ThemaAbdeckung = {
  thema: string
  /** |einstieg ∪ darunter| */
  umfang: number
  /** Direkt geprüfte Bereiche im Raum. */
  direkt: number
  /** Abgeleitete Bereiche im Raum, die nicht direkt geprüft wurden. */
  abgeleitet: number
  /** umfang − direkt − abgeleitet */
  offen: number
}

/**
 * null, wenn der Thema-Satz entfällt: nicht abgestuft, kein Raum oder keiner
 * vom Abschluss, leerer Raum, kein Label, nichts direkt im Raum.
 */
export function themaAbdeckung({
  modus,
  raum,
  themaLabel,
  direkt,
  abgeleitet,
}: ThemaAbdeckungEingabe): ThemaAbdeckung | null {
  if (modus !== 'adaptiv' || raum?.herkunft !== 'abschluss' || !themaLabel) return null
  const menge = new Set([...raum.einstieg, ...raum.darunter])
  if (menge.size === 0) return null

  const direktImRaum = new Set(direkt.filter((k) => menge.has(k)))
  if (direktImRaum.size === 0) return null
  const abgeleitetImRaum = new Set(abgeleitet.filter((k) => menge.has(k) && !direktImRaum.has(k)))

  return {
    thema: themaLabel,
    umfang: menge.size,
    direkt: direktImRaum.size,
    abgeleitet: abgeleitetImRaum.size,
    offen: menge.size - direktImRaum.size - abgeleitetImRaum.size,
  }
}

/** Aus der Erzählschicht; das Thema wie in R6 aus Suchweg.themaLabel. */
export function themaAbdeckungAus(
  e: Pick<ReportErzaehlung, 'modus' | 'raum' | 'suche' | 'kompetenzen' | 'abgeleitet'>,
): ThemaAbdeckung | null {
  return themaAbdeckung({
    modus: e.modus,
    raum: e.raum,
    themaLabel: e.suche?.themaLabel ?? null,
    direkt: e.kompetenzen.map((k) => k.skillKey),
    abgeleitet: e.abgeleitet,
  })
}
