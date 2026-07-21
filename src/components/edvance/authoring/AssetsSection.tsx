// Assets (tasks.assets jsonb).
//
// Der Alt-Text ist Pflicht, und zwar blockierend: lsa_public_assets reicht
// { url, alt } ans Kind durch — ein Bild ohne Alt-Text ist fuer ein Kind mit
// Screenreader eine leere Stelle in der Aufgabe. Ein Item, dessen Frage man ohne
// das Bild nicht beantworten kann, waere damit unloesbar.

import { useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Crop, RotateCcw, X } from 'lucide-react'
import { EdvanceBadge } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import type { TaskAsset } from '@/types'
import { AssetCropper } from './AssetCropper'
import { AddButton, Field, IconButton } from './ui'

export function AssetsSection({
  assets,
  onChange,
  taskId,
  canWrite,
}: {
  assets: TaskAsset[]
  onChange: (next: TaskAsset[]) => void
  taskId: string
  /** Nur admin schneidet zu — wie beim Rest der Item-Pflege. Coach sieht nur. */
  canWrite: boolean
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const [cropping, setCropping] = useState<number | null>(null)

  const patch = (index: number, part: Partial<TaskAsset>): void =>
    onChange(assets.map((a, i) => (i === index ? { ...a, ...part } : a)))

  /**
   * Zuschnitt uebernehmen. original_url zeigt weiterhin auf das ECHTE Original:
   * schneidet der Pfleger einen Zuschnitt nochmal zu, bleibt der Rueckweg das
   * unangetastete Ausgangsbild — nicht der Zwischenschnitt.
   */
  const applyCrop = (index: number, cropUrl: string): void => {
    const asset = assets[index]
    patch(index, { url: cropUrl, original_url: asset.original_url ?? asset.url })
    setCropping(null)
  }

  /** Zurueck auf das Original. Im Bucket wird nichts geloescht, nur umgezeigt. */
  const restore = (index: number): void =>
    onChange(
      assets.map((a, i) => {
        if (i !== index || !a.original_url) return a
        const { original_url, ...rest } = a
        return { ...rest, url: original_url }
      }),
    )

  return (
    <div className="flex flex-col gap-4">
      {assets.map((asset, i) => (
        <div
          key={i}
          className="flex flex-col gap-4 rounded-[var(--radius-md)] border border-[var(--color-border)] p-4"
        >
          <div className="flex items-start gap-4">
            {asset.url && (
              <img
                src={asset.url}
                alt={asset.alt}
                className="h-20 w-20 shrink-0 rounded-[var(--radius-md)] border border-[var(--color-border)] object-cover"
              />
            )}
            <div className="flex flex-1 flex-col gap-4">
              <Field label={t('fields.assetUrl')}>
                <Input
                  value={asset.url}
                  onChange={(e) => patch(i, { url: e.target.value })}
                />
              </Field>

              {asset.original_url && (
                <div className="flex flex-wrap items-center gap-2">
                  <EdvanceBadge variant="muted">{t('fields.cropBadge')}</EdvanceBadge>
                  <span className="text-xs text-[var(--color-text-tertiary)]">
                    {t('fields.cropOriginalKept')}
                  </span>
                </div>
              )}
              <Field label={t('fields.assetAlt')}>
                <Input
                  value={asset.alt}
                  placeholder={t('fields.assetAltPlaceholder')}
                  onChange={(e) => patch(i, { alt: e.target.value })}
                />
              </Field>
              <Field label={t('fields.assetCaption')}>
                <Input
                  value={asset.caption ?? ''}
                  onChange={(e) => patch(i, { caption: e.target.value })}
                />
              </Field>
            </div>
            <IconButton
              label={t('fields.remove')}
              onClick={() => {
                // Der offene Cropper haengt an einem Index. Faellt ein Bild aus
                // der Liste, zeigt der Index auf ein anderes — also zu.
                setCropping(null)
                onChange(assets.filter((_, j) => j !== i))
              }}
            >
              <X className="h-4 w-4" />
            </IconButton>
          </div>

          {canWrite && asset.url && cropping !== i && (
            <div className="flex flex-wrap items-center gap-2">
              <Button variant="outline" size="sm" onClick={() => setCropping(i)}>
                <Crop className="mr-2 h-4 w-4" />
                {t('fields.crop')}
              </Button>
              {asset.original_url && (
                <Button variant="outline" size="sm" onClick={() => restore(i)}>
                  <RotateCcw className="mr-2 h-4 w-4" />
                  {t('fields.cropRestore')}
                </Button>
              )}
            </div>
          )}

          {canWrite && cropping === i && (
            <AssetCropper
              taskId={taskId}
              // Geschnitten wird immer aus dem Original, nie aus einem
              // Zuschnitt: sonst frisst sich ein zweiter Schnitt in die schon
              // weggeschnittenen Raender und der Pfleger verliert Bild.
              sourceUrl={asset.original_url ?? asset.url}
              alt={asset.alt}
              onCropped={(url) => applyCrop(i, url)}
              onCancel={() => setCropping(null)}
            />
          )}
        </div>
      ))}

      <AddButton
        label={t('fields.addAsset')}
        onClick={() => onChange([...assets, { url: '', alt: '' }])}
      />
    </div>
  )
}
