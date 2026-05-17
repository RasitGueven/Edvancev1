import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useNavigate, useSearchParams } from 'react-router-dom'
import { useDiagnosis, type DiagnosisState } from '@/context/DiagnosisContext'
import { useBehaviorTracker } from '@/hooks/useBehaviorTracker'
import { buildRunTasks, rebuildRunTasks } from '@/lib/screening/runtime'
import { useAuth } from '@/hooks/useAuth'
import { getStudentByProfile } from '@/lib/supabase/students'
import {
  createScreeningTest,
  getActiveScreeningTest,
  getScreeningSnapshots,
} from '@/lib/supabase/screening'
import {
  createScreeningRating,
  getRatingsForTest,
} from '@/lib/supabase/screeningRatings'
import { persistBehaviorSnapshot } from '@/lib/supabase/behavior'
import { Button } from '@/components/ui/button'
import type { OnboardingData } from '@/types'
import type { BehaviorSnapshot } from '@/types/diagnosis'
import { Lightbulb, Clock, Pencil, AlertCircle, CheckCircle2, ArrowRight } from 'lucide-react'

// ── Header ────────────────────────────────────────────────────────────────────

function MinimalHeader({ subtitle }: { subtitle: string }) {
  return (
    <nav className="flex items-center justify-between bg-card px-6 py-4 border-b-2 border-border">
      <div className="flex items-center gap-3">
        <div
          className="flex h-10 w-10 items-center justify-center rounded-2xl text-base font-black text-white"
          style={{
            background: 'linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)',
            boxShadow: '0 3px 0 0 var(--primary-shadow)',
          }}
        >
          E
        </div>
        <div>
          <p className="text-sm font-black text-foreground leading-tight tracking-tight">Edvance</p>
          <p className="text-xs font-semibold text-muted leading-tight uppercase tracking-wider">{subtitle}</p>
        </div>
      </div>
    </nav>
  )
}

// ── Progress bar ──────────────────────────────────────────────────────────────

function ProgressBar({ current, total }: { current: number; total: number }) {
  const pct = ((current + 1) / total) * 100
  return (
    <div className="mb-6">
      <div className="flex items-center justify-between mb-2">
        <p className="text-xs font-bold uppercase tracking-wider text-muted">
          Aufgabe {current + 1} von {total}
        </p>
        <p className="text-xs font-bold uppercase tracking-wider text-primary">{Math.round(pct)} %</p>
      </div>
      <div className="h-3 w-full rounded-full bg-border overflow-hidden">
        <div
          className="h-full rounded-full transition-all duration-300"
          style={{
            width: `${pct}%`,
            background: 'linear-gradient(90deg, var(--primary) 0%, var(--primary-dark) 100%)',
          }}
        />
      </div>
    </div>
  )
}

// ── Student View ──────────────────────────────────────────────────────────────

