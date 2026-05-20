import { useMemo, type JSX } from 'react'
import type { ScreeningItem, ScreeningTeilaufgabe } from '@/types'
import type { RawAnswer } from '@/lib/screening/screeningRuntime'
import { isMcPayload } from '@/lib/screening/screeningRuntime'
import { MCWidget } from './MCWidget'
import { NumericWidget } from './NumericWidget'
import { OpenWidget } from './OpenWidget'
import { MultiStepWidget } from './MultiStepWidget'

export type TaskState = {
  mcIndex: number | null
  text: string
  steps: Record<string, string>
}

export const EMPTY_TASK_STATE: TaskState = {
  mcIndex: null,
  text: '',
  steps: {},
}

type Props = {
  item: ScreeningItem
  state: TaskState
  onChange: (next: TaskState) => void
  onEnter?: () => void
  disabled?: boolean
}

function resolveTeilaufgaben(item: ScreeningItem): ScreeningTeilaufgabe[] | null {
  const raw = item.teilaufgaben
  if (!Array.isArray(raw) || raw.length === 0) return null
  return raw
}

// Liefert den Antwort-Wert im Format, das `buildScreeningAnswer` erwartet.
export function buildRawAnswer(item: ScreeningItem, s: TaskState): RawAnswer {
  if (item.input_type === 'MC') return { kind: 'mc', index: s.mcIndex }
  if (item.input_type === 'NUMERIC') return { kind: 'numeric', value: s.text }
  if (resolveTeilaufgaben(item)) return { kind: 'multistep', steps: s.steps }
  return { kind: 'open', text: s.text }
}

// Ist die Antwort vollständig genug, dass „Weiter" sinnvoll ist?
// Bewusst tolerant: bei OPEN reicht nicht-leerer Text. Bei MULTI-STEP müssen
// alle Teilaufgaben befüllt sein, damit Coach/Auto-Grader vollständig
// bewerten können.
export function isAnswerReady(item: ScreeningItem, s: TaskState): boolean {
  if (item.input_type === 'MC') return s.mcIndex !== null
  const tas = resolveTeilaufgaben(item)
  if (tas) return tas.every((ta) => (s.steps[ta.key] ?? '').trim().length > 0)
  return s.text.trim().length > 0
}

export function TaskRenderer({ item, state, onChange, onEnter, disabled }: Props): JSX.Element {
  const teilaufgaben = useMemo(() => resolveTeilaufgaben(item), [item])

  if (item.input_type === 'MC' && isMcPayload(item.payload)) {
    return (
      <MCWidget
        options={item.payload.options}
        selected={state.mcIndex}
        onChange={(idx) => onChange({ ...state, mcIndex: idx })}
        disabled={disabled ?? false}
      />
    )
  }

  if (teilaufgaben) {
    return (
      <MultiStepWidget
        steps={teilaufgaben}
        values={state.steps}
        onChange={(key, value) =>
          onChange({ ...state, steps: { ...state.steps, [key]: value } })
        }
        kontext={item.kontext ?? null}
        disabled={disabled}
      />
    )
  }

  if (item.input_type === 'NUMERIC') {
    return (
      <NumericWidget
        value={state.text}
        onChange={(v) => onChange({ ...state, text: v })}
        onEnter={onEnter}
        disabled={disabled}
      />
    )
  }

  // OPEN (manuell) — auch der Fallback für unbekannte Typen, damit Schüler
  // wenigstens eine freie Antwort hinterlassen können.
  return (
    <OpenWidget
      value={state.text}
      onChange={(v) => onChange({ ...state, text: v })}
      kontext={item.kontext ?? null}
      disabled={disabled}
    />
  )
}
