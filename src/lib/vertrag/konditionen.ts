import type { TierPlan } from '@/types'

/** Monatsbeitrag, Einheiten und Gesamtpreis fuer Paket + Laufzeit. */
export type Kondition = {
  laufzeit_monate: 6 | 12
  preis_cents: number
  einheiten: number
  /** Zahl der Monatsbeitraege = Laufzeit, auch wenn Ferien das Ende schieben. */
  beitraege: number
  gesamt_cents: number
}

export function gesamtCents(preisCents: number, laufzeitMonate: number): number {
  return preisCents * laufzeitMonate
}

/**
 * Kondition aus tier_laufzeiten. null, solange Paket oder Laufzeit fehlt oder
 * der Tarif fuer diese Laufzeit keine Zeile hat. Nur Anzeige — verbindlich
 * setzt der Datenbank-Trigger Preis und Einheiten am Vertrag.
 */
export function kondition(tier: TierPlan | null, laufzeitMonate: number | null): Kondition | null {
  if (!tier || laufzeitMonate === null) return null
  const zeile = tier.laufzeiten?.find((l) => l.laufzeit_monate === laufzeitMonate)
  if (!zeile) return null
  return {
    laufzeit_monate: zeile.laufzeit_monate,
    preis_cents: zeile.preis_cents,
    einheiten: zeile.einheiten,
    beitraege: zeile.laufzeit_monate,
    gesamt_cents: gesamtCents(zeile.preis_cents, zeile.laufzeit_monate),
  }
}
