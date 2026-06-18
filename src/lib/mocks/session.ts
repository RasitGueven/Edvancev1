/**
 * Mock-Daten für die Vor-Ort-Session (Tablet) — `/mock/session`.
 *
 * In-Memory only, kein Supabase, kein Netzwerk (Build-Auftrag §1/§11).
 * Aufgaben-Prompts, Optionen, Hinweise und Coach-Notiz sind simulierte
 * "DB-Inhalte" und bleiben bewusst als deutsche Strings hier (CLAUDE.md §12:
 * User-/DB-Content gehört nicht in die i18n-Schicht). UI-Chrome dagegen
 * läuft über das `mock`-Namespace.
 */
import type { BadgeForm, BadgeRarity } from '@/components/edvance/RarityBadge'

/* ─── Aufgaben (JSON-Stub, gestaffelt AFB I → III) ───────────────────────────── */

export type Afb = 'I' | 'II' | 'III'

interface SessionTaskBase {
  id: string
  /** Anforderungsbereich — steuert die Staffelung leicht → schwer. */
  afb: Afb
  /** Aufgabentext (simulierter DB-Content). */
  prompt: string
  /** Gestufte Hinweise: erst Denkanstoß, dann konkreter, nie die Lösung. */
  hints: string[]
  /** Basis-XP (vor Presence-Multiplikator). */
  xp: number
}

export interface SessionTaskMC extends SessionTaskBase {
  kind: 'mc'
  options: string[]
  correctIndex: number
}

export interface SessionTaskNumeric extends SessionTaskBase {
  kind: 'numeric'
  answer: number
  tolerance: number
  unit?: string
}

export interface SessionTaskCoordinate extends SessionTaskBase {
  kind: 'coordinate'
  shape: 'line' | 'parabola'
  pointLabels: string[]
  initialPoints: { x: number; y: number }[]
  targetPoints: { x: number; y: number }[]
  /** Erlaubte Abweichung pro Koordinate beim Vergleich. */
  tolerance: number
}

export type SessionTask =
  | SessionTaskMC
  | SessionTaskNumeric
  | SessionTaskCoordinate

/**
 * Beispiel-Session: Mathematik, Klasse 9, „Lineare Funktionen".
 * Sieben Aufgaben, AFB I → III, eine echte JSXGraph-Koordinatenaufgabe.
 */
