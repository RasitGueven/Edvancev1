// Assets (tasks.assets jsonb).
//
// Der Alt-Text ist Pflicht, und zwar blockierend: lsa_public_assets reicht
// { url, alt } ans Kind durch — ein Bild ohne Alt-Text ist fuer ein Kind mit
// Screenreader eine leere Stelle in der Aufgabe. Ein Item, dessen Frage man ohne
// das Bild nicht beantworten kann, waere damit unloesbar.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { X } from 'lucide-react'
import { Input } from '@/components/ui/input'
import type { TaskAsset } from '@/types'
import { AddButton, Field, IconButton } from './ui'

export function AssetsSection({
  assets,
  onChange,
}: {
  assets: TaskAsset[]
  onChange: (next: TaskAsset[]) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  const patch = (index: number, part: Partial<TaskAsset>): void =>
    onChange(assets.map((a, i) => (i === index ? { ...a, ...part } : a)))

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
              onClick={() => onChange(assets.filter((_, j) => j !== i))}
            >
              <X className="h-4 w-4" />
            </IconButton>
          </div>
        </div>
      ))}

      <AddButton
        label={t('fields.addAsset')}
        onClick={() => onChange([...assets, { url: '', alt: '' }])}
      />
    </div>
  )
}
