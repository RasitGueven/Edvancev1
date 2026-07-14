// Der Editor der Item-Pflege. Links bearbeiten, rechts sehen, was das Kind sieht.
//
// Ein Item wohnt in zwei Tabellen (tasks + task_solutions) mit zwei Rechtelagen
// und ohne gemeinsame Transaktion. Gespeichert wird deshalb in dieser Reihenfolge:
//   1. tasks   — hier greifen die DB-CHECKs (tasks_multipart_check, lsa_parts_valid).
//                Faellt das durch, ist nichts geschrieben.
//   2. task_solutions via RPC — erst wenn 1 durch ist.
// Scheitert Schritt 2, sagen wir das. Ein "gespeichert", das die Loesung verloren
// hat, waere die schlimmste Luege, die dieses Werkzeug erzaehlen koennte.

import { useCallback, useEffect, useMemo, useState, type JSX } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { ArrowLeft } from 'lucide-react'
import { Input } from '@/components/ui/input'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { AnswerSection } from '@/components/edvance/authoring/AnswerSection'
import { AssetsSection } from '@/components/edvance/authoring/AssetsSection'
import { AuthoringPreview } from '@/components/edvance/authoring/AuthoringPreview'
import { FlagList } from '@/components/edvance/authoring/FlagList'
import { GroundingPanel } from '@/components/edvance/authoring/GroundingPanel'
import { PartsEditor } from '@/components/edvance/authoring/PartsEditor'
import { PedagogySection } from '@/components/edvance/authoring/PedagogySection'
import { ReleaseGate } from '@/components/edvance/authoring/ReleaseGate'
import { SaveBar } from '@/components/edvance/authoring/SaveBar'
import { SchemaBanner } from '@/components/edvance/authoring/SchemaBanner'
import { TagsSection } from '@/components/edvance/authoring/TagsSection'
import { Field, Section } from '@/components/edvance/authoring/ui'
import {
  draftSolution,
  draftTask,
  fromTask,
  INPUT_TYPES,
  isMultiPart,
  toPatch,
  toSolution,
  type FormState,
} from '@/components/edvance/authoring/editorState'
import { computeFlags } from '@/lib/authoring/flags'
import { TEXTAREA_MD } from '@/lib/formStyles'
import {
  getAuthoringTask,
  getReviewerNames,
  getTaskSolution,
  listClustersWithSubject,
  probeAuthoringSchema,
  setTaskStatus,
  updateAuthoringTask,
  upsertTaskSolution,
  type AuthoringCluster,
} from '@/lib/supabase/taskAuthoring'
import { useAuth } from '@/hooks/useAuth'
import type { AuthoringSchema, AuthoringTask, GroundingBeleg, TaskStatus } from '@/types'

