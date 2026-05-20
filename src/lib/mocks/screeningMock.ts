// Frontend-Mocks für die Screening-Auswertungs-UI. Keine Supabase-Calls,
// keine RLS, kein Backend nötig — die Mock-Pages konsumieren diese Daten
// 1:1 und entsprechen so den echten Pages strukturell. Werte wurden so
// gewählt, dass alle Status-Zustände (Lücke / Erkennbar / Sicher, mit/
// ohne Pending) im Radar sichtbar werden.

import type {
  ParsedClusterResult,
  ParsedScreeningResult,
} from '@/lib/screening/screeningResult'

export type MockChild = {
  id: string
  fullName: string
  classLevel: number
  completedAt: string // ISO
  coachNote: string | null
}

export const MOCK_CLUSTERS: { id: string; name: string }[] = [
  { id: 'mock-cluster-zahl', name: 'Zahl & Rechnen' },
  { id: 'mock-cluster-funktion', name: 'Funktionaler Zusammenhang' },
  { id: 'mock-cluster-raum', name: 'Raum & Form' },
  { id: 'mock-cluster-daten', name: 'Daten & Zufall' },
  { id: 'mock-cluster-messen', name: 'Messen' },
]

export const MOCK_CLUSTER_NAMES: Map<string, string> = new Map(
  MOCK_CLUSTERS.map((c) => [c.id, c.name]),
)

const MOCK_CLUSTERS_DATA: ParsedClusterResult[] = [
  {
    clusterId: 'mock-cluster-zahl',
    answered: 6,
    correct: 5,
    pending: 0,
    estimatedLevel: 3,
    reachedAfb: 'III',
    mastery: 0.83,
    displayLevel: 9,
  },
  {
    clusterId: 'mock-cluster-funktion',
    answered: 5,
    correct: 3,
    pending: 1,
    estimatedLevel: 2,
    reachedAfb: 'II',
    mastery: 0.6,
    displayLevel: 6,
  },
  {
    clusterId: 'mock-cluster-raum',
    answered: 4,
    correct: 1,
    pending: 0,
    estimatedLevel: 1,
    reachedAfb: 'I',
    mastery: 0.25,
    displayLevel: 3,
  },
  {
    clusterId: 'mock-cluster-daten',
    answered: 5,
    correct: 4,
    pending: 1,
    estimatedLevel: 2,
    reachedAfb: 'II',
    mastery: 0.8,
    displayLevel: 7,
  },
  {
    clusterId: 'mock-cluster-messen',
    answered: 3,
    correct: 2,
    pending: 0,
    estimatedLevel: 2,
    reachedAfb: 'II',
    mastery: 0.66,
    displayLevel: 5,
  },
]

export const MOCK_PARSED_RESULT: ParsedScreeningResult = {
  answered: 23,
  clusters: MOCK_CLUSTERS_DATA,
  overallAnswered: MOCK_CLUSTERS_DATA.reduce((s, c) => s + c.answered, 0),
  overallCorrect: MOCK_CLUSTERS_DATA.reduce((s, c) => s + c.correct, 0),
  overallPending: MOCK_CLUSTERS_DATA.reduce((s, c) => s + c.pending, 0),
  overallPct: 72,
}

export const MOCK_CHILD: MockChild = {
  id: 'mock-child-1',
  fullName: 'Lina Demo',
  classLevel: 8,
  completedAt: '2026-05-14T15:42:00.000Z',
  coachNote:
    'Lina arbeitet konzentriert und kommt bei Routineaufgaben sehr gut zurecht. Bei Aufgaben zur Geometrie würde ich gemeinsam eine kleine Übungsrunde einplanen.',
}

export const MOCK_KPIS = {
  total: 23,
  autoGraded: 21,
  manualPending: 2,
  autoGradeRatePct: 91,
  medianDurationMs: 38_000,
}

export const MOCK_MEDIAN_BY_CLUSTER: Map<string, number> = new Map([
  ['mock-cluster-zahl', 28_000],
  ['mock-cluster-funktion', 52_000],
  ['mock-cluster-raum', 65_000],
  ['mock-cluster-daten', 31_000],
  ['mock-cluster-messen', 44_000],
])

export type MockPendingItem = {
  id: string
  clusterId: string
  prompt: string
  answer: string
}

export const MOCK_PENDING_ITEMS: MockPendingItem[] = [
  {
    id: 'mock-pending-1',
    clusterId: 'mock-cluster-funktion',
    prompt:
      'Beschreibe in eigenen Worten, was die Steigung einer linearen Funktion aussagt.',
    answer:
      'Wie steil die Linie nach oben oder unten geht, also wie schnell sich y verändert wenn x größer wird.',
  },
  {
    id: 'mock-pending-2',
    clusterId: 'mock-cluster-daten',
    prompt:
      'Erkläre den Unterschied zwischen Mittelwert und Median anhand der Zahlen 1, 2, 3, 4, 100.',
    answer:
      'Mittelwert ist 22, weil 110/5 = 22. Median ist 3 weil das die mittlere Zahl ist. Median ist hier besser weil 100 ein Ausreißer ist.',
  },
]
