// Tablet-Präsentation — die Empfehlungszeile in Station 04 (Entscheidung 9).
//
// Das Paket kommt aus dem Ausblick des Reports (lsa_report_notes.paket), der
// Name aus `tiers` wie auf Seite 5 des Druckbogens: aktive Pakete nach
// sort_order, basis → 1., standard → 2., premium → 3. Preise werden nie
// gelesen.

import { REPORT_PAKETE } from '@/types'
import type { ReportPaket, TierPlan, TpEmpfehlung } from '@/types'

export function empfehlungAus(
  paket: ReportPaket | null | undefined,
  tiers: readonly TierPlan[],
): TpEmpfehlung | null {
  if (!paket) return null
  const aktiv = tiers.filter((t) => t.active).sort((a, b) => a.sort_order - b.sort_order)
  if (aktiv.length !== REPORT_PAKETE.length) {
    console.warn(
      `praesentation: expected ${REPORT_PAKETE.length} active tiers, got ${aktiv.length} — no recommendation`,
    )
    return null
  }
  const index = REPORT_PAKETE.indexOf(paket)
  if (index < 0) return null
  return {
    paket: aktiv[index].name,
    basis: index === 0 ? null : aktiv[0].name,
  }
}
