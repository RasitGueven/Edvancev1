// Die Pflege-Strecke (/admin/pflege) — die gefuehrte Arbeitsansicht ueber der
// Editor-Maschinerie. Ein Item nach dem anderen, ein Schritt nach dem anderen,
// grosse Vorschau, nach der Freigabe automatisch das naechste Item.
//
// Der Wizard BAUT nichts nach: FormState/toPatch kommen aus editorState, die
// Flags aus computeFlags, die Vorschau aus task_preview_payload, der Status aus
// task_status_set. Er ist eine zweite Huelle um dieselben Teile — der Editor
// bleibt als Expertenansicht daneben bestehen.
//
// Gespeichert wird PRO SCHRITT (jeder Schrittwechsel schreibt den Entwurf, wenn
// er sich geaendert hat): ein Abbruch verliert hoechstens den aktuellen Schritt.
// Geschrieben wird dabei nur `tasks` (toPatch) — die Loesung ist im Wizard
// read-only, also fasst er task_solution_upsert gar nicht erst an.

import { useCallback, useEffect, useMemo, useRef, useState, type JSX } from 'react'
import { useLocation } from 'react-router-dom'
import { useTranslation } from 'react-i18next'
import { EmptyState, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { buttonVariants } from '@/components/ui/button'
import { PreviewModal } from '@/components/edvance/authoring/PreviewModal'
import {
  draftSolution,
  draftTask,
  fromTask,
  toPatch,
  type FormState,
} from '@/components/edvance/authoring/editorState'
import { StepAnchor } from '@/components/edvance/authoring/wizard/StepAnchor'
import { StepImages } from '@/components/edvance/authoring/wizard/StepImages'
import { StepRead } from '@/components/edvance/authoring/wizard/StepRead'
import { StepRelease } from '@/components/edvance/authoring/wizard/StepRelease'
import { StepSolution } from '@/components/edvance/authoring/wizard/StepSolution'
import { WizardFooter } from '@/components/edvance/authoring/wizard/WizardFooter'
import { WizardTopBar } from '@/components/edvance/authoring/wizard/WizardTopBar'
import {
  DoneScreen,
  NoQueueScreen,
  type WizardOutcome,
} from '@/components/edvance/authoring/wizard/WizardScreens'
import {
  clearQueue,
  persistPosition,
  persistQueue,
  restoreQueue,
  type PflegeQueue,
} from '@/components/edvance/authoring/wizard/wizardQueue'
import { stepsForTask, type WizardStepId } from '@/components/edvance/authoring/wizard/wizardSteps'
import { computeFlags } from '@/lib/authoring/flags'
import { imageRefFinding, type ImageRefFinding } from '@/lib/authoring/health'
import {
  getAuthoringTask,
  getTaskSolution,
  probeAuthoringSchema,
  setTaskStatus,
  updateAuthoringTask,
} from '@/lib/supabase/taskAuthoring'
import { useAuth } from '@/hooks/useAuth'
import type { AuthoringSchema, AuthoringTask, GroundingBeleg } from '@/types'

/**
 * Warteschlange aus location.state (frischer Einstieg) oder sessionStorage.
 *
 * Achtung Reload: der Browser stellt location.state wieder her. Kommt dieselbe
 * Warteschlange erneut herein, gilt die GESPEICHERTE Position weiter — sonst
 * wuerfe jeder Reload den Pfleger zurueck auf Item 1.
 */
function initialRun(state: unknown): { queue: PflegeQueue; pos: number } | null {
  const stored = restoreQueue()
  const s = state as { ids?: unknown; label?: unknown } | null
  if (s && Array.isArray(s.ids)) {
    const ids = s.ids.filter((id): id is string => typeof id === 'string')
    if (ids.length > 0) {
      if (stored && JSON.stringify(stored.queue.ids) === JSON.stringify(ids)) return stored
      const queue: PflegeQueue = { ids, label: typeof s.label === 'string' ? s.label : '' }
      persistQueue(queue)
      return { queue, pos: 0 }
    }
  }
  return stored
}

export function PflegeWizardPage(): JSX.Element {
  const { t } = useTranslation('authoring')
  const location = useLocation()
  const { role } = useAuth()
  const canWrite = role === 'admin'

  const [run] = useState(() => initialRun(location.state))
  const queue = run?.queue ?? null
  const [pos, setPos] = useState(run?.pos ?? 0)
  const [outcomes, setOutcomes] = useState<Record<string, WizardOutcome>>({})

  const finished = queue != null && pos >= queue.ids.length
  const currentId = queue && !finished ? queue.ids[pos] : null

  const [schema, setSchema] = useState<AuthoringSchema | null>(null)
  const [task, setTask] = useState<AuthoringTask | null>(null)
  const [state, setState] = useState<FormState | null>(null)
  const [baseline, setBaseline] = useState<FormState | null>(null)
  const [beleg, setBeleg] = useState<GroundingBeleg[]>([])
  const [imageRef, setImageRef] = useState<ImageRefFinding | null>(null)
  const [steps, setSteps] = useState<WizardStepId[]>([])
  const [stepIdx, setStepIdx] = useState(0)

  const [previewOpen, setPreviewOpen] = useState(false)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [loadError, setLoadError] = useState<string | null>(null)
  const [saveError, setSaveError] = useState<string | null>(null)
  const [statusError, setStatusError] = useState<string | null>(null)

  // ── Item laden ────────────────────────────────────────────────────────────
  useEffect(() => {
    if (!currentId) return
    let alive = true
    void (async () => {
      setLoading(true)
      setLoadError(null)
      setSaveError(null)
      setStatusError(null)
      const [detected, taskRes] = await Promise.all([
        probeAuthoringSchema(),
        getAuthoringTask(currentId),
      ])
      if (!alive) return
      setSchema(detected)
      if (taskRes.error || !taskRes.data) {
        setLoadError(taskRes.error ?? t('page.loadError'))
        setLoading(false)
        return
      }
      const solutionRes = await getTaskSolution(currentId)
      if (!alive) return
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
      // Verdacht + Schrittliste EINMAL beim Laden — Schritte verschwinden nicht
      // unter dem Pfleger, wenn er mittendrin den toten Pfad entfernt.
      setImageRef(imageRefFinding(taskRes.data))
      setSteps(stepsForTask(taskRes.data))
      setStepIdx(0)
      setPreviewOpen(false)
      setLoading(false)
    })()
    return () => {
      alive = false
    }
  }, [currentId, t])

  // Am Ende der Strecke ist die Warteschlange verbraucht — ein Reload soll dann
  // nicht wieder bei Item 1 anfangen.
  useEffect(() => {
    if (finished) clearQueue()
  }, [finished])

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

  // Flags ueber den DRAFT — wie im Editor (Begruendung dort).
  const flags = useMemo(() => {
    if (!task || !state || !schema) return []
    return computeFlags(draftTask(state, task), draftSolution(state, beleg), schema.hasStoffanker)
  }, [task, state, schema, beleg])
  const blockingFlags = useMemo(() => flags.filter((f) => f.blocking), [flags])

  const previewDraft = useMemo(() => (state ? toPatch(state) : null), [state])

  // ── Speichern pro Schritt ─────────────────────────────────────────────────
  const saveStep = useCallback(async (): Promise<boolean> => {
    if (!currentId || !state || !dirty) return true
    setSaveError(null)
    setBusy(true)
    const res = await updateAuthoringTask(currentId, toPatch(state))
    setBusy(false)
    if (res.error || !res.data) {
      setSaveError(res.error ?? 'unknown')
      return false
    }
    setTask(res.data)
    setBaseline(state)
    return true
  }, [currentId, state, dirty])

  const goNext = useCallback(async (): Promise<void> => {
    if (busy || stepIdx >= steps.length - 1) return
    if (await saveStep()) setStepIdx((i) => i + 1)
  }, [busy, stepIdx, steps.length, saveStep])

  const goBack = useCallback(async (): Promise<void> => {
    if (busy || stepIdx === 0) return
    if (await saveStep()) setStepIdx((i) => i - 1)
  }, [busy, stepIdx, saveStep])

  const advanceItem = useCallback(
    (outcome?: WizardOutcome): void => {
      if (outcome && currentId) {
        setOutcomes((prev) => ({ ...prev, [currentId]: outcome }))
      }
      persistPosition(pos + 1)
      setPos(pos + 1)
    },
    [currentId, pos],
  )

  const changeStatusAndAdvance = useCallback(
    async (status: 'ready' | 'review', outcome: WizardOutcome): Promise<void> => {
      if (!currentId) return
      setStatusError(null)
      if (!(await saveStep())) return
      setBusy(true)
      const res = await setTaskStatus(currentId, status)
      setBusy(false)
      if (res.error) {
        setStatusError(res.error)
        return
      }
      advanceItem(outcome)
    },
    [currentId, saveStep, advanceItem],
  )

  const skip = useCallback(async (): Promise<void> => {
    if (!(await saveStep())) return
    advanceItem('skipped')
  }, [saveStep, advanceItem])

  // ── Tastatur: Enter = weiter, V = Vorschau, Esc = Vorschau zu ─────────────
  // Ein Listener, Refs fuer den aktuellen Stand — sonst haengt am Fenster ein
  // veralteter Closure-Stand.
  const keyCtx = useRef({ next: goNext, previewOpen })
  keyCtx.current = { next: goNext, previewOpen }
  useEffect(() => {
    const onKey = (e: KeyboardEvent): void => {
      const el = e.target as HTMLElement | null
      const tag = el?.tagName ?? ''
      const typing = tag === 'TEXTAREA' || tag === 'SELECT' || Boolean(el?.isContentEditable)
      if (e.key === 'Escape') {
        setPreviewOpen(false)
        return
      }
      if (keyCtx.current.previewOpen) return
      if ((e.key === 'v' || e.key === 'V') && !typing && tag !== 'INPUT') {
        e.preventDefault()
        setPreviewOpen(true)
        return
      }
      if (e.key === 'Enter' && !typing && tag !== 'BUTTON' && tag !== 'A') {
        e.preventDefault()
        void keyCtx.current.next()
      }
    }
    window.addEventListener('keydown', onKey)
    return () => window.removeEventListener('keydown', onKey)
  }, [])

  // ── Render ────────────────────────────────────────────────────────────────
  if (!queue) return <NoQueueScreen />
  if (finished) return <DoneScreen total={queue.ids.length} outcomes={outcomes} />

  const step = steps[stepIdx] ?? 'read'

  return (
    <div className="min-h-screen bg-[var(--color-bg-app)] font-[family-name:var(--font-body)]">
      <EdvanceNavbar subtitle={t('wizard.subtitle')} sticky />
      <main className="mx-auto flex max-w-6xl flex-col gap-6 px-4 pb-36 pt-6">
        <WizardTopBar
          label={queue.label}
          position={pos + 1}
          total={queue.ids.length}
          onPreview={() => setPreviewOpen(true)}
        />

        {loading && <LoadingPulse type="list" lines={6} />}

        {!loading && (loadError || !task || !state || !schema) && (
          <>
            <EmptyState
              icon="⚠️"
              title={t('wizard.loadErrorTitle')}
              description={loadError ?? t('page.loadError')}
            />
            <div className="flex justify-center">
              <button
                type="button"
                onClick={() => advanceItem()}
                className={buttonVariants({ variant: 'outline', size: 'sm' })}
              >
                {t('wizard.skipBroken')}
              </button>
            </div>
          </>
        )}

        {!loading && !loadError && task && state && schema && (
          <>
            {step === 'read' && previewDraft && (
              <StepRead task={task} draft={previewDraft} dirty={dirty} flags={flags} />
            )}
            {step === 'anchor' && (
              <StepAnchor
                task={task}
                grade={state.curriculum_grade}
                hasStoffanker={schema.hasStoffanker}
                canWrite={canWrite}
                onSelect={(g) => set('curriculum_grade', g)}
                onConfirm={() => void goNext()}
              />
            )}
            {step === 'images' && (
              <StepImages
                task={task}
                assets={state.assets}
                needsImage={state.needs_image}
                parts={state.parts}
                imageRef={imageRef}
                canWrite={canWrite}
                onAssets={(next) => set('assets', next)}
                onNeedsImage={(next) => set('needs_image', next)}
                onPart={(i, next) =>
                  set(
                    'parts',
                    state.parts.map((p, j) => (j === i ? { ...p, needs_image: next } : p)),
                  )
                }
              />
            )}
            {step === 'solution' && (
              <StepSolution taskId={task.id} state={state} beleg={beleg} />
            )}
            {step === 'release' && (
              <StepRelease
                status={task.status}
                blocking={blockingFlags}
                busy={busy}
                isAdmin={canWrite}
                error={statusError}
                onRelease={() => void changeStatusAndAdvance('ready', 'released')}
                onReview={() => void changeStatusAndAdvance('review', 'reviewed')}
                onSkip={() => void skip()}
                onNextItem={() => advanceItem()}
              />
            )}
          </>
        )}
      </main>

      {currentId && previewDraft && (
        <PreviewModal
          open={previewOpen}
          onClose={() => setPreviewOpen(false)}
          taskId={currentId}
          draft={previewDraft}
          dirty={dirty}
          wide
        />
      )}

      {!loading && !loadError && task && (
        <WizardFooter
          step={step}
          stepIndex={stepIdx}
          stepCount={steps.length}
          dirty={dirty}
          busy={busy}
          canWrite={canWrite}
          error={saveError}
          onBack={() => void goBack()}
          onNext={() => void goNext()}
        />
      )}
    </div>
  )
}
