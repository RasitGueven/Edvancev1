// Eltern-Bericht R7 · Seite 5 — welche Pakete stehen da, welches ist der
// Coach-Vorschlag (Bauauftrag R7-3, Entscheidung 2).

import type { ReportPaket, TierPlan } from '@/types'

/** notes.paket → Position unter den aktiven Paketen (nach sort_order). */
const POSITION: Record<ReportPaket, number> = { basis: 0, standard: 1, premium: 2 }

/** Aktive Pakete nach sort_order und das vorgeschlagene, falls eindeutig. */
export function paketWahl(
  tiers: readonly TierPlan[],
  paket: ReportPaket | null | undefined,
): { pakete: TierPlan[]; vorschlag: TierPlan | null; eindeutig: boolean } {
  const pakete = tiers.filter((p) => p.active).sort((a, b) => a.sort_order - b.sort_order)
  // Die Zuordnung basis/standard/premium → 1./2./3. Paket gilt nur bei genau drei.
  const eindeutig = pakete.length === 3
  const vorschlag = eindeutig && paket ? (pakete[POSITION[paket]] ?? null) : null
  return { pakete, vorschlag, eindeutig }
}
