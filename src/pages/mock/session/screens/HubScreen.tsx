import type { JSX } from 'react'
import { useTranslation } from 'react-i18next'
import { Rocket, Route, Trophy, Smile } from 'lucide-react'
import { AvatarInitials, StreakPill, XPBar } from '@/components/edvance'
import { SessionShell } from '../components/SessionShell'
import { HubTile } from '../components/HubTile'
import { WeekStreak, type DayState } from '../components/WeekStreak'
import { MOCK_SESSION_STUDENT, MOCK_SESSION_TOPIC } from '@/lib/mocks/session'
import { levelFromXp, xpInLevel, XP_PER_LEVEL } from '@/lib/mocks/sessionMachine'
import type { ScreenProps } from '../screenProps'

/** Diese Woche: ein Tag erledigt, heute läuft die Session (füllt sich am Ende). */
const WEEK_HUB: DayState[] = [
  'done',
  'today-open',
  'empty',
  'empty',
  'empty',
  'empty',
  'empty',
]

/**
 * Screen 2 — Hub / Tablet-Menü. Launchpad mit lautem Gamification-Header
 * (Level, Presence-Streak) und Absprung-Kacheln. Nach „Session starten"
 * tritt der Hub zurück (linearer Flow). Nie andere Schüler, nie Rangliste.
 */
export function HubScreen({ state, dispatch }: ScreenProps): JSX.Element {
  const { t } = useTranslation('mock')
  const student = MOCK_SESSION_STUDENT
  const level = levelFromXp(state.xp)

  const header = (
    <div className="flex flex-col gap-3">
      <div className="flex items-center gap-3">
        <div className="min-w-0 flex-1">
          <XPBar
            current={xpInLevel(state.xp)}
            max={XP_PER_LEVEL}
            level={level}
            levelName={t('session.common.level', { level })}
          />
        </div>
        <AvatarInitials name={student.fullName} size="sm" />
      </div>
      <div className="flex flex-wrap items-center justify-between gap-3">
        <StreakPill
          variant="presence"
          count={student.presenceWeeks}
          multiplier={state.presenceMultiplier}
        />
        <WeekStreak states={WEEK_HUB} />
      </div>
    </div>
  )

  return (
    <SessionShell header={header} showExit>
      <div className="flex flex-col gap-6 pt-2">
        <div>
          <p className="text-eyebrow text-warm-56">{t('session.hub.eyebrow')}</p>
          <h1 className="text-display mt-1 text-2xl text-warm">
            {t('session.hub.greeting', { name: student.displayName })}
          </h1>
          <p className="mt-1 text-sm text-warm-72">{t('session.hub.subtitle')}</p>
        </div>

        <HubTile
          emphasis
          icon={<Rocket className="h-7 w-7" />}
          title={t('session.hub.tileSessionTitle')}
          description={t('session.hub.tileSessionDesc', { topic: MOCK_SESSION_TOPIC.name })}
          onClick={() => dispatch({ type: 'START_SESSION' })}
        />

        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <HubTile
            icon={<Route className="h-6 w-6" />}
            title={t('session.hub.tileProgressTitle')}
            description={t('session.hub.tileProgressDesc')}
            onClick={() => dispatch({ type: 'OPEN_PROGRESS' })}
          />
          <HubTile
            icon={<Trophy className="h-6 w-6" />}
            title={t('session.hub.tileTrophiesTitle')}
            description={t('session.hub.tileTrophiesDesc')}
            onClick={() => dispatch({ type: 'OPEN_TROPHIES' })}
          />
        </div>

        <HubTile
          disabled
          icon={<Smile className="h-6 w-6" />}
          title={t('session.hub.tileAvatarTitle')}
          description={t('session.hub.avatarLocked')}
        />

        <div className="flex justify-center pt-2">
          <button
            type="button"
            onClick={() => dispatch({ type: 'OPEN_STREAK_REPAIR' })}
            className="min-h-[44px] text-xs font-semibold uppercase tracking-widest text-warm-42 hover:text-warm-72"
          >
            {t('session.hub.demoStreakLoss')}
          </button>
        </div>
      </div>
    </SessionShell>
  )
}
