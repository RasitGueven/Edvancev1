import { useEffect, useMemo, useRef, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useDiagnosis } from '@/context/DiagnosisContext'
import {
  averageMetrics,
  buildDiagnosisResult,
  recommendFocus,
} from '@/lib/behaviorAnalysis'
import { getClustersBySubject, getSubjects } from '@/lib/supabase/tasks'
import { completeScreeningTest } from '@/lib/supabase/screening'
import type { BehaviorAnalysis, BehaviorSnapshot } from '@/types/diagnosis'
import type { RunTask } from '@/types'
import { Button } from '@/components/ui/button'
import { EdvanceNavbar } from '@/components/edvance/EdvanceNavbar'

// Mapping: Diagnose-Mock-Cluster (M8.* taxonomy) → KMK-Kompetenzbereich
// (Schema seit Migration 001). Bei Klick auf einen Fokus-Cluster im
// Lernplan-Block wird ueber diesen Namen das echte Cluster in Supabase
// gefunden und zur ClusterView navigiert.
const DIAGNOSIS_TO_COMPETENCY: Record<string, string> = {
  'Rationale Zahlen': 'Zahl & Rechnen',
  'Terme & Gleichungen': 'Algebra & Funktionen',
  'Proportionalität': 'Sachrechnen & Modellieren',
  'Prozentrechnung': 'Zahl & Rechnen',
  'Lineare Funktionen': 'Algebra & Funktionen',
}
import {
  ChevronDown,
  ChevronUp,
  Clock,
  Pencil,
  Lightbulb,
  Target,
  TrendingUp,
  ShieldAlert,
  Sparkles,
  CheckCircle2,
  Award,
  Activity,
  Brain,
  Zap,
  AlertTriangle,
} from 'lucide-react'

// ── Constants ─────────────────────────────────────────────────────────────────

const SIGNAL_LABELS: Record<
  BehaviorAnalysis['mastery_signal'],
  { label: string; color: string; emoji: string }
> = {
  secure: { label: 'Sicher', color: 'var(--success)', emoji: '✓' },
  developing: { label: 'In Entwicklung', color: 'var(--primary)', emoji: '↗' },
  gap: { label: 'Lücke', color: 'var(--destructive)', emoji: '✗' },
  guessing: { label: 'Geraten', color: 'var(--warning)', emoji: '?' },
}

function formatDate(iso: string) {
  return new Intl.DateTimeFormat('de-DE', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  }).format(new Date(iso))
}

function formatDuration(ms: number) {
  const totalSec = Math.round(ms / 1000)
  const min = Math.floor(totalSec / 60)
  const sec = totalSec % 60
  if (min === 0) return `${sec}s`
  return `${min}m ${sec}s`
}

function getInitials(name: string) {
  return name
    .split(' ')
    .map(n => n[0])
    .join('')
    .toUpperCase()
    .slice(0, 2)
}

// ── Radial Gauge ──────────────────────────────────────────────────────────────

function RadialGauge({
  value,
  color,
  size = 140,
  thickness = 12,
}: {
  value: number
  color: string
  size?: number
  thickness?: number
}) {
  const radius = (size - thickness) / 2
  const circumference = 2 * Math.PI * radius
  const offset = circumference - (value / 100) * circumference

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
      <circle
        cx={size / 2}
        cy={size / 2}
        r={radius}
        stroke="var(--border)"
        strokeWidth={thickness}
        fill="none"
      />
      <circle
        cx={size / 2}
        cy={size / 2}
        r={radius}
        stroke={color}
        strokeWidth={thickness}
        fill="none"
        strokeDasharray={circumference}
        strokeDashoffset={offset}
        strokeLinecap="round"
        transform={`rotate(-90 ${size / 2} ${size / 2})`}
        style={{ transition: 'stroke-dashoffset 0.6s ease' }}
      />
    </svg>
  )
}

