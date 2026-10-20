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

import { feldVon } from '@/lib/report/elternbericht/themenfelder'
import type { KatalogSkill, ReportErzaehlung, ThemenfeldKey, Themenraum } from '@/types'

export type ThemaAbdeckungEingabe = {
  modus: 'fest' | 'adaptiv' | null
  raum: Themenraum | null
  /** Suchweg.themaLabel — dieselbe Quelle wie im R6-Abschnitt „Wie wir gesucht haben“. */
  themaLabel: string | null
  /** Schlüssel der direkt geprüften Bereiche (ReportErzaehlung.kompetenzen). */
  direkt: readonly string[]
  /** ReportErzaehlung.abgeleitet */
  abgeleitet: readonly string[]
  /** ReportErzaehlung.katalog — nur für die Klasse der abgeleiteten Bereiche (R7-8). */
  katalog?: readonly KatalogSkill[]
}

/** Ein abgeleiteter Bereich, wie Seite 2 ihn braucht: ohne Schlüssel (R7-8). */
export type AbgeleiteterBereich = {
  feld: ThemenfeldKey
  /** Aus dem Katalog; null, wenn der Katalog den Schlüssel nicht kennt. */
  klasse: number | null
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
  /** Die Schlüssel hinter `abgeleitet`, sortiert (R7-8). */
  abgeleiteteSchluessel: string[]
  /**
   * Dieselben Bereiche in derselben Reihenfolge, mit Feld und Klasse: die
   * Umriss-Kästchen auf Seite 2. Der Bogen selbst kennt so keine Schlüssel
   * (INV-4.3) und schlägt nichts im Katalog nach (R7-8).
   */
  abgeleiteteBereiche: AbgeleiteterBereich[]
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
  katalog = [],
}: ThemaAbdeckungEingabe): ThemaAbdeckung | null {
  if (modus !== 'adaptiv' || raum?.herkunft !== 'abschluss' || !themaLabel) return null
  const menge = new Set([...raum.einstieg, ...raum.darunter])
  if (menge.size === 0) return null

  const direktImRaum = new Set(direkt.filter((k) => menge.has(k)))
  if (direktImRaum.size === 0) return null
  const abgeleitetImRaum = new Set(abgeleitet.filter((k) => menge.has(k) && !direktImRaum.has(k)))
  const schluessel = [...abgeleitetImRaum].sort()
  const klasse = new Map(katalog.map((k) => [k.skillKey, k.klasse]))

  return {
    thema: themaLabel,
    umfang: menge.size,
    direkt: direktImRaum.size,
    abgeleitet: abgeleitetImRaum.size,
    offen: menge.size - direktImRaum.size - abgeleitetImRaum.size,
    abgeleiteteSchluessel: schluessel,
    abgeleiteteBereiche: schluessel.map((k) => ({ feld: feldVon(k), klasse: klasse.get(k) ?? null })),
  }
}

/** Aus der Erzählschicht; das Thema wie in R6 aus Suchweg.themaLabel. */
export function themaAbdeckungAus(
  e: Pick<ReportErzaehlung, 'modus' | 'raum' | 'suche' | 'kompetenzen' | 'abgeleitet' | 'katalog'>,
): ThemaAbdeckung | null {
  return themaAbdeckung({
    modus: e.modus,
    raum: e.raum,
    themaLabel: e.suche?.themaLabel ?? null,
    direkt: e.kompetenzen.map((k) => k.skillKey),
    abgeleitet: e.abgeleitet,
    katalog: e.katalog,
  })
}
