/**
 * Mock-Daten für /mock/lernpfad — Mario-Style Level-Map.
 * Statische Exports wie die übrigen Mocks; Inhalte (Themen-Namen) sind Daten,
 * keine UI-Strings (UI-Labels laufen über i18n, siehe student.json → lernpfad).
 */

import type { MasteryStage } from '@/lib/mastery'

export type LevelStatus = 'done' | 'current' | 'locked'

export interface LearningPathNode {
  id: string
  /** Thema/Cluster, das dieses Level abdeckt. */
  clusterName: string
  /** Kurz-Label unter dem Knoten (1–2 Wörter). */
  shortLabel: string
  stage: MasteryStage
  status: LevelStatus
}

/**
 * Reihenfolge = Pfad-Reihenfolge (Level 1 unten/links bis Ziel oben/rechts).
 * „done" = gemeistert, „current" = aktueller Stopp, „locked" = noch gesperrt.
 */
export const MOCK_LEARNING_PATH: LearningPathNode[] = [
  {
    id: 'lvl-zahl',
    clusterName: 'Zahl & Rechnen',
    shortLabel: 'Grundrechnen',
    stage: 'mastered',
    status: 'done',
  },
  {
    id: 'lvl-bruch',
    clusterName: 'Bruchrechnung',
    shortLabel: 'Brüche',
    stage: 'proficient',
    status: 'done',
  },
  {
    id: 'lvl-prozent',
    clusterName: 'Prozentrechnung',
    shortLabel: 'Prozente',
    stage: 'progressing',
    status: 'current',
  },
  {
    id: 'lvl-gleichung',
    clusterName: 'Gleichungen lösen',
    shortLabel: 'Gleichungen',
    stage: 'developing',
    status: 'locked',
  },
  {
    id: 'lvl-linear',
    clusterName: 'Lineare Funktionen',
    shortLabel: 'Funktionen',
    stage: 'introduced',
    status: 'locked',
  },
  {
    id: 'lvl-geometrie',
    clusterName: 'Geometrie & Winkel',
    shortLabel: 'Geometrie',
    stage: 'introduced',
    status: 'locked',
  },
  {
    id: 'lvl-parabel',
    clusterName: 'Quadratische Funktionen',
    shortLabel: 'Parabeln',
    stage: 'introduced',
    status: 'locked',
  },
]