function StudentView() {
  const { state, submitAnswer, recordSnapshotId } = useDiagnosis()
  const { user } = useAuth()
  const tracker = useBehaviorTracker()
  const [answer, setAnswer] = useState('')
  const [hintRequested, setHintRequested] = useState(false)
  const startedTaskRef = useRef<number | null>(null)

  const task = state.tasks[state.currentIndex]

  // Start tracking exactly once per task — wenn die Aufgabe wechselt UND nicht gerade auf Coach gewartet wird
  useEffect(() => {
    if (state.finished) return
    if (state.awaitingCoachRating) return
    if (startedTaskRef.current === state.currentIndex) return
    startedTaskRef.current = state.currentIndex
    setAnswer('')
    setHintRequested(false)
    tracker.startTracking()
  }, [state.currentIndex, state.awaitingCoachRating, state.finished, tracker])

  // ── Finished screen ─────────────────────────────────────────
  if (state.finished) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-16 flex flex-col items-center text-center">
        <div
          className="mb-6 flex h-24 w-24 items-center justify-center rounded-3xl text-5xl"
          style={{
            background: 'color-mix(in srgb, var(--success) 12%, transparent)',
            border: '2px solid var(--border)',
            borderBottomWidth: '4px',
          }}
        >
          🎉
        </div>
        <h1 className="text-4xl font-black text-foreground tracking-tight">Du hast es geschafft!</h1>
        <p className="mt-3 text-base font-semibold text-muted max-w-sm">
          Super Arbeit. Dein Coach geht gleich mit dir zusammen die Auswertung durch.
        </p>
      </main>
    )
  }

  if (!task) return null

  // ── Transition-Screen während Coach bewertet ────────────────
  if (state.awaitingCoachRating) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-20 flex flex-col items-center text-center">
        <div
          className="mb-6 flex h-20 w-20 items-center justify-center rounded-3xl text-4xl animate-pulse"
          style={{
            background: 'color-mix(in srgb, var(--primary) 10%, transparent)',
            border: '2px solid var(--border)',
            borderBottomWidth: '4px',
          }}
        >
          ⏳
        </div>
        <h2 className="text-2xl font-black text-foreground tracking-tight">Danke!</h2>
        <p className="mt-2 text-base font-semibold text-muted">Gleich geht's weiter.</p>
      </main>
    )
  }

  const handleHint = () => {
    if (hintRequested) return
    setHintRequested(true)
    tracker.onHintRequested()
  }

  const handleSubmit = async () => {
    if (answer.trim().length === 0) return
    tracker.onLastKeystroke()
    const snapshot = tracker.getSnapshot(task.id, answer)
    const idx = state.currentIndex
    submitAnswer(snapshot)
    // DB-Modus (Screening): Snapshot sofort persistieren (append-only)
    if (state.mode === 'db' && state.screeningTestId && user) {
      const { data } = await persistBehaviorSnapshot(
        task.id,
        user.id,
        snapshot,
        state.screeningTestId,
      )
      if (data) recordSnapshotId(idx, data.id)
    }
  }

  return (
    <main className="mx-auto max-w-2xl px-4 py-8">
      <ProgressBar current={state.currentIndex} total={state.tasks.length} />

      <div
        className="rounded-3xl bg-card p-8"
        style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
      >
        <p className="text-xs font-bold uppercase tracking-wider text-muted mb-3">{task.skill_cluster}</p>
        <h1 className="text-2xl font-black text-foreground tracking-tight leading-snug">
          {task.question}
        </h1>

        <div className="mt-6 flex flex-col gap-2">
          <label htmlFor="answer" className="text-xs font-bold uppercase tracking-wider text-muted">
            Deine Antwort
          </label>
          <textarea
            id="answer"
            value={answer}
            onChange={e => {
              setAnswer(e.target.value)
              tracker.onChange(e.target.value)
            }}
            onKeyDown={e => tracker.onKeyDown(e)}
            placeholder="Schreib hier deinen Rechenweg auf …"
            rows={6}
            className="w-full rounded-2xl border-2 border-border bg-card p-4 text-base font-medium text-foreground focus:border-primary focus:outline-none resize-none"
            style={{ borderBottomWidth: '4px', borderBottomColor: 'var(--border-strong)' }}
          />
        </div>

        {hintRequested && (
          <div
            className="mt-4 rounded-2xl px-4 py-3 text-sm font-medium"
            style={{
              background: 'color-mix(in srgb, var(--warning) 10%, transparent)',
              border: '2px solid color-mix(in srgb, var(--warning) 30%, transparent)',
              color: 'var(--warning-dark)',
            }}
          >
            💡 Lies die Aufgabe nochmal in Ruhe durch. Schreib auf, was du schon weißt.
          </div>
        )}

        <div className="mt-6 flex items-center justify-between gap-3">
          <button
            type="button"
            onClick={handleHint}
            disabled={hintRequested}
            className="text-xs font-bold uppercase tracking-wider text-muted hover:text-warning disabled:opacity-50 flex items-center gap-1.5"
          >
            <Lightbulb className="h-3.5 w-3.5" />
            {hintRequested ? 'Hint angefordert' : 'Hint anfordern'}
          </button>
          <Button onClick={handleSubmit} disabled={answer.trim().length === 0}>
            Abschicken →
          </Button>
        </div>
      </div>
    </main>
  )
}

// ── Coach View ────────────────────────────────────────────────────────────────

