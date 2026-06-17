import { XPBar, StreakPill, EdvanceCard } from '@/components/edvance'

const XP_PER_LEVEL = 500

interface StudentHeroProps {
  displayName: string
  xpTotal: number
  /** Präsenz-Streak in Wochen (Migration 032). */
  presenceWeeks: number
  /** Home-Streak in Sessions (Migration 032). */
  homeSessions: number
  presenceMultiplier?: number
  level: number
}

/**
 * Schüler-Hero — student-hero Gradient + light-source Overlay.
 * Glass-Pill-Streaks NUR auf dieser dunklen Bühne erlaubt (Hard Rule §3).
 */
export function StudentHero({
  displayName,
  xpTotal,
  presenceWeeks,
  homeSessions,
  presenceMultiplier = 1,
  level,
}: StudentHeroProps) {
  return (
    <section className="relative overflow-hidden student-hero light-source">
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

          <div className="flex flex-col gap-2">
            <StreakPill
              variant="presence"
              count={presenceWeeks}
              multiplier={presenceMultiplier}
            />
            <StreakPill variant="home" count={homeSessions} />
          </div>
        </div>

        <EdvanceCard variant="glass" className="p-5">
          <XPBar
            current={xpTotal % XP_PER_LEVEL}
            max={XP_PER_LEVEL}
            level={level}
            levelName={`Level ${level}`}
          />
        </EdvanceCard>
      </div>
    </section>
  )
}
