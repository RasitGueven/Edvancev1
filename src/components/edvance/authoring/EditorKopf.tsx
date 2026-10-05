// Kopf des Editors in der Admin-Hülle: „← Item-Pflege“ oder, wenn der Editor aus der Admin-Prüfansicht kam,
// „← Zurück zur Prüfansicht“. Nach dem Speichern steht dort „Gespeichert.“ mit dem Knopf zurück — ohne
// automatische Weiterleitung (Bauauftrag D 17).

import type { JSX } from 'react'
import { useNavigate } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { CheckCircle2 } from 'lucide-react'
import { PageHeader } from '@/components/edvance/shell/PageHeader'
import { Button } from '@/components/ui/button'
import { usePruefRueckweg } from './usePruefRueckweg'

export function EditorKopf({ titel, gespeichert = false }: { titel?: string | null; gespeichert?: boolean }): JSX.Element {
  const { t } = useTranslation('authoring')
  const navigate = useNavigate()
  const { zurueck, ausPruefen } = usePruefRueckweg()
  return (
    <>
      <PageHeader
        rubrik={titel ? t('page.editorSubtitle') : undefined}
        titel={titel || t('page.editorSubtitle')}
        zurueckZu={zurueck.to}
        zurueckLabel={t(zurueck.labelKey)}
      />
      {gespeichert && ausPruefen && (
        <div role="status" className="flex flex-wrap items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-success)] bg-[var(--color-success-light)] p-3 text-sm font-semibold text-[var(--color-success)] animate-fade-in">
          <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
          {t('editor.gespeichert')}
          <Button className="ml-auto" onClick={() => navigate(zurueck.to)}>{t('editor.zurueckPruefen')}</Button>
        </div>
      )}
    </>
  )
}
