// Tags: AFB, Kompetenzen, Cluster — und der STOFFANKER.
//
// Der Stoffanker ist der Grund, warum es dieses Tool gibt. Er ist NICHT der
// Jahrgang, aus dem der Test stammt (das ist class_level, hier nur zur Anzeige),
// sondern der Jahrgang, dessen STOFF geprueft wird. "Berechne 20 % von 80 m" aus
// VERA-8 ist Klasse-7-Stoff. Wer das verwechselt, laesst die LSA auf dem falschen
// Jahrgang ziehen — und das faellt niemandem auf, weil das Item ja "funktioniert".
//
// Bei MULTI_PART sind AFB und Kompetenz ausgeblendet: dort traegt sie die
// Teilaufgabe (siehe PartsEditor).

import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Input } from '@/components/ui/input'
import { SELECT_SM } from '@/lib/formStyles'
import type { Afb } from '@/types'
import type { AuthoringCluster } from '@/lib/supabase/taskAuthoring'
import { Field } from './ui'
import { AFB_VALUES, GRADES, type FormState } from './editorState'

export function TagsSection({
  state,
  set,
  clusters,
  competencies,
  classLevel,
  hasStoffankerField,
}: {
  state: FormState
  set: <K extends keyof FormState>(key: K, value: FormState[K]) => void
  clusters: AuthoringCluster[]
  competencies: string[]
  classLevel: number | null
  hasStoffankerField: boolean
}): JSX.Element {
  const { t } = useTranslation('authoring')
  const multi = state.input_type === 'MULTI_PART'

  return (
    <div className="flex flex-col gap-4">
      <Field
        label={t('stoffanker.label')}
        hint={
          hasStoffankerField
            ? t('stoffanker.help')
            : `${t('stoffanker.help')} — ${t('schema.stoffanker')}`
        }
      >
        <div className="flex flex-wrap items-center gap-3">
          <select
            className={SELECT_SM}
            value={state.curriculum_grade}
            disabled={!hasStoffankerField}
            onChange={(e) => set('curriculum_grade', e.target.value)}
          >
            <option value="">{t('stoffanker.unset')}</option>
            {GRADES.map((g) => (
              <option key={g} value={String(g)}>
                {t('stoffanker.grade', { grade: g })}
              </option>
            ))}
          </select>
          <span className="text-xs text-[var(--color-text-tertiary)]">
            {classLevel != null
              ? t('stoffanker.origin', { grade: classLevel })
              : t('stoffanker.originUnknown')}
          </span>
        </div>
      </Field>

      <Field label={t('fields.cluster')}>
        <select
          className={`${SELECT_SM} w-full`}
          value={state.cluster_id}
          onChange={(e) => set('cluster_id', e.target.value)}
        >
          <option value="">{t('fields.none')}</option>
          {clusters.map((c) => (
            <option key={c.id} value={c.id}>
              {c.subject_name} · {c.name}
            </option>
          ))}
        </select>
      </Field>

      {!multi && (
        <>
          <Field label={t('fields.afb')}>
            <select
              className={`${SELECT_SM} w-full`}
              value={state.afb}
              onChange={(e) => set('afb', e.target.value as Afb | '')}
            >
              <option value="">{t('fields.none')}</option>
              {AFB_VALUES.map((a) => (
                <option key={a} value={a}>
                  {t(`afbLevel.${a}`)}
                </option>
              ))}
            </select>
          </Field>

          <div className="grid gap-4 sm:grid-cols-2">
            <Field label={t('fields.competencyContent')}>
              <Input
                list="authoring-competencies-item"
                value={state.competency_content}
                onChange={(e) => set('competency_content', e.target.value)}
              />
            </Field>
            <Field label={t('fields.competencyProcess')}>
              <Input
                value={state.competency_process}
                onChange={(e) => set('competency_process', e.target.value)}
              />
            </Field>
          </div>

          <datalist id="authoring-competencies-item">
            {competencies.map((c) => (
              <option key={c} value={c} />
            ))}
          </datalist>
        </>
      )}
    </div>
  )
}
