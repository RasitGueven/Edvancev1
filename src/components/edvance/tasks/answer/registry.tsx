import type { ComponentType, JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { CanonicalInputType } from '@/types'
import type { TaskAnswerInputProps } from './types'
import { MCInput } from './MCInput'
import { NumericInput } from './NumericInput'
import { ShortTextInput } from './ShortTextInput'
import { TrueFalseInput } from './TrueFalseInput'
import { FreeTextInput } from './FreeTextInput'
import { MatchingInput } from './MatchingInput'
import { ClozeInput } from './ClozeInput'
import { CoordinateInput } from './CoordinateInput'

// Geteilte Renderer-Registry: input_type → Input-Komponente. Eine Quelle, die
// QS-Tool, Lernpfad-Session und (künftig) Screening teilen.
export const ANSWER_REGISTRY: Record<CanonicalInputType, ComponentType<TaskAnswerInputProps>> = {
  MC: MCInput,
  NUMERIC: NumericInput,
  SHORT_TEXT: ShortTextInput,
  TRUE_FALSE: TrueFalseInput,
  FREE_TEXT: FreeTextInput,
  MATCHING: MatchingInput,
  CLOZE: ClozeInput,
  COORDINATE: CoordinateInput,
}

// Unbekannter/legacy Typ → sichtbarer Fallback statt stillem Bruch.
function Fallback({ type }: { type: string }): JSX.Element {
  const { t } = useTranslation('student')
  return (
    <div className="rounded-[var(--radius-lg)] border-2 border-dashed border-[var(--color-border)] p-4 text-sm text-[var(--color-text-tertiary)]">
      {t('taskAnswer.fallback', { type })}
    </div>
  )
}

// Dispatcher: wählt die Komponente nach payload.input_type. Robust gegen
// Schrott-/Bestandsdaten (unbekannter Typ → Fallback).
export function TaskAnswer({
  payload,
  answer,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element {
  const type = (payload as { input_type?: string } | null)?.input_type
  const Comp = type ? ANSWER_REGISTRY[type as CanonicalInputType] : undefined
  if (!Comp) return <Fallback type={String(type ?? 'unknown')} />
  return <Comp payload={payload} answer={answer} onChange={onChange} disabled={disabled} />
}