const RATINGS: { rating: 1 | 2 | 3 | 4; label: string; sub: string; color: string; dark: string }[] = [
  {
    rating: 4,
    label: 'Korrekt & selbständig',
    sub: 'L4',
    color: 'var(--success)',
    dark: 'var(--success-dark)',
  },
  {
    rating: 3,
    label: 'Korrekt mit Zögern',
    sub: 'L3',
    color: 'var(--primary)',
    dark: 'var(--primary-shadow)',
  },
  {
    rating: 2,
    label: 'Ansatz gut, Fehler',
    sub: 'L3-4',
    color: 'var(--warning)',
    dark: 'var(--warning-dark)',
  },
  {
    rating: 1,
    label: 'Falsch / kein Ansatz',
    sub: 'L1-2',
    color: 'var(--destructive)',
    dark: 'var(--destructive-dark)',
  },
]

function CoachView() {
  const { state, setCoachRating, resetSession } = useDiagnosis()
  const { user } = useAuth()
  const navigate = useNavigate()
  const task = state.tasks[state.currentIndex]
  const currentSnapshot = state.snapshots[state.currentIndex]

  const rate = (rating: 1 | 2 | 3 | 4): void => {
    const idx = state.currentIndex
    const snapId = state.snapshotIds[idx]
    setCoachRating(rating)
    if (state.mode === 'db' && state.screeningTestId && snapId) {
      void createScreeningRating(
        snapId,
        state.screeningTestId,
        rating,
        user?.id ?? null,
      )
    }
  }

  if (state.finished) {
    return (
      <main className="mx-auto max-w-2xl px-4 py-16 flex flex-col items-center text-center">
        <div
          className="mb-6 flex h-24 w-24 items-center justify-center rounded-3xl text-5xl"
          style={{
            background: 'color-mix(in srgb, var(--success) 12%, transparent)',
            border: '2px solid var(--border)',
            borderBottomWidth: '4px',
          }}
        >
          ✅
        </div>
        <h1 className="text-3xl font-black text-foreground tracking-tight">Diagnose abgeschlossen</h1>
        <p className="mt-3 text-base font-semibold text-muted max-w-sm">
          Alle Aufgaben bewertet. Geh jetzt zur Auswertung.
        </p>
        <div className="mt-6 flex gap-3">
          <Button onClick={() => navigate('/diagnosis/result')} size="lg">
            Auswertung öffnen →
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              resetSession()
              navigate('/diagnosis?view=student')
            }}
          >
            Neue Diagnose
          </Button>
        </div>
      </main>
    )
  }

  if (!task) return null

  return (
    <main className="mx-auto max-w-3xl px-4 py-8">
      <ProgressBar current={state.currentIndex} total={state.tasks.length} />

      <div
        className="rounded-3xl bg-card p-6 mb-4"
        style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
      >
        <div className="flex items-center justify-between mb-3">
          <p className="text-xs font-bold uppercase tracking-wider text-muted">
            {task.skill_cluster} · {task.skill_id}
          </p>
          <p className="text-xs font-bold uppercase tracking-wider text-muted">
            ⏱ ~{task.estimated_minutes} Min
          </p>
        </div>
        <h1 className="text-xl font-black text-foreground leading-snug">{task.question}</h1>
      </div>

      {/* Coach Helper Boxes */}
      <div className="grid grid-cols-1 gap-3 mb-4">
        <CoachInfoBox
          icon={<CheckCircle2 className="h-4 w-4" />}
          title="Musterlösung"
          color="var(--success)"
          bg="color-mix(in srgb, var(--success) 8%, transparent)"
          text={task.solution}
        />
        <CoachInfoBox
          icon={<AlertCircle className="h-4 w-4" />}
          title="Typische Fehler"
          color="var(--warning-dark)"
          bg="color-mix(in srgb, var(--warning) 8%, transparent)"
          text={task.common_errors}
        />
        <CoachInfoBox
          icon={<Lightbulb className="h-4 w-4" />}
          title="Coach-Hinweis"
          color="var(--primary)"
          bg="color-mix(in srgb, var(--primary) 8%, transparent)"
          text={task.coach_hint}
        />
      </div>

      {/* Schülerantwort */}
      <div
        className="rounded-3xl bg-card p-6 mb-4"
        style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
      >
        <p className="text-xs font-bold uppercase tracking-wider text-muted mb-2">Antwort des Schülers</p>
        {currentSnapshot ? (
          <>
            <pre
              className="whitespace-pre-wrap font-mono text-sm font-medium text-foreground bg-background rounded-xl p-4"
              style={{ border: '2px solid var(--border)' }}
            >
              {currentSnapshot.answer_text}
            </pre>

            {/* Live-Verhaltensdaten */}
            <div className="mt-4 flex flex-wrap gap-2">
              <BehaviorBadge
                icon={<Clock className="h-3 w-3" />}
                label={`Bedenkzeit ${(currentSnapshot.thinking_time_ms / 1000).toFixed(1)}s`}
              />
              <BehaviorBadge
                icon={<Clock className="h-3 w-3" />}
                label={`Dauer ${(currentSnapshot.task_duration_ms / 1000).toFixed(1)}s`}
              />
              <BehaviorBadge
                icon={<Pencil className="h-3 w-3" />}
                label={`${currentSnapshot.revision_count} Revisionen`}
              />
              {currentSnapshot.rewrite_count > 0 && (
                <BehaviorBadge label={`${currentSnapshot.rewrite_count} Rewrites`} />
              )}
              {currentSnapshot.hint_used && (
                <BehaviorBadge icon={<Lightbulb className="h-3 w-3" />} label="Hint genutzt" />
              )}
              <BehaviorBadge label={`${currentSnapshot.answer_length} Zeichen`} />
            </div>
          </>
        ) : (
          <div className="rounded-xl bg-background p-6 text-center" style={{ border: '2px dashed var(--border)' }}>
            <p className="text-sm font-semibold text-muted">Schüler arbeitet noch …</p>
          </div>
        )}
      </div>

      {/* Bewertung */}
      <div
        className="rounded-3xl bg-card p-6"
        style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
      >
        <p className="text-xs font-bold uppercase tracking-wider text-muted mb-3">Bewertung</p>
        <div className="grid grid-cols-1 gap-2 sm:grid-cols-2">
          {RATINGS.map(r => (
            <button
              key={r.rating}
              type="button"
              disabled={!currentSnapshot}
              onClick={() => rate(r.rating)}
              className="flex items-center justify-between rounded-2xl px-4 py-3 text-left text-white font-bold transition-all active:translate-y-[2px] disabled:opacity-40 disabled:pointer-events-none"
              style={{
                background: r.color,
                borderBottom: `4px solid ${r.dark}`,
              }}
            >
              <span className="text-sm">{r.label}</span>
              <span className="text-xs font-black opacity-80">{r.sub}</span>
            </button>
          ))}
        </div>
        {!currentSnapshot && (
          <p className="mt-3 text-xs font-semibold text-muted">
            Warte bis der Schüler die Antwort abgeschickt hat.
          </p>
        )}
      </div>

      <div className="mt-6 flex justify-end">
        <Link to="/diagnosis/result" className="text-xs font-bold uppercase tracking-wider text-muted hover:text-foreground flex items-center gap-1">
          Auswertung anzeigen <ArrowRight className="h-3 w-3" />
        </Link>
      </div>
    </main>
  )
}

