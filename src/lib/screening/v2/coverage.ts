import type { ScreeningAfb, ScreeningItem, ScreeningPhase } from '@/types'

export const AFB_VALUES: readonly ScreeningAfb[] = ['I', 'II', 'III'] as const
export const PHASE_VALUES: readonly ScreeningPhase[] = [
  'sprint',
  'tiefe',
] as const

// Pro (Cluster × Phase × AFB) wieviele AKTIVE v2-Items vorhanden sind.
// Items ohne afb oder phase zaehlen NICHT (Legacy/v1-Bestand, vgl. SCREENING_V2.md).
export type CoverageCell = {
  clusterId: string
  phase: ScreeningPhase
  afb: ScreeningAfb
  activeCount: number
  draftCount: number
}

export type CoverageMatrix = Map<string, CoverageCell>

const key = (
  clusterId: string,
  phase: ScreeningPhase,
  afb: ScreeningAfb,
): string => `${clusterId}|${phase}|${afb}`

export function buildCoverage(items: ScreeningItem[]): CoverageMatrix {
  const matrix: CoverageMatrix = new Map()
  for (const it of items) {
    if (!it.afb || !it.phase) continue
    const k = key(it.cluster_id, it.phase, it.afb)
    const existing = matrix.get(k) ?? {
      clusterId: it.cluster_id,
      phase: it.phase,
      afb: it.afb,
      activeCount: 0,
      draftCount: 0,
    }
    if (it.active) existing.activeCount += 1
    else existing.draftCount += 1
    matrix.set(k, existing)
  }
  return matrix
}

export function getCell(
  matrix: CoverageMatrix,
  clusterId: string,
  phase: ScreeningPhase,
  afb: ScreeningAfb,
): CoverageCell {
  return (
    matrix.get(key(clusterId, phase, afb)) ?? {
      clusterId,
      phase,
      afb,
      activeCount: 0,
      draftCount: 0,
    }
  )
}

// Ampel-Logik: rot < 1 aktiv, gelb 1, gruen >= 2 aktive Items pro Zelle.
// Schwelle 2 = pro Skill-Mix mindestens eine kleine Auswahl.
export type CoverageStatus = 'missing' | 'thin' | 'ok'

export function cellStatus(cell: CoverageCell): CoverageStatus {
  if (cell.activeCount === 0) return 'missing'
  if (cell.activeCount === 1) return 'thin'
  return 'ok'
}
