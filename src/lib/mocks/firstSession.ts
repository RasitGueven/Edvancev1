/**
 * Mock-Daten für /mock/first-session — Schüler erste Session End-to-End.
 * Konvention wie screeningMock.ts: statische Exports, keine API-Aufrufe.
 * Strings hier sind Mock-Inhalte (Aufgabentexte, Cluster-Namen) — also
 * Daten, nicht UI-Strings. UI-Labels laufen über i18n (siehe student.json).
 */

import type { MasteryStage } from '@/lib/mastery'

export type MockMood = 'happy' | 'neutral' | 'low'

export interface MockTeacherTopic {
  id: string
  name: string
}

export type MockInputType = 'MC' | 'FREE_INPUT' | 'MATCHING' | 'STEPS' | 'COORDINATE'

export type MockTask =
  | MockTaskMC
  | MockTaskFreeInput
  | MockTaskMatching
  | MockTaskSteps
  | MockTaskCoordinate

interface MockTaskBase {
  id: string
  clusterId: string
  clusterName: string
  question: string
  xp: number
  difficulty: 'I' | 'II' | 'III'
  durationMin: number
  topicIds: string[]
}

/** Punkt im Koordinatensystem (Ganzzahl-Gitter). */
export interface MockPoint {
  x: number
  y: number
}

export interface MockTaskMC extends MockTaskBase {
  inputType: 'MC'
  options: string[]
  correctIndex: number
}

export interface MockTaskFreeInput extends MockTaskBase {
  inputType: 'FREE_INPUT'
  correctAnswer: string
}

export interface MockTaskMatching extends MockTaskBase {
  inputType: 'MATCHING'
  left: string[]
  right: string[]
  correctPairs: [number, number][]
}

export interface MockTaskSteps extends MockTaskBase {
  inputType: 'STEPS'
  steps: Array<{
    key: string
    prompt: string
    correctAnswer: string
  }>
}

export interface MockTaskCoordinate extends MockTaskBase {
  inputType: 'COORDINATE'
  /** Gerade = 2 Punkte; Parabel = Scheitelpunkt + 1 weiterer Punkt. */
  shape: 'line' | 'parabola'
  /** Beschriftungen der zu setzenden Punkte (UI-Hilfe). */
  pointLabels: string[]
  /** Start-Positionen der draggable Punkte. */
  initialPoints: MockPoint[]
  /** Zielpunkte — Reihenfolge-unabhängig validiert (ganzzahlig). */
  targetPoints: MockPoint[]
}

export interface MockClusterProgress {
  clusterId: string
  clusterName: string
  before: MasteryStage
  after: MasteryStage
  beforeScore: number
  afterScore: number
}

export interface MockHomeQuestTask {
  id: string
  title: string
  clusterName: string
  difficulty: 'I' | 'II' | 'III'
  durationMin: number
}

export const MOCK_STUDENT_FIRST_SESSION = {
  displayName: 'Lina',
  classLevel: 8,
  /** Fach kommt aus dem Schüler-Profil — wird nicht im Check-In abgefragt. */
  subject: 'Mathe',
  /** Pre-Session aus dem Screening abgeleitet (Mock). */
  startXp: 0,
  startLevel: 1,
}

export const MOCK_TEACHER_TOPICS: MockTeacherTopic[] = [
  { id: 'topic-bruch', name: 'Bruchrechnung' },
  { id: 'topic-prozent', name: 'Prozentrechnung' },
  { id: 'topic-linear', name: 'Lineare Funktionen' },
  { id: 'topic-geometrie', name: 'Geometrie & Winkel' },
  { id: 'topic-gleichung', name: 'Gleichungen lösen' },
]

