// Schritt 4 — ABSCHLUSS. Oben, was noch blockiert (direkt setzbar, wo moeglich),
// darunter die Entscheidung. Der Status wechselt NUR hier — oeffnen und blaettern
// aendern nichts.
//
// Zwei Stufen (Migration 20260922100000):
//   Pruefer (coach mit darf_pruefen) → "Zur Freigabe" (review)
//   admin                             → "Freigeben" (ready), "Freigabe zuruecknehmen"
// Fuer beide: "Zurueckweisen" (beanstandet, mit Grund) und "Spaeter" (Status
// bleibt, gesetzte Angaben sind gespeichert).
//
// Das Gate hier ist die HOEFLICHE Version; die verbindliche steht in
// task_status_set und gilt fuer review wie fuer ready.

import type { JSX, ReactNode } from 'react'
import { useTranslation } from 'react-i18next'
import { ShieldCheck, Undo2 } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import type { BeanstandungsKategorie, TaskStatus } from '@/types'
import { StatusBadge } from '../ui'
import { RejectPanel } from './RejectPanel'

const SECONDARY =
  'inline-flex min-h-[44px] items-center justify-center gap-2 rounded-xl border border-[var(--color-border)] px-4 text-sm font-semibold text-[var(--color-text-secondary)] transition hover:border-[var(--color-primary)] hover:text-[var(--color-primary)] disabled:opacity-40'

export function StepRelease({
  status,
  isAdmin,
  canWrite,
  blocked,
  busy,
  error,
  rejectOpen,
  required,
  onPrimary,
  onRevoke,
  onToggleReject,
  onReject,
  onLater,
}: {
  status: TaskStatus
  isAdmin: boolean
  /** Pruefrecht fuer DIESE Aufgabe (bei 'ready' nur admin). */
  canWrite: boolean
  blocked: boolean
  busy: boolean
  error: string | null
  rejectOpen: boolean
  /** Die setzbaren Pflichtangaben (RequiredFields). */
  required: ReactNode
  /** admin: Freigeben; Pruefer: Zur Freigabe. */
  onPrimary: () => void
  /** ready → draft (admin) bzw. review → draft (Pruefer). */
  onRevoke: () => void
  onToggleReject: () => void
  onReject: (kategorie: BeanstandungsKategorie, notiz: string | null) => void
  onLater: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const done = status === 'ready' || (!isAdmin && status === 'review')

  return (
    <EdvanceCard className="mx-auto flex w-full max-w-2xl flex-col gap-6 p-6">
      <div className="flex items-center justify-between gap-2">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('wizard.steps.release')}
        </h3>
        <StatusBadge status={status} label={t(`status.${status}`)} />
      </div>

      {!canWrite && (
        <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
          {status === 'ready' ? t('wizard.release.alreadyReady') : t('wizard.release.noRight')}
        </p>
      )}

      {canWrite && !done && required}

      {canWrite && done && (
        <div className="flex items-start gap-2 rounded-[var(--radius-md)] bg-[var(--color-success)]/10 p-3">
          <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-success)]" />
          <span className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {status === 'ready' ? t('wizard.release.alreadyReady') : t('wizard.release.alreadyReview')}
          </span>
        </div>
      )}

      <div className="flex flex-wrap items-center gap-2">
        {canWrite && !done && (
          <Button
            size="lg"
            disabled={busy || blocked}
            title={blocked ? t('wizard.release.blockedTooltip') : undefined}
            onClick={onPrimary}
          >
            <ShieldCheck className="h-5 w-5" aria-hidden="true" />
            {isAdmin ? t('wizard.release.release') : t('wizard.release.toReview')}
          </Button>
        )}
        {canWrite && done && (
          <button type="button" disabled={busy} onClick={onRevoke} className={SECONDARY}>
            <Undo2 className="h-4 w-4" aria-hidden="true" />
            {status === 'ready' ? t('wizard.release.revoke') : t('wizard.release.revokeReview')}
          </button>
        )}
        {canWrite && (isAdmin || status !== 'ready') && (
          <button
            type="button"
            disabled={busy}
            onClick={onToggleReject}
            aria-expanded={rejectOpen}
            className={SECONDARY}
          >
            {t('wizard.release.reject')}
          </button>
        )}
        <button type="button" disabled={busy} onClick={onLater} className={SECONDARY}>
          {done || !canWrite ? t('wizard.next') : t('wizard.release.later')}
        </button>
        {canWrite && (
          <span className="ml-auto text-xs text-[var(--color-text-tertiary)]">
            {t('wizard.release.keys')}
          </span>
        )}
      </div>

      {canWrite && !done && blocked && (
        <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {t('wizard.release.blockedHint')}
        </p>
      )}

      {canWrite && rejectOpen && (isAdmin || status !== 'ready') && (
        <RejectPanel busy={busy} onReject={onReject} />
      )}

      {error && (
        <p className="text-xs leading-relaxed text-[var(--color-destructive)]">
          {t('release.failed', { error })}
        </p>
      )}
    </EdvanceCard>
  )
}
