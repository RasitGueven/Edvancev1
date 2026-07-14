// Invariante: Die Vorschau zeigt, was das KIND sieht — und nichts sonst.
//
// Der Datenvertrag (P01 §4) haelt die Loesung serverseitig aus dem Payload heraus:
// lsa_question_payload BAUT das Payload aus einer Whitelist, statt ein bestehendes
// jsonb durchzukopieren. Diese Vorschau ist die Client-Seite derselben Zusage —
// und sie hat es leichter, sie zu brechen, weil hier Item UND Loesung im selben
// FormState liegen. Ein `{JSON.stringify(state)}` an der falschen Stelle, und die
// Loesung steht im DOM.
//
// Genau das prueft dieser Test: er fuellt jedes Geheimfeld mit einem eindeutigen
// Marker und behauptet, dass keiner davon gerendert wird. Er ueberlebt ein
// Refactoring der Komponente, das ein Snapshot nicht ueberleben wuerde.

import { describe, expect, it } from 'vitest'
import { render, screen } from '@testing-library/react'
import '@/i18n'
import { AuthoringPreview } from './AuthoringPreview'
import type { FormState } from './editorState'

const SECRETS = {
  answer: 'GEHEIM_ANTWORT_16',
  partAnswer: 'GEHEIM_TEILANTWORT_B',
  solution: 'GEHEIM_RECHENWEG',
  hint: 'GEHEIM_HINWEIS',
  coachHint: 'GEHEIM_COACHHINWEIS',
  typicalError: 'GEHEIM_TYPISCHER_FEHLER',
  socratic: 'GEHEIM_SOKRATISCH',
} as const

const flat: FormState = {
  title: 'Zwanzig Prozent',
  question: 'Berechne 20 % von 80 m.',
  input_type: 'SHORT_TEXT',
  unit: 'm',
  est_duration_sec: '120',
  afb: 'I',
  competency_content: 'arithmetik_algebra',
  competency_process: 'ope',
  cluster_id: 'c1',
  curriculum_grade: '7',
  parts: [],
  assets: [{ url: 'https://example.test/bild.png', alt: 'Ein Balkendiagramm' }],
  mcOptions: [],
  answers: [SECRETS.answer],
  partAnswers: {},
  solutionText: SECRETS.solution,
  hints: [{ level: 1, text: SECRETS.hint }],
  coachHints: [SECRETS.coachHint],
  typicalErrors: [{ error: SECRETS.typicalError, socratic_question: SECRETS.socratic }],
}

const multi: FormState = {
  ...flat,
  input_type: 'MULTI_PART',
  answers: [],
  parts: [
    { nr: 1, kind: 'short_input', prompt: 'Wie viel Prozent sind es?', unit: '%', afb: 'I' },
    {
      nr: 2,
      kind: 'mc',
      prompt: 'Welche Aussage stimmt?',
      afb: 'II',
      options: [
        { id: 'a', label: 'Der Anteil wächst.' },
        { id: 'b', label: 'Der Anteil fällt.' },
      ],
    },
  ],
  partAnswers: { '1': [SECRETS.answer], '2': [SECRETS.partAnswer] },
}

function renderedText(): string {
  return document.body.textContent ?? ''
}

describe('AuthoringPreview — kein Loesungsleck', () => {
  it('rendert bei einem flachen Item keines der Geheimfelder', () => {
    render(<AuthoringPreview state={flat} />)
    const text = renderedText()
    for (const secret of Object.values(SECRETS)) {
      expect(text).not.toContain(secret)
    }
  })

  it('rendert bei Multi-Part keine Teilloesung', () => {
    render(<AuthoringPreview state={multi} />)
    const text = renderedText()
    for (const secret of Object.values(SECRETS)) {
      expect(text).not.toContain(secret)
    }
  })

  it('zeigt keine Diagnostik-Metadaten (AFB, Kompetenz, Stoffanker)', () => {
    render(<AuthoringPreview state={flat} />)
    const text = renderedText()
    expect(text).not.toContain('arithmetik_algebra')
    expect(text).not.toContain('AFB')
  })
})

describe('AuthoringPreview — zeigt, was das Kind sieht', () => {
  it('rendert Stamm, Einheit und das Bild mit Alt-Text', () => {
    render(<AuthoringPreview state={flat} />)
    expect(screen.getByText(/Berechne 20 % von 80 m\./)).toBeInTheDocument()
    expect(screen.getByAltText('Ein Balkendiagramm')).toBeInTheDocument()
    expect(screen.getByText('m')).toBeInTheDocument()
  })

  it('rendert jede Teilaufgabe mit ihrer Frage und ihren MC-Optionen', () => {
    render(<AuthoringPreview state={multi} />)
    expect(screen.getByText(/Wie viel Prozent sind es\?/)).toBeInTheDocument()
    expect(screen.getByText(/Welche Aussage stimmt\?/)).toBeInTheDocument()
    expect(screen.getByText('Der Anteil wächst.')).toBeInTheDocument()
    expect(screen.getByText('Der Anteil fällt.')).toBeInTheDocument()
  })

  it('haelt die Eingabefelder inaktiv — die Vorschau prueft Layout, nicht Antworten', () => {
    render(<AuthoringPreview state={flat} />)
    expect(screen.getByPlaceholderText('Deine Antwort')).toBeDisabled()
  })
})