export const MOCK_SESSION_TASKS: SessionTask[] = [
  {
    id: 'lf-1',
    kind: 'mc',
    afb: 'I',
    prompt: 'Welche Gleichung beschreibt eine lineare Funktion?',
    options: ['y = x² + 1', 'y = 2x + 3', 'y = 1 / x', 'y = √x'],
    correctIndex: 1,
    hints: [
      'Linear heißt: konstante Steigung, eine Gerade.',
      'Suche die Form y = m·x + b ohne Hochzahlen oder Wurzeln.',
    ],
    xp: 20,
  },
  {
    id: 'lf-2',
    kind: 'numeric',
    afb: 'I',
    prompt: 'Die Gerade y = 3x − 5 schneidet die y-Achse bei welchem Wert?',
    answer: -5,
    tolerance: 0.01,
    hints: [
      'Der y-Achsenabschnitt ist der Wert von y, wenn x = 0 ist.',
      'Setze x = 0 ein: y = 3·0 − 5.',
    ],
    xp: 25,
  },
  {
    id: 'lf-3',
    kind: 'numeric',
    afb: 'II',
    prompt:
      'Eine Gerade verläuft durch P(0|1) und Q(2|7). Wie groß ist die Steigung m?',
    answer: 3,
    tolerance: 0.01,
    hints: [
      'Steigung = Höhenunterschied geteilt durch Schrittweite.',
      'm = (7 − 1) / (2 − 0).',
    ],
    xp: 30,
  },
  {
    id: 'lf-4',
    kind: 'mc',
    afb: 'II',
    prompt: 'Welche Gerade ist steiler?',
    options: ['y = 0,5x + 4', 'y = 2x − 1', 'Beide gleich', 'Lässt sich nicht sagen'],
    correctIndex: 1,
    hints: [
      'Je größer der Betrag der Steigung m, desto steiler.',
      'Vergleiche 0,5 mit 2.',
    ],
    xp: 30,
  },
  {
    id: 'lf-5',
    kind: 'numeric',
    afb: 'II',
    prompt:
      'Bei welchem x-Wert hat die Gerade y = 2x − 6 ihre Nullstelle (y = 0)?',
    answer: 3,
    tolerance: 0.01,
    hints: [
      'An der Nullstelle ist y = 0.',
      'Löse 0 = 2x − 6 nach x auf.',
    ],
    xp: 35,
  },
  {
    id: 'lf-6',
    kind: 'coordinate',
    afb: 'III',
    prompt:
      'Zeichne die Gerade y = x + 1: Zieh die beiden Punkte P und Q auf passende Gitterpunkte.',
    shape: 'line',
    pointLabels: ['P', 'Q'],
    initialPoints: [
      { x: -2, y: 0 },
      { x: 2, y: 0 },
    ],
    targetPoints: [
      { x: 0, y: 1 },
      { x: 3, y: 4 },
    ],
    tolerance: 0.6,
    hints: [
      'Setze zuerst den y-Achsenabschnitt: bei x = 0 ist y = 1.',
      'Pro Schritt nach rechts geht es eins nach oben (m = 1).',
    ],
    xp: 40,
  },
  {
    id: 'lf-7',
    kind: 'mc',
    afb: 'III',
    prompt:
      'Ein Taxi kostet 4 € Grundpreis plus 2 € pro km. Welche Funktion beschreibt den Preis y bei x Kilometern?',
    options: ['y = 4x + 2', 'y = 2x + 4', 'y = 6x', 'y = 2x − 4'],
    correctIndex: 1,
    hints: [
      'Der feste Grundpreis ist der y-Achsenabschnitt b.',
      'Der Preis pro km ist die Steigung m. Setze in y = m·x + b ein.',
    ],
    xp: 40,
  },
]

/* ─── Thema & Mastery (Kompetenz-Score 0–100, Coach-granted-Flag) ────────────── */

export interface MockTopic {
  id: string
  name: string
  /** Stand zu Session-Beginn (für die Wachstums-Animation in Screen 7). */
  startScore: number
  /** Stand nach der Session. */
  score: number
  /**
   * Mastered wird NIE vom Mock berechnet, sondern ausschließlich über dieses
   * Flag visualisiert (Hard Rule §6 — Coach gewährt vor Ort).
   */
  coachGranted: boolean
}

export const MOCK_SESSION_TOPIC: MockTopic = {
  id: 'lineare-funktionen',
  name: 'Lineare Funktionen',
  startScore: 64,
  score: 88,
  coachGranted: true,
}

export interface MockCheckpoint {
  id: string
  label: string
}

export const MOCK_SESSION_CHECKPOINTS: MockCheckpoint[] = [
  { id: 'cp-1', label: 'Steigung und y-Achsenabschnitt ablesen' },
  { id: 'cp-2', label: 'Geraden zeichnen und Nullstellen finden' },
  { id: 'cp-3', label: 'Sachaufgaben in eine Funktion übersetzen' },
]

/* ─── Skill-Tree (Screen 9): vier Zustände ───────────────────────────────────── */

export type SkillNodeStatus = 'mastered' | 'in-progress' | 'locked' | 'unknown'

export interface SkillNode {
  id: string
  name: string
  shortLabel: string
  status: SkillNodeStatus
  /** Nur bei mastered/in-progress gesetzt (Kompetenz-Score 0–100). */
  score?: number
  /** Mastered-Anzeige nur mit Coach-Bestätigung (Hard Rule §6). */
  coachGranted?: boolean
}

