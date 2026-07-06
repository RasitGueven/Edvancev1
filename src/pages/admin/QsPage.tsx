import { useEffect, useMemo, useState, type JSX } from 'react'
import { Link } from 'react-router-dom'
import { ArrowLeft, Plus, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { EdvanceCard, LoadingPulse } from '@/components/edvance'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import { MathContent } from '@/lib/render/MathContent'
import {
  TaskRenderer,
  EMPTY_TASK_STATE,
  type TaskState,
} from '@/components/edvance/tasks/TaskRenderer'
import { isMcPayload } from '@/lib/screening/screeningRuntime'
import {
  Field,
  SaveBar,
  SELECT,
  TEXTAREA,
} from '@/components/edvance/screening/editor/ScreeningEditorPrimitives'
import {
  listScreeningItems,
  createScreeningItem,
  updateScreeningItem,
  setScreeningItemActive,
} from '@/lib/supabase/screeningItems'
import {
  getSubjects,
  getClustersBySubject,
  getMicroskillsByCluster,
} from '@/lib/supabase/tasks'
import { listProcessCompetencies } from '@/lib/supabase/competencyMastery'
import type {
  Microskill,
  ProcessCompetency,
  ScreeningAfb,
  ScreeningCheckType,
  ScreeningInputType,
  ScreeningItem,
  ScreeningItemInput,
  ScreeningLevel,
  ScreeningPhase,
  SkillCluster,
  Subject,
} from '@/types'

// ---------------------------------------------------------------------------
// Geführter QS-/Tagging-Editor für Screening-Items (/admin/qs).
// Phase 1: MC / NUMERIC / FREE_TEXT vollständig geführt; Vorschau über den
// echten TaskRenderer (1:1 Schüler-Ansicht). Weitere Formate folgen.
// ---------------------------------------------------------------------------

const LETTERS = ['A', 'B', 'C', 'D', 'E', 'F']

type QsLevel = 'error' | 'warn' | 'info'
type QsCheck = { lvl: QsLevel; msg: string }

type Draft = {
  skill_label: string
  skill_code: string
  topic: string
  class_level: number
  level: ScreeningLevel
  input_type: ScreeningInputType
  prompt: string
  kontext: string
  afb: ScreeningAfb | ''
  phase: ScreeningPhase | ''
  cluster_id: string
  competency_id: string
  microskill_id: string
  explanation: string
  typical: string
  // answer builders
  mcOptions: string[]
  mcCorrect: number
  numericValue: string
  numericTolerance: string
}

type FormatDef = {
  id: ScreeningInputType
  label: string
  hint: string
  ready: boolean
}

const FORMATS: FormatDef[] = [
  { id: 'MC', label: 'Multiple Choice', hint: 'Mehrere Optionen, genau eine richtig', ready: true },
  { id: 'NUMERIC', label: 'Zahl', hint: 'Eine Zahl als Lösung (mit Toleranz)', ready: true },
  { id: 'FREE_TEXT', label: 'Freitext', hint: 'Offene Antwort — der Coach bewertet', ready: true },
  { id: 'SHORT_TEXT', label: 'Kurztext', hint: 'Kurze Texteingabe', ready: false },
  { id: 'TRUE_FALSE', label: 'Wahr / Falsch', hint: 'Zwei Optionen', ready: false },
  { id: 'MATCHING', label: 'Zuordnung', hint: 'Paare verbinden', ready: false },
  { id: 'CLOZE', label: 'Lückentext', hint: 'Wörter einsetzen', ready: false },
  { id: 'COORDINATE', label: 'Koordinaten', hint: 'Punkte im Gitter', ready: false },
]

const STEPS = ['Format', 'Aufgabe', 'Antwort', 'Einordnung', 'Freigabe']

function emptyDraft(): Draft {
  return {
    skill_label: '',
    skill_code: '',
    topic: '',
    class_level: 8,
    level: 1,
    input_type: 'MC',
    prompt: '',
    kontext: '',
    afb: '',
    phase: '',
    cluster_id: '',
    competency_id: '',
    microskill_id: '',
    explanation: '',
    typical: '',
    mcOptions: ['', ''],
    mcCorrect: 0,
    numericValue: '',
    numericTolerance: '',
  }
}

function draftFromItem(it: ScreeningItem): Draft {
  const d = emptyDraft()
  d.skill_label = it.skill_label ?? ''
  d.skill_code = it.skill_code ?? ''
  d.topic = it.topic ?? ''
  d.class_level = it.class_level
  d.level = it.level
  d.input_type = it.input_type
  d.prompt = it.prompt ?? ''
  d.kontext = it.kontext ?? ''
  d.afb = it.afb ?? ''
  d.phase = it.phase ?? ''
  d.cluster_id = it.cluster_id ?? ''
  d.competency_id = it.competency_id ?? ''
  d.microskill_id = it.microskill_id ?? ''
  d.explanation = it.explanation ?? ''
  d.typical = it.typical_errors.join('\n')
  if (it.input_type === 'MC' && isMcPayload(it.payload)) {
    d.mcOptions = it.payload.options.length > 0 ? [...it.payload.options] : ['', '']
    const c = it.canonical as { index?: number } | null
    d.mcCorrect = typeof c?.index === 'number' ? c.index : 0
  }
  if (it.input_type === 'NUMERIC') {
    const c = it.canonical as { value?: number | null } | null
    d.numericValue = c?.value != null ? String(c.value) : ''
    d.numericTolerance = it.tolerance != null ? String(it.tolerance) : ''
  }
  return d
}

type Derived = {
  payload: unknown
  canonical: unknown
  check_type: ScreeningCheckType
  tolerance: number | null
}

function derive(d: Draft): Derived {
  if (d.input_type === 'MC') {
    const options = d.mcOptions.map((o) => o.trim()).filter(Boolean)
    return {
      payload: { type: 'mc', options, correct_index: d.mcCorrect },
      canonical: { index: d.mcCorrect },
      check_type: 'mc_index',
      tolerance: null,
    }
  }
  if (d.input_type === 'NUMERIC') {
    const v = d.numericValue.trim()
    return {
      payload: null,
      canonical: { value: v === '' ? null : Number(v) },
      check_type: 'numeric',
      tolerance: d.numericTolerance.trim() === '' ? null : Number(d.numericTolerance),
    }
  }
  // FREE_TEXT (and any not-yet-built format) → coach-graded
  return { payload: null, canonical: {}, check_type: 'manual', tolerance: null }
}

function buildInputFromDraft(d: Draft): ScreeningItemInput {
  const der = derive(d)
  return {
    cluster_id: d.cluster_id,
    class_level: d.class_level,
    topic: d.topic.trim(),
    skill_code: d.skill_code.trim(),
    skill_label: d.skill_label.trim(),
    level: d.level,
    curriculum_seq: null,
    input_type: d.input_type,
    prompt: d.prompt.trim(),
    payload: der.payload,
    canonical: der.canonical,
    check_type: der.check_type,
    tolerance: der.tolerance,
    typical_errors: d.typical.split('\n').map((s) => s.trim()).filter(Boolean),
    explanation: d.explanation.trim() === '' ? null : d.explanation.trim(),
    afb: d.afb === '' ? null : d.afb,
    phase: d.phase === '' ? null : d.phase,
    kontext: d.kontext.trim() === '' ? null : d.kontext.trim(),
    competency_id: d.competency_id || null,
    microskill_id: d.microskill_id || null,
  }
}

function qsChecks(d: Draft): QsCheck[] {
  const out: QsCheck[] = []
  if (!d.prompt.trim()) out.push({ lvl: 'error', msg: 'Aufgabentext fehlt' })
  if (!d.skill_label.trim()) out.push({ lvl: 'warn', msg: 'Kein Titel (skill_label)' })
  if (!d.cluster_id) out.push({ lvl: 'warn', msg: 'Kein Inhaltsfeld / Cluster (Achse A)' })
  if (!d.competency_id) out.push({ lvl: 'warn', msg: 'Keine Prozesskompetenz (Achse B)' })
  if (!d.microskill_id) out.push({ lvl: 'warn', msg: 'Kein Microskill (Achse C)' })
  if ((d.afb === '') !== (d.phase === '')) out.push({ lvl: 'info', msg: 'AFB und Phase nur zusammen sinnvoll' })
  if (d.input_type === 'MC') {
    const opts = d.mcOptions.map((o) => o.trim()).filter(Boolean)
    if (opts.length < 2) out.push({ lvl: 'error', msg: 'Mindestens 2 Antwortoptionen nötig' })
    if (!d.mcOptions[d.mcCorrect]?.trim()) out.push({ lvl: 'error', msg: 'Richtige Option ist leer' })
  }
  if (d.input_type === 'NUMERIC' && d.numericValue.trim() === '') {
    out.push({ lvl: 'warn', msg: 'Keine erwartete Zahl gesetzt' })
  }
  return out
}

function itemTitle(it: ScreeningItem): string {
  return it.skill_label || it.skill_code || (it.prompt ? it.prompt.slice(0, 40) : '') || '(ohne Titel)'
}

export function QsPage(): JSX.Element {
  const [items, setItems] = useState<ScreeningItem[]>([])
  const [loadingList, setLoadingList] = useState(true)
  const [search, setSearch] = useState('')
  const [subjects, setSubjects] = useState<Subject[]>([])
  const [clusters, setClusters] = useState<SkillCluster[]>([])
  const [competencies, setCompetencies] = useState<ProcessCompetency[]>([])
  const [microskills, setMicroskills] = useState<Microskill[]>([])
  const [d, setDraft] = useState<Draft>(emptyDraft)
  const [loaded, setLoaded] = useState<ScreeningItem | null>(null)
  const [active, setActive] = useState(false)
  const [step, setStep] = useState(0)
  const [previewState, setPreviewState] = useState<TaskState>(EMPTY_TASK_STATE)
  const [dirty, setDirty] = useState(false)
  const [busy, setBusy] = useState(false)
  const [err, setErr] = useState<string | null>(null)

  const up = (patch: Partial<Draft>): void => {
    setDraft((prev) => ({ ...prev, ...patch }))
    setDirty(true)
    setErr(null)
  }

  const refreshList = (): void => {
    setLoadingList(true)
    listScreeningItems().then(({ data }) => {
      setItems(data ?? [])
      setLoadingList(false)
    })
  }

  useEffect(() => {
    refreshList()
    void (async () => {
      const [{ data: subs }, { data: comps }] = await Promise.all([
        getSubjects(),
        listProcessCompetencies(),
      ])
      setCompetencies(comps ?? [])
      const subjectList = subs ?? []
      setSubjects(subjectList)
      const lists = await Promise.all(subjectList.map((s) => getClustersBySubject(s.id)))
      setClusters(lists.flatMap((r) => r.data ?? []))
    })()
  }, [])

  useEffect(() => {
    if (!d.cluster_id) {
      setMicroskills([])
      return
    }
    getMicroskillsByCluster(d.cluster_id).then(({ data }) => setMicroskills(data ?? []))
  }, [d.cluster_id])

  // Vorschau-Antwortzustand zurücksetzen, wenn Format oder Item wechselt.
  useEffect(() => {
    setPreviewState(EMPTY_TASK_STATE)
  }, [d.input_type, loaded?.id])

  const derived = useMemo(() => derive(d), [d])
  const checks = useMemo(() => qsChecks(d), [d])
  const errorCount = checks.filter((c) => c.lvl === 'error').length

  const previewItem = useMemo<ScreeningItem>(
    () => ({
      id: loaded?.id ?? 'preview',
      created_at: loaded?.created_at ?? '',
      cluster_id: d.cluster_id,
      class_level: d.class_level,
      topic: d.topic,
      skill_code: d.skill_code,
      skill_label: d.skill_label,
      level: d.level,
      curriculum_seq: null,
      input_type: d.input_type,
      prompt: d.prompt,
      payload: derived.payload,
      canonical: derived.canonical,
      check_type: derived.check_type,
      tolerance: derived.tolerance,
      typical_errors: [],
      explanation: null,
      source: '',
      active: false,
      afb: d.afb === '' ? null : d.afb,
      phase: d.phase === '' ? null : d.phase,
      kontext: d.kontext.trim() === '' ? null : d.kontext.trim(),
      teilaufgaben: null,
      akzeptierte_antworten: null,
      competency_id: d.competency_id || null,
      microskill_id: d.microskill_id || null,
    }),
    [d, derived, loaded],
  )

  const subjectName = (id: string): string => subjects.find((s) => s.id === id)?.name ?? ''

  const selectItem = (it: ScreeningItem): void => {
    setLoaded(it)
    setDraft(draftFromItem(it))
    setActive(it.active)
    setDirty(false)
    setErr(null)
    setStep(1)
  }

  const startNew = (): void => {
    setLoaded(null)
    setDraft(emptyDraft())
    setActive(false)
    setDirty(false)
    setErr(null)
    setStep(0)
  }

  const setMcOption = (i: number, v: string): void => {
    setDraft((p) => ({ ...p, mcOptions: p.mcOptions.map((o, idx) => (idx === i ? v : o)) }))
    setDirty(true)
  }
  const addMcOption = (): void => {
    setDraft((p) => (p.mcOptions.length >= 6 ? p : { ...p, mcOptions: [...p.mcOptions, ''] }))
    setDirty(true)
  }
  const removeMcOption = (i: number): void => {
    setDraft((p) => {
      if (p.mcOptions.length <= 2) return p
      const mcOptions = p.mcOptions.filter((_, idx) => idx !== i)
      const mcCorrect = p.mcCorrect >= mcOptions.length ? mcOptions.length - 1 : p.mcCorrect
      return { ...p, mcOptions, mcCorrect }
    })
    setDirty(true)
  }

  const save = async (): Promise<void> => {
    setErr(null)
    if (!d.prompt.trim()) {
      setErr('Aufgabentext fehlt.')
      setStep(1)
      return
    }
    if (!d.cluster_id) {
      setErr('Bitte ein Inhaltsfeld (Cluster) wählen.')
      setStep(3)
      return
    }
    if (!d.skill_label.trim()) {
      setErr('Bitte einen Titel angeben.')
      setStep(3)
      return
    }
    setBusy(true)
    const input = buildInputFromDraft(d)
    const res = loaded
      ? await updateScreeningItem(loaded.id, input)
      : await createScreeningItem(input)
    setBusy(false)
    if (res.error || !res.data) {
      setErr(res.error ?? 'Speichern fehlgeschlagen.')
      return
    }
    setLoaded(res.data)
    setActive(res.data.active)
    setDirty(false)
    refreshList()
  }

  const toggleActive = async (): Promise<void> => {
    if (!loaded) {
      setErr('Erst speichern, dann freigeben.')
      return
    }
    if (dirty) {
      setErr('Erst speichern, dann freigeben.')
      return
    }
    if (!active) {
      if (errorCount > 0) {
        setErr('Erst die QS-Fehler beheben, dann aktiv schalten.')
        return
      }
      if (!window.confirm('Aktiv schalten?\n\nAktiv = im Screening für Schüler:innen sichtbar.')) return
    }
    const next = !active
    setActive(next)
    const res = await setScreeningItemActive(loaded.id, next)
    if (res.error) {
      setActive(!next)
      setErr(res.error)
      return
    }
    refreshList()
  }

  const filtered = items.filter((it) => {
    if (!search.trim()) return true
    const q = search.toLowerCase()
    return (itemTitle(it) + ' ' + (it.skill_code ?? '')).toLowerCase().includes(q)
  })

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Aufgaben-QS & Tagging" sticky />
      <main className="mx-auto max-w-[1400px] px-4 pb-32 pt-6">
        <Link
          to="/admin"
          className="mb-3 inline-flex items-center gap-1 text-sm text-[var(--color-text-tertiary)]"
        >
          <ArrowLeft className="h-4 w-4" /> Admin
        </Link>

        <div className="grid gap-5 lg:grid-cols-[260px_1fr_minmax(320px,400px)]">
          {/* LEFT: item list */}
          <aside className="flex flex-col gap-3">
            <Button onClick={startNew} className="w-full">
              <Plus className="h-4 w-4" /> Neue Aufgabe
            </Button>
            <Input
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Suchen …"
            />
            <div className="flex max-h-[70vh] flex-col gap-1.5 overflow-y-auto pr-1">
              {loadingList ? (
                <LoadingPulse type="list" lines={6} />
              ) : (
                filtered.map((it) => {
                  const sel = loaded?.id === it.id
                  return (
                    <button
                      key={it.id}
                      type="button"
                      onClick={() => selectItem(it)}
                      className={`rounded-xl border p-2.5 text-left text-sm transition ${
                        sel
                          ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]'
                          : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] hover:border-[var(--color-primary)]'
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="truncate font-medium text-[var(--color-text-primary)]">
                          {itemTitle(it)}
                        </span>
                        {!it.microskill_id && (
                          <span
                            title="kein Microskill"
                            className="ml-auto shrink-0 text-[var(--color-gold-warning)]"
                          >
                            ◌
                          </span>
                        )}
                      </div>
                      <div className="mt-0.5 text-xs text-[var(--color-text-tertiary)]">
                        Kl.{it.class_level} · {it.input_type}
                        {it.active ? ' · aktiv' : ''}
                      </div>
                    </button>
                  )
                })
              )}
              {!loadingList && filtered.length === 0 && (
                <p className="px-1 py-6 text-center text-sm text-[var(--color-text-tertiary)]">
                  Keine Aufgaben.
                </p>
              )}
            </div>
          </aside>

          {/* CENTER: guided steps */}
          <section className="flex flex-col gap-4">
            <StepNav step={step} onStep={setStep} errorCount={errorCount} />
            <EdvanceCard className="p-5">{renderStep()}</EdvanceCard>
            <div className="flex items-center justify-between">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setStep((s) => Math.max(0, s - 1))}
                disabled={step === 0}
              >
                Zurück
              </Button>
              {step < STEPS.length - 1 ? (
                <Button size="sm" onClick={() => setStep((s) => Math.min(STEPS.length - 1, s + 1))}>
                  Weiter
                </Button>
              ) : (
                <Button size="sm" onClick={save} disabled={busy}>
                  {busy ? 'Speichert…' : loaded ? 'Speichern' : 'Anlegen'}
                </Button>
              )}
            </div>
          </section>

          {/* RIGHT: live student preview */}
          <aside className="lg:sticky lg:top-20 lg:self-start">
            <p className="mb-2 text-xs font-semibold uppercase tracking-widest text-[var(--color-text-tertiary)]">
              Vorschau · so sieht es der Schüler
            </p>
            <EdvanceCard className="p-6">
              {d.prompt.trim() ? (
                <>
                  <div className="text-[var(--color-text-primary)]">
                    <MathContent text={d.prompt} />
                  </div>
                  <div className="mt-5">
                    <TaskRenderer
                      item={previewItem}
                      state={previewState}
                      onChange={setPreviewState}
                      disabled={false}
                      studentId={null}
                    />
                  </div>
                  <Button className="mt-6 w-full rounded-xl" disabled>
                    Weiter
                  </Button>
                </>
              ) : (
                <p className="py-10 text-center text-sm text-[var(--color-text-tertiary)]">
                  Sobald du einen Aufgabentext eingibst, erscheint hier die echte Schüler-Ansicht.
                </p>
              )}
            </EdvanceCard>
            <CoachAnswerNote d={d} />
          </aside>
        </div>
      </main>

      <SaveBar
        dirty={dirty}
        busy={busy}
        error={err}
        onSave={save}
        onDiscard={() => {
          if (loaded) setDraft(draftFromItem(loaded))
          else setDraft(emptyDraft())
          setDirty(false)
          setErr(null)
        }}
      />
    </div>
  )

  function renderStep(): JSX.Element {
    if (step === 0) {
      return (
        <div className="flex flex-col gap-3">
          <StepHead title="Welches Antwortformat?" hint="Bestimmt, wie Schüler:innen antworten — und welche Felder du danach ausfüllst." />
          <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-3">
            {FORMATS.map((f) => {
              const sel = d.input_type === f.id
              return (
                <button
                  key={f.id}
                  type="button"
                  disabled={!f.ready}
                  onClick={() => up({ input_type: f.id })}
                  className={`flex flex-col gap-1 rounded-xl border-2 p-3 text-left transition ${
                    sel
                      ? 'border-[var(--color-primary)] bg-[var(--color-primary-light)]'
                      : 'border-[var(--color-border)] bg-[var(--color-bg-surface)]'
                  } ${f.ready ? 'hover:border-[var(--color-primary)]' : 'cursor-not-allowed opacity-50'}`}
                >
                  <span className="text-sm font-semibold text-[var(--color-text-primary)]">
                    {f.label}
                  </span>
                  <span className="text-xs text-[var(--color-text-tertiary)]">
                    {f.ready ? f.hint : 'folgt'}
                  </span>
                </button>
              )
            })}
          </div>
        </div>
      )
    }
    if (step === 1) {
      return (
        <div className="flex flex-col gap-3">
          <StepHead title="Aufgabentext" hint="Das, was die Schüler:in liest. Formeln in $…$ — rechts siehst du die Vorschau sofort." />
          <Field label="Aufgabentext (prompt)">
            <textarea
              className={TEXTAREA}
              value={d.prompt}
              onChange={(e) => up({ prompt: e.target.value })}
              placeholder="z.B. Kürze den Bruch $\frac{6}{8}$ so weit wie möglich."
            />
          </Field>
          <Field label="Kontext / Einleitung (optional)">
            <textarea
              className={TEXTAREA}
              value={d.kontext}
              onChange={(e) => up({ kontext: e.target.value })}
            />
          </Field>
        </div>
      )
    }
    if (step === 2) return <AnswerStep />
    if (step === 3) {
      return (
        <div className="flex flex-col gap-3">
          <StepHead title="Einordnung & Tagging" hint="Wo gehört die Aufgabe hin? Microskill bestimmt später den Lernpfad — bitte immer setzen." />
          <Field label="Titel (skill_label)">
            <Input value={d.skill_label} onChange={(e) => up({ skill_label: e.target.value })} placeholder="Kurzer, eindeutiger Titel" />
          </Field>
          <div className="grid grid-cols-2 gap-3">
            <Field label="Skill-Code (optional)">
              <Input value={d.skill_code} onChange={(e) => up({ skill_code: e.target.value })} />
            </Field>
            <Field label="Thema / topic (optional)">
              <Input value={d.topic} onChange={(e) => up({ topic: e.target.value })} />
            </Field>
          </div>
          <Field label="Inhaltsfeld / Cluster (Achse A)">
            <select
              className={SELECT}
              value={d.cluster_id}
              onChange={(e) => up({ cluster_id: e.target.value, microskill_id: '' })}
            >
              <option value="">– wählen –</option>
              {clusters.map((c) => (
                <option key={c.id} value={c.id}>
                  {subjectName(c.subject_id)} · {c.name} ({c.class_level_min}–{c.class_level_max})
                </option>
              ))}
            </select>
          </Field>
          <Field label="Microskill (Achse C — feinste Granularität)">
            <select
              className={SELECT}
              value={d.microskill_id}
              onChange={(e) => up({ microskill_id: e.target.value })}
              disabled={!d.cluster_id}
            >
              <option value="">{d.cluster_id ? '– kein Microskill –' : '– erst Cluster wählen –'}</option>
              {microskills.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.code} · {m.name} · Kl.{m.class_level}
                </option>
              ))}
            </select>
          </Field>
          <Field label="Prozesskompetenz (Achse B)">
            <select
              className={SELECT}
              value={d.competency_id}
              onChange={(e) => up({ competency_id: e.target.value })}
            >
              <option value="">– keine –</option>
              {competencies.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.code} · {c.name}
                </option>
              ))}
            </select>
          </Field>
          <div className="grid grid-cols-3 gap-3">
            <Field label="AFB">
              <select className={SELECT} value={d.afb} onChange={(e) => up({ afb: e.target.value as Draft['afb'] })}>
                <option value="">–</option>
                <option value="I">I</option>
                <option value="II">II</option>
                <option value="III">III</option>
              </select>
            </Field>
            <Field label="Phase">
              <select className={SELECT} value={d.phase} onChange={(e) => up({ phase: e.target.value as Draft['phase'] })}>
                <option value="">–</option>
                <option value="sprint">Sprint</option>
                <option value="tiefe">Tiefe</option>
              </select>
            </Field>
            <Field label="Klasse">
              <select
                className={SELECT}
                value={d.class_level}
                onChange={(e) => up({ class_level: Number(e.target.value) })}
              >
                {[5, 6, 7, 8, 9, 10, 11, 12, 13].map((n) => (
                  <option key={n} value={n}>
                    {n}
                  </option>
                ))}
              </select>
            </Field>
          </div>
        </div>
      )
    }
    return <ReleaseStep />
  }

  function AnswerStep(): JSX.Element {
    if (d.input_type === 'MC') {
      return (
        <div className="flex flex-col gap-3">
          <StepHead title="Antwortoptionen" hint="Tippe die Optionen ein und wähle links die richtige aus." />
          {d.mcOptions.map((opt, i) => (
            <div key={i} className="flex items-center gap-2">
              <input
                type="radio"
                name="mc-correct"
                checked={d.mcCorrect === i}
                onChange={() => up({ mcCorrect: i })}
                title="richtige Antwort"
                className="h-4 w-4 shrink-0 accent-[var(--color-primary)]"
              />
              <span className="w-5 shrink-0 text-sm font-semibold text-[var(--color-text-tertiary)]">
                {LETTERS[i]}
              </span>
              <Input value={opt} onChange={(e) => setMcOption(i, e.target.value)} placeholder={`Option ${LETTERS[i]}`} />
              <button
                type="button"
                onClick={() => removeMcOption(i)}
                disabled={d.mcOptions.length <= 2}
                title="Entfernen"
                className="grid h-9 w-9 shrink-0 place-items-center rounded-lg border border-[var(--color-border)] text-[var(--color-text-tertiary)] disabled:opacity-40"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          ))}
          {d.mcOptions.length < 6 && (
            <Button variant="outline" size="sm" onClick={addMcOption} className="self-start">
              <Plus className="h-4 w-4" /> Option
            </Button>
          )}
        </div>
      )
    }
    if (d.input_type === 'NUMERIC') {
      return (
        <div className="flex flex-col gap-3">
          <StepHead title="Erwartete Zahl" hint="Die korrekte Zahl und optional eine Toleranz (z.B. 0.1 für Rundung)." />
          <div className="grid grid-cols-2 gap-3">
            <Field label="Richtige Zahl">
              <Input
                value={d.numericValue}
                onChange={(e) => up({ numericValue: e.target.value })}
                placeholder="z.B. 1,4 → 1.4"
                inputMode="decimal"
              />
            </Field>
            <Field label="Toleranz (optional)">
              <Input
                value={d.numericTolerance}
                onChange={(e) => up({ numericTolerance: e.target.value })}
                placeholder="z.B. 0.1"
                inputMode="decimal"
              />
            </Field>
          </div>
          <p className="text-xs text-[var(--color-text-tertiary)]">
            Dezimaltrennzeichen als Punkt eingeben (1.4). Auto-Bewertung über check_type „numeric".
          </p>
        </div>
      )
    }
    // FREE_TEXT
    return (
      <div className="flex flex-col gap-3">
        <StepHead title="Freitext-Antwort" hint="Offene Aufgabe — es gibt keine Auto-Lösung, der Coach bewertet die Antwort." />
        <Field label="Bewertungshinweis für den Coach (optional)">
          <textarea
            className={TEXTAREA}
            value={d.explanation}
            onChange={(e) => up({ explanation: e.target.value })}
            placeholder="Worauf kommt es bei der Bewertung an?"
          />
        </Field>
      </div>
    )
  }

  function ReleaseStep(): JSX.Element {
    return (
      <div className="flex flex-col gap-4">
        <StepHead title="QS & Freigabe" hint="Prüfe die Hinweise, speichere — und schalte die Aufgabe erst dann aktiv." />
        <div className="flex flex-col gap-1.5">
          {checks.length === 0 ? (
            <div className="rounded-xl bg-[var(--color-success-soft,#E3F1EB)] px-3 py-2 text-sm font-semibold text-[var(--color-success,#0F6E56)]">
              ✓ Keine offenen QS-Punkte.
            </div>
          ) : (
            checks.map((c, i) => (
              <div
                key={i}
                className={`rounded-xl px-3 py-2 text-sm ${
                  c.lvl === 'error'
                    ? 'bg-[var(--color-danger-soft,#FBE3E3)] text-[var(--color-danger,#DC2626)]'
                    : c.lvl === 'warn'
                      ? 'bg-[var(--color-warning-soft,#FBEEDC)] text-[var(--color-warning,#D97706)]'
                      : 'bg-[var(--color-bg-subtle)] text-[var(--color-text-secondary)]'
                }`}
              >
                {c.lvl === 'error' ? '✕' : c.lvl === 'warn' ? '⚑' : 'ℹ'} {c.msg}
              </div>
            ))
          )}
        </div>

        <div className="flex flex-col gap-2 rounded-xl border border-[var(--color-border)] p-4">
          <div className="flex items-center gap-3">
            <Button
              variant={active ? 'outline' : 'default'}
              size="sm"
              onClick={toggleActive}
              disabled={!loaded || dirty}
            >
              {active ? 'Aktiv — deaktivieren' : 'Aktiv schalten'}
            </Button>
            <span className="text-xs text-[var(--color-text-tertiary)]">
              {!loaded
                ? 'Erst speichern.'
                : dirty
                  ? 'Erst speichern, dann freigeben.'
                  : active
                    ? 'Für Schüler:innen sichtbar.'
                    : errorCount > 0
                      ? 'QS-Fehler beheben, dann freischaltbar.'
                      : 'Bereit zum Freischalten.'}
            </span>
          </div>
        </div>

        <Button onClick={save} disabled={busy} className="self-start">
          {busy ? 'Speichert…' : loaded ? 'Speichern' : 'Anlegen'}
        </Button>
      </div>
    )
  }
}

function StepNav({
  step,
  onStep,
  errorCount,
}: {
  step: number
  onStep: (n: number) => void
  errorCount: number
}): JSX.Element {
  return (
    <div className="flex flex-wrap gap-1.5">
      {STEPS.map((label, i) => {
        const sel = step === i
        const isRelease = i === STEPS.length - 1
        return (
          <button
            key={label}
            type="button"
            onClick={() => onStep(i)}
            className={`flex items-center gap-1.5 rounded-full border px-3 py-1.5 text-xs font-semibold transition ${
              sel
                ? 'border-[var(--color-primary)] bg-[var(--color-primary)] text-white'
                : 'border-[var(--color-border)] bg-[var(--color-bg-surface)] text-[var(--color-text-secondary)]'
            }`}
          >
            <span className={`grid h-4 w-4 place-items-center rounded-full text-[10px] ${sel ? 'bg-white/25' : 'bg-[var(--color-bg-subtle)]'}`}>
              {i + 1}
            </span>
            {label}
            {isRelease && errorCount > 0 && (
              <span className="ml-1 rounded-full bg-[var(--color-danger,#DC2626)] px-1.5 text-[10px] text-white">
                {errorCount}
              </span>
            )}
          </button>
        )
      })}
    </div>
  )
}

function StepHead({ title, hint }: { title: string; hint: string }): JSX.Element {
  return (
    <div className="flex flex-col gap-1">
      <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{title}</h2>
      <p className="text-sm text-[var(--color-text-secondary)]">{hint}</p>
    </div>
  )
}

function CoachAnswerNote({ d }: { d: Draft }): JSX.Element | null {
  if (d.input_type === 'MC') {
    const txt = d.mcOptions[d.mcCorrect]?.trim()
    if (!txt) return null
    return (
      <p className="mt-2 text-xs text-[var(--color-text-tertiary)]">
        Richtige Antwort: <strong>{LETTERS[d.mcCorrect]}</strong> — {txt}
      </p>
    )
  }
  if (d.input_type === 'NUMERIC' && d.numericValue.trim()) {
    return (
      <p className="mt-2 text-xs text-[var(--color-text-tertiary)]">
        Erwartet: <strong>{d.numericValue}</strong>
        {d.numericTolerance.trim() ? ` (±${d.numericTolerance})` : ''}
      </p>
    )
  }
  return null
}
