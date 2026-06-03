import { useState, type JSX, type ReactNode } from 'react'
import { MasteryBar, EdvanceBadge, RarityBadge, StreakPill, XPBar } from '@/components/edvance'
import {
  MASTERY_STAGES,
  MASTERY_STAGE_LABEL,
  MASTERY_STAGE_COLOR,
} from '@/lib/mastery'
import type { BadgeRarity } from '@/components/edvance'

/** Repräsentativer Score je Stufe (Mitte des Spec-Bereichs). */
const STAGE_SCORE: Record<string, number> = {
  introduced: 20,
  developing: 50,
  progressing: 68,
  proficient: 80,
  mastered: 92,
}

const COLOR_FAMILIES: { title: string; swatches: { label: string; varName: string }[] }[] = [
  {
    title: 'Primär — Midnight Academy',
    swatches: [
      { label: 'Primary', varName: '--color-primary' },
      { label: 'Hover', varName: '--color-primary-hover' },
      { label: 'Light', varName: '--color-primary-light' },
      { label: 'Navy Deep', varName: '--color-navy-deep' },
    ],
  },
  {
    title: 'Grün — 6 Kontexte',
    swatches: [
      { label: 'Mastered', varName: '--color-success' },
      { label: 'Eltern', varName: '--color-success-eltern' },
      { label: 'Antwort', varName: '--color-success-answer' },
      { label: 'Grow', varName: '--color-success-grow' },
      { label: 'Celebration', varName: '--color-success-celebration' },
      { label: 'Skilltree', varName: '--color-success-skilltree' },
    ],
  },
  {
    title: 'Rot — 5 Kontexte',
    swatches: [
      { label: 'Lücke', varName: '--color-error-gap' },
      { label: 'Antwort', varName: '--color-error-answer' },
      { label: 'Klausur', varName: '--color-error-exam' },
      { label: 'Streak', varName: '--color-error-streak' },
      { label: 'Coach', varName: '--color-error-coach' },
    ],
  },
  {
    title: 'Gold & Lila',
    swatches: [
      { label: 'Altgold', varName: '--color-gold-altgold' },
      { label: 'Champagner', varName: '--color-gold-champagner' },
      { label: 'Accent', varName: '--color-accent' },
      { label: 'Warning', varName: '--color-gold-warning' },
      { label: 'Repair', varName: '--color-repair' },
    ],
  },
]

const RARITIES: BadgeRarity[] = ['bronze', 'silver', 'gold', 'platinum']

function Section({ eyebrow, title, children }: { eyebrow: string; title: string; children: ReactNode }): JSX.Element {
  return (
    <section className="flex flex-col gap-4">
      <div className="flex flex-col gap-1">
        <p className="text-eyebrow text-[var(--color-text-tertiary)]">{eyebrow}</p>
        <h2 className="text-base font-semibold text-[var(--color-text-primary)]">{title}</h2>
      </div>
      {children}
    </section>
  )
}

function Card({ children, className = '' }: { children: ReactNode; className?: string }): JSX.Element {
  return (
    <div
      className={`rounded-[var(--radius-lg)] border border-[var(--color-border)] bg-[var(--color-bg-surface)] p-6 shadow-md ${className}`}
    >
      {children}
    </div>
  )
}

function ColorSection(): JSX.Element {
  return (
    <Section eyebrow="§02 · Foundation" title="Farb-System (kontextabhängig)">
      <div className="grid gap-4 sm:grid-cols-2">
        {COLOR_FAMILIES.map((fam) => (
          <Card key={fam.title}>
            <p className="mb-3 text-sm font-semibold text-[var(--color-text-secondary)]">{fam.title}</p>
            <div className="flex flex-wrap gap-3">
              {fam.swatches.map((s) => (
                <div key={s.varName} className="flex flex-col items-center gap-1.5">
                  <span
                    className="h-12 w-12 rounded-[var(--radius-md)] border border-[var(--color-border)]"
                    style={{ backgroundColor: `var(${s.varName})` }}
                  />
                  <span className="text-[10px] text-[var(--color-text-tertiary)]">{s.label}</span>
                </div>
              ))}
            </div>
          </Card>
        ))}
      </div>
    </Section>
  )
}

function MasterySection(): JSX.Element {
  return (
    <Section eyebrow="§03 · Progress Model" title="Mastery — 5 Stufen nach Score">
      <Card>
        <div className="flex flex-col gap-5">
          {MASTERY_STAGES.map((stage) => (
            <div key={stage} className="flex flex-col gap-1.5">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-[var(--color-text-primary)]">
                  {MASTERY_STAGE_LABEL[stage]}
                </span>
                <span className="text-xs font-bold" style={{ color: MASTERY_STAGE_COLOR[stage] }}>
                  {STAGE_SCORE[stage]}%
                </span>
              </div>
              <MasteryBar score={STAGE_SCORE[stage]} size="md" />
            </div>
          ))}
        </div>
        <p className="mt-4 text-xs text-[var(--color-text-tertiary)]">
          Mastered (85–100%) nur in Präsenz — kein Home-App-Pfad (Hard Rule §6).
        </p>
      </Card>
    </Section>
  )
}

