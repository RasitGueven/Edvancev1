import { Flame } from 'lucide-react'
import { XPBar } from '@/components/edvance'

const XP_PER_LEVEL = 500

interface StudentHeroProps {
  displayName: string
  xpTotal: number
  streakDays: number
  level: number
}

export function StudentHero({ displayName, xpTotal, streakDays, level }: StudentHeroProps) {
  return (
    <section className="relative overflow-hidden bg-gradient-hero noise-overlay">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-24 -right-24 h-72 w-72 rounded-full opacity-20 blur-3xl"
        style={{ background: 'var(--color-moment-gold)' }}
      />
      <div className="mx-auto max-w-3xl px-4 py-8 text-white">
        <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
          <div className="min-w-0">
            <p className="text-eyebrow opacity-70">Heute · Mein Lernplan</p>
            <h1 className="text-display text-3xl mt-1.5 leading-none">
              Hi {displayName} 👋
            </h1>
            <p className="mt-2 text-sm opacity-80 max-w-md">
              Wähle ein Thema oder suche direkt nach einer Aufgabe.
            </p>
          </div>

          <div className="inline-flex items-center gap-2 rounded-full bg-white/10 backdrop-blur-sm px-3 py-1.5 text-xs font-semibold">
            <Flame className="h-3.5 w-3.5 text-[var(--color-moment-gold)]" />
            {streakDays} Tage Streak
          </div>
        </div>

        <div className="glass-dark rounded-[var(--radius-xl)] p-5">
          <XPBar
            current={xpTotal % XP_PER_LEVEL}
            max={XP_PER_LEVEL}
            level={level}
            levelName={`Level ${level}`}
          />
        </div>
      </div>
    </section>
  )
}