export function AuthoringEditorPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const { id } = useParams<{ id: string }>()
  const { role } = useAuth()
  const canWrite = role === 'admin'

  const [task, setTask] = useState<AuthoringTask | null>(null)
  const [state, setState] = useState<FormState | null>(null)
  // Der Quellenbeleg lebt BEWUSST neben dem FormState, nicht darin: was nicht im
  // Formular steht, kann ein Speichern nicht ueberschreiben (B01).
  const [beleg, setBeleg] = useState<GroundingBeleg[]>([])
  const [baseline, setBaseline] = useState<FormState | null>(null)
  const [schema, setSchema] = useState<AuthoringSchema | null>(null)
  const [clusters, setClusters] = useState<AuthoringCluster[]>([])
  const [reviewerName, setReviewerName] = useState<string | null>(null)

  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [statusError, setStatusError] = useState<string | null>(null)

  const load = useCallback(async (): Promise<void> => {
    if (!id) return
    setLoading(true)

    const [detected, taskRes, clusterRes] = await Promise.all([
      probeAuthoringSchema(),
      getAuthoringTask(id),
      listClustersWithSubject(),
    ])
    setSchema(detected)
    setClusters(clusterRes.data ?? [])

    if (taskRes.error || !taskRes.data) {
      setLoadError(taskRes.error ?? t('page.loadError'))
      setLoading(false)
      return
    }

    const solutionRes = await getTaskSolution(id)
    if (solutionRes.error || !solutionRes.data) {
      setLoadError(solutionRes.error ?? t('page.loadError'))
      setLoading(false)
      return
    }

    const form = fromTask(taskRes.data, solutionRes.data)
    setTask(taskRes.data)
    setState(form)
    setBaseline(form)
    setBeleg(solutionRes.data.beleg)

    if (taskRes.data.reviewed_by) {
      const names = await getReviewerNames([taskRes.data.reviewed_by])
      setReviewerName(names.data?.get(taskRes.data.reviewed_by) ?? null)
    } else {
      setReviewerName(null)
    }

    setLoading(false)
  }, [id, t])

  useEffect(() => {
    void load()
  }, [load])

  const set = useCallback(
    <K extends keyof FormState>(key: K, value: FormState[K]): void => {
      setState((s) => (s ? { ...s, [key]: value } : s))
    },
    [],
  )

  const dirty = useMemo(
    () => Boolean(state && baseline) && JSON.stringify(state) !== JSON.stringify(baseline),
    [state, baseline],
  )

  // Flags und Vorschau laufen ueber den DRAFT — den Stand, der gespeichert wuerde.
  // Gegen den Server-Stand zu pruefen hiesse, die Aenderung zu ignorieren, die der
  // Pfleger gerade gemacht hat.
  const flags = useMemo(() => {
    if (!task || !state || !schema) return []
    return computeFlags(draftTask(state, task), draftSolution(state, beleg), schema.hasStoffanker)
  }, [task, state, schema, beleg])

  const blockingCount = flags.filter((f) => f.blocking).length

  const competencies = useMemo(() => {
    const set2 = new Set<string>()
    if (task?.competency_content) set2.add(task.competency_content)
    for (const part of task?.parts ?? []) {
      if (part.competency_content) set2.add(part.competency_content)
    }
    return [...set2].sort()
  }, [task])

  const save = async (): Promise<void> => {
    if (!id || !state) return
    setSaveError(null)
    setBusy(true)

    const taskRes = await updateAuthoringTask(id, toPatch(state))
    if (taskRes.error || !taskRes.data) {
      setSaveError(taskRes.error ?? 'unknown')
      setBusy(false)
      return
    }

    const solRes = await upsertTaskSolution(id, toSolution(state))
    setBusy(false)
    if (solRes.error) {
      setSaveError(solRes.error)
      return
    }

    setTask(taskRes.data)
    setBaseline(state)
  }

  const changeStatus = async (next: TaskStatus): Promise<void> => {
    if (!id) return
    setStatusError(null)
    setBusy(true)
    const res = await setTaskStatus(id, next)
    setBusy(false)
    if (res.error) {
      setStatusError(res.error)
      return
    }
    await load()
  }

  if (loading) {
    return (
      <Shell>
        <LoadingPulse type="list" lines={6} />
      </Shell>
    )
  }

  if (loadError || !task || !state || !schema) {
    return (
      <Shell>
        <EmptyState
          icon="⚠️"
          title={t('page.notFound')}
          description={loadError ?? t('page.loadError')}
        />
      </Shell>
    )
  }

  const multi = isMultiPart(state)

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle={t('page.editorSubtitle')} sticky />
      <main className="mx-auto flex max-w-7xl flex-col gap-6 px-4 pb-32 pt-6">
        <Link
          to="/admin/authoring"
          className="inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
        >
          <ArrowLeft className="h-4 w-4" /> {t('page.backToList')}
        </Link>

        <SchemaBanner schema={schema} />

        <div className="grid gap-6 lg:grid-cols-[minmax(0,1fr)_minmax(0,26rem)]">
          <div className="flex flex-col gap-6">
            <Section title={t('sections.stem')}>
              <Field label={t('fields.title')}>
                <Input
                  value={state.title}
                  placeholder={t('fields.titlePlaceholder')}
                  onChange={(e) => set('title', e.target.value)}
                />
              </Field>
              <Field label={t('fields.question')}>
                <textarea
                  className={`${TEXTAREA_MD} min-h-[160px] w-full font-mono`}
                  value={state.question}
                  placeholder={t('fields.questionPlaceholder')}
                  onChange={(e) => set('question', e.target.value)}
                />
              </Field>
            </Section>

            <Section title={t('sections.type')}>
              <div className="flex flex-wrap gap-2">
                {INPUT_TYPES.map((type) => (
                  <button
                    key={type}
                    type="button"
                    onClick={() => set('input_type', type)}
                    className={`min-h-[44px] rounded-xl border px-4 text-xs font-semibold transition ${
                      state.input_type === type
                        ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-white'
                        : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
                    }`}
                  >
                    {type}
                  </button>
                ))}
              </div>
              <Field label={t('fields.estDuration')}>
                <Input
                  type="number"
                  value={state.est_duration_sec}
                  onChange={(e) => set('est_duration_sec', e.target.value)}
                />
              </Field>
            </Section>

            {multi ? (
              <Section title={t('sections.parts')}>
                <PartsEditor
                  parts={state.parts}
                  partAnswers={state.partAnswers}
                  competencies={competencies}
                  onParts={(next) => set('parts', next)}
                  onPartAnswers={(next) => set('partAnswers', next)}
                />
              </Section>
            ) : (
              <Section title={t('sections.answer')}>
                <AnswerSection state={state} set={set} />
              </Section>
            )}

            <Section title={t('sections.tags')}>
              <TagsSection
                state={state}
                set={set}
                clusters={clusters}
                competencies={competencies}
                classLevel={task.class_level}
                hasStoffankerField={schema.hasStoffanker}
              />
            </Section>

            <Section title={t('sections.pedagogy')}>
              <PedagogySection state={state} set={set} beleg={beleg} />
            </Section>

            <Section title={t('sections.assets')}>
              <AssetsSection assets={state.assets} onChange={(next) => set('assets', next)} />
            </Section>

            <GroundingPanel source={task.source} sourceRef={task.source_ref} />
          </div>

          <div className="flex flex-col gap-6 lg:sticky lg:top-24 lg:self-start">
            <AuthoringPreview state={state} />

            <Section title={t('sections.flags')}>
              <FlagList flags={flags} />
            </Section>

            <Section title={t('sections.release')}>
              <ReleaseGate
                status={task.status}
                blockingCount={blockingCount}
                dirty={dirty}
                busy={busy}
                canWrite={canWrite}
                hasAudit={schema.hasStatusGate}
                reviewerName={reviewerName}
                reviewedAt={task.reviewed_at ?? null}
                error={statusError}
                onSetStatus={(next) => void changeStatus(next)}
              />
            </Section>
          </div>
        </div>
      </main>

      <SaveBar
        dirty={dirty}
        busy={busy}
        canWrite={canWrite}
        error={saveError}
        onSave={() => void save()}
        onDiscard={() => {
          setState(baseline)
          setSaveError(null)
        }}
      />
    </div>
  )
}

function Shell({ children }: { children: JSX.Element }): JSX.Element {
  const { t } = useTranslation('authoring')
  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle={t('page.editorSubtitle')} sticky />
      <main className="mx-auto max-w-7xl px-4 py-8">{children}</main>
    </div>
  )
}
