// Die Vorschau als Overlay. Sie zeigt die Aufgabe gross — so, wie das Kind sie
// saehe — statt sie inline an den Rand zu draengen, wo sie bei langen Items aus
// dem Blick geraet.
//
// WICHTIG: Dieses Modal baut KEINE Vorschau. Es reicht taskId/draft/dirty
// unveraendert an AuthoringPreview weiter — die ruft weiterhin task_preview_payload
// (A02). Hier aendert sich nur der ORT, nie die Datenquelle. Der ungespeichert-
// Marker (dirty) bleibt sichtbar, weil ihn AuthoringPreview selbst traegt.

import { useEffect, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { X } from 'lucide-react'
import type { AuthoringTaskPatch } from '@/types'
import { AuthoringPreview } from './AuthoringPreview'

export function PreviewModal({
  open,
  onClose,
  taskId,
  draft,
  dirty,
}: {
  open: boolean
  onClose: () => void
  taskId: string
  draft: AuthoringTaskPatch
  dirty: boolean
}): JSX.Element | null {
  const { t } = useTranslation('authoring')

  useEffect(() => {
    if (!open) return
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') onClose()
    }
    window.addEventListener('keydown', onKey)
    document.body.style.overflow = 'hidden'
    return () => {
      window.removeEventListener('keydown', onKey)
      document.body.style.overflow = ''
    }
  }, [open, onClose])

  if (!open) return null

  return (
    <div
      className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 animate-fade-in sm:p-8"
      role="dialog"
      aria-modal="true"
      aria-label={t('sections.preview')}
    >
      {/* Klick daneben schliesst. Escape ebenso (siehe useEffect). */}
      <button
        type="button"
        aria-label={t('preview.close')}
        className="fixed inset-0 bg-[var(--color-overlay)]"
        onClick={onClose}
      />
      <div className="relative z-10 w-full max-w-2xl animate-scale-in">
        <div className="mb-3 flex justify-end">
          <button
            type="button"
            onClick={onClose}
            aria-label={t('preview.close')}
            className="flex h-11 w-11 items-center justify-center rounded-[var(--radius-full)] bg-[var(--color-bg-surface)] text-[var(--color-text-tertiary)] shadow-card transition hover:text-[var(--color-text-primary)]"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <AuthoringPreview taskId={taskId} draft={draft} dirty={dirty} />
      </div>
    </div>
  )
}
