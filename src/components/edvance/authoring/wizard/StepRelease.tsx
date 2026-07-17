// Schritt 5 — FREIGABE. Die Checkliste aus A04 (die blockierenden Flags,
// namentlich), dann die eine grosse Aktion:
//
//   admin  → "Freigeben"            (ready via task_status_set — wie im Editor)
//   coach  → "Als geprueft markieren" (review — schreiben darf laut RLS nur die
//                                      Status-RPC, freigeben bleibt admin-only)
//
// Blockiert etwas, haelt "Ueberspringen (spaeter)" den Fluss — das Item bleibt,
// wie es ist, und die Strecke geht weiter. Das Gate hier ist wie im Editor die
// HOEFLICHE Version; die verbindliche steht in task_status_set.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Circle, ShieldCheck } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { ItemFlag, TaskStatus } from '@/types'
import { StatusBadge } from '../ui'

export function StepRelease({
  status,
  blocking,
  busy,
  isAdmin,
  error,
  onRelease,
  onReview,
  onSkip,
  onNextItem,
}: {
  status: TaskStatus
  blocking: ItemFlag[]
  busy: boolean
  isAdmin: boolean
  error: string | null
  onRelease: () => void
  onReview: () => void
  onSkip: () => void
  /** Bereits freigegebene Items: einfach weiter, ohne Aktion und ohne Zaehler. */
  onNextItem: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const blocked = blocking.length > 0

  return (
    <EdvanceCard className="mx-auto flex w-full max-w-2xl flex-col gap-6 p-6">
      <div className="flex items-center justify-between gap-2">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('sections.release')}
        </h3>
        <StatusBadge status={status} label={t(`status.${status}`)} />
      </div>

      {status === 'ready' ? (
        <>
          <div className="flex items-start gap-2 rounded-[var(--radius-md)] bg-[var(--color-success)]/10 p-3">
            <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-success)]" />
            <span className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
              {t('wizard.release.alreadyReady')}
            </span>
          </div>
          <Button size="lg" onClick={onNextItem}>
            {t('wizard.next')}
          </Button>
        </>
      ) : blocked ? (
        <>
          <div className="flex flex-col gap-2 rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-4">
            <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              {t('release.checklistTitle')}
            </span>
            <ul className="flex flex-col gap-2">
              {blocking.map((f, i) => (
                <li key={`${f.code}-${i}`} className="flex items-start gap-2 text-sm leading-relaxed">
                  <Circle
                    className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-text-tertiary)]"
                    aria-hidden="true"
                  />
                  <span className="text-[var(--color-text-secondary)]">
                    {t(`flags.${f.code}`, f.vars)}
                  </span>
                </li>
              ))}
            </ul>
          </div>
          <Button size="lg" disabled={busy} onClick={onSkip}>
            {t('wizard.release.skip')}
          </Button>
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {t('wizard.release.blockedHint')}
          </p>
        </>
      ) : (
        <>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {isAdmin ? t('wizard.release.clear') : t('wizard.release.clearCoach')}
          </p>
          {isAdmin ? (
            <Button size="lg" disabled={busy} onClick={onRelease}>
              <ShieldCheck className="h-5 w-5" aria-hidden="true" />
              {t('wizard.release.release')}
            </Button>
          ) : (
            <Button size="lg" disabled={busy} onClick={onReview}>
              {t('wizard.release.review')}
            </Button>
          )}
          <button
            type="button"
            disabled={busy}
            onClick={onSkip}
            className="inline-flex min-h-[44px] items-center justify-center rounded-xl border border-[var(--color-border)] px-4 text-sm font-semibold text-[var(--color-text-secondary)] transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary)] disabled:opacity-40"
          >
            {t('wizard.release.skip')}
          </button>
        </>
      )}

      {error && (
        <p className="text-xs leading-relaxed text-[var(--color-destructive)]">
          {t('release.failed', { error })}
        </p>
      )}
    </EdvanceCard>
  )
}
