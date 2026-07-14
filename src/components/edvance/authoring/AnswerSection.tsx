// Antwort und Loesung eines FLACHEN Items (kein Multi-Part).
//
// Die akzeptierten Antworten werden von lsa_is_correct gegen die Eingabe des
// Kindes geprueft — nach lsa_normalize_answer: trimmen, Whitespace kollabieren,
// ERSTES Komma zu Punkt, lowercase. Praktisch heisst das:
//   - "0,95" und "0.95" sind dasselbe. Beide einzutragen ist unnoetig.
//   - "500 000" und "500000" sind NICHT dasselbe (Whitespace wird kollabiert,
//     nicht entfernt). Beide Schreibweisen gehoeren rein.
//   - Die Einheit wird nicht umgerechnet: steht unit='m' und die Antwort '16',
//     dann geht '160' nicht durch — aber '16' auch dann, wenn das Kind Zentimeter
//     meinte. Die Einheit ist Anzeige, keine Pruefung.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import type { PartOption } from '@/types'
import { Field, StringList } from './ui'
import type { FormState } from './editorState'

export function AnswerSection({
  state,
  set,
}: {
  state: FormState
  set: <K extends keyof FormState>(key: K, value: FormState[K]) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  return (
    <div className="flex flex-col gap-4">
      {state.input_type === 'MC' ? (
        <Field label={t('fields.mcOptions')}>
          <StringList
            values={state.mcOptions.map((o) => o.label)}
            placeholder={t('fields.optionPlaceholder')}
            addLabel={t('fields.addOption')}
            removeLabel={t('fields.remove')}
            onChange={(labels) =>
              set(
                'mcOptions',
                labels.map((label, i): PartOption => ({
                  id: state.mcOptions[i]?.id ?? String.fromCharCode(97 + i),
                  label,
                })),
              )
            }
          />
        </Field>
      ) : (
        <Field label={t('fields.unit')}>
          <Input
            value={state.unit}
            placeholder={t('fields.unitPlaceholder')}
            onChange={(e) => set('unit', e.target.value)}
          />
        </Field>
      )}

      <Field
        label={t('fields.correctAnswers')}
        hint={state.input_type === 'MC' ? undefined : t('fields.answersHint')}
      >
        <StringList
          values={state.answers}
          placeholder={t('fields.answerPlaceholder')}
          addLabel={t('fields.addAnswer')}
          removeLabel={t('fields.remove')}
          onChange={(next) => set('answers', next)}
        />
      </Field>
    </div>
  )
}
