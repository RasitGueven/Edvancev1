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

/** Ein Paket, wie es in der Auswahl steht — mit den Zahlen der Laufzeit. */
export type PaketOption = {
  id: string
  name: string
  /** null, solange keine Laufzeit gewaehlt ist oder der Tarif dafuer keine Zeile hat. */
  kondition: Kondition | null
}

/**
 * Die Pakete zur GEWAEHLTEN Laufzeit.
 *
 * Vorher zeigte die Paketauswahl `tiers.price_cents` — den Referenzpreis, der
 * dem Jahrespaket entspricht und sich beim Laufzeitwechsel nie aendert. Wer
 * auf Halbjahr umstellte, sah darunter Beitrag und Einheiten springen, in der
 * Auswahl darueber aber weiter den Jahrespreis. Die Auswahl muss dieselbe
 * Quelle lesen wie alles andere: tier_laufzeiten.
 */
export function paketOptionen(tiers: TierPlan[], laufzeitMonate: number | null): PaketOption[] {
  return tiers.map((tier) => ({
    id: tier.id,
    name: tier.name,
    kondition: kondition(tier, laufzeitMonate),
  }))
}