export const MOCK_TODAY_TASKS: MockTask[] = [
  {
    id: 'mock-task-1',
    clusterId: 'mock-cluster-zahl',
    clusterName: 'Zahl & Rechnen',
    question: 'Was ist 3/4 + 1/8?',
    inputType: 'MC',
    options: ['4/12', '5/8', '7/8', '4/8'],
    correctIndex: 2,
    xp: 20,
    difficulty: 'II',
    durationMin: 5,
    topicIds: ['topic-bruch'],
  },
  {
    id: 'mock-task-2',
    clusterId: 'mock-cluster-zahl',
    clusterName: 'Zahl & Rechnen',
    question: 'Wie viel sind 15 % von 80? Gib die Antwort ein:',
    inputType: 'FREE_INPUT',
    correctAnswer: '12',
    xp: 20,
    difficulty: 'I',
    durationMin: 4,
    topicIds: ['topic-prozent'],
  },
  {
    id: 'mock-task-3',
    clusterId: 'mock-cluster-funktion',
    clusterName: 'Funktionaler Zusammenhang',
    question:
      'Ordne die Funktionsgleichungen ihren Steigungen zu:',
    inputType: 'MATCHING',
    left: ['f(x) = 2x + 3', 'f(x) = -x + 5', 'f(x) = 3x - 1'],
    right: ['Steigung 2', 'Steigung 3', 'Steigung -1'],
    correctPairs: [[0, 0], [1, 2], [2, 1]],
    xp: 30,
    difficulty: 'II',
    durationMin: 6,
    topicIds: ['topic-linear'],
  },
  {
    id: 'mock-task-4',
    clusterId: 'mock-cluster-raum',
    clusterName: 'Raum & Form',
    question: 'Bestimme die Winkelberechnung:',
    inputType: 'STEPS',
    steps: [
      {
        key: '1a',
        prompt: 'In einem Dreieck sind zwei Winkel 45° und 65°. Welche Winkelsumme haben diese?',
        correctAnswer: '110',
      },
      {
        key: '1b',
        prompt: 'Wie groß ist der dritte Winkel?',
        correctAnswer: '70',
      },
    ],
    xp: 25,
    difficulty: 'II',
    durationMin: 5,
    topicIds: ['topic-geometrie'],
  },
  {
    id: 'mock-task-5',
    clusterId: 'mock-cluster-gleichung',
    clusterName: 'Gleichungen lösen',
    question: 'Löse die Gleichung: 3x + 7 = 22',
    inputType: 'FREE_INPUT',
    correctAnswer: '5',
    xp: 25,
    difficulty: 'II',
    durationMin: 5,
    topicIds: ['topic-gleichung'],
  },
  {
    id: 'mock-task-6',
    clusterId: 'mock-cluster-funktion',
    clusterName: 'Funktionaler Zusammenhang',
    question: 'Zeichne die Gerade durch die Punkte P(−2|−1) und Q(2|3).',
    inputType: 'COORDINATE',
    shape: 'line',
    pointLabels: ['P', 'Q'],
    initialPoints: [
      { x: -3, y: 3 },
      { x: 3, y: -2 },
    ],
    targetPoints: [
      { x: -2, y: -1 },
      { x: 2, y: 3 },
    ],
    xp: 35,
    difficulty: 'II',
    durationMin: 6,
    topicIds: ['topic-linear'],
  },
  {
    id: 'mock-task-7',
    clusterId: 'mock-cluster-funktion',
    clusterName: 'Funktionaler Zusammenhang',
    question:
      'Die Parabel y = x² − 2: Setze den Scheitelpunkt S und einen weiteren Punkt P der Parabel.',
    inputType: 'COORDINATE',
    shape: 'parabola',
    pointLabels: ['S', 'P'],
    initialPoints: [
      { x: -3, y: 4 },
      { x: 3, y: 4 },
    ],
    targetPoints: [
      { x: 0, y: -2 },
      { x: 2, y: 2 },
    ],
    xp: 40,
    difficulty: 'III',
    durationMin: 7,
    topicIds: ['topic-linear'],
  },
]

/**
 * Wählt die Aufgaben für die Session.
 *
 * MOCK: Wir zeigen bewusst **alle Aufgaben-Typen** (MC, Eingabe, Zuordnen,
 * Schritte, Koordinaten), damit der Flow die volle Bandbreite demonstriert —
 * unabhängig von den gewählten Lehrer-Themen.
 *
 * TODO (Realdaten): Hier gehört ein adaptiver Selector hin, der die *nächste*
 * Aufgabe anhand von Mastery, Behavior-Snapshots und Lehrer-Themen bestimmt,
 * statt eine statische Liste auszugeben.
 */
export function selectTasksForSession(_topicIds: string[]): MockTask[] {
  // Eine Aufgabe pro Typ — kuratiert für den Demo-Walkthrough.
  const byType = new Map<MockInputType, MockTask>()
  for (const task of MOCK_TODAY_TASKS) {
    if (!byType.has(task.inputType)) byType.set(task.inputType, task)
  }
  // Beide Koordinaten-Varianten zusätzlich anhängen (Gerade + Parabel).
  const coordParabola = MOCK_TODAY_TASKS.find(
    (t) => t.inputType === 'COORDINATE' && t.shape === 'parabola',
  )
  const ordered = Array.from(byType.values())
  if (coordParabola && !ordered.includes(coordParabola)) ordered.push(coordParabola)
  return ordered
}

export const MOCK_CLUSTER_PROGRESS: MockClusterProgress[] = [
  {
    clusterId: 'mock-cluster-zahl',
    clusterName: 'Zahl & Rechnen',
    before: 'developing',
    after: 'progressing',
    beforeScore: 48,
    afterScore: 64,
  },
  {
    clusterId: 'mock-cluster-funktion',
    clusterName: 'Funktionaler Zusammenhang',
    before: 'introduced',
    after: 'developing',
    beforeScore: 30,
    afterScore: 46,
  },
]

export const MOCK_HOME_QUEST: MockHomeQuestTask[] = [
  {
    id: 'mock-home-1',
    title: 'Bruchrechnung üben',
    clusterName: 'Zahl & Rechnen',
    difficulty: 'I',
    durationMin: 8,
  },
  {
    id: 'mock-home-2',
    title: 'Lineare Funktionen zeichnen',
    clusterName: 'Funktionaler Zusammenhang',
    difficulty: 'II',
    durationMin: 10,
  },
]

/** Geschätzte Session-Dauer in Minuten, abhängig von ausgewählten Aufgaben. */
export function sessionMinutes(tasks: MockTask[]): number {
  return tasks.reduce((sum, t) => sum + t.durationMin, 0)
}

/**
 * Vergleicht gesetzte Punkte mit den Zielpunkten (reihenfolge-unabhängig,
 * auf Ganzzahl gerundet). Jeder Zielpunkt muss genau einmal getroffen sein.
 */
export function pointsMatchTarget(
  placed: MockPoint[],
  target: MockPoint[],
): boolean {
  if (placed.length !== target.length) return false
  const remaining = target.map((p) => ({ x: Math.round(p.x), y: Math.round(p.y) }))
  for (const p of placed) {
    const rx = Math.round(p.x)
    const ry = Math.round(p.y)
    const idx = remaining.findIndex((t) => t.x === rx && t.y === ry)
    if (idx === -1) return false
    remaining.splice(idx, 1)
  }
  return remaining.length === 0
}
