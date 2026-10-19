// Eltern-Bericht R7 — die gemeinsamen Props aller fünf Seiten.
//
// Jede Seite bekommt dasselbe, damit R7-3 und R7-4 ihre Seiten bauen, ohne den
// Bogen anzufassen. Gerechnet wird einmal im Bogen, nicht je Seite.

import type { Bausteinsatz } from '@/lib/report/bausteine'
import type { Elternbericht, ReportData, ReportNotes, TierPlan } from '@/types'

export type SeitenProps = {
  data: ReportData
  bericht: Elternbericht
  satz: Bausteinsatz
  notes: ReportNotes | null
  tiers: TierPlan[]
  /** Rufname, getrimmt; null ohne Namen. */
  name: string | null
  /** genitiv(name) („Ilkays“); null ohne Namen. */
  wessen: string | null
}

/** Seitenzahl des Bogens (Fuß „n / 5“). */
export const SEITEN_GESAMT = 5

/** id des Schraffur-Patterns für Seite 2 (`fill="url(#…)"`). */
export const SCHRAFFUR_ID = 'eb-schraffur'
