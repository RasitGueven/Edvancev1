// Alles, was in task_solutions liegt: Musterloesung, gestufte Hinweise,
// Coach-Hinweise, typische Fehler.
//
// Nichts davon sieht das Kind waehrend der LSA. Die Musterloesung ist fuer Coach
// und Erklaerartikel, die typischen Fehler sind die diagnostische Substanz — sie
// stehen im _grounding der didaktischen Kommentierung und wollen von dort
// uebernommen werden, nicht erfunden.
//
// Coach-Hinweise: maximal drei (DB-CHECK). Wer mehr braucht, hat das Item nicht
// verstanden.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { X } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { TEXTAREA_MD } from '@/lib/formStyles'
import { AddButton, Field, IconButton, StringList } from './ui'
import type { FormState, Hint, TypicalError } from './editorState'

export function PedagogySection({
  state,
  set,
}: {
  state: FormState
  set: <K extends keyof FormState>(key: K, value: FormState[K]) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  return (
    <div className="flex flex-col gap-4">
      <Field label={t('fields.solutionText')}>
        <textarea
          className={`${TEXTAREA_MD} w-full`}
          value={state.solutionText}
          placeholder={t('fields.solutionTextPlaceholder')}
          onChange={(e) => set('solutionText', e.target.value)}
        />
      </Field>

      <Field label={t('fields.hints')}>
        <StringList
          values={state.hints.map((h) => h.text)}
          placeholder={t('fields.hintPlaceholder')}
          addLabel={t('fields.addHint')}
          removeLabel={t('fields.remove')}
          onChange={(texts) =>
            set(
              'hints',
              texts.map((text, i): Hint => ({ level: i + 1, text })),
            )
          }
        />
      </Field>

      <Field label={t('fields.coachHints')}>
        <StringList
          values={state.coachHints}
          placeholder={t('fields.coachHintPlaceholder')}
          addLabel={t('fields.addCoachHint')}
          removeLabel={t('fields.remove')}
          max={3}
          onChange={(next) => set('coachHints', next)}
        />
      </Field>

      <Field label={t('fields.typicalErrors')}>
        <div className="flex flex-col gap-3">
          {state.typicalErrors.map((entry, i) => (
            <div key={i} className="flex items-start gap-2">
              <div className="flex flex-1 flex-col gap-2">
                <Input
                  value={entry.error}
                  placeholder={t('fields.typicalErrorPlaceholder')}
                  onChange={(e) =>
                    set(
                      'typicalErrors',
                      state.typicalErrors.map(
                        (x, j): TypicalError =>
                          j === i ? { ...x, error: e.target.value } : x,
                      ),
                    )
                  }
                />
                <Input
                  value={entry.socratic_question ?? ''}
                  placeholder={t('fields.socraticPlaceholder')}
                  onChange={(e) =>
                    set(
                      'typicalErrors',
                      state.typicalErrors.map(
                        (x, j): TypicalError =>
                          j === i ? { ...x, socratic_question: e.target.value } : x,
                      ),
                    )
                  }
                />
              </div>
              <IconButton
                label={t('fields.remove')}
                onClick={() =>
                  set(
                    'typicalErrors',
                    state.typicalErrors.filter((_, j) => j !== i),
                  )
                }
              >
                <X className="h-4 w-4" />
              </IconButton>
            </div>
          ))}
          <AddButton
            label={t('fields.addTypicalError')}
            onClick={() => set('typicalErrors', [...state.typicalErrors, { error: '' }])}
          />
        </div>
      </Field>
    </div>
  )
}
