// Das Freigabe-Gate: draft → review → ready.
//
// Nur der Uebergang nach 'ready' bringt das Item in den LSA-Pool (lsa_start zieht
// ausschliesslich status='ready'). Deshalb ist genau dieser eine Uebergang
// gesperrt, solange blockierende Punkte offen sind — die anderen nicht: "zur
// Pruefung geben" darf man ein halbfertiges Item, "freigeben" nicht.
//
// Das Gate hier ist die HOEFLICHE Version. Die verbindliche steht in
// task_status_set (SECURITY DEFINER): sie prueft dieselben Pflichtfelder noch
// einmal serverseitig und stempelt den Pruefer aus auth.uid(). Ein Frontend-Gate
// allein waere eine Bitte, keine Regel.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Lock, ShieldCheck } from 'lucide-react'
import { Button } from '@/components/ui/button'
import type { TaskStatus } from '@/types'
import { StatusBadge } from './ui'

export function ReleaseGate({
  status,
  blockingCount,
  dirty,
  busy,
  canWrite,
  hasAudit,
  reviewerName,
  reviewedAt,
  error,
  onSetStatus,
}: {
  status: TaskStatus
  blockingCount: number
  dirty: boolean
  busy: boolean
  canWrite: boolean
  hasAudit: boolean
  reviewerName: string | null
  reviewedAt: string | null
  error: string | null
  onSetStatus: (next: TaskStatus) => void
}): JSX.Element {
  const { t, i18n } = useTranslation('authoring')

  const blocked = blockingCount > 0
  // Ungespeicherte Aenderungen: die DB pruefte gegen den ALTEN Stand. Ein "ready",
  // das gegen einen Stand freigibt, den der Pfleger gerade verworfen hat, waere
  // ein falsch ausgestellter Stempel.
  const releaseDisabled = !canWrite || busy || blocked || dirty

  const formatDate = (iso: string): string =>
    new Intl.DateTimeFormat(i18n.language, {
      dateStyle: 'medium',
      timeStyle: 'short',
      timeZone: 'Europe/Berlin',
    }).format(new Date(iso))

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-2">
        <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
          {t('release.current')}
        </span>
        <StatusBadge status={status} label={t(`status.${status}`)} />
      </div>

      {status === 'ready' && (
        <div className="flex items-start gap-2 rounded-[var(--radius-md)] bg-[var(--color-success)]/10 p-3">
          <ShieldCheck className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-success)]" />
          <span className="text-xs leading-relaxed text-[var(--color-text-secondary)]">
            {!hasAudit
              ? t('release.noAudit')
              : reviewerName
                ? `${t('release.reviewedBy', { name: reviewerName })}${
                    reviewedAt ? ` ${t('release.reviewedAt', { date: formatDate(reviewedAt) })}` : ''
                  }`
                : t('release.noAudit')}
          </span>
        </div>
      )}

      <div className="flex flex-wrap gap-2">
        {status !== 'draft' && (
          <Button
            variant="outline"
            size="sm"
            disabled={!canWrite || busy}
            onClick={() => onSetStatus('draft')}
          >
            {t('release.toDraft')}
          </Button>
        )}
        {status !== 'review' && (
          <Button
            variant="outline"
            size="sm"
            disabled={!canWrite || busy}
            onClick={() => onSetStatus('review')}
          >
            {t('release.toReview')}
          </Button>
        )}
        {status !== 'ready' && (
          <Button size="sm" disabled={releaseDisabled} onClick={() => onSetStatus('ready')}>
            {blocked && <Lock className="mr-1 h-4 w-4" />}
            {t('release.toReady')}
          </Button>
        )}
      </div>

      <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
        {!canWrite
          ? t('release.adminOnly')
          : blocked
            ? t('release.blockedHint', { count: blockingCount })
            : dirty
              ? t('release.unsavedHint')
              : t('release.readyHint')}
      </p>

      {error && (
        <p className="text-xs leading-relaxed text-[var(--color-destructive)]">
          {t('release.failed', { error })}
        </p>
      )}
    </div>
  )
}
