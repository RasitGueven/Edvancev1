import type {
  ScreeningAfb,
  ScreeningCheckType,
  ScreeningInputType,
  ScreeningItem,
  ScreeningItemInput,
  ScreeningLevel,
  ScreeningPhase,
  ScreeningTeilaufgabe,
} from '@/types'

// DRAW war ein Editor-Only-Alias (→ DB 'OPEN'). Seit Migration 042 ist
// COORDINATE ein kanonischer Wert; der Alias entfaellt.
export type EditorInputType = ScreeningInputType

export type EditorUsage = 'screening' | 'lernpfad' | 'beides'

export type FormState = {
  topic: string
  skill_code: string
  skill_label: string
  class_level: number
  level: ScreeningLevel
  curriculum_seq: string
  input_type: EditorInputType
  check_type: ScreeningCheckType
  afb: ScreeningAfb | ''
  phase: ScreeningPhase | ''
  prompt: string
  kontext: string
  payloadStr: string
  canonicalStr: string
  tolerance: string
  typical: string
  explanation: string
  teilaufgaben: ScreeningTeilaufgabe[]
  hint1: string
  hint2: string
  usage: EditorUsage
}

export const INPUT_TYPES: EditorInputType[] = [
  'MC',
  'NUMERIC',
  'MATCHING',
  'FREE_TEXT',
  'COORDINATE',
]

export const AFB_OPTIONS: ScreeningAfb[] = ['I', 'II', 'III']
export const PHASE_OPTIONS: ScreeningPhase[] = ['sprint', 'tiefe']
export const CHECK_TYPES: ScreeningCheckType[] = [
  'mc_index',
  'numeric',
  'matching_set',
  'normalized',
  'manual',
]

export function emptyState(): FormState {
  return {
    topic: '',
    skill_code: '',
    skill_label: '',
    class_level: 8,
    level: 1,
    curriculum_seq: '',
    input_type: 'MC',
    check_type: 'mc_index',
    afb: '',
    phase: '',
    prompt: '',
    kontext: '',
    payloadStr: '{\n  "options": [{ "text": "", "correct": true }]\n}',
    canonicalStr: '{}',
    tolerance: '',
    typical: '',
    explanation: '',
    teilaufgaben: [],
    hint1: '',
    hint2: '',
    usage: 'lernpfad',
  }
}

export function fromItem(item: ScreeningItem): FormState {
  return {
    topic: item.topic,
    skill_code: item.skill_code,
    skill_label: item.skill_label,
    class_level: item.class_level,
    level: item.level,
    curriculum_seq:
      item.curriculum_seq == null ? '' : String(item.curriculum_seq),
    input_type: item.input_type,
    check_type: item.check_type,
    afb: item.afb ?? '',
    phase: item.phase ?? '',
    prompt: item.prompt,
    kontext: item.kontext ?? '',
    payloadStr: JSON.stringify(item.payload ?? null, null, 2),
    canonicalStr: JSON.stringify(item.canonical, null, 2),
    tolerance: item.tolerance == null ? '' : String(item.tolerance),
    typical: item.typical_errors.join('\n'),
    explanation: item.explanation ?? '',
    teilaufgaben: item.teilaufgaben ?? [],
    hint1: '',
    hint2: '',
    usage: deriveUsage(item),
  }
}

function deriveUsage(item: ScreeningItem): EditorUsage {
  return item.afb && item.phase ? 'screening' : 'lernpfad'
}

export type ValidationError =
  | 'promptEmpty'
  | 'skillCodeMissing'
  | 'skillLabelMissing'
  | 'topicMissing'
  | 'openManualMismatch'
  | 'afbPhaseMismatch'

export function validate(s: FormState): ValidationError | null {
  if (!s.prompt.trim()) return 'promptEmpty'
  if (!s.skill_code.trim()) return 'skillCodeMissing'
  if (!s.skill_label.trim()) return 'skillLabelMissing'
  if (!s.topic.trim()) return 'topicMissing'
  // Cross-Constraint OPEN<=>manual ist mit Migration 042 entfallen: FREE_TEXT
  // darf jetzt sowohl auto (check_type=normalized) als auch coach (manual) sein.
  if ((s.afb === '') !== (s.phase === '')) return 'afbPhaseMismatch'
  return null
}

export function buildInput(
  s: FormState,
  clusterId: string,
  payload: unknown,
  canonical: unknown,
): ScreeningItemInput {
  return {
    cluster_id: clusterId,
    class_level: s.class_level,
    topic: s.topic.trim(),
    skill_code: s.skill_code.trim(),
    skill_label: s.skill_label.trim(),
    level: s.level,
    curriculum_seq:
      s.curriculum_seq.trim() === '' ? null : Number(s.curriculum_seq),
    input_type: s.input_type,
    prompt: s.prompt.trim(),
    payload,
    canonical,
    check_type: s.check_type,
    tolerance: s.tolerance.trim() === '' ? null : Number(s.tolerance),
    typical_errors: s.typical
      .split('\n')
      .map((t) => t.trim())
      .filter(Boolean),
    explanation: s.explanation.trim() === '' ? null : s.explanation.trim(),
    afb: s.afb === '' ? null : s.afb,
    phase: s.phase === '' ? null : s.phase,
    kontext: s.kontext.trim() === '' ? null : s.kontext.trim(),
    teilaufgaben: s.teilaufgaben.length === 0 ? null : s.teilaufgaben,
    akzeptierte_antworten: null,
  }
}

export function parsePayloadCanonical(
  s: FormState,
): { payload: unknown; canonical: unknown } | { error: true } {
  try {
    const payload =
      s.payloadStr.trim() === '' ? null : JSON.parse(s.payloadStr)
    const canonical = JSON.parse(s.canonicalStr)
    return { payload, canonical }
  } catch {
    return { error: true }
  }
}
