// Eine Zeile der Content-Gesundheit — ein Item mit seinen Mängeln.
//
// Zeigt Titel, Status, die Mängel als knappe Marker (keine Badge-Pills) und — beim
// toten Bildpfad — den relativen Pfad samt Lizenzhinweis aus dem Grounding. Der
// Klick auf „Im Editor öffnen" springt in /admin/authoring/:id; „Bildpfad
// entfernen" schreibt über den Editor-Update-Pfad (updateAuthoringTask), löscht
// nichts im Bucket und ist idempotent.

import { useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, CheckCircle2 } from 'lucide-react'
import { EdvanceCard } from '@/components/edvance'
import { buttonVariants } from '@/components/ui/button'
import { DEFECT_ORDER, type HealthDefect, type ImageRefFinding } from '@/lib/authoring/health'
import type { AuthoringTask, TaskAsset } from '@/types'
import { StatusBadge } from './ui'

export type HealthItem = {
  task: AuthoringTask
  defects: Set<HealthDefect>
  dead: TaskAsset[]
  imageRef: ImageRefFinding | null
  licenseStatus: string | null
  licenseHints: string[]
}

function Marker({ label }: { label: string }): JSX.Element {
  return (
    <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[var(--color-text-secondary)]">
      <AlertTriangle className="h-3.5 w-3.5 text-[var(--color-text-tertiary)]" aria-hidden />
      {label}
    </span>
  )
}

export function HealthItemRow({
  item,
  canWrite,
  removing,
  onRemovePath,
}: {
  item: HealthItem
  canWrite: boolean
  removing: boolean
  onRemovePath: (taskId: string) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const [confirming, setConfirming] = useState(false)
  const { task, defects, imageRef } = item
  const hasDeadPath = defects.has('deadPath')

  return (
    <EdvanceCard className="flex flex-col gap-3 p-5">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex flex-col gap-1">
          <span className="text-base font-semibold text-[var(--color-text-primary)]">
            {task.title ?? t('fields.none')}
          </span>
          {task.competency_content && (
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {task.competency_content}
            </span>
          )}
        </div>
        <StatusBadge status={task.status} label={t(`status.${task.status}`)} />
      </div>

      <div className="flex flex-wrap items-center gap-x-4 gap-y-2">
        {defects.size === 0 ? (
          <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[var(--color-success)]">
            <CheckCircle2 className="h-4 w-4" aria-hidden />
            {t('health.marker.clean')}
          </span>
        ) : (
          DEFECT_ORDER.filter((d) => defects.has(d)).map((d) => (
            <Marker key={d} label={t(`health.marker.${d}`)} />
          ))
        )}
      </div>

      {hasDeadPath && (
        <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-app)] p-4">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('health.path.label')}
          </span>
          {item.dead.map((asset, i) => (
            <code
              key={i}
              className="break-all font-[family-name:var(--font-mono,monospace)] text-xs text-[var(--color-text-secondary)]"
            >
              {asset.url}
            </code>
          ))}
          {item.licenseStatus && (
            <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
              <span className="font-semibold">{t('health.path.license')}:</span>{' '}
              {item.licenseStatus}
            </p>
          )}
          {item.licenseHints.map((hint, i) => (
            <p
              key={i}
              className="text-xs leading-relaxed text-[var(--color-text-secondary)]"
            >
              {hint}
            </p>
          ))}
        </div>
      )}

      {imageRef && (
        <div className="flex flex-col gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-bg-app)] p-4">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {imageRef.source === 'question'
              ? t('health.imageRef.labelQuestion')
              : t('health.imageRef.labelPart', { nr: imageRef.source })}
          </span>
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {imageRef.excerpt}
          </p>
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {t('health.imageRef.hint')}
          </p>
        </div>
      )}

      <div className="flex flex-wrap items-center justify-between gap-3">
        {hasDeadPath && canWrite && !confirming && (
          <button
            type="button"
            onClick={() => setConfirming(true)}
            disabled={removing}
            className="inline-flex min-h-[44px] items-center rounded-xl border border-[var(--color-destructive)] px-3 text-sm font-semibold text-[var(--color-destructive)] transition hover:bg-[color-mix(in_srgb,var(--color-destructive)_8%,transparent)] disabled:opacity-60"
          >
            {removing ? t('health.remove.running') : t('health.remove.action')}
          </button>
        )}

        {hasDeadPath && canWrite && confirming && (
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-xs text-[var(--color-text-secondary)]">
              {t('health.remove.confirm')}
            </span>
            <button
              type="button"
              onClick={() => {
                setConfirming(false)
                onRemovePath(task.id)
              }}
              className="inline-flex min-h-[44px] items-center rounded-xl border border-[var(--color-destructive)] px-3 text-sm font-semibold text-[var(--color-destructive)] transition hover:bg-[color-mix(in_srgb,var(--color-destructive)_8%,transparent)]"
            >
              {t('health.remove.confirmYes')}
            </button>
            <button
              type="button"
              onClick={() => setConfirming(false)}
              className="inline-flex min-h-[44px] items-center rounded-xl border border-[var(--color-border)] px-3 text-sm font-semibold text-[var(--color-text-secondary)] transition hover:border-[var(--color-primary)]"
            >
              {t('health.remove.confirmNo')}
            </button>
          </div>
        )}

        {hasDeadPath && !canWrite && (
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('health.remove.adminOnly')}
          </span>
        )}

        <Link
          to={`/admin/authoring/${task.id}`}
          className={`${buttonVariants({ variant: 'outline', size: 'sm' })} ml-auto`}
        >
          {t('health.open')}
        </Link>
      </div>

      {hasDeadPath && canWrite && (
        <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {t('health.remove.hint')}
        </p>
      )}
    </EdvanceCard>
  )
}
