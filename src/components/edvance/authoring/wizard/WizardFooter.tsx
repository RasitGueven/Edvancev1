// Die Schritt-Navigation der Pflege-Strecke: Zurueck/Weiter, der Speicher-Stand
// und die Tastatur-Hinweise. Fest am unteren Rand — wie die SaveBar des Editors,
// nur dass "Weiter" hier das Speichern gleich mitbringt (Speichern pro Schritt).
//
// Auf dem Freigabe-Schritt gibt es kein "Weiter": dort entscheiden die grossen
// Aktionen der StepRelease (Freigeben / geprueft / ueberspringen).

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { ArrowLeft, ArrowRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import type { WizardStepId } from './wizardSteps'

export function WizardFooter({
  step,
  stepIndex,
  stepCount,
  dirty,
  busy,
  canWrite,
  error,
  onBack,
  onNext,
}: {
  step: WizardStepId
  stepIndex: number
  stepCount: number
  dirty: boolean
  busy: boolean
  canWrite: boolean
  error: string | null
  onBack: () => void
  onNext: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const isLast = step === 'release'

  return (
    <div className="fixed inset-x-0 bottom-0 z-20 border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-3 shadow-elevation-lg">
      <div className="mx-auto flex max-w-6xl flex-wrap items-center gap-x-4 gap-y-2">
        <div className="flex flex-col gap-0.5">
          <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
            {t('wizard.stepLabel', {
              pos: stepIndex + 1,
              total: stepCount,
              name: t(`wizard.steps.${step}`),
            })}
          </span>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('wizard.keyboardHint')}
          </span>
        </div>

        <span
          className={`flex items-center gap-2 text-xs font-semibold ${
            dirty ? 'text-[var(--color-gold-warning)]' : 'text-[var(--color-text-tertiary)]'
          }`}
        >
          <span
            className={`h-2 w-2 rounded-full ${
              dirty ? 'bg-[var(--color-gold-warning)]' : 'bg-[var(--color-success)]'
            }`}
          />
          {dirty ? t('save.dirty') : t('save.clean')}
        </span>

        {!canWrite && (
          <span className="text-xs text-[var(--color-text-tertiary)]">{t('save.readOnly')}</span>
        )}

        {error && (
          <span className="text-xs text-[var(--color-destructive)]">
            {t('save.failed', { error })}
          </span>
        )}

        <div className="ml-auto flex gap-2">
          <Button variant="outline" disabled={stepIndex === 0 || busy} onClick={onBack}>
            <ArrowLeft className="h-4 w-4" aria-hidden="true" />
            {t('wizard.back')}
          </Button>
          {!isLast && (
            <Button disabled={busy} onClick={onNext}>
              {busy ? t('save.saving') : t('wizard.next')}
              <ArrowRight className="h-4 w-4" aria-hidden="true" />
            </Button>
          )}
        </div>
      </div>
    </div>
  )
}
