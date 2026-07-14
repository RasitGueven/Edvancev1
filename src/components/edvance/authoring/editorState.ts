// Der Formularzustand des Autoren-Tools — und die Uebersetzung von/zu der DB.
//
// Eine Eigenheit, die hier sichtbar bleiben soll: das Item wohnt in ZWEI Tabellen.
// Der oeffentliche Teil (Stamm, Teilaufgaben, Tags, Assets) in `tasks`, die Loesung
// in `task_solutions` — erreichbar nur ueber RPCs (P01 §4). Der FormState haelt
// beides zusammen, `toPatch`/`toSolution` trennen es wieder. Es gibt keine
// Transaktion ueber beide Schreibpfade; der Editor speichert deshalb erst die
// Aufgabe, dann die Loesung, und meldet, wenn der zweite Schritt scheitert.
//
// `draftTask`/`draftSolution` bauen aus dem Formular das, was gespeichert WUERDE.
// Vorschau und Flags laufen darueber — sie zeigen den ungespeicherten Stand, nicht
// den letzten Server-Stand. Sonst prueft der Pfleger gegen etwas, das er gerade
// geaendert hat.

import type {
  Afb,
  AuthoringInputType,
  AuthoringTask,
  AuthoringTaskPatch,
  PartOption,
  SolutionAnswers,
  TaskAsset,
  TaskPart,
  TaskSolution,
} from '@/types'

export type Hint = { level?: number; text: string }
export type TypicalError = { error: string; socratic_question?: string }

export type FormState = {
  title: string
  question: string
  input_type: AuthoringInputType | ''
  unit: string
  est_duration_sec: string
  afb: Afb | ''
  competency_content: string
  competency_process: string
  cluster_id: string
  /** Stoffanker. Leerstring = nicht gesetzt. */
  curriculum_grade: string
  parts: TaskPart[]
  assets: TaskAsset[]
  /** Optionen bei flachem MC (liegen in tasks.question_payload.options). */
  mcOptions: PartOption[]
  /** Akzeptierte Antworten bei flachem Item. */
  answers: string[]
  /** Akzeptierte Antworten je Teilaufgabe: { "1": ["20"] }. */
  partAnswers: Record<string, string[]>
  solutionText: string
  hints: Hint[]
  coachHints: string[]
  typicalErrors: TypicalError[]
}

export const INPUT_TYPES: AuthoringInputType[] = [
  'SHORT_TEXT',
  'NUMERIC',
  'MC',
  'MULTI_PART',
]

export const AFB_VALUES: Afb[] = ['I', 'II', 'III']
export const GRADES: number[] = [5, 6, 7, 8, 9, 10, 11, 12, 13]

export const isMultiPart = (s: FormState): boolean => s.input_type === 'MULTI_PART'

function optionsFromPayload(payload: unknown): PartOption[] {
  if (!payload || typeof payload !== 'object') return []
  const opts = (payload as { options?: unknown }).options
  return Array.isArray(opts) ? (opts as PartOption[]) : []
}

function splitAnswers(answers: SolutionAnswers): {
  flat: string[]
  byPart: Record<string, string[]>
} {
  if (Array.isArray(answers)) return { flat: answers, byPart: {} }
  return { flat: [], byPart: answers }
}

export function fromTask(task: AuthoringTask, solution: TaskSolution): FormState {
  const { flat, byPart } = splitAnswers(solution.correct_answers)
  return {
    title: task.title ?? '',
    question: task.question ?? '',
    input_type: task.input_type ?? '',
    unit: task.unit ?? '',
    est_duration_sec: task.est_duration_sec != null ? String(task.est_duration_sec) : '',
    afb: task.afb ?? '',
    competency_content: task.competency_content ?? '',
    competency_process: task.competency_process ?? '',
    cluster_id: task.cluster_id ?? '',
    curriculum_grade: task.curriculum_grade != null ? String(task.curriculum_grade) : '',
    parts: task.parts.map((p) => ({ ...p })),
    assets: task.assets.map((a) => ({ ...a })),
    mcOptions: optionsFromPayload(task.question_payload),
    answers: flat,
    partAnswers: byPart,
    solutionText: solution.solution ?? '',
    hints: solution.hints.map((h) => ({ ...h })),
    coachHints: [...solution.coach_hints],
    typicalErrors: solution.typical_errors.map((e) => ({ ...e })),
  }
}

const nullIfBlank = (s: string): string | null => (s.trim() === '' ? null : s.trim())
const intOrNull = (s: string): number | null => {
  const n = Number.parseInt(s, 10)
  return Number.isFinite(n) ? n : null
}

