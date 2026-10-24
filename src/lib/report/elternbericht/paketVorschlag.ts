// Eltern-Bericht v2 — Seite 5: der Paketvorschlag des Systems.
//
// Ein VORSCHLAG nach PAKET_REGEL (berichtKonfig.ts), kein Urteil und keine
// Vorhersage. Bestätigt der Coach ein Paket (ReportNotes.paketBestaetigt),
// gilt seine Wahl; sonst steht der Vorschlag mit dem Schild „Vorschlag“.

import { PAKET_REGEL } from '@/lib/report/elternbericht/berichtKonfig'
import type { ReportPaket } from '@/types'

export type PaketGrund = 'breit' | 'mehrere' | 'einer' | 'wenig'

export type PaketVorschlag = {
  paket: ReportPaket
  /** Für den Satz „… schlagen wir X vor, weil …“ (i18n s5.grund.<grund>). */
  grund: PaketGrund
  schwerpunkte: number
  /** Anteil Übungsbedarf an den geprüften Bereichen, 0–1. */
  anteil: number
}

/**
 * @param schwerpunkte die Schwerpunkte von Seite 4 (höchstens vier, ohne „danach“)
 * @param uebung, untersucht die Zahlen von Seite 1 und 2
 */
export function paketVorschlag(schwerpunkte: number, uebung: number, untersucht: number): PaketVorschlag {
  const anteil = untersucht > 0 ? uebung / untersucht : 0
  const { premium, basic } = PAKET_REGEL
  if (anteil >= premium.minAnteil && schwerpunkte >= premium.minSchwerpunkte) {
    return { paket: 'premium', grund: 'breit', schwerpunkte, anteil }
  }
  if (anteil <= basic.maxAnteil && schwerpunkte <= basic.maxSchwerpunkte) {
    return { paket: 'basis', grund: 'wenig', schwerpunkte, anteil }
  }
  return { paket: 'standard', grund: schwerpunkte >= 2 ? 'mehrere' : 'einer', schwerpunkte, anteil }
}