function CoachInfoBox({
  icon,
  title,
  color,
  bg,
  text,
}: {
  icon: React.ReactNode
  title: string
  color: string
  bg: string
  text: string
}) {
  return (
    <div
      className="rounded-2xl p-4"
      style={{ background: bg, border: `2px solid color-mix(in srgb, ${color} 25%, transparent)` }}
    >
      <div className="flex items-center gap-1.5 mb-1.5" style={{ color }}>
        {icon}
        <span className="text-xs font-bold uppercase tracking-wider">{title}</span>
      </div>
      <p className="text-sm font-medium text-foreground whitespace-pre-line leading-relaxed">{text}</p>
    </div>
  )
}

function BehaviorBadge({ icon, label }: { icon?: React.ReactNode; label: string }) {
  return (
    <span
      className="inline-flex items-center gap-1 rounded-full px-2.5 py-1 text-xs font-semibold"
      style={{
        background: 'var(--background)',
        border: '1px solid var(--border)',
        color: 'var(--foreground)',
      }}
    >
      {icon}
      {label}
    </span>
  )
}

// ── Setup screen (when session not started) ───────────────────────────────────

const SUBJECT_OPTIONS: { label: string; code: OnboardingData['subject'] }[] = [
  { label: 'Mathematik', code: 'MATH' },
  { label: 'Deutsch', code: 'GERMAN' },
  { label: 'Englisch', code: 'ENGLISH' },
]
const GRADES = Array.from({ length: 9 }, (_, i) => i + 5)

