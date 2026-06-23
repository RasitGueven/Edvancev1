// Gemeinsamer Vertrag der Renderer-Registry. Jede Input-Komponente bekommt das
// kanonische AnswerPayload + die bisherige StudentAnswer und meldet die
// strukturierte (nicht flache!) Antwort über onChange zurück. Die Registry-Map
// (registry.tsx) ist auf input_type gekeyt; <TaskAnswer> dispatcht.

import type { AnswerPayload, StudentAnswer } from '@/types'

export type TaskAnswerInputProps = {
  payload: AnswerPayload
  answer: StudentAnswer | null
  onChange: (answer: StudentAnswer) => void
  disabled?: boolean
}

// Leere Start-Antwort pro Typ — der Session-Flow initialisiert damit den State.
export function emptyAnswer(payload: AnswerPayload): StudentAnswer {
  switch (payload.input_type) {
    case 'MC':
      return { input_type: 'MC', selected: [] }
    case 'NUMERIC':
      return { input_type: 'NUMERIC', value: '' }
    case 'SHORT_TEXT':
      return { input_type: 'SHORT_TEXT', text: '' }
    case 'TRUE_FALSE':
      return { input_type: 'TRUE_FALSE', value: null }
    case 'FREE_TEXT':
      return { input_type: 'FREE_TEXT', text: '' }
    case 'MATCHING':
      return { input_type: 'MATCHING', pairs: [] }
    case 'CLOZE':
      return { input_type: 'CLOZE', blanks: {} }
    case 'COORDINATE':
      return { input_type: 'COORDINATE', points: [] }
  }
}

// Genug ausgefüllt, dass „prüfen" sinnvoll ist? Bewusst tolerant.
export function isAnswerReady(payload: AnswerPayload, answer: StudentAnswer | null): boolean {
  if (!answer || answer.input_type !== payload.input_type) return false
  switch (answer.input_type) {
    case 'MC':
      return answer.selected.length > 0
    case 'NUMERIC':
      return answer.value.trim().length > 0
    case 'SHORT_TEXT':
    case 'FREE_TEXT':
      return answer.text.trim().length > 0
    case 'TRUE_FALSE':
      return answer.value !== null
    case 'MATCHING':
      return payload.input_type === 'MATCHING' && answer.pairs.length === payload.left.length
    case 'CLOZE':
      return (
        payload.input_type === 'CLOZE' &&
        payload.blanks.every((b) => (answer.blanks[b.id] ?? '').trim().length > 0)
      )
    case 'COORDINATE':
      return (answer.points?.length ?? 0) > 0
  }
}
