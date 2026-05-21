import { useEffect, useMemo, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useDiagnosis } from '@/context/DiagnosisContext'
import {
  averageMetrics,
  buildDiagnosisResult,
  recommendFocus,
} from '@/lib/behaviorAnalysis'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import { completeScreeningTest } from '@/lib/supabase/screening'
import type { BehaviorSnapshot } from '@/types/diagnosis'
import { Button } from '@/components/ui/button'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'
import {
  Clock,
  TrendingUp,
  ShieldAlert,
  CheckCircle2,
  Award,
  Activity,
  Brain,
  Zap,
  AlertTriangle,
  Pencil,
} from 'lucide-react'
import { getInitials } from '@/lib/utils'
import {
  formatDate,
  formatDuration,
  GaugeCard,
  KpiCard,
  FlagTag,
  SkillBar,
  SectionHeader,
  TaskCard,
} from './DiagnosisResultComponents'
import { LernplanSection } from './DiagnosisLernplan'

// Mapping: Diagnose-Mock-Cluster (M8.* taxonomy) → KMK-Kompetenzbereich
const DIAGNOSIS_TO_COMPETENCY: Record<string, string> = {
  'Rationale Zahlen': 'Zahl & Rechnen',
  'Terme & Gleichungen': 'Algebra & Funktionen',
  'Proportionalität': 'Sachrechnen & Modellieren',
  'Prozentrechnung': 'Zahl & Rechnen',
  'Lineare Funktionen': 'Algebra & Funktionen',
}

