// Schritt 4, oberer Teil: was die Freigabe noch blockiert.
//
// Vier Angaben sind hier DIREKT setzbar (Themengebiet, Inhaltsfeld, AFB,
// Stoffanker) — alles andere steht als Punkt da, mit dem Weg in den Editor.
//
// Welche Felder erscheinen, wird beim Betreten des Schritts EINMAL festgehalten:
// die Flags laufen ueber den Entwurf, ein gesetztes Feld liesse sein Flag sofort
// verschwinden — und die Auswahl unter dem Finger gleich mit.

import { useState, type JSX, type ReactNode } from 'react'
import { Link } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { Circle, PenLine } from 'lucide-react'
import { buttonVariants } from '@/components/ui/button'
import { INHALTSFELDER, inhaltsfeldVorschlag, istDirektSetzbar } from '@/lib/authoring/einordnung'
import type { AuthoringCluster } from '@/lib/supabase/taskAuthoring'
import type { Afb, ItemFlag } from '@/types'
import { AFB_VALUES, type FormState } from '../editorState'
import { ChoiceChip } from './ChoiceChip'
import { editorAusStrecke } from './wizardQueue'

const GRADES = [5, 6, 7, 8, 9]

export function RequiredFields({
  taskId,
  state,
  blocking,
  clusters,
  canWrite,
  set,
}: {
  taskId: string
  state: FormState
  blocking: ItemFlag[]
  clusters: AuthoringCluster[]
  canWrite: boolean
  set: <K extends keyof FormState>(key: K, value: FormState[K]) => void
}): JSX.Element | null {
  const { t } = useTranslation('authoring')
  const [shown] = useState(() => new Set(blocking.map((f) => f.code).filter(istDirektSetzbar)))
  const rest = blocking.filter((f) => !istDirektSetzbar(f.code))

  if (shown.size === 0 && rest.length === 0) return null

  const clusterName = clusters.find((c) => c.id === state.cluster_id)?.name ?? null
  const vorschlag = inhaltsfeldVorschlag(clusterName)

  return (
    <div className="flex flex-col gap-4 rounded-[var(--radius-md)] bg-[var(--color-bg-app)] p-4">
      <span className="text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
        {t('wizard.release.requiredTitle')}
      </span>

      {shown.has('clusterMissing') && (
        <FieldRow label={t('wizard.anchor.themeTitle')}>
          {clusters.map((c) => (
            <ChoiceChip
              key={c.id}
              selected={state.cluster_id === c.id}
              disabled={!canWrite}
              onClick={() => set('cluster_id', c.id)}
            >
              {c.name}
            </ChoiceChip>
          ))}
        </FieldRow>
      )}

      {shown.has('competencyMissing') && (
        <FieldRow
          label={t('fields.competencyContent')}
          hint={vorschlag ? t('wizard.release.suggestion', { value: t(`inhaltsfeld.${vorschlag}`) }) : undefined}
        >
          {INHALTSFELDER.map((f) => (
            <ChoiceChip
              key={f}
              selected={state.competency_content === f}
              disabled={!canWrite}
              onClick={() => set('competency_content', f)}
            >
              {t(`inhaltsfeld.${f}`)}
            </ChoiceChip>
          ))}
        </FieldRow>
      )}

      {shown.has('afbMissing') && (
        <FieldRow label={t('fields.afb')}>
          {AFB_VALUES.map((a) => (
            <ChoiceChip
              key={a}
              selected={state.afb === a}
              disabled={!canWrite}
              onClick={() => set('afb', a as Afb)}
            >
              {t(`afbLevel.${a}`)}
            </ChoiceChip>
          ))}
        </FieldRow>
      )}

      {shown.has('stoffankerMissing') && (
        <FieldRow label={t('stoffanker.label')}>
          {GRADES.map((g) => (
            <ChoiceChip
              key={g}
              selected={state.curriculum_grade === String(g)}
              disabled={!canWrite}
              onClick={() => set('curriculum_grade', String(g))}
            >
              {t('stoffanker.grade', { grade: g })}
            </ChoiceChip>
          ))}
        </FieldRow>
      )}

      {rest.length > 0 && (
        <div className="flex flex-col gap-2">
          <ul className="flex flex-col gap-2">
            {rest.map((f, i) => (
              <li key={`${f.code}-${i}`} className="flex items-start gap-2 text-sm leading-relaxed">
                <Circle
                  className="mt-0.5 h-4 w-4 shrink-0 text-[var(--color-text-tertiary)]"
                  aria-hidden="true"
                />
                <span className="text-[var(--color-text-secondary)]">
                  {t(`flags.${f.code}`, f.vars)}
                </span>
              </li>
            ))}
          </ul>
          <Link
            to={editorAusStrecke(taskId, 'release')}
            className={`${buttonVariants({ variant: 'outline', size: 'sm' })} self-start`}
          >
            <PenLine className="h-4 w-4" aria-hidden="true" />
            {t('wizard.solution.openEditor')}
          </Link>
        </div>
      )}
    </div>
  )
}

function FieldRow({
  label,
  hint,
  children,
}: {
  label: string
  hint?: string
  children: ReactNode
}): JSX.Element {
  return (
    <div className="flex flex-col gap-2">
      <span className="text-sm font-semibold text-[var(--color-text-primary)]">{label}</span>
      <div className="flex flex-wrap gap-2">{children}</div>
      {hint && <span className="text-xs text-[var(--color-text-tertiary)]">{hint}</span>}
    </div>
  )
}