function SetupScreen({
  view,
  screening = false,
}: {
  view: 'student' | 'coach'
  screening?: boolean
}) {
  const { startSession, startScreening, hydrate } = useDiagnosis()
  const { user } = useAuth()
  const [name, setName] = useState('')
  const [subject, setSubject] = useState<OnboardingData['subject']>('MATH')
  const [grade, setGrade] = useState<number>(8)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const NO_TASKS_MSG =
    'Keine diagnostischen Aufgaben in der Datenbank. Bitte Diagnostik-Content seeden.'

  const start = async (): Promise<void> => {
    setLoading(true)
    setError(null)
    const label =
      SUBJECT_OPTIONS.find(s => s.code === subject)?.label ?? 'Mathematik'

    if (!screening) {
      const { tasks, warnings } = await buildRunTasks({ grade, subject })
      setLoading(false)
      if (tasks.length === 0) {
        setError(warnings[0] ?? NO_TASKS_MSG)
        return
      }
      startSession({ studentName: name || 'Schüler', subject: label, tasks })
      return
    }

    // ── Screening (DB-Modus) ──────────────────────────────────
    if (!user) {
      setLoading(false)
      setError('Nicht eingeloggt.')
      return
    }
    const { data: student } = await getStudentByProfile(user.id)
    if (!student) {
      setLoading(false)
      setError('Kein Schülerprofil gefunden.')
      return
    }

    // Resume: laufenden Test fortsetzen
    const { data: active } = await getActiveScreeningTest(student.id, label)
    if (active && active.generated_test) {
      const tasks = await rebuildRunTasks(active.generated_test)
      const { data: snaps } = await getScreeningSnapshots(active.id)
      const { data: ratings } = await getRatingsForTest(active.id)
      setLoading(false)
      if (tasks.length === 0) {
        setError('Screening hat keine Aufgaben.')
        return
      }
      const ratingBySnap = new Map(
        (ratings ?? []).map(r => [r.behavior_snapshot_id, r.rating]),
      )
      const snapshots: BehaviorSnapshot[] = []
      const snapshotIds: (string | null)[] = []
      ;(snaps ?? []).forEach((s, i) => {
        snapshots[i] = {
          ...(s as Omit<BehaviorSnapshot, 'coach_rating'>),
          coach_rating:
            (ratingBySnap.get(s.id) ?? null) as BehaviorSnapshot['coach_rating'],
        }
        snapshotIds[i] = s.id
      })
      const ratedCount = snapshots.filter(s => s.coach_rating != null).length
      const isFinished = ratedCount >= tasks.length
      const next: DiagnosisState = {
        studentName: name || 'Schüler',
        subject: label,
        date: active.created_at,
        currentIndex: isFinished ? tasks.length - 1 : ratedCount,
        awaitingCoachRating: snapshots.length > ratedCount && !isFinished,
        snapshots,
        tasks,
        coachNote: active.coach_note ?? '',
        finished: isFinished,
        startedAt: active.started_at,
        mode: 'db',
        screeningTestId: active.id,
        snapshotIds,
      }
      hydrate(next)
      return
    }

    // Neuer Lauf
    const { tasks, test, warnings } = await buildRunTasks({
      grade: student.class_level ?? grade,
      subject,
    })
    if (tasks.length === 0 || !test) {
      setLoading(false)
      setError(warnings[0] ?? NO_TASKS_MSG)
      return
    }
    const { data: created, error: cErr } = await createScreeningTest({
      student_id: student.id,
      subject: label,
      generated_test: test,
      estimated_total_minutes: test.estimated_total_minutes,
    })
    setLoading(false)
    if (cErr || !created) {
      setError(cErr ?? 'Screening konnte nicht gestartet werden.')
      return
    }
    startScreening({
      studentName: name || 'Schüler',
      subject: label,
      tasks,
      screeningTestId: created.id,
    })
  }

  if (view === 'coach') {
    return (
      <main className="mx-auto max-w-md px-4 py-16">
        <div
          className="rounded-3xl bg-card p-8"
          style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
        >
          <h1 className="text-2xl font-black text-foreground tracking-tight">Diagnose-Session</h1>
          <p className="mt-2 text-sm font-semibold text-muted">
            Warte bis der Schüler die Diagnose startet. Dann erscheint die erste Aufgabe hier.
          </p>
          <div
            className="mt-6 rounded-2xl px-4 py-3 text-sm font-medium"
            style={{
              background: 'color-mix(in srgb, var(--primary) 8%, transparent)',
              border: '2px solid color-mix(in srgb, var(--primary) 25%, transparent)',
              color: 'var(--primary)',
            }}
          >
            💡 Tipp: Schüler-Tablet öffnet <code>/diagnosis?view=student</code>
          </div>
        </div>
      </main>
    )
  }

  return (
    <main className="mx-auto max-w-md px-4 py-16">
      <div
        className="rounded-3xl bg-card p-8"
        style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
      >
        <div className="flex justify-center mb-4">
          <div
            className="flex h-16 w-16 items-center justify-center rounded-3xl text-3xl"
            style={{
              background: 'color-mix(in srgb, var(--primary) 12%, transparent)',
              border: '2px solid var(--border)',
              borderBottomWidth: '4px',
            }}
          >
            🎯
          </div>
        </div>
        <h1 className="text-center text-2xl font-black text-foreground tracking-tight">
          Bereit für die Diagnose?
        </h1>
        <p className="mt-2 text-center text-sm font-semibold text-muted">
          Du hast genug Zeit, Rechenweg ist erlaubt.
        </p>

        <label htmlFor="name" className="mt-6 block text-xs font-bold uppercase tracking-wider text-muted mb-1.5">
          Wie heißt du?
        </label>
        <input
          id="name"
          value={name}
          onChange={e => setName(e.target.value)}
          placeholder="Dein Vorname"
          className="w-full h-12 rounded-xl border-2 border-border bg-card px-4 text-base font-semibold text-foreground focus:border-primary focus:outline-none"
        />

        <div className="mt-4 grid grid-cols-2 gap-3">
          <div>
            <label htmlFor="subject" className="block text-xs font-bold uppercase tracking-wider text-muted mb-1.5">
              Fach
            </label>
            <select
              id="subject"
              value={subject}
              onChange={e => setSubject(e.target.value as OnboardingData['subject'])}
              className="w-full h-12 rounded-xl border-2 border-border bg-card px-3 text-base font-semibold text-foreground focus:border-primary focus:outline-none"
            >
              {SUBJECT_OPTIONS.map(s => (
                <option key={s.code} value={s.code}>
                  {s.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label htmlFor="grade" className="block text-xs font-bold uppercase tracking-wider text-muted mb-1.5">
              Klasse
            </label>
            <select
              id="grade"
              value={grade}
              onChange={e => setGrade(Number(e.target.value))}
              className="w-full h-12 rounded-xl border-2 border-border bg-card px-3 text-base font-semibold text-foreground focus:border-primary focus:outline-none"
            >
              {GRADES.map(g => (
                <option key={g} value={g}>
                  {g}. Klasse
                </option>
              ))}
            </select>
          </div>
        </div>

        {error && (
          <p className="mt-4 text-sm font-semibold text-destructive">{error}</p>
        )}

        <Button
          onClick={start}
          disabled={!name.trim() || loading}
          size="lg"
          className="mt-5 w-full"
        >
          {loading ? 'Test wird erstellt …' : "Los geht's →"}
        </Button>
      </div>
    </main>
  )
}

// ── Main ──────────────────────────────────────────────────────────────────────

export function DiagnosisSession({ screening = false }: { screening?: boolean }) {
  const [params] = useSearchParams()
  const { state } = useDiagnosis()
  const view = (params.get('view') === 'coach' ? 'coach' : 'student') as 'student' | 'coach'

  const base = screening ? 'Screening' : 'Diagnose'
  const subtitle = useMemo(
    () => (view === 'coach' ? `${base} · Coach-Sicht` : base),
    [view, base],
  )

  const sessionStarted = state.startedAt !== null

  return (
    <div className="min-h-screen bg-background">
      <MinimalHeader subtitle={subtitle} />
      {!sessionStarted ? (
        <SetupScreen view={view} screening={screening} />
      ) : view === 'coach' ? (
        <CoachView />
      ) : (
        <StudentView />
      )}
    </div>
  )
}
