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
// Zwei Wege zum richtigen Bild, beide ohne DB-Schreibpfad — der Schrittwechsel
// speichert, wie bei allen anderen Feldern des Wizards:
//   1. Kandidaten: was scripts/kandidaten_upload.py unter
//      task-assets/kandidaten/<task_id>/ abgelegt hat. Klick uebernimmt.
//   2. Zuschnitt: derselbe AssetCropper wie im Expertenmodus (AssetsSection).
//      Die EMF-Renders der Quelle haben den Aufgabentext eingebrannt; der steht
//      schon in tasks.question, das Kind saehe ihn doppelt (§12).

import { useEffect, useState, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Crop, RotateCcw } from 'lucide-react'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { getGrounding } from '@/lib/authoring/grounding'
import { graphicLicenseHints, isDeadAssetUrl, type ImageRefFinding } from '@/lib/authoring/health'
import { listCandidateAssets } from '@/lib/supabase/storage'
import type { AuthoringTask, TaskAsset, TaskPart } from '@/types'
import { AssetCropper } from '../AssetCropper'
import { NeedsImageSection } from '../NeedsImageSection'
import { Field } from '../ui'
import { LicenceSection } from './LicenceSection'

export function StepImages({
  task,
  assets,
  needsImage,
  parts,
  imageRef,
  licenceText,
  canWrite,
  onAssets,
  onNeedsImage,
  onLicence,
  onPart,
}: {
  task: AuthoringTask
  /** Formularstand (state.assets) — Aenderungen speichert der Schrittwechsel. */
  assets: TaskAsset[]
  /** tasks.needs_image (Stamm) — die Didaktik-Frage, VOR der Technik (A08). */
  needsImage: boolean | null
  /** Formularstand (state.parts) — traegt parts[i].needs_image je Teilaufgabe. */
  parts: TaskPart[]
  /** Der Bildverweis-Verdacht, beim Laden des Items berechnet. */
  imageRef: ImageRefFinding | null
  /** Formularstand (state.licence_text) — Aenderungen speichert der Schrittwechsel. */
  licenceText: string
  canWrite: boolean
  onAssets: (next: TaskAsset[]) => void
  onNeedsImage: (next: boolean | null) => void
  onLicence: (next: string) => void
  onPart: (index: number, next: boolean | null) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const [confirming, setConfirming] = useState(false)
  const [licenseStatus, setLicenseStatus] = useState<string | null>(null)
  const [licenseHints, setLicenseHints] = useState<string[]>([])
  const [candidates, setCandidates] = useState<string[]>([])
  const [candidatesError, setCandidatesError] = useState<string | null>(null)
  /** Index des Assets, das gerade zugeschnitten wird — hoechstens eines. */
  const [cropping, setCropping] = useState<number | null>(null)

  const dead = assets.filter((a) => isDeadAssetUrl(a.url))
  const hasDead = dead.length > 0
  // Ein echtes, heiles Bild ist zugewiesen — nur dann braucht das Item eine
  // Attribution, und nur dann blockiert ein leerer Lizenztext die Freigabe.
  const hasImage = assets.some((a) => !isDeadAssetUrl(a.url))

  // Die vorbereiteten Kandidatenbilder des Items. Leere Liste ist der
  // Normalfall fuer Items ohne Bildbedarf — dann bleibt der Bereich unsichtbar
  // und der manuelle Weg unveraendert.
  useEffect(() => {
    let alive = true
    setCandidates([])
    setCandidatesError(null)
    void listCandidateAssets(task.id).then((res) => {
      if (!alive) return
      if (res.error || !res.data) {
        setCandidatesError(t('wizard.images.candidatesFailed'))
        return
      }
      setCandidates(res.data.map((f) => f.url))
    })
    return () => {
      alive = false
    }
  }, [task.id, t])

  const patchAlt = (index: number, alt: string): void =>
    onAssets(assets.map((a, i) => (i === index ? { ...a, alt } : a)))

  /**
   * Kandidat uebernehmen. Alt-Text bleibt leer — den schreibt der Pfleger im
   * Feld darunter, und leer blockiert die Freigabe (AssetsSection erklaert warum).
   */
  const takeCandidate = (url: string): void => onAssets([...assets, { url, alt: '' }])

  /**
   * Zuschnitt uebernehmen. original_url zeigt weiterhin auf das ECHTE Original:
   * ein zweiter Schnitt behaelt den Rueckweg auf das Ausgangsbild statt auf den
   * Zwischenschnitt. Gleiche Regel wie in AssetsSection.
   */
  const applyCrop = (index: number, cropUrl: string): void => {
    onAssets(
      assets.map((a, i) =>
        i === index ? { ...a, url: cropUrl, original_url: a.original_url ?? a.url } : a,
      ),
    )
    setCropping(null)
  }

  /** Zurueck auf das Original. Im Bucket wird nichts geloescht, nur umgezeigt. */
  const restore = (index: number): void =>
    onAssets(
      assets.map((a, i) => {
        if (i !== index || !a.original_url) return a
        const { original_url, ...rest } = a
        return { ...rest, url: original_url }
      }),
    )

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

  return (
    <div className="flex flex-col gap-6">
      {/* Zuerst die Didaktik: braucht die Aufgabe/Teilaufgabe ein Bild? Erst
          danach die Technik (Alt-Text, toter Pfad, Loesbarkeit) — die nur zaehlt,
          wenn ueberhaupt ein Bild noetig ist (A08). */}
      <NeedsImageSection
        needsImage={needsImage}
        parts={parts}
        multi={task.input_type === 'MULTI_PART'}
        canWrite={canWrite}
        onItem={onNeedsImage}
        onPart={onPart}
      />

      {/* Kandidaten aus der Quelle. Fehlen sie, bleibt der manuelle Weg der
          einzige — dieser Bereich verschwindet dann ersatzlos. */}
      {(candidates.length > 0 || candidatesError) && (
        <EdvanceCard className="flex flex-col gap-4 p-6">
          <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('wizard.images.candidatesTitle')}
          </h3>
          {candidatesError ? (
            <p className="text-xs leading-relaxed text-[var(--color-destructive)]">
              {candidatesError}
            </p>
          ) : (
            <>
              <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
                {t('wizard.images.candidatesHint')}
              </p>
              <div className="flex flex-wrap gap-4">
                {candidates.map((url, i) => {
                  // Auch ein Zuschnitt zaehlt als uebernommen: original_url
                  // zeigt dann auf genau diesen Kandidaten.
                  const taken = assets.some((a) => a.url === url || a.original_url === url)
                  return (
                    <button
                      key={url}
                      type="button"
                      disabled={!canWrite || taken}
                      aria-pressed={taken}
                      aria-label={t('wizard.images.candidateSelect', { nr: i + 1 })}
                      onClick={() => takeCandidate(url)}
                      className={`flex min-h-[44px] flex-col items-center gap-2 rounded-[var(--radius-md)] border p-2 transition ${
                        taken
                          ? 'border-[var(--color-primary)] bg-[color-mix(in_srgb,var(--color-primary)_8%,transparent)]'
                          : 'border-[var(--color-border)] hover:border-[var(--color-primary)]'
                      } ${!canWrite || taken ? 'cursor-default' : 'cursor-pointer'}`}
                    >
                      <img
                        src={url}
                        alt=""
                        loading="lazy"
                        className="max-h-[120px] w-auto max-w-[120px] rounded-[var(--radius-sm)] object-contain"
                      />
                      {taken && (
                        <EdvanceBadge variant="muted">
                          {t('wizard.images.candidateSelected')}
                        </EdvanceBadge>
                      )}
                    </button>
                  )
                })}
              </div>
            </>
          )}
        </EdvanceCard>
      )}

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

            {asset.original_url && (
              <div className="flex flex-wrap items-center gap-2">
                <EdvanceBadge variant="muted">{t('fields.cropBadge')}</EdvanceBadge>
                <span className="text-xs text-[var(--color-text-tertiary)]">
                  {t('fields.cropOriginalKept')}
                </span>
              </div>
            )}

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
                taskId={task.id}
                // Geschnitten wird immer aus dem Original, nie aus einem
                // Zuschnitt: sonst frisst sich ein zweiter Schnitt in die schon
                // weggeschnittenen Raender und der Pfleger verliert Bild.
                sourceUrl={asset.original_url ?? asset.url}
                alt={asset.alt}
                onCropped={(url) => applyCrop(i, url)}
                onCancel={() => setCropping(null)}
              />
            )}
          </EdvanceCard>
        ),
      )}

      {/* Lizenz/Quellenangabe — Pflicht, sobald ein Bild zugewiesen ist (A09).
          Vorbefuellt mit dem CC-BY-4.0-Standardtext, ueberschreibbar fuer den
          Ausnahmefall: eingebettetes Fremdmaterial in der VERA-Aufgabe. */}
      <LicenceSection
        task={task}
        hasImage={hasImage}
        licenceText={licenceText}
        canWrite={canWrite}
        onLicence={onLicence}
      />

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
                  // Der offene Cropper haengt an einem Index. Faellt ein Bild
                  // aus der Liste, zeigt der Index auf ein anderes — also zu.
                  setCropping(null)
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
