/**
 * Edvance Design-System v2 — Schueler-App Showcase
 *
 * SCHRITT 5 — Schueler-App exklusiv: Verlauf-Header, Hero-Card,
 * Glaseffekte, XP-Bar Gold-Gradient, Animationen (fly-in, xp-float,
 * count-up, bar-grow). Glaseffekte AUSSCHLIESSLICH auf dunklen
 * Flaechen (Regel 3 aus Schritt 7).
 */
import { useState, type JSX } from 'react'
import { cn } from '@/lib/utils'

function StreakPill({ count }: { count: number }): JSX.Element {
  return (
    <div className="glass-pill px-3 py-1.5 inline-flex items-center gap-1.5 text-white">
      <span aria-hidden="true">🔥</span>
      <span className="text-sm font-semibold">{count}</span>
      <span className="text-xs opacity-80">Tage</span>
    </div>
  )
}

function LevelPill({ level }: { level: number }): JSX.Element {
  return (
    <div className="glass-pill px-3 py-1.5 inline-flex items-center gap-1.5 text-white">
      <span className="text-[10px] uppercase tracking-widest opacity-70">Level</span>
      <span className="text-sm font-bold">{level}</span>
    </div>
  )
}

function XpBar({ value, target }: { value: number; target: number }): JSX.Element {
  const pct = Math.min(100, Math.round((value / target) * 100))
  return (
    <div className="flex flex-col gap-1">
      <div className="flex items-baseline justify-between text-white">
        <span className="text-[10px] uppercase tracking-widest opacity-70">XP-Fortschritt</span>
        <span className="text-xs font-semibold">
          {value} / {target}
        </span>
      </div>
      <div className="bg-white/15 rounded-full h-2 overflow-hidden">
        <div
          className="xp-bar-fill h-full rounded-full animate-bar-grow"
          style={{ ['--bar-target' as string]: `${pct}%` }}
        />
      </div>
    </div>
  )
}

function HeroCard(): JSX.Element {
  return (
    <div className="student-hero light-source overflow-hidden rounded-[var(--radius-lg)] p-6 shadow-lg animate-fly-in">
      <div className="relative">
        <p className="text-[10px] uppercase tracking-widest opacity-70 text-white">Heute</p>
        <h2 className="text-2xl font-bold text-white mt-1">Mathematik · Bruchrechnen</h2>
        <p className="text-sm text-white/80 mt-2 max-w-xs leading-relaxed">
          5 Aufgaben warten auf dich. Ungefaehr 8 Minuten — und du sicherst deinen Streak.
        </p>
        <button
          type="button"
          className="mt-5 glass-button px-5 py-2.5 rounded-md text-white text-sm font-medium hover:-translate-y-0.5 transition-all duration-base ease-bounce"
        >
          Lernpfad starten
        </button>
      </div>
    </div>
  )
}

function TaskCard(): JSX.Element {
  const [showXp, setShowXp] = useState(false)
  const [tick, setTick] = useState(0)

  function trigger(): void {
    setTick((t) => t + 1)
    setShowXp(true)
    window.setTimeout(() => setShowXp(false), 1200)
  }

  return (
    <div className="relative bg-[var(--color-bg-surface)] border border-[var(--color-border)] rounded-[var(--radius-lg)] p-6 shadow-md hover:-translate-y-1 hover:shadow-lg transition-all duration-base ease-bounce animate-fly-in">
      <p className="text-[10px] uppercase tracking-widest text-[var(--color-text-tertiary)]">Aufgabe 3 von 5</p>
      <p className="text-base font-semibold mt-2">Wie viel ergibt 3/4 + 1/8?</p>
      <div className="grid grid-cols-2 gap-2 mt-4">
        {['5/8', '7/8', '4/12', '6/8'].map((opt) => (
          <button
            key={opt}
            type="button"
            onClick={trigger}
            className="border border-[var(--color-border)] rounded-md py-3 text-sm font-medium hover:border-[var(--color-primary)] hover:bg-[var(--color-primary-light)] transition-all duration-fast"
          >
            {opt}
          </button>
        ))}
      </div>
      {showXp ? (
        <span
          key={tick}
          className="absolute -top-2 right-4 inline-flex items-center px-2 py-0.5 text-xs font-bold rounded-sm bg-[var(--color-gold-altgold)] text-[var(--color-text-primary)] animate-xp-float"
        >
          +25 XP
        </span>
      ) : null}
      <p className="text-[10px] text-[var(--color-text-tertiary)] mt-3 italic">
        Antippen → XP-Float-Animation triggert (Regel: nur positives Feedback).
      </p>
    </div>
  )
}

function CountUpDemo(): JSX.Element {
  const [key, setKey] = useState(0)
  return (
    <div className="bg-[var(--color-bg-surface)] border border-[var(--color-border)] rounded-[var(--radius-lg)] p-6 shadow-md flex items-center gap-5">
      <span
        key={key}
        className="text-3xl font-bold text-[var(--color-primary)] animate-count-up"
      >
        1.245
      </span>
      <div className="flex-1">
        <p className="text-base font-semibold">Gesamt-XP</p>
        <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">
          `animate-count-up` mit Bounce-Easing. Skaliert beim Erscheinen.
        </p>
      </div>
      <button
        type="button"
        onClick={() => setKey((k) => k + 1)}
        className="text-[var(--color-primary)] px-3 py-1.5 rounded-md hover:bg-[var(--color-primary-light)] text-sm font-medium"
      >
        Replay
      </button>
    </div>
  )
}

export function V2Student(): JSX.Element {
  return (
    <div data-interface="student" className="flex flex-col gap-5">
      <p className="text-xs text-[var(--color-text-tertiary)]">
        Schueler-App · lebendig, motivierend. Verlaeufe, Glas, Bounce-Animationen.
      </p>

      <header className={cn('student-header light-source rounded-[var(--radius-lg)] px-5 py-4 shadow-lg overflow-hidden')}>
        <div className="relative flex flex-col gap-4">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-[10px] uppercase tracking-widest text-white/70">Hi Mia</p>
              <p className="text-lg font-semibold text-white">Bereit fuer heute?</p>
            </div>
            <div className="flex gap-2">
              <StreakPill count={12} />
              <LevelPill level={7} />
            </div>
          </div>
          <XpBar value={345} target={500} />
        </div>
      </header>

      <HeroCard />
      <TaskCard />
      <CountUpDemo />
    </div>
  )
}
