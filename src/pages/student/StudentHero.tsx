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
 * Schüler-Hero — Hub-Header der Mock: reitet direkt auf der dunklen
 * `.session-stage` (Elternseite), warme Off-White-Typo + Glass-XP-Karte.
 * Glass-Pill-Streaks + Glass-Card NUR auf dieser dunklen Bühne (Hard Rule §3).
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
    <section className="mx-auto max-w-3xl px-4 pb-2 pt-8 text-warm">
      <div className="mb-6 flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0">
          <p className="text-eyebrow text-warm-56">Heute · Mein Lernplan</p>
          <h1 className="text-display mt-1.5 text-3xl leading-none text-warm">
            Hi {displayName} 👋
          </h1>
          <p className="mt-2 max-w-md text-sm text-warm-72">
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

      <EdvanceCard variant="glass" className="p-5 text-warm">
        <XPBar
          current={xpTotal % XP_PER_LEVEL}
          max={XP_PER_LEVEL}
          level={level}
          levelName={`Level ${level}`}
        />
      </EdvanceCard>
    </section>
  )
}
