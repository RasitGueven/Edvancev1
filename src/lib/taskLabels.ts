// Deutsche, sprechende Labels für Aufgaben-Enums. Eine Quelle, damit
// Admin-/Coach-Oberflächen nie rohe Codes (FACT, FREE_INPUT, Diff 3)
// zeigen. In UI immer diese Maps statt der Rohwerte rendern.

import type { CognitiveType, ContentType, InputType } from '@/types'

export const CONTENT_TYPE_LABELS: Record<ContentType, string> = {
  exercise: 'Übung',
  exercise_group: 'Übungsgruppe',
  article: 'Artikel',
  video: 'Video',
  course: 'Kurs',
}

export const INPUT_TYPE_LABELS: Record<InputType, string> = {
  MC: 'Multiple Choice',
  FREE_INPUT: 'Freie Eingabe',
  STEPS: 'Schritt für Schritt',
  MATCHING: 'Zuordnung',
  DRAW: 'Zeichnung',
}

export const COGNITIVE_TYPE_LABELS: Record<CognitiveType, string> = {
  FACT: 'Faktenwissen',
  TRANSFER: 'Transfer / Anwendung',
  ANALYSIS: 'Analyse / Problemlösen',
}

// Schwierigkeit 1–5 mit Klartext-Beschreibung.
export const DIFFICULTY_OPTIONS: { value: number; label: string }[] = [
  { value: 1, label: '1 – Sehr leicht' },
  { value: 2, label: '2 – Leicht' },
  { value: 3, label: '3 – Mittel' },
  { value: 4, label: '4 – Schwer' },
  { value: 5, label: '5 – Sehr schwer' },
]

export function inputTypeLabel(t: InputType | null | undefined): string {
  return t ? INPUT_TYPE_LABELS[t] : '–'
}

export function cognitiveTypeLabel(t: CognitiveType | null | undefined): string {
  return t ? COGNITIVE_TYPE_LABELS[t] : '–'
}