function GaugeCard({
  icon,
  label,
  value,
  color,
  inverted = false,
  caption,
}: {
  icon: React.ReactNode
  label: string
  value: number
  color: string
  inverted?: boolean
  caption: string
}) {
  const displayColor = inverted
    ? value > 60
      ? 'var(--destructive)'
      : value > 30
      ? 'var(--warning)'
      : 'var(--success)'
    : value > 65
    ? color
    : value > 35
    ? 'var(--warning)'
    : 'var(--destructive)'

  return (
    <div
      className="flex flex-col items-center rounded-3xl bg-card p-6 text-center"
      style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
    >
      <div className="relative">
        <RadialGauge value={value} color={displayColor} />
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span style={{ color: displayColor }} className="mb-1">
            {icon}
          </span>
          <span className="text-3xl font-black" style={{ color: displayColor }}>
            {value}
          </span>
        </div>
      </div>
      <p className="mt-3 text-xs font-bold uppercase tracking-wider text-muted">{label}</p>
      <p className="mt-1.5 text-xs font-semibold text-muted leading-relaxed max-w-[180px]">{caption}</p>
    </div>
  )
}

// ── KPI Card ──────────────────────────────────────────────────────────────────

function KpiCard({
  icon,
  label,
  value,
  sub,
  color,
  bg,
}: {
  icon: React.ReactNode
  label: string
  value: string
  sub?: string
  color: string
  bg: string
}) {
  return (
    <div
      className="rounded-2xl bg-card p-5"
      style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
    >
      <div className="flex items-center gap-2.5 mb-3">
        <span
          className="flex h-9 w-9 items-center justify-center rounded-xl"
          style={{ background: bg, color }}
        >
          {icon}
        </span>
        <p className="text-xs font-bold uppercase tracking-wider text-muted">{label}</p>
      </div>
      <p className="text-3xl font-black text-foreground tracking-tight">{value}</p>
      {sub && <p className="mt-0.5 text-xs font-semibold text-muted">{sub}</p>}
    </div>
  )
}

// ── Flag Tag ──────────────────────────────────────────────────────────────────

function FlagTag({ label, tone = 'primary' }: { label: string; tone?: 'primary' | 'warning' | 'success' }) {
  const colors = {
    primary: { bg: 'var(--primary)', tag: 'color-mix(in srgb, var(--primary) 12%, transparent)' },
    warning: { bg: 'var(--warning)', tag: 'color-mix(in srgb, var(--warning) 12%, transparent)' },
    success: { bg: 'var(--success)', tag: 'color-mix(in srgb, var(--success) 12%, transparent)' },
  }[tone]
  return (
    <span
      className="inline-flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-bold"
      style={{
        background: colors.tag,
        color: colors.bg,
        border: `1.5px solid color-mix(in srgb, ${colors.bg} 25%, transparent)`,
      }}
    >
      <span className="h-1.5 w-1.5 rounded-full inline-block" style={{ background: colors.bg }} />
      {label}
    </span>
  )
}

// ── Skill Bar ─────────────────────────────────────────────────────────────────

function SkillBar({ cluster, level, label }: { cluster: string; level: number; label: string }) {
  const colorMap = {
    Sicher: { c: 'var(--success)', d: 'var(--success-dark)' },
    Erkennbar: { c: 'var(--primary)', d: 'var(--primary-shadow)' },
    Lücke: { c: 'var(--destructive)', d: 'var(--destructive-dark)' },
  } as const
  const { c: color, d: dark } = colorMap[label as keyof typeof colorMap]
  const pct = (level / 10) * 100

  return (
    <div className="py-3 first:pt-0 last:pb-0 border-b border-border last:border-0">
      <div className="flex items-center justify-between mb-2">
        <div>
          <p className="text-sm font-black text-foreground">{cluster}</p>
          <p className="text-xs font-semibold text-muted">{label}</p>
        </div>
        <div
          className="flex h-10 w-12 items-center justify-center rounded-xl text-sm font-black text-white shrink-0"
          style={{ background: color, borderBottom: `3px solid ${dark}` }}
        >
          L{level}
        </div>
      </div>
      <div className="relative h-2.5 w-full rounded-full bg-border overflow-hidden">
        <div
          className="h-full rounded-full transition-all duration-700"
          style={{
            width: `${pct}%`,
            background: `linear-gradient(90deg, ${color} 0%, ${dark} 100%)`,
          }}
        />
        {/* Tick marks for L1, L4, L7, L10 */}
        {[10, 40, 70].map(tickPct => (
          <div
            key={tickPct}
            className="absolute top-0 bottom-0 w-px bg-card opacity-60"
            style={{ left: `${tickPct}%` }}
          />
        ))}
      </div>
      <div className="mt-1 flex justify-between text-[10px] font-bold uppercase tracking-wider text-muted">
        <span>L1</span>
        <span>L5</span>
        <span>L10</span>
      </div>
    </div>
  )
}