export const MOCK_SKILL_TREE: SkillNode[] = [
  {
    id: 'sn-terme',
    name: 'Terme & Gleichungen',
    shortLabel: 'Terme',
    status: 'mastered',
    score: 92,
    coachGranted: true,
  },
  {
    id: 'sn-proportional',
    name: 'Proportionalität',
    shortLabel: 'Proportional',
    status: 'mastered',
    score: 90,
    coachGranted: true,
  },
  {
    id: 'sn-linear',
    name: 'Lineare Funktionen',
    shortLabel: 'Lineare Fkt.',
    status: 'in-progress',
    score: 88,
    // Bewusst false: zeigt, dass das System trotz Score ≥ 85 NICHT selbst
    // „Gemeistert" setzt — das gewährt nur der Coach vor Ort.
    coachGranted: false,
  },
  {
    id: 'sn-systeme',
    name: 'Lineare Gleichungssysteme',
    shortLabel: 'LGS',
    status: 'locked',
  },
  {
    id: 'sn-quadratisch',
    name: 'Quadratische Funktionen',
    shortLabel: 'Quadratisch',
    status: 'locked',
  },
  {
    id: 'sn-unknown',
    name: 'Trigonometrie',
    shortLabel: 'Trigonometrie',
    status: 'unknown',
  },
]

/* ─── Badges (Screen 10): earned / achievable-locked; hidden = ausgelassen ───── */

export type BadgeState = 'earned' | 'achievable-locked'

export interface MockBadge {
  id: string
  name: string
  form: BadgeForm
  rarity: BadgeRarity
  state: BadgeState
  /** Zeichen im Zentrum (earned). */
  icon: string
  /** Klassenhinweis für „in Reichweite, aber offen". */
  classHint?: number
}

/**
 * Hinweis: Badges anderer Klassenstufen sind hier bewusst NICHT enthalten
 * (PlayStation-Trophy-Logik: komplett verborgen, nicht nur abgedunkelt).
 */
export const MOCK_BADGES: MockBadge[] = [
  { id: 'bg-first', name: 'Erste Session', form: 'round', rarity: 'bronze', state: 'earned', icon: '🚀' },
  { id: 'bg-streak3', name: '3 Wochen am Stück', form: 'round', rarity: 'silver', state: 'earned', icon: '🔥' },
  { id: 'bg-focus', name: 'Voller Fokus', form: 'round', rarity: 'silver', state: 'earned', icon: '🎯' },
  { id: 'bg-linear', name: 'Geraden-Profi', form: 'round', rarity: 'gold', state: 'earned', icon: '📈' },
  { id: 'bg-grade9', name: 'Klasse 9 gemeistert', form: 'shield', rarity: 'platinum', state: 'earned', icon: '9' },
  {
    id: 'bg-boss',
    name: 'Boss-Bezwinger',
    form: 'round',
    rarity: 'gold',
    state: 'achievable-locked',
    icon: '★',
    classHint: 9,
  },
]

/* ─── Schüler:in & Coach ──────────────────────────────────────────────────────── */

export interface MockSessionStudent {
  displayName: string
  fullName: string
  grade: number
  subject: string
  durationMin: number
  startXp: number
  presenceWeeks: number
  homeSessions: number
  repairTokens: number
  coachName: string
  coachNote: string
  lastSessionNote: string
}

export const MOCK_SESSION_STUDENT: MockSessionStudent = {
  displayName: 'Mara',
  fullName: 'Mara Keller',
  grade: 9,
  subject: 'Mathematik',
  durationMin: 60,
  // Gewählt so, dass die Session sicher eine 500er-Level-Grenze überschreitet
  // (Level-Up-Demo, genau 1× pro Session).
  startXp: 1340,
  presenceWeeks: 4,
  homeSessions: 3,
  repairTokens: 2,
  coachName: 'Herr Demir',
  coachNote:
    'Mara, du hast heute die Steigung richtig stark erklärt. Beim Zeichnen warst du sicher – weiter so!',
  lastSessionNote: 'Steigung dreieckig hergeleitet',
}
