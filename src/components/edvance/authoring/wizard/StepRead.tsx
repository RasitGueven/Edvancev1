// Schritt 1 — LESEN. Die Aufgabe, wie das Kind sie saehe: die Schueler-Vorschau
// gross und eingebettet (dieselbe AuthoringPreview wie im Editor, dieselbe RPC
// task_preview_payload — hier aendert sich nur der Platz, nie die Datenquelle).
// Daneben kompakt: Titel, Typ, Status, Maengel-Marker.

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { AlertTriangle, CheckCircle2 } from 'lucide-react'
import { EdvanceBadge, EdvanceCard } from '@/components/edvance'
import type { AuthoringTask, AuthoringTaskPatch, ItemFlag } from '@/types'
import { AuthoringPreview } from '../AuthoringPreview'
import { StatusBadge } from '../ui'

export function StepRead({
  task,
  draft,
  dirty,
  flags,
}: {
  task: AuthoringTask
  draft: AuthoringTaskPatch
  dirty: boolean
  flags: ItemFlag[]
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const blocking = flags.filter((f) => f.blocking)

  return (
    <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,20rem)]">
      <div className="flex flex-col gap-2">
        <p className="text-xs leading-relaxed text-[var(--color-text-tertiary)]">
          {t('wizard.read.hint')}
        </p>
        <AuthoringPreview taskId={task.id} draft={draft} dirty={dirty} />
      </div>

      <EdvanceCard className="flex h-fit flex-col gap-4 p-6">
        <h3 className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
          {t('wizard.read.meta')}
        </h3>
        <span className="text-base font-semibold text-[var(--color-text-primary)]">
          {task.title ?? t('fields.none')}
        </span>
        <div className="flex flex-wrap items-center gap-2">
          <StatusBadge status={task.status} label={t(`status.${task.status}`)} />
          {task.input_type && <EdvanceBadge variant="muted">{task.input_type}</EdvanceBadge>}
          {task.afb && <EdvanceBadge variant="primary">AFB {task.afb}</EdvanceBadge>}
        </div>

        <div className="flex flex-col gap-2">
          <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
            {t('wizard.read.defects')}
          </span>
          {blocking.length === 0 ? (
            <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-[var(--color-success)]">
              <CheckCircle2 className="h-4 w-4" aria-hidden="true" />
              {t('wizard.read.noDefects')}
            </span>
          ) : (
            <ul className="flex flex-col gap-2">
              {blocking.map((f, i) => (
                <li
                  key={`${f.code}-${i}`}
                  className="flex items-start gap-2 text-xs leading-relaxed text-[var(--color-text-secondary)]"
                >
                  <AlertTriangle
                    className="mt-0.5 h-3.5 w-3.5 shrink-0 text-[var(--color-text-tertiary)]"
                    aria-hidden="true"
                  />
                  {t(`flags.${f.code}`, f.vars)}
                </li>
              ))}
            </ul>
          )}
        </div>
      </EdvanceCard>
    </div>
  )
}