// ── Task Card ─────────────────────────────────────────────────────────────────

function TaskCard({
  index,
  task,
  snapshot,
  analysis,
}: {
  index: number
  task: RunTask | undefined
  snapshot: BehaviorSnapshot | undefined
  analysis: BehaviorAnalysis | undefined
}) {
  const [open, setOpen] = useState(false)
  if (!task) return null

  const signal = analysis ? SIGNAL_LABELS[analysis.mastery_signal] : null
  const ratingNum = snapshot?.coach_rating ?? null
  const ratingColor = ratingNum
    ? ratingNum >= 3
      ? 'var(--success)'
      : ratingNum === 2
      ? 'var(--warning)'
      : 'var(--destructive)'
    : 'var(--muted)'
  const ratingDark = ratingNum
    ? ratingNum >= 3
      ? 'var(--success-dark)'
      : ratingNum === 2
      ? 'var(--warning-dark)'
      : 'var(--destructive-dark)'
    : 'var(--border-strong)'

  return (
    <div
      className="rounded-2xl bg-card overflow-hidden transition-all"
      style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
    >
      <button
        type="button"
        onClick={() => setOpen(o => !o)}
        className="w-full flex items-center gap-4 p-5 text-left hover:bg-background transition-colors"
      >
        {/* Index & Rating Medal */}
        <div className="flex flex-col items-center gap-1 shrink-0">
          <span className="text-[10px] font-bold uppercase tracking-wider text-muted">Aufg. {index + 1}</span>
          <span
            className="flex h-12 w-12 items-center justify-center rounded-2xl text-base font-black text-white"
            style={{
              background: ratingColor,
              borderBottom: `3px solid ${ratingDark}`,
            }}
          >
            {ratingNum ? `L${ratingNum}` : '–'}
          </span>
        </div>

        {/* Center: Skill + Question */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 mb-1.5">
            <span className="text-[10px] font-black uppercase tracking-wider text-muted">{task.skill_id}</span>
            {signal && (
              <span
                className="rounded-full px-2 py-0.5 text-[10px] font-black tracking-wide text-white"
                style={{ background: signal.color }}
              >
                {signal.label}
              </span>
            )}
          </div>
          <p className="text-sm font-bold text-foreground leading-snug truncate">{task.question}</p>
          {snapshot && (
            <div className="mt-2 flex flex-wrap gap-1.5">
              <SmallBadge icon={<Clock className="h-2.5 w-2.5" />} text={formatDuration(snapshot.task_duration_ms)} />
              <SmallBadge icon={<Pencil className="h-2.5 w-2.5" />} text={`${snapshot.revision_count} Rev.`} />
              {snapshot.hint_used && <SmallBadge icon={<Lightbulb className="h-2.5 w-2.5" />} text="Hint" />}
              <SmallBadge text={`${snapshot.answer_length} Zch`} />
            </div>
          )}
        </div>

        <span className="ml-2 shrink-0 text-muted">
          {open ? <ChevronUp className="h-5 w-5" /> : <ChevronDown className="h-5 w-5" />}
        </span>
      </button>

      {open && snapshot && analysis && (
        <div
          className="border-t-2 border-border p-5"
          style={{ background: 'var(--background)' }}
        >
          <div className="grid grid-cols-1 gap-5 lg:grid-cols-5">
            {/* Antwort */}
            <div className="lg:col-span-3">
              <p className="text-xs font-bold uppercase tracking-wider text-muted mb-2">Schülerantwort</p>
              <pre
                className="whitespace-pre-wrap font-mono text-sm bg-card rounded-xl p-4 leading-relaxed"
                style={{ border: '2px solid var(--border)' }}
              >
                {snapshot.answer_text}
              </pre>
              <p className="mt-3 text-xs font-bold uppercase tracking-wider text-muted mb-2">Musterlösung</p>
              <pre
                className="whitespace-pre-wrap font-mono text-sm rounded-xl p-4 leading-relaxed"
                style={{
                  background: 'color-mix(in srgb, var(--success) 6%, transparent)',
                  border: '2px solid color-mix(in srgb, var(--success) 25%, transparent)',
                }}
              >
                {task.solution}
              </pre>
            </div>

            {/* Verhaltensdaten */}
            <div className="lg:col-span-2">
              <p className="text-xs font-bold uppercase tracking-wider text-muted mb-2">Verhalten</p>
              <div className="grid grid-cols-2 gap-2 text-xs font-semibold mb-3">
                <KV k="Bedenkzeit" v={`${(snapshot.thinking_time_ms / 1000).toFixed(1)}s`} />
                <KV k="Dauer" v={formatDuration(snapshot.task_duration_ms)} />
                <KV k="Revisionen" v={String(snapshot.revision_count)} />
                <KV k="Rewrites" v={String(snapshot.rewrite_count)} />
                <KV k="Antwort-Länge" v={`${snapshot.answer_length} Zch`} />
                <KV k="Nach-Check" v={`${(snapshot.time_after_completion_ms / 1000).toFixed(1)}s`} />
              </div>

              <div className="grid grid-cols-3 gap-2 mb-3">
                <MiniMetric label="Conf" value={analysis.confidence_score} color="var(--success)" />
                <MiniMetric label="Effort" value={analysis.effort_score} color="var(--primary)" />
                <MiniMetric label="Frust" value={analysis.frustration_index} color="var(--warning)" inverted />
              </div>

              {analysis.flags.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {analysis.flags.map(f => (
                    <FlagTag key={f} label={f} />
                  ))}
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

function MiniMetric({
  label,
  value,
  color,
  inverted = false,
}: {
  label: string
  value: number
  color: string
  inverted?: boolean
}) {
  const display = inverted
    ? value > 60
      ? 'var(--destructive)'
      : value > 30
      ? 'var(--warning)'
      : 'var(--success)'
    : value > 65
    ? color
    : value > 35
    ? 'var(--warning)'
    : 'var(--destructive)'
  return (
    <div className="rounded-lg bg-card p-2 text-center" style={{ border: '1px solid var(--border)' }}>
      <p className="text-[9px] font-bold uppercase tracking-wider text-muted">{label}</p>
      <p className="text-base font-black" style={{ color: display }}>
        {value}
      </p>
    </div>
  )
}

function SmallBadge({ icon, text }: { icon?: React.ReactNode; text: string }) {
  return (
    <span
      className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold text-muted"
      style={{ background: 'var(--background)', border: '1px solid var(--border)' }}
    >
      {icon}
      {text}
    </span>
  )
}

function KV({ k, v }: { k: string; v: string }) {
  return (
    <div
      className="flex items-center justify-between rounded-lg bg-card px-2.5 py-1.5"
      style={{ border: '1px solid var(--border)' }}
    >
      <span className="text-muted">{k}</span>
      <span className="text-foreground font-black">{v}</span>
    </div>
  )
}

// ── Section Header ────────────────────────────────────────────────────────────

function SectionHeader({
  icon,
  label,
  description,
}: {
  icon: React.ReactNode
  label: string
  description?: string
}) {
  return (
    <div className="mb-4 flex items-start gap-3">
      <span
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-primary"
        style={{ background: 'color-mix(in srgb, var(--primary) 10%, transparent)' }}
      >
        {icon}
      </span>
      <div>
        <h2 className="text-sm font-black uppercase tracking-wider text-foreground">{label}</h2>
        {description && <p className="text-xs font-semibold text-muted mt-0.5">{description}</p>}
      </div>
    </div>
  )
}

// ── Page ──────────────────────────────────────────────────────────────────────

export function DiagnosisResult() {
  const { state, setCoachNote, resetSession } = useDiagnosis()
  const navigate = useNavigate()

  // Map Cluster-Name (KMK) → cluster_id in Supabase, fuer Klick-Navigation.
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
    return () => {
      cancelled = true
    }
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

  // U5c: Screening-Ergebnis genau einmal persistieren (DB-Modus, fertig).
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

  // KPIs
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
          className="rounded-3xl p-8 mb-8 overflow-hidden relative"
          style={{
            background: 'linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)',
            border: '2px solid var(--primary-shadow)',
            borderBottomWidth: '4px',
          }}
        >
          {/* Decorative circles */}
          <div
            className="absolute -top-12 -right-12 h-48 w-48 rounded-full opacity-10 bg-[var(--surface)]"
          />
          <div
            className="absolute -bottom-16 -left-16 h-56 w-56 rounded-full opacity-5 bg-[var(--surface)]"
          />

          <div className="relative flex items-start justify-between gap-4 flex-wrap">
            <div className="flex items-center gap-5">
              <div
                className="flex h-20 w-20 items-center justify-center rounded-3xl text-3xl font-black text-primary shrink-0 bg-[var(--surface)]"
                style={{ borderBottom: '4px solid color-mix(in srgb, white 80%, black)' }}
              >
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
            <span
              className="flex items-center gap-1.5 rounded-full px-3 py-1.5 text-xs font-black uppercase tracking-wider"
              style={{ background: 'color-mix(in srgb, var(--success) 30%, white)', color: 'var(--success-dark)' }}
            >
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
            <div
              className="rounded-2xl bg-card p-5"
              style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
            >
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
          <div
            className="rounded-3xl bg-card p-6"
            style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
          >
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
          <div
            className="rounded-3xl bg-card p-1.5"
            style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
          >
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
        <section className="mb-10">
          <SectionHeader
            icon={<Target className="h-4 w-4" />}
            label="Empfohlener Lernplan"
            description="Automatisch generiert auf Basis der schwächsten Skills"
          />
          <div
            className="rounded-3xl p-7 relative overflow-hidden"
            style={{
              background: 'linear-gradient(135deg, color-mix(in srgb, var(--primary) 8%, white) 0%, color-mix(in srgb, var(--primary-dark) 4%, white) 100%)',
              border: '2px solid color-mix(in srgb, var(--primary) 25%, transparent)',
              borderBottomWidth: '4px',
            }}
          >
            <div className="flex items-center gap-2 mb-4">
              <Sparkles className="h-4 w-4 text-primary" />
              <p className="text-xs font-black uppercase tracking-widest text-primary">
                Fokus für die nächsten 1–2 Sessions
              </p>
            </div>

            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
              {focus.map((s, i) => {
                const cid = clusterIdFor(s.skill_cluster)
                const card = (
                  <div
                    className="rounded-2xl bg-card p-5 transition-shadow group-hover:shadow-md"
                    style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
                  >
                    <div className="flex items-center gap-3 mb-2">
                      <span
                        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-sm font-black text-white"
                        style={{
                          background: 'linear-gradient(135deg, var(--primary) 0%, var(--primary-dark) 100%)',
                          borderBottom: '3px solid var(--primary-shadow)',
                        }}
                      >
                        {i + 1}
                      </span>
                      <p className="text-sm font-black text-foreground flex-1">{s.skill_cluster}</p>
                    </div>
                    <div className="flex items-center justify-between">
                      <p className="text-xs font-semibold text-muted">
                        Aktuell L{s.level} ({s.label})
                      </p>
                      <span className="text-xs font-black text-primary">
                        {cid ? '→ Lernen starten' : '→ Ziel L7+'}
                      </span>
                    </div>
                    <div className="mt-3 h-1.5 w-full rounded-full bg-border overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${(s.level / 10) * 100}%`,
                          background: 'linear-gradient(90deg, var(--primary) 0%, var(--primary-dark) 100%)',
                        }}
                      />
                    </div>
                  </div>
                )
                return cid ? (
                  <Link key={s.skill_cluster} to={`/student/cluster/${cid}`} className="group block">
                    {card}
                  </Link>
                ) : (
                  <div key={s.skill_cluster}>{card}</div>
                )
              })}
            </div>

            <p className="mt-5 text-xs font-semibold text-muted leading-relaxed">
              💡 Der Lernpfad startet bei der schwächsten Stelle und arbeitet sich systematisch nach oben.
              Nach DGSR-Logik (Diagnose → Generation → Spacing → Reflection).
            </p>
          </div>
        </section>

        {/* ── Action Footer ──────────────────────────────────────── */}
        <div
          className="rounded-2xl bg-card p-5 flex items-center justify-between gap-3 flex-wrap"
          style={{ border: '2px solid var(--border)', borderBottomWidth: '4px' }}
        >
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
