import { useState, type ReactNode } from 'react'
import { Clock, Pencil, Lightbulb } from 'lucide-react'
import type { BehaviorAnalysis, BehaviorSnapshot } from '@/types/diagnosis'
import type { RunTask } from '@/types'

// ── Signal Labels (shared constant) ──────────────────────────────────────────

export const SIGNAL_LABELS: Record<
  BehaviorAnalysis['mastery_signal'],
  { label: string; color: string; emoji: string }
> = {
  secure:     { label: 'Sicher',         color: 'var(--success)',     emoji: '✓' },
  developing: { label: 'In Entwicklung', color: 'var(--primary)',     emoji: '↗' },
  gap:        { label: 'Lücke',          color: 'var(--destructive)', emoji: '✗' },
  guessing:   { label: 'Geraten',        color: 'var(--warning)',     emoji: '?' },
}

// ── Formatters ────────────────────────────────────────────────────────────────

export function formatDate(iso: string) {
  return new Intl.DateTimeFormat('de-DE', {
    day: '2-digit',
    month: 'long',
    year: 'numeric',
  }).format(new Date(iso))
}

export function formatDuration(ms: number) {
  const totalSec = Math.round(ms / 1000)
  const min = Math.floor(totalSec / 60)
  const sec = totalSec % 60
  if (min === 0) return `${sec}s`
  return `${min}m ${sec}s`
}

// ── RadialGauge ───────────────────────────────────────────────────────────────

export function RadialGauge({
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
      <circle cx={size / 2} cy={size / 2} r={radius} stroke="var(--border)" strokeWidth={thickness} fill="none" />
      <circle
        cx={size / 2} cy={size / 2} r={radius}
        stroke={color} strokeWidth={thickness} fill="none"
        strokeDasharray={circumference} strokeDashoffset={offset}
        strokeLinecap="round"
        transform={`rotate(-90 ${size / 2} ${size / 2})`}
        style={{ transition: 'stroke-dashoffset 0.6s ease' }}
      />
    </svg>
  )
}

// ── GaugeCard ─────────────────────────────────────────────────────────────────

export function GaugeCard({
  icon, label, value, color, inverted = false, caption,
}: {
  icon: ReactNode
  label: string
  value: number
  color: string
  inverted?: boolean
  caption: string
}) {
  const displayColor = inverted
    ? value > 60 ? 'var(--destructive)' : value > 30 ? 'var(--warning)' : 'var(--success)'
    : value > 65 ? color : value > 35 ? 'var(--warning)' : 'var(--destructive)'

  return (
    <div className="flex flex-col items-center rounded-3xl bg-card p-6 text-center border-2 border-b-4 border-[var(--border)]">
      <div className="relative">
        <RadialGauge value={value} color={displayColor} />
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span style={{ color: displayColor }} className="mb-1">{icon}</span>
          <span className="text-3xl font-black" style={{ color: displayColor }}>{value}</span>
        </div>
      </div>
      <p className="mt-3 text-xs font-bold uppercase tracking-wider text-muted">{label}</p>
      <p className="mt-1.5 text-xs font-semibold text-muted leading-relaxed max-w-[180px]">{caption}</p>
    </div>
  )
}

// ── KpiCard ───────────────────────────────────────────────────────────────────

export function KpiCard({
  icon, label, value, sub, color, bg,
}: {
  icon: ReactNode
  label: string
  value: string
  sub?: string
  color: string
  bg: string
}) {
  return (
    <div className="rounded-2xl bg-card p-5 border-2 border-b-4 border-[var(--border)]">
      <div className="flex items-center gap-2.5 mb-3">
        <span className="flex h-9 w-9 items-center justify-center rounded-xl" style={{ background: bg, color }}>
          {icon}
        </span>
        <p className="text-xs font-bold uppercase tracking-wider text-muted">{label}</p>
      </div>
      <p className="text-3xl font-black text-foreground tracking-tight">{value}</p>
      {sub && <p className="mt-0.5 text-xs font-semibold text-muted">{sub}</p>}
    </div>
  )
}

// ── FlagTag ───────────────────────────────────────────────────────────────────

