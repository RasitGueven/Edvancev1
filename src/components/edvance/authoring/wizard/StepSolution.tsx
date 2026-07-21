// Schritt 4 — LOESUNG & BELEG. Anzeige, keine Bearbeitung.
//
// Der Wizard prueft nur: passt die Loesung zum Item? Die Daten sind dieselben,
// die der Editor haelt (task_solution_get → FormState); der Beleg sind die
// read-only-Zitate aus task_solutions.beleg (B01). Korrigiert wird im
// Expertenmodus — der Link oeffnet den Editor in einem neuen Tab, damit die
// Warteschlange stehen bleibt.

import type { JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ExternalLink } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { buttonVariants } from '@/components/ui/button'
import type { GroundingBeleg } from '@/types'
import { BelegQuote } from '../BelegQuote'
import { isMultiPart, type FormState } from '../editorState'

function AnswerList({ answers }: { answers: string[] }): JSX.Element {
  const { t } = useTranslation('authoring')
  const filled = answers.filter((a) => a.trim() !== '')
  if (filled.length === 0) {
    return (
      <span className="text-sm text-[var(--color-text-tertiary)]">
        {t('wizard.solution.noAnswers')}
      </span>
    )
  }
  return (
    <div className="flex flex-wrap gap-2">
      {filled.map((a, i) => (
        <code
          key={i}
          className="rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-app)] px-2 py-1 font-[family-name:var(--font-mono,monospace)] text-sm text-[var(--color-text-primary)]"
        >
          {a}
        </code>
      ))}
    </div>
  )
}

export function StepSolution({
  taskId,
  state,
  beleg,
}: {
  taskId: string
  state: FormState
  /** Read-only-Zitate aus task_solutions.beleg — nie Teil des Formulars. */
  beleg: GroundingBeleg[]
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const multi = isMultiPart(state)

  return (
    <div className="flex flex-col gap-6">
      <EdvanceCard className="flex flex-col gap-4 p-6">
        <div className="flex flex-wrap items-center justify-between gap-2">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('wizard.solution.title')}
          </h3>
          <Link
            to={`/admin/authoring/${taskId}`}
            target="_blank"
            className={buttonVariants({ variant: 'outline', size: 'sm' })}
          >
            {t('wizard.solution.openEditor')}
            <ExternalLink className="h-3.5 w-3.5" aria-hidden="true" />
          </Link>
        </div>
        <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {t('wizard.solution.hint')}
        </p>

        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
            {t('wizard.solution.answers')}
          </span>
          {multi ? (
            <div className="flex flex-col gap-3">
              {state.parts.map((part) => (
                <div key={part.nr} className="flex flex-col gap-1">
                  <span className="text-xs text-[var(--color-text-tertiary)]">
                    {t('wizard.solution.partAnswers', { nr: part.nr })}
                  </span>
                  <AnswerList answers={state.partAnswers[String(part.nr)] ?? []} />
                </div>
              ))}
            </div>
          ) : (
            <AnswerList answers={state.answers} />
          )}
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
            {t('wizard.solution.solutionText')}
          </span>
          {state.solutionText.trim() !== '' ? (
            <p className="whitespace-pre-wrap text-sm leading-relaxed text-[var(--color-text-secondary)]">
              {state.solutionText}
            </p>
          ) : (
            <span className="text-sm text-[var(--color-text-tertiary)]">
              {t('wizard.solution.noSolutionText')}
            </span>
          )}
        </div>
      </EdvanceCard>

      {beleg.length > 0 && (
        <EdvanceCard className="flex flex-col gap-3 p-6">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('fields.solutionBeleg')}
          </h3>
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {t('fields.solutionBelegHint')}
          </p>
          <div className="flex flex-col gap-3 rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-4">
            {beleg.map((b, i) => (
              <BelegQuote key={i} beleg={b} />
            ))}
          </div>
        </EdvanceCard>
      )}
    </div>
  )
}
