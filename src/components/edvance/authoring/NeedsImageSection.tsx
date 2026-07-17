// Bild-Notwendigkeit — die didaktische Frage, gebuendelt an einem Ort (A08).
//
// Zwei verschiedene Fragen, zwei verschiedene UI-Bereiche — hier NICHT die
// Technik (welches Bild ist da, ist es heil, Alt-Text, Zuschnitt), sondern nur:
// braucht die Aufgabe inhaltlich eine Abbildung? Am Stamm und — bei Multi-Part —
// je Teilaufgabe einzeln, denn oft braucht nur EINE Teilaufgabe ein Bild.
//
// Reine Anzeige ueber `NeedsImageControl`; das Speichern laeuft ueber den
// Editor-/Wizard-Update-Pfad (toPatch schreibt tasks.needs_image und
// tasks.parts[].needs_image).

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { TaskPart } from '@/types'
import { NeedsImageControl } from './NeedsImageControl'

export function NeedsImageSection({
  needsImage,
  parts,
  multi,
  canWrite,
  onItem,
  onPart,
}: {
  /** tasks.needs_image — die Beurteilung des Stamms. */
  needsImage: boolean | null
  /** Die Teilaufgaben (nur bei Multi-Part relevant). */
  parts: TaskPart[]
  multi: boolean
  canWrite: boolean
  onItem: (next: boolean | null) => void
  onPart: (index: number, next: boolean | null) => void
}): JSX.Element {
  const { t } = useTranslation('authoring')

  return (
    <div className="flex flex-col gap-4 rounded-[var(--radius-md)] border border-[var(--color-border)] p-4">
      <div className="flex flex-col gap-1">
        <h4 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('needsImage.title')}
        </h4>
        <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {t('needsImage.hint')}
        </p>
      </div>

      <NeedsImageControl
        label={multi ? t('needsImage.itemLabelMulti') : t('needsImage.itemLabel')}
        value={needsImage}
        canWrite={canWrite}
        onChange={onItem}
      />

      {multi &&
        parts.map((part, i) => (
          <NeedsImageControl
            key={i}
            label={t('needsImage.partLabel', { nr: part.nr })}
            value={part.needs_image ?? null}
            canWrite={canWrite}
            onChange={(next) => onPart(i, next)}
          />
        ))}
    </div>
  )
}