export function DiagnosisResult() {
  const { state, setCoachNote, resetSession } = useDiagnosis()
  const navigate = useNavigate()

  const [clusterIdByName, setClusterIdByName] = useState<Record<string, string>>({})
  useEffect(() => {
    let cancelled = false
    void (async () => {
      const { data: subjects } = await getSubjects()
      const math = subjects?.find((s) => s.name === 'Mathematik')
      if (!math) return
      const { data: clusters } = await getClustersBySubject(math.id)
      if (cancelled || !clusters) return
      const map: Record<string, string> = {}
      for (const c of clusters) map[c.name] = c.id
      setClusterIdByName(map)
    })()
    return () => { cancelled = true }
  }, [])

  const clusterIdFor = (diagnosisName: string): string | undefined => {
    const targetName = DIAGNOSIS_TO_COMPETENCY[diagnosisName] ?? diagnosisName
    return clusterIdByName[targetName]
  }

  const result = useMemo(
    () =>
      buildDiagnosisResult({
        tasks: state.tasks,
        snapshots: state.snapshots,
        studentName: state.studentName,
        subject: state.subject,
        date: state.date,
        coachNote: state.coachNote,
      }),
    [state],
  )

  const { avgConfidence, avgEffort, avgFrustration } = averageMetrics(result.analyses)
  const focus = recommendFocus(result.skill_levels)

  const completedRef = useRef(false)
  useEffect(() => {
    if (completedRef.current) return
    if (state.mode !== 'db' || !state.screeningTestId || !state.finished) return
    completedRef.current = true
    void completeScreeningTest(
      state.screeningTestId,
      {
        skill_levels: result.skill_levels,
        overall_behavior_flags: result.overall_behavior_flags,
        averages: {
          confidence: avgConfidence,
          effort: avgEffort,
          frustration: avgFrustration,
        },
      },
      state.coachNote,
    )
  }, [
    state.mode,
    state.screeningTestId,
    state.finished,
    state.coachNote,
    result,
    avgConfidence,
    avgEffort,
    avgFrustration,
  ])

  const completedSnaps = state.snapshots.filter((s): s is BehaviorSnapshot => s != null)
  const hasData = completedSnaps.length > 0

  const totalDuration = completedSnaps.reduce((sum, s) => sum + s.task_duration_ms, 0)
  const correctCount = completedSnaps.filter(s => (s.coach_rating ?? 0) >= 3).length
  const avgLevel =
    result.skill_levels.length > 0
      ? Math.round(result.skill_levels.reduce((sum, s) => sum + s.level, 0) / result.skill_levels.length)
      : 0
  const masteryLabel = avgLevel >= 7 ? 'Sicher' : avgLevel >= 4 ? 'Erkennbar' : 'Lücke'

  if (!hasData) {
    return (
      <div className="min-h-screen bg-background">
        <EdvanceNavbar subtitle="Diagnose · Auswertung" />
        <main className="mx-auto max-w-2xl px-4 py-16 text-center">
          <p className="text-base font-semibold text-muted">Es liegt noch keine Diagnose vor.</p>
          <Button onClick={() => navigate('/diagnosis?view=student')} className="mt-4">
            Diagnose starten
          </Button>
        </main>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background">
      <EdvanceNavbar subtitle="Diagnose · Auswertung" />

      <main className="mx-auto max-w-4xl px-4 py-8 pb-24">
        {/* ── Hero Header ────────────────────────────────────────── */}
        <div
          className="rounded-3xl p-8 mb-8 overflow-hidden relative border-2 border-b-4 border-[var(--primary-shadow)]"
          style={{ background: 'linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)' }}
        >
          <div className="absolute -top-12 -right-12 h-48 w-48 rounded-full opacity-10 bg-[var(--surface)]" />
          <div className="absolute -bottom-16 -left-16 h-56 w-56 rounded-full opacity-5 bg-[var(--surface)]" />

          <div className="relative flex items-start justify-between gap-4 flex-wrap">
            <div className="flex items-center gap-5">
              <div className="flex h-20 w-20 items-center justify-center rounded-3xl text-3xl font-black text-primary shrink-0 bg-[var(--surface)] border-b-4 border-b-[color-mix(in_srgb,white_80%,black)]">
                {getInitials(result.student_name)}
              </div>
              <div>
                <p className="text-xs font-black uppercase tracking-widest text-white/70">
                  Initialdiagnostik · {result.subject}
                </p>
                <h1 className="mt-1 text-3xl font-black text-white tracking-tight">{result.student_name}</h1>
                <p className="mt-1 text-sm font-semibold text-white/80">
                  {formatDate(result.date)} · Coach: Frau Demir
                </p>
              </div>
            </div>
            <span className="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-black uppercase tracking-wider bg-[color-mix(in_srgb,var(--success)_30%,white)] text-[var(--success-dark)]">
              <CheckCircle2 className="h-3.5 w-3.5" />
              Abgeschlossen
            </span>
          </div>
        </div>

        {/* ── KPI Strip ──────────────────────────────────────────── */}
        <div className="grid grid-cols-2 gap-4 mb-10 lg:grid-cols-4">
          <KpiCard
            icon={<CheckCircle2 className="h-5 w-5" />}
            label="Gelöste Aufgaben"
            value={`${completedSnaps.length}`}
            sub={`von ${state.tasks.length}`}
            color="var(--primary)"
            bg="color-mix(in srgb, var(--primary) 12%, transparent)"
          />
          <KpiCard
            icon={<Award className="h-5 w-5" />}
            label="Korrekt-Quote"
            value={`${correctCount}/${completedSnaps.length}`}
            sub={`${Math.round((correctCount / completedSnaps.length) * 100)} % Ratings ≥ L3`}
            color="var(--success)"
            bg="color-mix(in srgb, var(--success) 12%, transparent)"
          />
          <KpiCard
            icon={<Clock className="h-5 w-5" />}
            label="Diagnose-Dauer"
            value={formatDuration(totalDuration)}
            sub="Aktive Bearbeitung"
            color="var(--warning)"
            bg="color-mix(in srgb, var(--warning) 12%, transparent)"
          />
          <KpiCard
            icon={<TrendingUp className="h-5 w-5" />}
            label="Ø Mastery-Level"
            value={`L${avgLevel}`}
            sub={masteryLabel}
            color="var(--primary)"
            bg="color-mix(in srgb, var(--primary) 12%, transparent)"
          />
        </div>

        {/* ── Verhaltens-Profil ──────────────────────────────────── */}
        <section className="mb-10">
          <SectionHeader
            icon={<Activity className="h-4 w-4" />}
            label="Verhaltens-Profil"
            description="Was wir über das Lernverhalten beobachtet haben"
          />

          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3 mb-5">
            <GaugeCard
              icon={<Brain className="h-5 w-5" />}
              label="Confidence"
              value={avgConfidence}
              color="var(--success)"
              caption={
                avgConfidence > 65
                  ? 'Geht selbstbewusst an Aufgaben heran'
                  : avgConfidence > 35
                  ? 'Zeigt mittleres Selbstvertrauen'
                  : 'Wirkt unsicher und zögerlich'
              }
            />
            <GaugeCard
              icon={<Zap className="h-5 w-5" />}
              label="Effort"
              value={avgEffort}
              color="var(--primary)"
              caption={
                avgEffort > 65
                  ? 'Investiert spürbar in Lösungen'
                  : avgEffort > 35
                  ? 'Bleibt durchschnittlich dran'
                  : 'Gibt schnell auf, kurze Antworten'
              }
            />
            <GaugeCard
              icon={<AlertTriangle className="h-5 w-5" />}
              label="Frustration"
              value={avgFrustration}
              color="var(--warning)"
              inverted
              caption={
                avgFrustration < 30
                  ? 'Bleibt entspannt, wenig Frustsignale'
                  : avgFrustration < 60
                  ? 'Gelegentliche Frustsignale erkennbar'
                  : 'Hohes Frustrationsniveau'
              }
            />
          </div>

          {result.overall_behavior_flags.length > 0 ? (
            <div className="rounded-2xl bg-card p-5 border-2 border-b-4 border-[var(--border)]">
              <div className="flex items-center gap-1.5 mb-3">
                <ShieldAlert className="h-3.5 w-3.5 text-muted" />
                <p className="text-xs font-bold uppercase tracking-wider text-muted">Wiederkehrende Muster</p>
              </div>
              <div className="flex flex-wrap gap-2">
                {result.overall_behavior_flags.map(f => (
                  <FlagTag key={f} label={f} />
                ))}
              </div>
            </div>
          ) : (
            <p className="text-sm font-semibold text-muted text-center py-4">
              Keine wiederkehrenden Verhaltensmuster erkennbar.
            </p>
          )}
        </section>

        {/* ── Mastery-Profil ─────────────────────────────────────── */}
        <section className="mb-10">
          <SectionHeader
            icon={<TrendingUp className="h-4 w-4" />}
            label="Mastery-Profil"
            description="Kompetenzstand pro Themengebiet auf einer Skala von 1–10"
          />
          <div className="rounded-3xl bg-card p-6 border-2 border-b-4 border-[var(--border)]">
            {result.skill_levels.map(s => (
              <SkillBar key={s.skill_cluster} cluster={s.skill_cluster} level={s.level} label={s.label} />
            ))}
          </div>
        </section>

        {/* ── Aufgaben-Detail ────────────────────────────────────── */}
        <section className="mb-10">
          <SectionHeader
            icon={<Pencil className="h-4 w-4" />}
            label="Aufgaben im Detail"
            description="Klick auf eine Aufgabe für Antwort, Musterlösung und Verhaltensdaten"
          />
          <div className="flex flex-col gap-3">
            {state.tasks.map((t, i) => (
              <TaskCard
                key={i}
                index={i}
                task={t}
                snapshot={result.snapshots[i]}
                analysis={result.analyses[i]}
              />
            ))}
          </div>
        </section>

        {/* ── Coach-Notiz ────────────────────────────────────────── */}
        <section className="mb-10">
          <SectionHeader
            icon={<Pencil className="h-4 w-4" />}
            label="Coach-Notiz"
            description="Abschließende Einschätzung in eigenen Worten"
          />
          <div className="rounded-3xl bg-card p-1.5 border-2 border-b-4 border-[var(--border)]">
            <textarea
              value={state.coachNote}
              onChange={e => setCoachNote(e.target.value)}
              placeholder="Was ist dir während der Diagnose besonders aufgefallen? Welche Stärken nehmen wir mit, an welchen Stellen lohnt sich der erste Fokus?"
              rows={5}
              className="w-full rounded-2xl bg-transparent p-4 text-sm font-medium text-foreground focus:outline-none resize-none leading-relaxed"
            />
          </div>
        </section>

        {/* ── Lernplan ───────────────────────────────────────────── */}
        <LernplanSection focus={focus} clusterIdFor={clusterIdFor} />

        {/* ── Action Footer ──────────────────────────────────────── */}
        <div className="rounded-2xl bg-card p-5 flex items-center justify-between gap-3 flex-wrap border-2 border-b-4 border-[var(--border)]">
          <div>
            <p className="text-sm font-black text-foreground">Bereit für die erste Lernsession?</p>
            <p className="text-xs font-semibold text-muted mt-0.5">
              Lernpfad ist erstellt — der Coach kann jetzt mit Schüler:in starten.
            </p>
          </div>
          <div className="flex gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                if (confirm('Diagnose zurücksetzen? Alle Daten gehen verloren.')) {
                  resetSession()
                  navigate('/diagnosis?view=student')
                }
              }}
            >
              Neue Diagnose
            </Button>
            <Button onClick={() => navigate('/admin')} size="sm">
              Zurück zum Admin
            </Button>
          </div>
        </div>
      </main>
    </div>
  )
}