export function FlagTag({ label, tone = 'primary' }: { label: string; tone?: 'primary' | 'warning' | 'success' }) {
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

// ── SkillBar ──────────────────────────────────────────────────────────────────

export function SkillBar({ cluster, level, label }: { cluster: string; level: number; label: string }) {
  const colorMap = {
    Sicher:     { c: 'var(--success)',     d: 'var(--success-dark)' },
    Erkennbar:  { c: 'var(--primary)',     d: 'var(--primary-shadow)' },
    Lücke:      { c: 'var(--destructive)', d: 'var(--destructive-dark)' },
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
          style={{ width: `${pct}%`, background: `linear-gradient(90deg, ${color} 0%, ${dark} 100%)` }}
        />
        {[10, 40, 70].map(tickPct => (
          <div
            key={tickPct}
            className="absolute top-0 bottom-0 w-px bg-card opacity-60"
            style={{ left: `${tickPct}%` }}
          />
        ))}
      </div>
      <div className="mt-1 flex justify-between text-[10px] font-bold uppercase tracking-wider text-muted">
        <span>L1</span><span>L5</span><span>L10</span>
      </div>
    </div>
  )
}

// ── MiniMetric ────────────────────────────────────────────────────────────────

export function MiniMetric({
  label, value, color, inverted = false,
}: {
  label: string
  value: number
  color: string
  inverted?: boolean
}) {
  const display = inverted
    ? value > 60 ? 'var(--destructive)' : value > 30 ? 'var(--warning)' : 'var(--success)'
    : value > 65 ? color : value > 35 ? 'var(--warning)' : 'var(--destructive)'
  return (
    <div className="rounded-lg bg-card p-2 text-center border border-[var(--border)]">
      <p className="text-[9px] font-bold uppercase tracking-wider text-muted">{label}</p>
      <p className="text-base font-black" style={{ color: display }}>{value}</p>
    </div>
  )
}

// ── SmallBadge ────────────────────────────────────────────────────────────────

export function SmallBadge({ icon, text }: { icon?: ReactNode; text: string }) {
  return (
    <span className="inline-flex items-center gap-1 rounded-full px-2 py-0.5 text-[10px] font-bold text-muted bg-[var(--background)] border border-[var(--border)]">
      {icon}
      {text}
    </span>
  )
}

// ── KV ────────────────────────────────────────────────────────────────────────

export function KV({ k, v }: { k: string; v: string }) {
  return (
    <div className="flex items-center justify-between rounded-lg bg-card px-2.5 py-1.5 border border-[var(--border)]">
      <span className="text-muted">{k}</span>
      <span className="text-foreground font-black">{v}</span>
    </div>
  )
}

// ── SectionHeader ─────────────────────────────────────────────────────────────

export function SectionHeader({
  icon, label, description,
}: {
  icon: ReactNode
  label: string
  description?: string
}) {
  return (
    <div className="mb-4 flex items-start gap-3">
      <span
        className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-primary bg-[color-mix(in_srgb,var(--primary)_10%,transparent)]"
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

// ── TaskCard ──────────────────────────────────────────────────────────────────

export function TaskCard({
  index, task, snapshot, analysis,
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
    ? ratingNum >= 3 ? 'var(--success)' : ratingNum === 2 ? 'var(--warning)' : 'var(--destructive)'
    : 'var(--muted)'
  const ratingDark = ratingNum
    ? ratingNum >= 3 ? 'var(--success-dark)' : ratingNum === 2 ? 'var(--warning-dark)' : 'var(--destructive-dark)'
    : 'var(--border-strong)'

  return (
    <div className="rounded-2xl bg-card overflow-hidden transition-all border-2 border-b-4 border-[var(--border)]">
      <button
        type="button"
        onClick={() => setOpen(o => !o)}
        className="w-full flex items-center gap-4 p-5 text-left hover:bg-background transition-colors"
      >
        <div className="flex flex-col items-center gap-1 shrink-0">
          <span className="text-[10px] font-bold uppercase tracking-wider text-muted">Aufg. {index + 1}</span>
          <span
            className="flex h-12 w-12 items-center justify-center rounded-2xl text-base font-black text-white"
            style={{ background: ratingColor, borderBottom: `3px solid ${ratingDark}` }}
          >
            {ratingNum ? `L${ratingNum}` : '–'}
          </span>
        </div>

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
          {open ? '▲' : '▼'}
        </span>
      </button>

      {open && snapshot && analysis && (
        <div className="border-t-2 border-border p-5 bg-[var(--background)]">
          <div className="grid grid-cols-1 gap-5 lg:grid-cols-5">
            <div className="lg:col-span-3">
              <p className="text-xs font-bold uppercase tracking-wider text-muted mb-2">Schülerantwort</p>
              <pre className="whitespace-pre-wrap font-mono text-sm bg-card rounded-xl p-4 leading-relaxed border-2 border-[var(--border)]">
                {snapshot.answer_text}
              </pre>
              <p className="mt-3 text-xs font-bold uppercase tracking-wider text-muted mb-2">Musterlösung</p>
              <pre
                className="whitespace-pre-wrap font-mono text-sm rounded-xl p-4 leading-relaxed bg-[color-mix(in_srgb,var(--success)_6%,transparent)] border-2 border-[color-mix(in_srgb,var(--success)_25%,transparent)]"
              >
                {task.solution}
              </pre>
            </div>

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
