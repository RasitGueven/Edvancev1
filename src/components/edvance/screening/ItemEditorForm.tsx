import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import type {
  ScreeningAfb,
  ScreeningCheckType,
  ScreeningInputType,
  ScreeningLevel,
  ScreeningPhase,
} from '@/types'

const SELECT_CLASS =
  'h-10 w-full rounded-xl border border-[var(--border)] bg-[var(--card)] px-2 text-sm'
const TEXTAREA_CLASS =
  'min-h-[80px] w-full rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 text-sm'
const JSON_CLASS =
  'min-h-[100px] w-full rounded-xl border border-[var(--border)] bg-[var(--card)] px-3 py-2 font-mono text-xs'

export const INPUT_TYPES: ScreeningInputType[] = [
  'MC',
  'NUMERIC',
  'MATCHING',
  'STEPS_FINAL',
  'OPEN',
]
export const CHECK_TYPES: ScreeningCheckType[] = [
  'mc_index',
  'numeric',
  'matching_set',
  'normalized',
  'manual',
]
export const AFB_OPTIONS: ScreeningAfb[] = ['I', 'II', 'III']
export const PHASE_OPTIONS: ScreeningPhase[] = ['sprint', 'tiefe']

export type FormState = {
  topic: string
  skill_code: string
  skill_label: string
  class_level: number
  level: ScreeningLevel
  curriculum_seq: string
  input_type: ScreeningInputType
  check_type: ScreeningCheckType
  afb: ScreeningAfb | ''
  phase: ScreeningPhase | ''
  prompt: string
  payloadStr: string
  canonicalStr: string
  tolerance: string
  typical: string
  explanation: string
}

export function ItemEditorForm({
  state,
  set,
}: {
  state: FormState
  set: <K extends keyof FormState>(k: K, v: FormState[K]) => void
}): JSX.Element {
  return (
    <div className="flex flex-col gap-3">
      <div className="grid grid-cols-2 gap-3">
        <Field label="skill_code">
          <Input
            value={state.skill_code}
            onChange={(e) => set('skill_code', e.target.value)}
          />
        </Field>
        <Field label="skill_label">
          <Input
            value={state.skill_label}
            onChange={(e) => set('skill_label', e.target.value)}
          />
        </Field>
        <Field label="topic">
          <Input
            value={state.topic}
            onChange={(e) => set('topic', e.target.value)}
          />
        </Field>
        <Field label="class_level">
          <Input
            type="number"
            min={5}
            max={13}
            value={state.class_level}
            onChange={(e) => set('class_level', Number(e.target.value))}
          />
        </Field>
        <Field label="level (1–3)">
          <select
            className={SELECT_CLASS}
            value={state.level}
            onChange={(e) =>
              set('level', Number(e.target.value) as ScreeningLevel)
            }
          >
            <option value={1}>1</option>
            <option value={2}>2</option>
            <option value={3}>3</option>
          </select>
        </Field>
        <Field label="curriculum_seq">
          <Input
            value={state.curriculum_seq}
            onChange={(e) => set('curriculum_seq', e.target.value)}
          />
        </Field>
        <Field label="AFB (v2)">
          <select
            className={SELECT_CLASS}
            value={state.afb}
            onChange={(e) => set('afb', e.target.value as ScreeningAfb | '')}
          >
            <option value="">— (Legacy)</option>
            {AFB_OPTIONS.map((a) => (
              <option key={a} value={a}>
                AFB {a}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Phase (v2)">
          <select
            className={SELECT_CLASS}
            value={state.phase}
            onChange={(e) =>
              set('phase', e.target.value as ScreeningPhase | '')
            }
          >
            <option value="">— (Legacy)</option>
            {PHASE_OPTIONS.map((p) => (
              <option key={p} value={p}>
                {p}
              </option>
            ))}
          </select>
        </Field>
        <Field label="input_type">
          <select
            className={SELECT_CLASS}
            value={state.input_type}
            onChange={(e) =>
              set('input_type', e.target.value as ScreeningInputType)
            }
          >
            {INPUT_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </Field>
        <Field label="check_type">
          <select
            className={SELECT_CLASS}
            value={state.check_type}
            onChange={(e) =>
              set('check_type', e.target.value as ScreeningCheckType)
            }
          >
            {CHECK_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </Field>
        <Field label="Toleranz (numeric)">
          <Input
            value={state.tolerance}
            onChange={(e) => set('tolerance', e.target.value)}
          />
        </Field>
      </div>
      <Field label="Frage / prompt">
        <textarea
          className={TEXTAREA_CLASS}
          value={state.prompt}
          onChange={(e) => set('prompt', e.target.value)}
        />
      </Field>
      <Field label="payload (JSON)">
        <textarea
          className={JSON_CLASS}
          value={state.payloadStr}
          onChange={(e) => set('payloadStr', e.target.value)}
        />
      </Field>
      <Field label="canonical (JSON)">
        <textarea
          className={JSON_CLASS}
          value={state.canonicalStr}
          onChange={(e) => set('canonicalStr', e.target.value)}
        />
      </Field>
      <Field label="Typische Fehler (eine pro Zeile)">
        <textarea
          className={TEXTAREA_CLASS}
          value={state.typical}
          onChange={(e) => set('typical', e.target.value)}
        />
      </Field>
      <Field label="Erklärung">
        <textarea
          className={TEXTAREA_CLASS}
          value={state.explanation}
          onChange={(e) => set('explanation', e.target.value)}
        />
      </Field>
    </div>
  )
}

function Field({
  label,
  children,
}: {
  label: string
  children: React.ReactNode
}): JSX.Element {
  return (
    <div className="flex flex-col gap-1.5">
      <Label className="text-xs font-semibold uppercase tracking-widest text-[var(--text-muted)]">
        {label}
      </Label>
      {children}
    </div>
  )
}
