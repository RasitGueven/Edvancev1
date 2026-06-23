import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { MessageCircle } from 'lucide-react'
import { OpenWidget } from '../OpenWidget'
import type { TaskAnswerInputProps } from './types'

// FREE_TEXT ist coach-bewertet (FernUSG / CLAUDE §6) — kein Auto-Check. Der
// dezente Hinweis macht transparent, dass der Coach das in der Session anschaut.
export function FreeTextInput({
  payload,
  answer,
  onChange,
  disabled,
}: TaskAnswerInputProps): JSX.Element | null {
  const { t } = useTranslation('student')
  if (payload.input_type !== 'FREE_TEXT') return null
  const value = answer?.input_type === 'FREE_TEXT' ? answer.text : ''
  return (
    <div className="flex flex-col gap-2">
      <OpenWidget
        value={value}
        onChange={(v) => onChange({ input_type: 'FREE_TEXT', text: v })}
        disabled={disabled}
      />
      <p className="inline-flex items-center gap-1.5 text-xs text-[var(--color-text-tertiary)]">
        <MessageCircle className="h-3.5 w-3.5" />
        {t('taskAnswer.coachGraded')}
      </p>
    </div>
  )
}
