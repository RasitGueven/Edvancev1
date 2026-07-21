// Lizenz-/Quellenangabe der Aufgabe (A09).
//
// CC BY 4.0 verlangt beim Zeigen einer Abbildung eine Namensnennung. Sobald das
// Item ein Bild traegt, ist dieses Feld Pflicht (das Freigabe-Gate in flags.ts
// blockiert einen leeren Text) — Items ohne Bild sehen es gar nicht.
//
// Vorbefuellung: der CC-BY-4.0-Standardtext wird aus dem Quellenbeleg gebaut
// (buildAttribution, EINE Stelle) und eingesetzt, sobald ein Bild da und das
// Feld noch leer ist. Der Pfleger kann ihn ueberschreiben — der Ausnahmefall ist
// eingebettetes Fremdmaterial in der VERA-Aufgabe, das eine abweichende Nennung
// braucht. Gespeichert wird wie ueberall im Wizard beim Schrittwechsel.

import { useEffect, type JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { EdvanceCard } from '@/components/edvance'
import { buildAttribution } from '@/lib/authoring/attribution'
import { getGrounding } from '@/lib/authoring/grounding'
import { TEXTAREA_MD } from '@/lib/formStyles'
import type { AuthoringTask } from '@/types'
import { Field } from '../ui'

export function LicenceSection({
  task,
  /** Ein echtes, heiles Bild ist zugewiesen — nur dann greift die Pflicht. */
  hasImage,
  /** Formularstand (state.licence_text) — der Schrittwechsel speichert. */
  licenceText,
  canWrite,
  onLicence,
}: {
  task: AuthoringTask
  hasImage: boolean
  licenceText: string
  canWrite: boolean
  onLicence: (next: string) => void
}): JSX.Element | null {
  const { t } = useTranslation('authoring')

  // Vorbefuellen, sobald ein Bild da und noch kein Text gepflegt ist. Nur einmal:
  // steht der Text, greift der Blank-Guard. Ueberschreibt nie einen vorhandenen —
  // Fremdmaterial-Nennungen bleiben unangetastet.
  useEffect(() => {
    if (!canWrite || !hasImage || licenceText.trim() !== '') return
    let alive = true
    void getGrounding(task.source, task.source_ref).then((record) => {
      if (!alive) return
      const text = buildAttribution(task, record)
      if (text) onLicence(text)
    })
    return () => {
      alive = false
    }
  }, [canWrite, hasImage, licenceText, task, onLicence])

  if (!hasImage) return null

  return (
    <EdvanceCard className="flex flex-col gap-4 p-6">
      <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('wizard.images.licenceTitle')}
      </h3>
      <Field label={t('fields.licenceText')} hint={t('wizard.images.licenceHint')}>
        <textarea
          className={`${TEXTAREA_MD} w-full`}
          value={licenceText}
          placeholder={t('fields.licenceTextPlaceholder')}
          disabled={!canWrite}
          onChange={(e) => onLicence(e.target.value)}
        />
      </Field>
    </EdvanceCard>
  )
}