/** Was an `tasks` geht. Der Status ist NICHT dabei — der laeuft ueber das Gate. */
export function toPatch(state: FormState): AuthoringTaskPatch {
  const multi = isMultiPart(state)
  return {
    title: nullIfBlank(state.title),
    question: nullIfBlank(state.question),
    input_type: state.input_type === '' ? null : state.input_type,
    unit: nullIfBlank(state.unit),
    est_duration_sec: intOrNull(state.est_duration_sec),
    // Bei Multi-Part traegt die Teilaufgabe AFB und Kompetenz (P02) — am Item
    // waeren sie eine zweite, konkurrierende Wahrheit.
    afb: multi ? null : state.afb === '' ? null : state.afb,
    competency_content: multi ? null : nullIfBlank(state.competency_content),
    competency_process: multi ? null : nullIfBlank(state.competency_process),
    curriculum_grade: intOrNull(state.curriculum_grade),
    // tasks_multipart_check verlangt parts = '[]' bei flachen Items.
    parts: multi ? normalizeParts(state.parts) : [],
    assets: state.assets.filter((a) => a.url.trim() !== ''),
    question_payload:
      state.input_type === 'MC'
        ? { input_type: 'MC', options: state.mcOptions.filter((o) => o.label.trim() !== '') }
        : null,
  }
}

/** Nummern luecklos und aufsteigend — lsa_parts_valid verlangt eindeutige nr >= 1. */
export function normalizeParts(parts: TaskPart[]): TaskPart[] {
  return parts.map((part, i) => {
    const clean: TaskPart = {
      nr: i + 1,
      kind: part.kind,
      prompt: part.prompt.trim(),
      afb: part.afb ?? null,
      competency_content: nullIfBlank(part.competency_content ?? ''),
      competency_process: nullIfBlank(part.competency_process ?? ''),
      unit: nullIfBlank(part.unit ?? ''),
    }
    if (part.kind === 'mc') {
      clean.options = (part.options ?? []).filter((o) => o.label.trim() !== '')
    }
    return clean
  })
}

/**
 * Was an task_solution_upsert geht. Die RPC ersetzt ALLE Felder bei jedem Aufruf —
 * hier steht deshalb immer das vollstaendige Objekt, nie ein Patch.
 *
 * Die Antwortform folgt dem input_type der TASK, nicht dem, was gerade im State
 * liegt: flach → Array, Multi-Part → { "<nr>": [...] } (P02, lsa_answers_valid).
 */
export function toSolution(state: FormState): Omit<TaskSolution, 'exists' | 'updated_at'> {
  const multi = isMultiPart(state)
  const clean = (arr: string[]): string[] => arr.map((a) => a.trim()).filter((a) => a !== '')

  let correct: SolutionAnswers
  if (multi) {
    const byPart: Record<string, string[]> = {}
    normalizeParts(state.parts).forEach((part) => {
      const answers = clean(state.partAnswers[String(part.nr)] ?? [])
      if (answers.length > 0) byPart[String(part.nr)] = answers
    })
    correct = byPart
  } else {
    correct = clean(state.answers)
  }

  return {
    correct_answers: correct,
    solution: nullIfBlank(state.solutionText),
    hints: state.hints
      .filter((h) => h.text.trim() !== '')
      .map((h, i) => ({ level: h.level ?? i + 1, text: h.text.trim() })),
    coach_hints: clean(state.coachHints).slice(0, 3),
    typical_errors: state.typicalErrors
      .filter((e) => e.error.trim() !== '')
      .map((e) => ({
        error: e.error.trim(),
        ...(e.socratic_question?.trim() ? { socratic_question: e.socratic_question.trim() } : {}),
      })),
  }
}

/** Das Item, wie es nach dem Speichern aussaehe — Grundlage fuer Flags + Vorschau. */
export function draftTask(state: FormState, base: AuthoringTask): AuthoringTask {
  const patch = toPatch(state)
  return {
    ...base,
    ...patch,
    parts: patch.parts ?? [],
    assets: patch.assets ?? [],
    // `undefined` heisst "Spalte gibt es nicht" — das darf toPatch nicht ueberschreiben.
    curriculum_grade:
      base.curriculum_grade === undefined ? undefined : (patch.curriculum_grade ?? null),
  }
}

export function draftSolution(state: FormState): TaskSolution {
  return { ...toSolution(state), exists: true }
}
