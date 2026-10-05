// Kopf des Editors in der Admin-Hülle: „← Item-Pflege“ oder, wenn der Editor
// aus der Pflege-Strecke kam, zurück an dieselbe Stelle der Strecke.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { usePflegeRueckweg } from './wizard/usePflegeRueckweg'

export function EditorKopf({ titel }: { titel?: string | null }): JSX.Element {
  const { t } = useTranslation('authoring')
  const { zurueck } = usePflegeRueckweg()
  return (
    <PageHeader
      rubrik={titel ? t('page.editorSubtitle') : undefined}
      titel={titel || t('page.editorSubtitle')}
      zurueckZu={zurueck.to}
      zurueckState={zurueck.state}
      zurueckLabel={t(zurueck.labelKey)}
    />
  )
}
