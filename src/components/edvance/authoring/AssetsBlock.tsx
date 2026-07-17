// Die Assets-Sektion des Editors — zwei getrennte Fragen unter einem Dach.
//
// Zuerst die DIDAKTIK (braucht die Aufgabe/Teilaufgabe ein Bild? A08), danach die
// TECHNIK (welches Bild ist da, Alt-Text, Zuschnitt). Bewusst nicht vermischt:
// der EMF-Befund sagt nichts darueber aus, ob inhaltlich ein Bild noetig ist.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import type { FormState } from './editorState'
import { AssetsSection } from './AssetsSection'
import { NeedsImageSection } from './NeedsImageSection'
import { Section } from './ui'

export function AssetsBlock({
  state,
  set,
  taskId,
  multi,
  canWrite,
}: {
  state: FormState
  set: <K extends keyof FormState>(key: K, value: FormState[K]) => void
  taskId: string
  multi: boolean
  canWrite: boolean
}): JSX.Element {
  const { t } = useTranslation('authoring')

  return (
    <Section title={t('sections.assets')} collapsible defaultOpen={false}>
      <NeedsImageSection
        needsImage={state.needs_image}
        parts={state.parts}
        multi={multi}
        canWrite={canWrite}
        onItem={(next) => set('needs_image', next)}
        onPart={(i, next) =>
          set(
            'parts',
            state.parts.map((p, j) => (j === i ? { ...p, needs_image: next } : p)),
          )
        }
      />
      <AssetsSection
        assets={state.assets}
        onChange={(next) => set('assets', next)}
        taskId={taskId}
        canWrite={canWrite}
      />
    </Section>
  )
}
