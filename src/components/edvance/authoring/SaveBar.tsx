// Speicherleiste. Zeigt an, ob es ungespeicherte Aenderungen gibt — und was
// schiefging.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Button } from '@/components/ui/button'

export function SaveBar({
  dirty,
  busy,
  canWrite,
  error,
  onSave,
  onDiscard,
}: {
  dirty: boolean
  busy: boolean
  canWrite: boolean
  error: string | null
  onSave: () => void
  onDiscard: () => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  return (
    <div className="fixed inset-x-0 bottom-0 z-20 border-t border-[var(--color-border)] bg-[var(--color-bg-surface)] px-4 py-3 shadow-elevation-lg">
      <div className="mx-auto flex max-w-7xl flex-wrap items-center gap-4">
        <span
          className={`flex items-center gap-2 text-xs font-semibold ${
            dirty
              ? 'text-[var(--color-gold-warning)]'
              : 'text-[var(--color-text-tertiary)]'
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
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {t('save.readOnly')}
          </span>
        )}

        {error && (
          <span className="text-xs text-[var(--color-destructive)]">
            {t('save.failed', { error })}
          </span>
        )}

        <div className="ml-auto flex gap-2">
          <Button variant="outline" size="sm" disabled={!dirty || busy} onClick={onDiscard}>
            {t('save.discard')}
          </Button>
          <Button size="sm" disabled={!dirty || busy || !canWrite} onClick={onSave}>
            {busy ? t('save.saving') : t('save.save')}
          </Button>
        </div>
      </div>
    </div>
  )
}
