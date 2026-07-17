// Schritt 3 — BILDER. Nur wenn das Item Assets hat oder der Text auf eine
// Abbildung verweist (stepsForTask).
//
// Echtes Bild: gross anzeigen, Alt-Text-Feld darunter (der Alt-Text blockiert
// die Freigabe, AssetsSection erklaert warum). Toter Pfad: derselbe
// "Bildpfad entfernen"-Weg wie auf der Content-Gesundheit — er leert nur den
// Asset-Eintrag im Formular, gespeichert wird ueber den Editor-Update-Pfad beim
// Schrittwechsel. Dazu sichtbar: die Loesbarkeits-Frage — ist die Aufgabe ohne
// dieses Bild ueberhaupt loesbar?
//
// Kein Crop-Werkzeug: es gibt im Frontend keines (der "AssetCropper" des
// C04-Laufs ist ein Python-Skript, scripts/content/crop_task_assets.py).
// Eines nachzubauen waere ein neuer geteilter Baustein — nicht Teil der Strecke.

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { Input } from '@/components/ui/input'
import { getGrounding } from '@/lib/authoring/grounding'
import { graphicLicenseHints, isDeadAssetUrl, type ImageRefFinding } from '@/lib/authoring/health'
import type { AuthoringTask, TaskAsset } from '@/types'
import { Field } from '../ui'

export function StepImages({
  task,
  assets,
  imageRef,
  canWrite,
  onAssets,
}: {
  task: AuthoringTask
  /** Formularstand (state.assets) — Aenderungen speichert der Schrittwechsel. */
  assets: TaskAsset[]
  /** Der Bildverweis-Verdacht, beim Laden des Items berechnet. */
  imageRef: ImageRefFinding | null
  canWrite: boolean
  onAssets: (next: TaskAsset[]) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const [confirming, setConfirming] = useState(false)
  const [licenseStatus, setLicenseStatus] = useState<string | null>(null)
  const [licenseHints, setLicenseHints] = useState<string[]>([])

  const dead = assets.filter((a) => isDeadAssetUrl(a.url))
  const hasDead = dead.length > 0

  // Lizenzhinweise nur bei totem Pfad — meist ist die Lizenz der Grund, warum
  // das Bild fehlt (C09). Dieselbe Quelle wie auf der Content-Gesundheit.
  useEffect(() => {
    if (!hasDead) return
    let alive = true
    void getGrounding(task.source, task.source_ref).then((record) => {
      if (!alive) return
      setLicenseStatus(record?.lizenz_status ?? null)
      setLicenseHints(graphicLicenseHints(record))
    })
    return () => {
      alive = false
    }
  }, [hasDead, task.source, task.source_ref])

  const patchAlt = (index: number, alt: string): void =>
    onAssets(assets.map((a, i) => (i === index ? { ...a, alt } : a)))

  return (
    <div className="flex flex-col gap-6">
      {assets.map((asset, i) =>
        isDeadAssetUrl(asset.url) ? null : (
          <EdvanceCard key={i} className="flex flex-col gap-4 p-6">
            <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              {assets.length > 1
                ? `${t('wizard.images.titleAssets')} — ${t('wizard.images.asset', { nr: i + 1 })}`
                : t('wizard.images.titleAssets')}
            </h3>
            <img
              src={asset.url}
              alt={asset.alt}
              className="mx-auto max-h-[55vh] w-auto max-w-full rounded-[var(--radius-md)] border border-[var(--color-border)] object-contain"
            />
            <Field label={t('fields.assetAlt')}>
              <Input
                value={asset.alt}
                placeholder={t('fields.assetAltPlaceholder')}
                disabled={!canWrite}
                onChange={(e) => patchAlt(i, e.target.value)}
              />
            </Field>
          </EdvanceCard>
        ),
      )}

      {hasDead && (
        <EdvanceCard className="flex flex-col gap-4 p-6">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('health.path.label')}
          </h3>
          {dead.map((asset, i) => (
            <code
              key={i}
              className="break-all font-[family-name:var(--font-mono,monospace)] text-xs text-[var(--color-text-secondary)]"
            >
              {asset.url}
            </code>
          ))}
          {licenseStatus && (
            <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
              <span className="font-semibold">{t('health.path.license')}:</span> {licenseStatus}
            </p>
          )}
          {licenseHints.map((hint, i) => (
            <p key={i} className="text-xs leading-relaxed text-[var(--color-text-secondary)]">
              {hint}
            </p>
          ))}

          {canWrite && !confirming && (
            <button
              type="button"
              onClick={() => setConfirming(true)}
              className="inline-flex min-h-[44px] items-center self-start rounded-xl border border-[var(--color-destructive)] px-3 text-sm font-semibold text-[var(--color-destructive)] transition hover:bg-[color-mix(in_srgb,var(--color-destructive)_8%,transparent)]"
            >
              {t('health.remove.action')}
            </button>
          )}
          {canWrite && confirming && (
            <div className="flex flex-wrap items-center gap-2">
              <span className="text-xs text-[var(--color-text-secondary)]">
                {t('health.remove.confirm')}
              </span>
              <button
                type="button"
                onClick={() => {
                  setConfirming(false)
                  onAssets(assets.filter((a) => !isDeadAssetUrl(a.url)))
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
          {canWrite && <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">{t('health.remove.hint')}</p>}
          {!canWrite && (
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {t('health.remove.adminOnly')}
            </span>
          )}
        </EdvanceCard>
      )}

      {(hasDead || imageRef) && (
        <EdvanceCard className="flex flex-col gap-3 p-6">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('wizard.images.solvableTitle')}
          </h3>
          {imageRef && (
            <>
              <span className="text-xs font-semibold text-[var(--color-text-secondary)]">
                {imageRef.source === 'question'
                  ? t('health.imageRef.labelQuestion')
                  : t('health.imageRef.labelPart', { nr: imageRef.source })}
              </span>
              <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
                {imageRef.excerpt}
              </p>
            </>
          )}
          <p className="text-sm leading-relaxed text-[var(--color-text-primary)]">
            {t('wizard.images.solvableQuestion')}
          </p>
          <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
            {t('health.imageRef.hint')}
          </p>
        </EdvanceCard>
      )}
    </div>
  )
}