function DarkStageSection(): JSX.Element {
  return (
    <Section eyebrow="§09 · Surface" title="Glas-Effekte & Gradienten (nur auf dunkel)">
      <div className="relative overflow-hidden rounded-[var(--radius-xl)] student-hero light-source p-6">
        <p className="text-eyebrow opacity-70">Student-Hero-Bühne</p>
        <div className="mt-4 flex flex-wrap items-center gap-3">
          <div className="glass-pill px-4 py-2 text-sm font-semibold text-white">🔥 5 W Präsenz</div>
          <div className="glass-button rounded-[var(--radius-md)] px-4 py-2 text-sm font-semibold">
            Aufgabe starten
          </div>
        </div>
        <div className="glass-card mt-4 p-4">
          <p className="text-sm font-semibold text-white">Glass-Card</p>
          <p className="mt-1 text-xs text-white/70">
            backdrop-blur 16px · nur auf Midnight-Bühne (Hard Rule §3)
          </p>
        </div>
      </div>
    </Section>
  )
}

function GamificationSection(): JSX.Element {
  return (
    <Section eyebrow="§05–06 · Progression" title="XP, Streaks & Badges">
      <Card>
        <div className="flex flex-col gap-5">
          <XPBar current={2340} max={3000} level={7} levelName="Fortgeschritten" />
          <div className="flex flex-wrap gap-3">
            <StreakPill variant="presence" count={5} multiplier={1.2} />
            <StreakPill variant="home" count={12} />
            <StreakPill variant="presence" count={3} frozen />
          </div>
          <div className="flex flex-wrap items-end gap-4">
            {RARITIES.map((r) => (
              <div key={r} className="flex flex-col items-center gap-2">
                <RarityBadge rarity={r} form="round" size="md" />
                <span className="text-[10px] uppercase tracking-wider text-[var(--color-text-tertiary)]">{r}</span>
              </div>
            ))}
            <div className="flex flex-col items-center gap-2">
              <RarityBadge rarity="platinum" form="shield" size="md">8</RarityBadge>
              <span className="text-[10px] uppercase tracking-wider text-[var(--color-text-tertiary)]">Shield</span>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <EdvanceBadge variant="mastered">Gemeistert</EdvanceBadge>
            <EdvanceBadge variant="strength">Stärke</EdvanceBadge>
            <EdvanceBadge variant="exam">Klausur</EdvanceBadge>
            <EdvanceBadge variant="xp-day">+40 XP</EdvanceBadge>
            <EdvanceBadge variant="repair">Repair</EdvanceBadge>
          </div>
        </div>
      </Card>
    </Section>
  )
}

function AnimationSection(): JSX.Element {
  const [key, setKey] = useState(0)
  const anims = [
    { cls: 'animate-fly-in', label: 'flyIn 400ms' },
    { cls: 'animate-xp-float', label: 'xpFloat 1200ms' },
    { cls: 'animate-count-up', label: 'countUp 500ms' },
    { cls: 'animate-bar-grow', label: 'barGrow 800ms' },
  ]
  return (
    <Section eyebrow="§11 · Motion" title="Animationen (Spec-Timing)">
      <Card>
        <button
          type="button"
          onClick={() => setKey((k) => k + 1)}
          className="mb-4 rounded-[var(--radius-md)] bg-[var(--color-primary)] px-4 py-2 text-sm font-semibold text-white shadow-md transition-colors hover:bg-[var(--color-primary-hover)]"
        >
          Erneut abspielen
        </button>
        <div key={key} className="grid gap-4 sm:grid-cols-2">
          {anims.map((a) => (
            <div
              key={a.cls}
              className="flex items-center justify-center rounded-[var(--radius-md)] bg-[var(--color-bg-subtle)] p-6"
            >
              {a.cls === 'animate-bar-grow' ? (
                <div className="h-2.5 w-full overflow-hidden rounded-[var(--radius-full)] bg-[var(--color-border)]">
                  <div className={`${a.cls} xp-bar-fill h-full`} style={{ ['--bar-target' as string]: '85%' }} />
                </div>
              ) : (
                <span className={`${a.cls} text-sm font-bold text-[var(--color-primary)]`}>{a.label}</span>
              )}
            </div>
          ))}
        </div>
      </Card>
    </Section>
  )
}

export function V3Showcase(): JSX.Element {
  return (
    <div className="min-h-screen bg-[var(--color-bg-app)]">
      <div className="relative overflow-hidden student-header">
        <div className="relative mx-auto max-w-3xl px-4 py-8 text-white">
          <p className="text-eyebrow opacity-70">Edvance · Midnight Academy</p>
          <h1 className="text-display mt-1.5 text-2xl leading-none">Design-System v3 — Living Reference</h1>
          <p className="mt-2 max-w-lg text-sm opacity-70">
            Verifiziert gegen die Single Source of Truth (v1.0). Jede Sektion zeigt den
            echten, spec-konformen Code-Stand.
          </p>
        </div>
      </div>

      <main className="mx-auto flex max-w-3xl flex-col gap-10 px-4 py-8">
        <ColorSection />
        <MasterySection />
        <DarkStageSection />
        <GamificationSection />
        <AnimationSection />
      </main>
    </div>
  )
}
